import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/formatters/money_formatter.dart';
import '../../../core/files/pdf_export.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_date_field.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/list_header_bar.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/section_header.dart';
import '../../dashboard/domain/dashboard_models.dart';
import '../../transactions/domain/transaction_models.dart';
import '../../transactions/presentation/transactions_screen.dart';
import '../data/reports_repository.dart';
import '../domain/report_models.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({required this.repository, super.key});
  final ReportsRepository repository;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportLookups? lookups;
  bool loading = true;
  bool failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      lookups = await widget.repository.lookups();
    } catch (_) {
      failed = true;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (loading) return AppStateView.loading();
    if (failed) {
      return AppStateView.error(
        message: s.reportsLoadError,
        retryLabel: s.retry,
        onRetry: _load,
      );
    }
    final cards = [
      _ReportCard(
        s.clientStatement,
        Icons.person_outline,
        () => _statement(ReportKind.client),
      ),
      _ReportCard(
        s.shipStatement,
        Icons.directions_boat_outlined,
        () => _statement(ReportKind.ship),
      ),
      _ReportCard(
        s.partnerStatement,
        Icons.handshake_outlined,
        () => _statement(ReportKind.partner),
      ),
      _ReportCard(
        s.ownerStatement,
        Icons.badge_outlined,
        () => _statement(ReportKind.owner),
      ),
      _ReportCard(s.dailySummary, Icons.today_outlined, () => _summary(true)),
      _ReportCard(
        s.customDateReport,
        Icons.date_range_outlined,
        () => _summary(false),
      ),
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 1100
              ? 3
              : constraints.maxWidth >= 650
              ? 2
              : 1;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              ListHeaderBar(
                title: s.reports,
                onRefresh: _load,
                refreshTooltip: s.refresh,
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: columns == 1 ? 3.2 : 2.3,
                children: cards
                    .map(
                      (item) => Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          boxShadow: AppShadows.soft(
                            Theme.of(context).colorScheme.shadow,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: item.open,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    item.icon,
                                    size: 24,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _statement(ReportKind kind) async {
    final request = await Navigator.push<StatementRequest>(
      context,
      MaterialPageRoute(
        builder: (_) => StatementSetupScreen(kind: kind, lookups: lookups!),
      ),
    );
    if (request != null && mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => StatementPreviewScreen(
            repository: widget.repository,
            request: request,
          ),
        ),
      );
    }
  }

  Future<void> _summary(bool daily) async {
    final today = DateUtils.dateOnly(DateTime.now());
    DateTime? start = today;
    DateTime? end = today;
    if (!daily) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDateRange: DateTimeRange(start: today, end: today),
      );
      if (range == null) return;
      start = range.start;
      end = range.end;
    }
    if (mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => SummaryReportScreen(
            repository: widget.repository,
            start: start!,
            end: end!,
            daily: daily,
          ),
        ),
      );
    }
  }
}

class _ReportCard {
  const _ReportCard(this.title, this.icon, this.open);
  final String title;
  final IconData icon;
  final VoidCallback open;
}

class StatementSetupScreen extends StatefulWidget {
  const StatementSetupScreen({
    required this.kind,
    required this.lookups,
    super.key,
  });
  final ReportKind kind;
  final ReportLookups lookups;

  @override
  State<StatementSetupScreen> createState() => _StatementSetupScreenState();
}

class _StatementSetupScreenState extends State<StatementSetupScreen> {
  String? entity;
  String? clientShip;
  final trips = <String>{};
  DateTime? start;
  DateTime? end;
  String? error;

  List<LookupOption> get entities => switch (widget.kind) {
    ReportKind.client => widget.lookups.clients,
    ReportKind.ship => widget.lookups.ships,
    ReportKind.partner => widget.lookups.partners,
    ReportKind.owner => widget.lookups.owners,
  };

