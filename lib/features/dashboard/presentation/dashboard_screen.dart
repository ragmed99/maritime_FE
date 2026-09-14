import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/formatters/money_formatter.dart';
import '../application/dashboard_controller.dart';
import '../domain/dashboard_models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.controller, super.key});
  final DashboardController controller;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.status == DashboardStatus.idle) {
      widget.controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => switch (widget.controller.status) {
        DashboardStatus.idle || DashboardStatus.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        DashboardStatus.error => _ErrorState(onRetry: widget.controller.load),
        DashboardStatus.loaded => _DashboardContent(
          data: widget.controller.data!,
          onRefresh: widget.controller.load,
        ),
      },
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data, required this.onRefresh});
  final DashboardData data;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final metrics = [
      (
        strings.expectedCash,
        data.metrics.expectedCash,
        Icons.account_balance_wallet_outlined,
      ),
      (
        strings.peopleOweUs,
        data.metrics.peopleOweUs,
        Icons.call_received_rounded,
      ),
      (strings.weOwePeople, data.metrics.weOwePeople, Icons.call_made_rounded),
      (strings.netPosition, data.metrics.netPosition, Icons.insights_outlined),
      (strings.totalRevenue, data.metrics.totalRevenue, Icons.trending_up),
      (strings.totalExpenses, data.metrics.totalExpenses, Icons.trending_down),
      (strings.profitLoss, data.metrics.profitLoss, Icons.balance),
    ];
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxWidth >= 900;
          final columns = desktop
              ? 4
              : constraints.maxWidth >= 560
              ? 2
              : 1;
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.welcomeTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(strings.welcomeSubtitle),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRefresh,
                    tooltip: strings.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _MetricGrid(
                metrics: metrics,
                columns: columns,
                availableWidth: constraints.maxWidth,
              ),
              const SizedBox(height: 28),
              _SectionTitle(strings.shipSummary),
              const SizedBox(height: 12),
              _ShipsSection(items: data.ships, desktop: desktop),
              const SizedBox(height: 28),
              _SectionTitle(strings.clientBalances),
              const SizedBox(height: 12),
              _PeopleSection.clients(items: data.clients, desktop: desktop),
              const SizedBox(height: 28),
              _SectionTitle(strings.partnerBalances),
              const SizedBox(height: 12),
              _PeopleSection.partners(items: data.partners, desktop: desktop),
            ],
          );
        },
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.metrics,
    required this.columns,
    required this.availableWidth,
  });
  final List<(String, double, IconData)> metrics;
  final int columns;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final width = (availableWidth - (columns - 1) * 16) / columns;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: metrics
          .map(
            (item) => SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Icon(
                        item.$3,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.$1),
                            const SizedBox(height: 8),
                            Text(
                              formatMru(
                                item.$2,
                                Localizations.localeOf(context).toLanguageTag(),
                              ),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);
  final String value;
  @override
  Widget build(BuildContext context) =>
      Text(value, style: Theme.of(context).textTheme.titleLarge);
}

class _ShipsSection extends StatelessWidget {
  const _ShipsSection({required this.items, required this.desktop});
  final List<ShipSummary> items;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (items.isEmpty) return _EmptyState(message: strings.noShips);
    if (!desktop) {
      return Column(
        children: items
            .map(
              (ship) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.directions_boat_outlined),
                    title: Text(ship.name),
                    subtitle: Text(
                      '${strings.totalRevenue}: ${formatMru(ship.revenue, Localizations.localeOf(context).toLanguageTag())}\n${strings.totalExpenses}: ${formatMru(ship.expenses, Localizations.localeOf(context).toLanguageTag())}',
                    ),
                    trailing: Text(
                      formatMru(
                        ship.profitLoss,
                        Localizations.localeOf(context).toLanguageTag(),
                      ),
                    ),
                  ),
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
            strings.shipName,
            strings.totalRevenue,
            strings.totalExpenses,
            strings.profitLoss,
          ].map((label) => DataColumn(label: Text(label))).toList(),
          rows: items
              .map(
                (ship) => DataRow(
                  cells: [
                    DataCell(Text(ship.name)),
                    DataCell(
                      Text(
                        formatMru(
                          ship.revenue,
                          Localizations.localeOf(context).toLanguageTag(),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        formatMru(
                          ship.expenses,
                          Localizations.localeOf(context).toLanguageTag(),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        formatMru(
                          ship.profitLoss,
                          Localizations.localeOf(context).toLanguageTag(),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _PeopleSection extends StatelessWidget {
  const _PeopleSection.clients({
    required List<ClientSummary> items,
    required this.desktop,
  }) : clientItems = items,
       partnerItems = null;
  const _PeopleSection.partners({
    required List<PartnerSummary> items,
    required this.desktop,
  }) : partnerItems = items,
       clientItems = null;
  final List<ClientSummary>? clientItems;
  final List<PartnerSummary>? partnerItems;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final rows = clientItems != null
        ? clientItems!
              .map(
                (item) => (
                  item.name,
                  item.balance,
                  _clientLabel(strings, item.balance),
                  _clientColor(context, item.balance),
                ),
              )
              .toList()
        : partnerItems!
              .map(
                (item) => (
                  item.name,
                  item.balance,
                  _partnerLabel(strings, item.balance),
                  _partnerColor(context, item.balance),
                ),
              )
              .toList();
    if (rows.isEmpty) {
      return _EmptyState(
        message: clientItems != null ? strings.noClients : strings.noPartners,
      );
    }
    if (!desktop) {
      return Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(row.$1),
                    subtitle: Text(row.$3),
                    trailing: Text(
                      formatMru(
                        row.$2,
                        Localizations.localeOf(context).toLanguageTag(),
                      ),
                      style: TextStyle(
                        color: row.$4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    }
    return Card(
      child: DataTable(
        columns: [
          strings.name,
          strings.currentBalance,
          strings.balanceStatus,
        ].map((label) => DataColumn(label: Text(label))).toList(),
        rows: rows
            .map(
              (row) => DataRow(
                cells: [
                  DataCell(Text(row.$1)),
                  DataCell(
                    Text(
                      formatMru(
                        row.$2,
                        Localizations.localeOf(context).toLanguageTag(),
                      ),
                      style: TextStyle(color: row.$4),
                    ),
                  ),
                  DataCell(Text(row.$3)),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  String _clientLabel(AppLocalizations strings, double balance) => balance > 0
      ? strings.clientOwesUs
      : balance < 0
      ? strings.clientCredit
      : strings.balanced;
  String _partnerLabel(AppLocalizations strings, double balance) => balance > 0
      ? strings.partnerOwesUs
      : balance < 0
      ? strings.weOwePartner
      : strings.balanced;
  Color _clientColor(BuildContext context, double balance) => balance > 0
      ? Colors.red.shade700
      : balance < 0
      ? Colors.green.shade700
      : Theme.of(context).colorScheme.onSurfaceVariant;
  Color _partnerColor(BuildContext context, double balance) => balance > 0
      ? Colors.red.shade700
      : balance < 0
      ? Colors.orange.shade800
      : Theme.of(context).colorScheme.onSurfaceVariant;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(message)),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          Text(strings.dashboardError),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(strings.retry),
          ),
        ],
      ),
    );
  }
}
