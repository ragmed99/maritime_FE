import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/models/account_position.dart';
import '../../../core/files/pdf_export.dart';
import '../../../core/formatters/money_formatter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_date_field.dart';
import '../../../core/widgets/app_dialog_shell.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/home_button.dart';
import '../../../core/widgets/list_header_bar.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/transaction_row_actions.dart';
import '../application/owners_controller.dart';
import '../data/owners_repository.dart';
import '../domain/owner_models.dart';

class OwnersScreen extends StatefulWidget {
  const OwnersScreen({required this.controller, super.key});

  final OwnersController controller;

  @override
  State<OwnersScreen> createState() => _OwnersScreenState();
}

class _OwnersScreenState extends State<OwnersScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.status == OwnersStatus.idle) {
      widget.controller.load();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      if (widget.controller.status == OwnersStatus.loading) {
        return AppStateView.loading();
      }
      if (widget.controller.status == OwnersStatus.error) {
        return AppStateView.error(
          message: s.ownersLoadError,
          retryLabel: s.retry,
          onRetry: widget.controller.load,
        );
      }
      final rows = widget.controller.filtered;
      return RefreshIndicator(
        onRefresh: widget.controller.load,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              ListHeaderBar(
                title: s.owners,
                onRefresh: widget.controller.load,
                refreshTooltip: s.refresh,
                onAdd: _edit,
                addLabel: s.addOwner,
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: widget.controller.search,
                decoration: InputDecoration(
                  labelText: s.searchOwners,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 18),
              if (rows.isEmpty)
                AppStateView.empty(
                  message: widget.controller.query.isEmpty
                      ? s.noOwners
                      : s.noOwnerSearchResults,
                  icon: Icons.badge_outlined,
                )
              else if (constraints.maxWidth >= 900)
                _OwnerTable(
                  rows: rows,
                  onOpen: _open,
                  onEdit: _edit,
                  onDelete: _delete,
                )
              else
                ...rows.map(
                  (owner) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: InitialsAvatar(
                          owner.name,
                          icon: Icons.badge_outlined,
                        ),
                        title: Text(owner.name),
                        subtitle: Text(owner.phone),
                        onTap: () => _open(owner),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) =>
                              value == 'edit' ? _edit(owner) : _delete(owner),
                          itemBuilder: (_) => [
                            PopupMenuItem(value: 'edit', child: Text(s.edit)),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(s.delete),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );

  Future<void> _open(OwnerRecord owner) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerDetailsScreen(
          owner: owner,
          repository: widget.controller.repository,
        ),
      ),
    );
    await widget.controller.load();
  }

  Future<void> _edit([OwnerRecord? owner]) async {
    final input = await showDialog<_OwnerInput>(
      context: context,
      builder: (_) => _OwnerDialog(owner: owner),
    );
    if (input == null) return;
    try {
      await widget.controller.save(
        owner: owner,
        name: input.name,
        phone: input.phone,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveError)),
        );
      }
    }
  }

  Future<void> _delete(OwnerRecord owner) async {
    final s = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialogShell(
        title: s.deleteOwner,
        icon: Icons.delete_outline,
        content: Text(s.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (yes == true) {
      try {
        await widget.controller.delete(owner.id);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(s.saveError)));
        }
      }
    }
  }
}