  String title(AppLocalizations s) => switch (widget.kind) {
    ReportKind.client => s.clientStatement,
    ReportKind.ship => s.shipStatement,
    ReportKind.partner => s.partnerStatement,
    ReportKind.owner => s.ownerStatement,
  };

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final entityLabel = switch (widget.kind) {
      ReportKind.client => s.client,
      ReportKind.ship => s.shipName,
      ReportKind.partner => s.partners,
      ReportKind.owner => s.owner,
    };
    final tripOptions = widget.lookups.trips.where((item) {
      final shipId = widget.kind == ReportKind.ship ? entity : clientShip;
      return shipId == null || item.parentId == shipId;
    }).toList();
    return Scaffold(
      appBar: AppBar(title: Text(title(s))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          DropdownButtonFormField<String>(
            initialValue: entity,
            decoration: InputDecoration(labelText: entityLabel),
            items: entities
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: (value) => setState(() {
              entity = value;
              if (widget.kind == ReportKind.ship) trips.clear();
            }),
          ),
          if (widget.kind == ReportKind.client) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: clientShip,
              decoration: InputDecoration(labelText: s.shipOptional),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(s.all)),
                ...widget.lookups.ships.map(
                  (item) => DropdownMenuItem<String?>(
                    value: item.id,
                    child: Text(item.name),
                  ),
                ),
              ],
              onChanged: (value) => setState(() {
                clientShip = value;
                trips.clear();
              }),
            ),
          ],
          if (widget.kind == ReportKind.client ||
              widget.kind == ReportKind.ship) ...[
            const SizedBox(height: 18),
            Text(
              widget.kind == ReportKind.ship ? s.selectTrips : s.tripOptional,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (tripOptions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(s.noTrips),
              )
            else
              ...tripOptions.map(
                (item) => CheckboxListTile(
                  value: trips.contains(item.id),
                  title: Text(item.name),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (selected) => setState(
                    () => selected == true
                        ? trips.add(item.id)
                        : trips.remove(item.id),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          AppDateField(
            label: s.startDate,
            value: start,
            placeholder: s.allDates,
            onChanged: (value) => setState(() => start = value),
          ),
          const SizedBox(height: 10),
          AppDateField(
            label: s.endDate,
            value: end,
            placeholder: s.allDates,
            firstDate: start,
            onChanged: (value) => setState(() => end = value),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              if (entity == null ||
                  (start != null && end != null && start!.isAfter(end!))) {
                setState(() => error = s.reportSelectionError);
                return;
              }
              Navigator.pop(
                context,
                StatementRequest(
                  kind: widget.kind,
                  entityId: entity!,
                  startDate: start,
                  endDate: end,
                  shipId: clientShip,
                  tripIds: trips.toList(),
                ),
              );
            },
            icon: const Icon(Icons.preview_outlined),
            label: Text(s.previewReport),
          ),
        ],
      ),
    );
  }
}

class StatementPreviewScreen extends StatefulWidget {
  const StatementPreviewScreen({
    required this.repository,
    required this.request,
    super.key,
  });
  final ReportsRepository repository;
  final StatementRequest request;
  @override
  State<StatementPreviewScreen> createState() => _StatementPreviewScreenState();
}

