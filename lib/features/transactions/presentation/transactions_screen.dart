import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_date_field.dart';
import '../../../core/widgets/app_dialog_shell.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/list_header_bar.dart';
import '../../../core/widgets/money_text.dart';
import '../application/transactions_controller.dart';
import '../domain/transaction_models.dart';

const transactionTypes = [
  'SHIP_REVENUE',
  'CLIENT_PURCHASE',
  'CLIENT_PAYMENT',
  'PARTNER_LOAN_RECEIVED',
  'PARTNER_LOAN_GIVEN',
  'PARTNER_REPAYMENT_RECEIVED',
  'PARTNER_REPAYMENT_PAID',
  'OWNER_DEPOSIT',
  'OWNER_WITHDRAWAL',
];

String transactionTypeLabel(AppLocalizations s, String type) => switch (type) {
  'SHIP_REVENUE' => s.shipRevenue,
  'SHIP_EXPENSE' => s.shipExpense,
  'CLIENT_PURCHASE' => s.clientPurchase,
  'CLIENT_PAYMENT' => s.clientPayment,
  'PARTNER_LOAN_RECEIVED' => s.loanReceived,
  'PARTNER_LOAN_GIVEN' => s.loanGiven,
  'PARTNER_REPAYMENT_RECEIVED' => s.repaymentReceived,
  'PARTNER_REPAYMENT_PAID' => s.repaymentPaid,
  'OWNER_DEPOSIT' => s.ownerDeposit,
  _ => s.ownerWithdrawal,
};

IconData _transactionIcon(String type) => switch (type) {
  'SHIP_REVENUE' => Icons.trending_up,
  'SHIP_EXPENSE' => Icons.trending_down,
  'CLIENT_PURCHASE' => Icons.shopping_cart_outlined,
  'CLIENT_PAYMENT' => Icons.payments_outlined,
  'PARTNER_LOAN_RECEIVED' => Icons.south_west,
  'PARTNER_LOAN_GIVEN' => Icons.north_east,
  'PARTNER_REPAYMENT_RECEIVED' => Icons.call_received,
  'PARTNER_REPAYMENT_PAID' => Icons.reply,
  'OWNER_DEPOSIT' => Icons.add_card,
  _ => Icons.payments_outlined,
};