class _OwnerTable extends StatelessWidget {
  const _OwnerTable({
    required this.rows,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<OwnerRecord> rows;
  final void Function(OwnerRecord) onOpen;
  final void Function([OwnerRecord?]) onEdit;
  final void Function(OwnerRecord) onDelete;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            s.name,
            s.phone,
            s.actions,
          ].map((label) => DataColumn(label: Text(label))).toList(),
          rows: rows
              .map(
                (owner) => DataRow(
                  onSelectChanged: (_) => onOpen(owner),
                  cells: [
                    DataCell(Text(owner.name)),
                    DataCell(Text(owner.phone)),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => onEdit(owner),
                            tooltip: s.edit,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => onDelete(owner),
                            tooltip: s.delete,
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
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

class OwnerDetailsScreen extends StatefulWidget {
  const OwnerDetailsScreen({
    required this.owner,
    required this.repository,
    super.key,
  });

  final OwnerRecord owner;
  final OwnersRepository repository;

  @override
  State<OwnerDetailsScreen> createState() => _OwnerDetailsScreenState();
}

class _OwnerDetailsScreenState extends State<OwnerDetailsScreen> {
  AccountPosition balance = const AccountPosition(
    theyOweUs: 0,
    weOweThem: 0,
    balance: 0,
  );
  List<OwnerTransaction> transactions = [];
  List<OwnerShip> ships = [];
  DateTime? startDate;
  DateTime? endDate;
  bool loading = true;
  bool failed = false;
  bool sharingPdf = false;

  List<OwnerTransaction> get visibleTransactions => transactions.where((row) {
    final date = DateUtils.dateOnly(row.date);
    if (startDate != null && date.isBefore(DateUtils.dateOnly(startDate!))) {
      return false;
    }
    if (endDate != null && date.isAfter(DateUtils.dateOnly(endDate!))) {
      return false;
    }
    return true;
  }).toList();

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
      final values = await Future.wait([
        widget.repository.balance(widget.owner.id),
        widget.repository.transactions(widget.owner.id),
        widget.repository.ships(widget.owner.id),
      ]);
      balance = values[0] as AccountPosition;
      transactions = values[1] as List<OwnerTransaction>;
      ships = values[2] as List<OwnerShip>;
      transactions.sort((a, b) => b.time.compareTo(a.time));
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
        title: Text(widget.owner.name),
        actions: [
          const HomeButton(),
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
              message: s.ownerDetailsError,
              retryLabel: s.retry,
              onRetry: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.owner.name,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            MoneyText(
                              balance.balance.abs(),
                              locale: locale,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: balance.balance > 0
                                        ? context.moneyColors.positive
                                        : balance.balance < 0
                                        ? context.moneyColors.negative
                                        : context.moneyColors.neutral,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _add('OWNER_DEPOSIT'),
                          icon: const Icon(Icons.add_card),
                          label: Text(s.addDeposit),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _add('OWNER_WITHDRAWAL'),
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(s.addExpense),
                        ),
                        OutlinedButton.icon(
                          onPressed: _filter,
                          icon: const Icon(Icons.date_range_outlined),
                          label: Text(s.filters),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: sharingPdf ? null : _sharePdf,
                          icon: sharingPdf
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
                    const SizedBox(height: 22),
                    SectionHeader(s.ownerTransactions),
                    const SizedBox(height: 12),
                    if (visibleTransactions.isEmpty)
                      AppStateView.empty(
                        message: s.noOwnerTransactions,
                        icon: Icons.receipt_long_outlined,
                      )
                    else
                      _OwnerAccountSheet(
                        rows: visibleTransactions,
                        ships: ships,
                        locale: locale,
                        onEdit: _editTransaction,
                        onDelete: _deleteTransaction,
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _editTransaction(OwnerTransaction row) async {
    final input = await showTransactionEditDialog(
      context,
      amount: row.amount,
      description: row.description,
    );
    if (input == null || !mounted) return;
    if (!await confirmLinkedTransactionChange(context, deleting: false)) {
      return;
    }
    await widget.repository.updateTransaction(
      row.id,
      amount: input.amount,
      description: input.description,
    );
    await _load();
  }

  Future<void> _deleteTransaction(OwnerTransaction row) async {
    if (!await confirmLinkedTransactionChange(context, deleting: true)) return;
    await widget.repository.deleteTransaction(row.id);
    await _load();
  }

  Future<void> _filter() async {
    final result = await showDialog<List<DateTime?>>(
      context: context,
      builder: (_) => _DateFilterDialog(start: startDate, end: endDate),
    );
    if (result != null) {
      setState(() {
        startDate = result[0];
        endDate = result[1];
      });
    }
  }

  Future<void> _sharePdf() async {
    setState(() => sharingPdf = true);
    try {
      final bytes = await widget.repository.statementPdf(
        widget.owner.id,
        startDate: startDate,
        endDate: endDate,
      );
      final savedPath = await exportPdf(
        bytes: bytes,
        filename: 'owner-${widget.owner.name}.pdf',
        title: widget.owner.name,
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
      if (mounted) setState(() => sharingPdf = false);
    }
  }

  Future<void> _add(String type) async {
    final input = await showDialog<_TransactionInput>(
      context: context,
      builder: (_) => _TransactionDialog(type: type),
    );
    if (input == null) return;
    try {
      await widget.repository.addTransaction(
        ownerId: widget.owner.id,
        type: type,
        amount: input.amount,
        date: input.date,
        description: input.description,
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).saveError)),
        );
      }
    }
  }
}

class OwnerBalance extends StatelessWidget {
  const OwnerBalance({required this.value, super.key});

  final AccountPosition value;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final money = context.moneyColors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final color = value.theyOweUs > 0
        ? money.negative
        : value.weOweThem > 0
        ? money.positive
        : money.neutral;
    final label = value.theyOweUs > 0
        ? s.ownerOwesBusiness
        : value.weOweThem > 0
        ? s.businessOwesOwner
        : s.balanced;
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            children: [
              Text('${s.theyOweUs}: '),
              MoneyText(
                value.theyOweUs,
                locale: locale,
                style: TextStyle(color: money.negative),
              ),
            ],
          ),
          Wrap(
            children: [
              Text('${s.weOweThem}: '),
              MoneyText(
                value.weOweThem,
                locale: locale,
                style: TextStyle(color: money.positive),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(s.currentBalance),
          MoneyText(
            value.balance.abs(),
            locale: locale,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          StatusPill(label, color: color),
        ],
      ),
    );
  }
}

class _OwnerAccountSheet extends StatelessWidget {
  const _OwnerAccountSheet({
    required this.rows,
    required this.ships,
    required this.locale,
    required this.onEdit,
    required this.onDelete,
  });

  final List<OwnerTransaction> rows;
  final List<OwnerShip> ships;
  final String locale;
  final ValueChanged<OwnerTransaction> onEdit;
  final ValueChanged<OwnerTransaction> onDelete;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final expenses = rows
        .where(
          (row) => row.type == 'OWNER_WITHDRAWAL' || row.type == 'SHIP_EXPENSE',
        )
        .toList();
    final deposits = rows.where((row) => row.type == 'OWNER_DEPOSIT').toList();
    final outcomes = rows
        .where((row) => row.type == 'CLIENT_PURCHASE')
        .toList();
    final shipNames = {for (final ship in ships) ship.id: ship.name};
    final totalExpenses = expenses.fold<double>(
      0,
      (sum, row) => sum + row.amount,
    );
    final totalDeposits = deposits.fold<double>(
      0,
      (sum, row) => sum + row.amount,
    );
    final totalOutcomes = outcomes.fold<double>(
      0,
      (sum, row) => sum + row.amount,
    );
    final totalIncome = totalDeposits + totalOutcomes;
    final tableRows = <TableRow>[
      _row(
        context,
        [s.expenses, s.amount],
        bold: true,
        background: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    ];

    for (final row in expenses) {
      tableRows.add(
        _row(context, [
          row.description.isEmpty ? s.expense : row.description,
          formatMru(row.amount, locale),
        ], transaction: row),
      );
    }
    tableRows.add(
      _row(
        context,
        [s.totalExpenses, formatMru(totalExpenses, locale)],
        bold: true,
        background: const Color(0xFF12DDE4),
      ),
    );
    tableRows.add(
      _row(
        context,
        [s.revenues, s.amount],
        bold: true,
        background: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
    for (final row in deposits) {
      tableRows.add(
        _row(context, [
          row.description.isEmpty ? s.deposit : row.description,
          formatMru(row.amount, locale),
        ]),
      );
    }
    for (final row in outcomes) {
      tableRows.add(
        _row(context, [
          shipNames[row.shipId] ?? '—',
          formatMru(row.amount, locale),
        ]),
      );
    }
    tableRows.add(
      _row(
        context,
        [s.totalRevenue, formatMru(totalIncome, locale)],
        bold: true,
        background: const Color(0xFF12DDE4),
      ),
    );
    tableRows.add(
      _row(
        context,
        [s.remaining, formatMru(totalIncome - totalExpenses, locale)],
        bold: true,
        background: const Color(0xFF16E316),
      ),
    );

    if (MediaQuery.sizeOf(context).width < 700) {
      Widget movement(
        OwnerTransaction row,
        String label, {
        bool editable = false,
      }) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(label),
          subtitle: MoneyText(row.amount, locale: locale),
          trailing: editable
              ? TransactionRowActions(
                  onEdit: () => onEdit(row),
                  onDelete: () => onDelete(row),
                )
              : null,
        ),
      );
      Widget totalCard(String label, double value, Color color) => Card(
        color: color,
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          trailing: MoneyText(
            value,
            locale: locale,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(s.expenses),
          const SizedBox(height: 8),
          ...expenses.map(
            (row) => movement(
              row,
              row.description.isEmpty ? s.expense : row.description,
              editable: true,
            ),
          ),
          totalCard(s.totalExpenses, totalExpenses, const Color(0xFF12DDE4)),
          SectionHeader(s.revenues),
          const SizedBox(height: 8),
          ...deposits.map(
            (row) => movement(
              row,
              row.description.isEmpty ? s.deposit : row.description,
            ),
          ),
          ...outcomes.map((row) => movement(row, shipNames[row.shipId] ?? '—')),
          totalCard(s.totalRevenue, totalIncome, const Color(0xFF12DDE4)),
          totalCard(
            s.remaining,
            totalIncome - totalExpenses,
            const Color(0xFF16E316),
          ),
        ],
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 620,
          child: Table(
            border: TableBorder.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.2),
              2: FixedColumnWidth(100),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: tableRows,
          ),
        ),
      ),
    );
  }

  TableRow _row(
    BuildContext context,
    List<String> values, {
    bool bold = false,
    Color? background,
    OwnerTransaction? transaction,
  }) => TableRow(
    decoration: background == null ? null : BoxDecoration(color: background),
    children: [
      ...values.map(
        (value) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            value,
            style: TextStyle(fontWeight: bold ? FontWeight.w800 : null),
          ),
        ),
      ),
      transaction == null
          ? const SizedBox.shrink()
          : TransactionRowActions(
              onEdit: () => onEdit(transaction),
              onDelete: () => onDelete(transaction),
            ),
    ],
  );
}