class _StatementPreviewScreenState extends State<StatementPreviewScreen> {
  StatementData? data;
  bool loading = true;
  bool failed = false;
  bool sharing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      data = await widget.repository.statement(widget.request);
    } catch (_) {
      failed = true;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(
        title: Text(s.reportPreview),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: s.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? AppStateView.loading()
          : failed
          ? AppStateView.error(
              message: s.reportPreviewError,
              retryLabel: s.retry,
              onRetry: _load,
            )
          : LayoutBuilder(
              builder: (context, constraints) => ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data!.subjectName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: sharing ? null : _share,
                        icon: sharing
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.picture_as_pdf_outlined),
                        label: Text(s.downloadSharePdf),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: data!.summary.entries
                        .map(
                          (item) => SizedBox(
                            width: 220,
                            child: MetricCard(
                              label: _summaryLabel(s, item.key),
                              value: formatMru(item.value, locale),
                              icon: Icons.summarize_outlined,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  if (data!.tripSummaries.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    SectionHeader(s.tripResults),
                    const SizedBox(height: 10),
                    _TripSummaries(
                      rows: data!.tripSummaries,
                      locale: locale,
                      desktop: constraints.maxWidth >= 900,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SectionHeader(s.transactions),
                  const SizedBox(height: 10),
                  if (data!.transactions.isEmpty)
                    AppStateView.empty(
                      message: s.noTransactionsFound,
                      icon: Icons.receipt_long_outlined,
                    )
                  else
                    _ReportRows(
                      rows: data!.transactions,
                      desktop: constraints.maxWidth >= 900,
                      locale: locale,
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _share() async {
    setState(() => sharing = true);
    final title = AppLocalizations.of(context).reportPreview;
    try {
      final bytes = await widget.repository.pdf(widget.request);
      final savedPath = await exportPdf(
        bytes: bytes,
        filename: 'statement.pdf',
        title: title,
      );
      if (mounted && savedPath != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF: $savedPath')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).pdfError)),
        );
      }
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }
}

class _ReportRows extends StatelessWidget {
  const _ReportRows({
    required this.rows,
    required this.desktop,
    required this.locale,
  });
  final List<ReportTransaction> rows;
  final bool desktop;
  final String locale;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (!desktop) {
      return Column(
        children: rows
            .map(
              (row) => Card(
                child: ListTile(
                  title: Text(transactionTypeLabel(s, row.type)),
                  subtitle: Text(
                    '${DateFormat.yMd(locale).format(row.date)} ${row.time.substring(0, 5)}${row.description.isEmpty ? '' : '\n${row.description}'}',
                  ),
                  trailing: MoneyText(row.amount, locale: locale),
                ),
              ),
            )
            .toList(),
      );
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            s.dateTime,
            s.transactionType,
            s.description,
            s.relatedTo,
            s.recordedBy,
            s.amountMru,
          ].map((label) => DataColumn(label: Text(label))).toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '${DateFormat.yMd(locale).format(row.date)} ${row.time.substring(0, 5)}',
                      ),
                    ),
                    DataCell(Text(transactionTypeLabel(s, row.type))),
                    DataCell(Text(row.description)),
                    DataCell(
                      Text(
                        [
                          row.ship,
                          row.trip,
                          row.client,
                        ].whereType<String>().join(' · '),
                      ),
                    ),
                    DataCell(Text(row.createdBy ?? '—')),
                    DataCell(MoneyText(row.amount, locale: locale)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TripSummaries extends StatelessWidget {
  const _TripSummaries({
    required this.rows,
    required this.locale,
    required this.desktop,
  });
  final List<TripReportSummary> rows;
  final String locale;
  final bool desktop;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    if (!desktop) {
      return Column(
        children: rows
            .map(
              (row) => Card(
                child: ListTile(
                  title: Text(DateFormat.yMd(locale).format(row.date)),
                  subtitle: Text(
                    '${s.revenue}: ${formatMru(row.revenue, locale)}\n${s.totalExpenses}: ${formatMru(row.expenses, locale)}\n${s.clientPurchase}: ${formatMru(row.purchases, locale)}',
                  ),
                  trailing: MoneyText(row.remaining, locale: locale),
                ),
              ),
            )
            .toList(),
      );
    }
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            s.trip,
            s.revenue,
            s.totalExpenses,
            s.clientPurchase,
            s.remainingResult,
          ].map((label) => DataColumn(label: Text(label))).toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(DateFormat.yMd(locale).format(row.date))),
                    DataCell(MoneyText(row.revenue, locale: locale)),
                    DataCell(MoneyText(row.expenses, locale: locale)),
                    DataCell(MoneyText(row.purchases, locale: locale)),
                    DataCell(MoneyText(row.remaining, locale: locale)),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class SummaryReportScreen extends StatefulWidget {
  const SummaryReportScreen({
    required this.repository,
    required this.start,
    required this.end,
    required this.daily,
    super.key,
  });
  final ReportsRepository repository;
  final DateTime start;
  final DateTime end;
  final bool daily;
  @override
  State<SummaryReportScreen> createState() => _SummaryReportScreenState();
}

class _SummaryReportScreenState extends State<SummaryReportScreen> {
  DashboardMetrics? data;
  bool loading = true;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      data = await widget.repository.summary(widget.start, widget.end);
    } catch (_) {
      failed = true;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final money = context.moneyColors;
    final values = data == null
        ? <(String, double, IconData, Color)>[]
        : [
            (
              s.expectedCash,
              data!.expectedCash,
              Icons.account_balance_wallet_outlined,
              Theme.of(context).colorScheme.primary,
            ),
            (
              s.peopleOweUs,
              data!.peopleOweUs,
              Icons.call_received_rounded,
              money.positive,
            ),
            (
              s.weOwePeople,
              data!.weOwePeople,
              Icons.call_made_rounded,
              money.negative,
            ),
            (
              s.netPosition,
              data!.netPosition,
              Icons.insights_outlined,
              Theme.of(context).colorScheme.primary,
            ),
            (
              s.totalRevenue,
              data!.totalRevenue,
              Icons.trending_up,
              money.positive,
            ),
            (
              s.totalExpenses,
              data!.totalExpenses,
              Icons.trending_down,
              money.negative,
            ),
            (
              s.profitLoss,
              data!.profitLoss,
              Icons.balance,
              data!.profitLoss >= 0 ? money.positive : money.negative,
            ),
          ];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.daily ? s.dailySummary : s.customDateReport),
      ),
      body: loading
          ? AppStateView.loading()
          : failed
          ? AppStateView.error(
              message: s.reportPreviewError,
              retryLabel: s.retry,
              onRetry: _load,
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '${DateFormat.yMd(locale).format(widget.start)} – ${DateFormat.yMd(locale).format(widget.end)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: values
                      .map(
                        (item) => SizedBox(
                          width: 250,
                          child: MetricCard(
                            label: item.$1,
                            value: formatMru(item.$2, locale),
                            icon: item.$3,
                            accent: item.$4,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }
}

String _summaryLabel(AppLocalizations s, String key) => switch (key) {
  'opening_balance' => s.openingBalance,
  'closing_balance' => s.closingBalance,
  'total_revenue' => s.totalRevenue,
  'total_expenses' => s.totalExpenses,
  'total_client_purchases' => s.totalClientPurchases,
  'remaining_result' => s.remainingResult,
  'total_purchases' => s.totalPurchases,
  'total_payments' => s.totalPayments,
  'total_deposits' => s.totalDeposits,
  'total_withdrawals' => s.totalWithdrawals,
  'period_movement' => s.periodMovement,
  _ => key,
};