Color _transactionTint(MoneyColors money, String type) => switch (type) {
  'SHIP_EXPENSE' ||
  'PARTNER_LOAN_GIVEN' ||
  'PARTNER_REPAYMENT_PAID' ||
  'OWNER_WITHDRAWAL' => money.negative,
  _ => money.positive,
};

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({required this.controller, super.key});
  final TransactionsController controller;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final search = TextEditingController();
  Timer? debounce;

  @override
  void initState() {
    super.initState();
    if (widget.controller.status == TransactionsStatus.idle) {
      widget.controller.load();
    }
  }

  @override
  void dispose() {
    debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      if (widget.controller.status == TransactionsStatus.loading) {
        return AppStateView.loading();
      }
      if (widget.controller.status == TransactionsStatus.error) {
        return AppStateView.error(
          message: s.transactionsLoadError,
          retryLabel: s.retry,
          onRetry: widget.controller.load,
        );
      }
      final lookups = widget.controller.lookups!;
      return RefreshIndicator(
        onRefresh: widget.controller.load,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              ListHeaderBar(
                title: s.transactions,
                onRefresh: widget.controller.load,
                refreshTooltip: s.refresh,
                trailing: OutlinedButton.icon(
                  onPressed: () => _filter(lookups),
                  icon: const Icon(Icons.filter_alt_outlined),
                  label: Text(s.filters),
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: search,
                decoration: InputDecoration(
                  labelText: s.searchTransactions,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: search.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            search.clear();
                            _search('');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
                onChanged: _search,
              ),
              const SizedBox(height: 18),
              if (widget.controller.rows.isEmpty)
                AppStateView.empty(
                  message: s.noTransactionsFound,
                  icon: Icons.receipt_long_outlined,
                )
              else if (constraints.maxWidth >= 900)
                _TransactionTable(
                  rows: widget.controller.rows,
                  lookups: lookups,
                )
              else
                ...widget.controller.rows.map(
                  (row) => _TransactionCard(row: row, lookups: lookups),
                ),
              if (widget.controller.hasMore)
                Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: widget.controller.loadingMore
                          ? null
                          : widget.controller.loadMore,
                      icon: widget.controller.loadingMore
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.expand_more),
                      label: Text(s.loadMore),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  void _search(String value) {
    setState(() {});
    debounce?.cancel();
    debounce = Timer(
      const Duration(milliseconds: 400),
      () => widget.controller.load(
        withFilters: _copyFilters(search: value.trim()),
      ),
    );
  }

  TransactionFilters _copyFilters({String? search}) {
    final value = widget.controller.filters;
    return TransactionFilters(
      startDate: value.startDate,
      endDate: value.endDate,
      type: value.type,
      shipId: value.shipId,
      tripId: value.tripId,
      clientId: value.clientId,
      partnerId: value.partnerId,
      ownerId: value.ownerId,
      search: search ?? value.search,
    );
  }

  Future<void> _filter(TransactionLookups lookups) async {
    final result = await showDialog<TransactionFilters>(
      context: context,
      builder: (_) =>
          _FilterDialog(value: widget.controller.filters, lookups: lookups),
    );
    if (result != null) {
      final merged = TransactionFilters(
        startDate: result.startDate,
        endDate: result.endDate,
        type: result.type,
        shipId: result.shipId,
        tripId: result.tripId,
        clientId: result.clientId,
        partnerId: result.partnerId,
        ownerId: result.ownerId,
        search: search.text,
      );
      await widget.controller.load(withFilters: merged);
    }
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.row, required this.lookups});
  final LedgerTransaction row;
  final TransactionLookups lookups;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final tint = _transactionTint(context.moneyColors, row.type);
    final relations = _relations(s, row, lookups);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          leading: CircleAvatar(
            backgroundColor: tint.withValues(alpha: 0.14),
            foregroundColor: tint,
            child: Icon(_transactionIcon(row.type), size: 18),
          ),
          title: Text(transactionTypeLabel(s, row.type)),
          isThreeLine: true,
          subtitle: Text(
            [
              _when(row, locale),
              if (row.description.isNotEmpty) row.description,
              if (relations.isNotEmpty) relations,
              if (row.recordedBy != null) '${s.recordedBy}: ${row.recordedBy}',
            ].join('\n'),
          ),
          trailing: MoneyText(
            row.amount,
            locale: locale,
            style: TextStyle(color: tint, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _TransactionTable extends StatelessWidget {
  const _TransactionTable({required this.rows, required this.lookups});
  final List<LedgerTransaction> rows;
  final TransactionLookups lookups;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final money = context.moneyColors;
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            s.dateTime,
            s.transactionType,
            s.amountMru,
            s.description,
            s.relatedTo,
            s.recordedBy,
          ].map((label) => DataColumn(label: Text(label))).toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(_when(row, locale))),
                    DataCell(Text(transactionTypeLabel(s, row.type))),
                    DataCell(
                      MoneyText(
                        row.amount,
                        locale: locale,
                        style: TextStyle(
                          color: _transactionTint(money, row.type),
                        ),
                      ),
                    ),
                    DataCell(Text(row.description)),
                    DataCell(Text(_relations(s, row, lookups))),
                    DataCell(Text(row.recordedBy ?? '—')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

String _when(LedgerTransaction row, String locale) =>
    '${DateFormat.yMd(locale).format(row.date)} ${DateFormat.Hm(locale).format(row.createdAt.toLocal())}';

String _relations(
  AppLocalizations s,
  LedgerTransaction row,
  TransactionLookups lookups,
) {
  final parts = <String>[];
  void add(String label, String? value) {
    if (value != null) parts.add('$label: $value');
  }

  add(s.shipName, lookups.name(lookups.ships, row.shipId));
  add(s.trip, lookups.name(lookups.trips, row.tripId));
  add(s.client, lookups.name(lookups.clients, row.clientId));
  add(s.partners, lookups.name(lookups.partners, row.partnerId));
  add(s.owner, lookups.name(lookups.owners, row.ownerId));
  return parts.isEmpty ? '—' : parts.join(' · ');
}

class _FilterDialog extends StatefulWidget {
  const _FilterDialog({required this.value, required this.lookups});
  final TransactionFilters value;
  final TransactionLookups lookups;
  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late DateTime? start = widget.value.startDate;
  late DateTime? end = widget.value.endDate;
  late String? type = widget.value.type;
  late String? ship = widget.value.shipId;
  late String? trip = widget.value.tripId;
  late String? client = widget.value.clientId;
  late String? partner = widget.value.partnerId;
  late String? owner = widget.value.ownerId;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final trips = ship == null
        ? widget.lookups.trips
        : widget.lookups.trips.where((item) => item.parentId == ship).toList();
    if (trip != null && !trips.any((item) => item.id == trip)) trip = null;
    return AppDialogShell(
      title: s.filters,
      icon: Icons.filter_alt_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDateField(
            label: s.startDate,
            value: start,
            placeholder: s.allDates,
            onChanged: (v) => setState(() => start = v),
          ),
          const SizedBox(height: 10),
          AppDateField(
            label: s.endDate,
            value: end,
            placeholder: s.allDates,
            firstDate: start,
            onChanged: (v) => setState(() => end = v),
          ),
          _Select(
            label: s.transactionType,
            value: type,
            options: transactionTypes
                .map(
                  (value) =>
                      LookupOption(value, transactionTypeLabel(s, value)),
                )
                .toList(),
            onChanged: (v) => setState(() => type = v),
          ),
          _Select(
            label: s.shipName,
            value: ship,
            options: widget.lookups.ships,
            onChanged: (v) => setState(() => ship = v),
          ),
          _Select(
            label: s.trip,
            value: trip,
            options: trips,
            onChanged: (v) => setState(() => trip = v),
          ),
          _Select(
            label: s.client,
            value: client,
            options: widget.lookups.clients,
            onChanged: (v) => setState(() => client = v),
          ),
          _Select(
            label: s.partners,
            value: partner,
            options: widget.lookups.partners,
            onChanged: (v) => setState(() => partner = v),
          ),
          _Select(
            label: s.owner,
            value: owner,
            options: widget.lookups.owners,
            onChanged: (v) => setState(() => owner = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const TransactionFilters()),
          child: Text(s.clearFilters),
        ),
        FilledButton(
          onPressed: () {
            if (start != null && end != null && start!.isAfter(end!)) return;
            Navigator.pop(
              context,
              TransactionFilters(
                startDate: start,
                endDate: end,
                type: type,
                shipId: ship,
                tripId: trip,
                clientId: client,
                partnerId: partner,
                ownerId: owner,
              ),
            );
          },
          child: Text(s.apply),
        ),
      ],
    );
  }
}

class _Select extends StatelessWidget {
  const _Select({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<LookupOption> options;
  final ValueChanged<String?> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<String?>(
          value: null,
          child: Text(AppLocalizations.of(context).all),
        ),
        ...options.map(
          (item) =>
              DropdownMenuItem<String?>(value: item.id, child: Text(item.name)),
        ),
      ],
      onChanged: onChanged,
    ),
  );
}