class _OwnerInput {
  const _OwnerInput(this.name, this.phone);
  final String name;
  final String phone;
}

class _OwnerDialog extends StatefulWidget {
  const _OwnerDialog({this.owner});
  final OwnerRecord? owner;

  @override
  State<_OwnerDialog> createState() => _OwnerDialogState();
}

class _OwnerDialogState extends State<_OwnerDialog> {
  late final name = TextEditingController(text: widget.owner?.name);
  late final phone = TextEditingController(text: widget.owner?.phone);
  String? error;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AppDialogShell(
      title: widget.owner == null ? s.addOwner : s.editOwner,
      icon: Icons.badge_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: InputDecoration(labelText: s.name),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: phone,
            decoration: InputDecoration(labelText: s.phone),
            keyboardType: TextInputType.phone,
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () {
            if (name.text.trim().isEmpty) {
              setState(() => error = s.ownerValidationError);
              return;
            }
            Navigator.pop(
              context,
              _OwnerInput(name.text.trim(), phone.text.trim()),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _TransactionInput {
  const _TransactionInput(this.amount, this.date, this.description);
  final double amount;
  final DateTime date;
  final String description;
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({required this.type});
  final String type;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final amount = TextEditingController();
  final description = TextEditingController();
  String? error;

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final title = switch (widget.type) {
      'OWNER_DEPOSIT' => s.addDeposit,
      _ => s.addExpense,
    };
    return AppDialogShell(
      title: title,
      icon: Icons.account_balance_wallet_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amount,
            decoration: InputDecoration(labelText: s.amountMru),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: description,
            decoration: InputDecoration(labelText: s.description),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(amount.text.replaceAll(',', '.'));
            if (value == null ||
                value <= 0 ||
                description.text.trim().isEmpty) {
              setState(() => error = s.validAmountRequired);
              return;
            }
            Navigator.pop(
              context,
              _TransactionInput(value, DateTime.now(), description.text.trim()),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _DateFilterDialog extends StatefulWidget {
  const _DateFilterDialog({required this.start, required this.end});
  final DateTime? start;
  final DateTime? end;

  @override
  State<_DateFilterDialog> createState() => _DateFilterDialogState();
}

class _DateFilterDialogState extends State<_DateFilterDialog> {
  late DateTime? start = widget.start;
  late DateTime? end = widget.end;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, <DateTime?>[null, null]),
          child: Text(s.clearFilters),
        ),
        FilledButton(
          onPressed: () {
            if (start != null && end != null && start!.isAfter(end!)) return;
            Navigator.pop(context, <DateTime?>[start, end]);
          },
          child: Text(s.apply),
        ),
      ],
    );
  }
}
