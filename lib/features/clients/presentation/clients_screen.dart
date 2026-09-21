import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/models/account_position.dart';
import '../../../core/files/pdf_export.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_date_field.dart';
import '../../../core/widgets/app_dialog_shell.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/home_button.dart';
import '../../../core/widgets/list_header_bar.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/transaction_row_actions.dart';
import '../application/clients_controller.dart';
import '../data/clients_repository.dart';
import '../domain/client_models.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({required this.controller, super.key});
  final ClientsController controller;
  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.status == ClientsStatus.idle) {
      widget.controller.load();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      if (widget.controller.status == ClientsStatus.loading) {
        return AppStateView.loading();
      }
      if (widget.controller.status == ClientsStatus.error) {
        return AppStateView.error(
          message: s.clientsLoadError,
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
                title: s.clients,
                onRefresh: widget.controller.load,
                refreshTooltip: s.refresh,
                onAdd: () => _edit(),
                addLabel: s.addClient,
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: widget.controller.search,
                decoration: InputDecoration(
                  labelText: s.searchClients,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 18),
              if (rows.isEmpty)
                AppStateView.empty(
                  message: widget.controller.query.isEmpty
                      ? s.noClients
                      : s.noClientSearchResults,
                  icon: Icons.people_outline,
                )
              else if (constraints.maxWidth >= 900)
                _ClientTable(
                  rows: rows,
                  onOpen: _open,
                  onEdit: _edit,
                  onDelete: _delete,
                )
              else
                ...rows.map(
                  (client) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: InitialsAvatar(client.name),
                        title: Text(client.name),
                        subtitle: _ClientListBalance(client: client),
                        isThreeLine: client.phone.isNotEmpty,
                        onTap: () => _open(client),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) =>
                              value == 'edit' ? _edit(client) : _delete(client),
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
  Future<void> _open(ClientRecord client) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientDetailsScreen(
          client: client,
          repository: widget.controller.repository,
        ),
      ),
    );
    await widget.controller.load();
  }

  Future<void> _edit([ClientRecord? client]) async {
    final input = await showDialog<_ClientInput>(
      context: context,
      builder: (_) => _ClientDialog(client: client),
    );
    if (input != null) {
      await widget.controller.save(
        client: client,
        name: input.name,
        phone: input.phone,
      );
    }
  }

  Future<void> _delete(ClientRecord client) async {
    final s = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialogShell(
        title: s.deleteClient,
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
    if (yes == true) await widget.controller.delete(client.id);
  }
}

class _ClientListBalance extends StatelessWidget {
  const _ClientListBalance({required this.client});
  final ClientRecord client;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final balance = client.position.balance;
    final color = balance > 0
        ? context.moneyColors.negative
        : balance < 0
        ? context.moneyColors.positive
        : context.moneyColors.neutral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (client.phone.isNotEmpty) Text(client.phone),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${s.currentBalance}: '),
            MoneyText(
              balance.abs(),
              locale: locale,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ],
    );
  }
}

class _ClientTable extends StatelessWidget {
  const _ClientTable({
    required this.rows,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });
  final List<ClientRecord> rows;
  final void Function(ClientRecord) onOpen;
  final void Function([ClientRecord?]) onEdit;
  final void Function(ClientRecord) onDelete;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            s.name,
            s.phone,
            s.currentBalance,
            s.actions,
          ].map((label) => DataColumn(label: Text(label))).toList(),
          rows: rows
              .map(
                (client) => DataRow(
                  onSelectChanged: (_) => onOpen(client),
                  cells: [
                    DataCell(Text(client.name)),
                    DataCell(Text(client.phone)),
                    DataCell(
                      MoneyText(
                        client.position.balance.abs(),
                        locale: locale,
                        style: TextStyle(
                          color: client.position.balance > 0
                              ? context.moneyColors.negative
                              : client.position.balance < 0
                              ? context.moneyColors.positive
                              : context.moneyColors.neutral,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => onEdit(client),
                            tooltip: s.edit,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => onDelete(client),
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

class ClientDetailsScreen extends StatefulWidget {
  const ClientDetailsScreen({
    required this.client,
    required this.repository,
    super.key,
  });
  final ClientRecord client;
  final ClientsRepository repository;
  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  ClientStatementData? data;
  List<RelationOption> ships = [];
  Map<String, List<RelationOption>> trips = {};
  ClientFilters filters = const ClientFilters();
  bool sharingPdf = false;
  bool loading = true;
  bool failed = false;
  @override
  void initState() {
    super.initState();
    _load(initial: true);
  }

  Future<void> _load({bool initial = false}) async {
    setState(() {
      loading = true;
      failed = false;
    });
    try {
      final values = await Future.wait([
        widget.repository.statement(widget.client.id, filters),
        if (initial) widget.repository.ships(),
        if (initial) widget.repository.tripsByShip(),
      ]);
      data = values[0] as ClientStatementData;
      if (initial) {
        ships = values[1] as List<RelationOption>;
        trips = values[2] as Map<String, List<RelationOption>>;
      }
    } catch (_) {
      failed = true;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client.name),
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
              message: s.clientDetailsError,
              retryLabel: s.retry,
              onRetry: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.client.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            _Balance(position: data!.position),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: _addPayment,
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(s.addPayment),
                        ),
                        OutlinedButton.icon(
                          onPressed: _filter,
                          icon: const Icon(Icons.filter_alt_outlined),
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
                    SectionHeader(s.clientTransactions),
                    const SizedBox(height: 12),
                    if (data!.transactions.isEmpty)
                      AppStateView.empty(
                        message: s.noClientTransactions,
                        icon: Icons.receipt_long_outlined,
                      )
                    else
                      _ClientStatementSheet(
                        rows: data!.transactions,
                        onEdit: _editTransaction,
                        onDelete: _deleteTransaction,
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _editTransaction(ClientTransactionRow row) async {
    final input = await showDialog<_PaymentInput>(
      context: context,
      builder: (_) => _PaymentDialog(transaction: row),
    );
    if (input == null || !mounted) return;
    if (!await confirmLinkedTransactionChange(context, deleting: false)) {
      return;
    }
    await widget.repository.updateTransaction(
      row.id,
      amount: input.amount,
      description: input.description,
      paymentMethod: input.paymentMethod,
    );
    await _load();
  }

  Future<void> _deleteTransaction(ClientTransactionRow row) async {
    if (!await confirmLinkedTransactionChange(context, deleting: true)) return;
    await widget.repository.deleteTransaction(row.id);
    await _load();
  }

  Future<void> _filter() async {
    final value = await showDialog<ClientFilters>(
      context: context,
      builder: (_) => _FilterDialog(value: filters, ships: ships, trips: trips),
    );
    if (value != null) {
      filters = value;
      await _load();
    }
  }

  Future<void> _addPayment() async {
    final input = await showDialog<_PaymentInput>(
      context: context,
      builder: (_) => const _PaymentDialog(),
    );
    if (input == null) return;
    try {
      await widget.repository.addTransaction(
        clientId: widget.client.id,
        type: 'CLIENT_PAYMENT',
        amount: input.amount,
        date: DateTime.now(),
        description: input.description,
        paymentMethod: input.paymentMethod,
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

  Future<void> _sharePdf() async {
    setState(() => sharingPdf = true);
    try {
      final language = Localizations.localeOf(context).languageCode;
      final bytes = await widget.repository.statementPdf(
        widget.client.id,
        language,
      );
      final savedPath = await exportPdf(
        bytes: bytes,
        filename: 'client-${widget.client.name}.pdf',
        title: widget.client.name,
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
}

class _Balance extends StatelessWidget {
  const _Balance({required this.position});
  final AccountPosition position;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final money = context.moneyColors;
    final color = position.theyOweUs > 0
        ? money.negative
        : position.weOweThem > 0
        ? money.positive
        : money.neutral;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(s.currentBalance),
        MoneyText(
          position.balance.abs(),
          locale: locale,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ClientStatementSheet extends StatelessWidget {
  const _ClientStatementSheet({
    required this.rows,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ClientTransactionRow> rows;
  final ValueChanged<ClientTransactionRow> onEdit;
  final ValueChanged<ClientTransactionRow> onDelete;

  String _number(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
  }

  Widget _cell(
    String value, {
    bool bold = false,
    TextAlign align = TextAlign.start,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    child: Text(
      value,
      textAlign: align,
      style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final purchases =
        rows.where((row) => row.type == 'CLIENT_PURCHASE').toList()
          ..sort((a, b) => (a.ship ?? '').compareTo(b.ship ?? ''));
    final payments = rows.where((row) => row.type == 'CLIENT_PAYMENT').toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final totalPurchases = purchases.fold<double>(
      0,
      (sum, row) => sum + row.amount,
    );
    final totalPayments = payments.fold<double>(
      0,
      (sum, row) => sum + row.amount,
    );
    final lineCount = purchases.length > payments.length
        ? purchases.length
        : payments.length;
    final remaining = totalPurchases - totalPayments;
    final border = TableBorder.all(color: Theme.of(context).dividerColor);
    if (MediaQuery.sizeOf(context).width < 700) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...purchases.map(
            (row) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(row.ship ?? '—'),
                subtitle: Text(s.purchases),
                trailing: Text(
                  _number(row.amount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
          ...payments.map(
            (row) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(s.payments),
                subtitle: Text(
                  '${_number(row.amount)} MRU${row.paymentMethod == null ? '' : ' • ${row.paymentMethod}'}',
                ),
                trailing: TransactionRowActions(
                  onEdit: () => onEdit(row),
                  onDelete: () => onDelete(row),
                ),
              ),
            ),
          ),
          Card(
            color: const Color(0xFF12DDE4),
            child: ListTile(
              title: Text(
                s.total,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${s.purchases}: ${_number(totalPurchases)}'),
              trailing: Text(
                '${s.payments}: ${_number(totalPayments)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          Card(
            color: const Color(0xFFFF9800),
            child: ListTile(
              title: Text(
                s.remaining,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              trailing: Text(
                _number(remaining),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 630,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Table(
                  border: border,
                  columnWidths: const {
                    0: FixedColumnWidth(210),
                    1: FixedColumnWidth(210),
                    2: FixedColumnWidth(210),
                  },
                  children: [
                    TableRow(
                      children: [
                        _cell(s.shipName, bold: true, align: TextAlign.center),
                        _cell(s.purchases, bold: true, align: TextAlign.center),
                        _cell(s.payments, bold: true, align: TextAlign.center),
                      ],
                    ),
                    ...List.generate(
                      lineCount,
                      (index) => TableRow(
                        children: [
                          _cell(
                            index < purchases.length
                                ? purchases[index].ship ?? '—'
                                : '',
                            bold: index < purchases.length,
                            align: TextAlign.center,
                          ),
                          index < purchases.length
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _cell(
                                      _number(purchases[index].amount),
                                      bold: true,
                                    ),
                                  ],
                                )
                              : _cell(''),
                          index < payments.length
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _cell(
                                      _number(payments[index].amount),
                                      bold: true,
                                    ),
                                    TransactionRowActions(
                                      onEdit: () => onEdit(payments[index]),
                                      onDelete: () => onDelete(payments[index]),
                                    ),
                                  ],
                                )
                              : _cell(''),
                        ],
                      ),
                    ),
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFF12DDE4)),
                      children: [
                        _cell(s.total, bold: true, align: TextAlign.center),
                        _cell(
                          _number(totalPurchases),
                          bold: true,
                          align: TextAlign.center,
                        ),
                        _cell(
                          _number(totalPayments),
                          bold: true,
                          align: TextAlign.center,
                        ),
                      ],
                    ),
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFFF9800)),
                      children: [
                        _cell(s.remaining, bold: true, align: TextAlign.center),
                        _cell(
                          _number(remaining),
                          bold: true,
                          align: TextAlign.center,
                        ),
                        _cell(''),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientInput {
  const _ClientInput(this.name, this.phone);
  final String name;
  final String phone;
}

class _ClientDialog extends StatefulWidget {
  const _ClientDialog({this.client});
  final ClientRecord? client;
  @override
  State<_ClientDialog> createState() => _ClientDialogState();
}

class _ClientDialogState extends State<_ClientDialog> {
  late final name = TextEditingController(text: widget.client?.name);
  late final phone = TextEditingController(text: widget.client?.phone);
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
      title: widget.client == null ? s.addClient : s.editClient,
      icon: Icons.person_outline,
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
              setState(() => error = s.clientValidationError);
              return;
            }
            Navigator.pop(
              context,
              _ClientInput(name.text.trim(), phone.text.trim()),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _PaymentInput {
  const _PaymentInput(this.amount, this.paymentMethod, this.description);
  final double amount;
  final String? paymentMethod;
  final String description;
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({this.transaction});
  final ClientTransactionRow? transaction;
  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  late final amount = TextEditingController(
    text: widget.transaction?.amount.toStringAsFixed(2),
  );
  late final otherMethod = TextEditingController(
    text: widget.transaction?.paymentMethod == null
        ? widget.transaction?.description
        : '',
  );
  String? error;
  late String paymentMethod = widget.transaction == null
      ? 'BANKILY'
      : widget.transaction!.paymentMethod ?? 'OTHER';
  @override
  void dispose() {
    amount.dispose();
    otherMethod.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AppDialogShell(
      title: widget.transaction == null ? s.addPayment : s.editTransaction,
      icon: Icons.payments_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amount,
            decoration: InputDecoration(labelText: s.amountMru),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: paymentMethod,
            decoration: InputDecoration(labelText: s.paymentMethod),
            items: [
              const DropdownMenuItem(value: 'BANKILY', child: Text('Bankily')),
              const DropdownMenuItem(value: 'MASRIVI', child: Text('Masrivi')),
              const DropdownMenuItem(value: 'SEDAD', child: Text('Sedad')),
              DropdownMenuItem(
                value: 'OTHER',
                child: Text(
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'آخر'
                      : 'Autre',
                ),
              ),
            ],
            onChanged: (value) => setState(() {
              if (value != null) paymentMethod = value;
            }),
          ),
          if (paymentMethod == 'OTHER') ...[
            const SizedBox(height: 10),
            TextField(
              controller: otherMethod,
              decoration: InputDecoration(
                labelText: Localizations.localeOf(context).languageCode == 'ar'
                    ? 'طريقة الدفع'
                    : 'Précisez le moyen de paiement',
              ),
            ),
          ],
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
                (paymentMethod == 'OTHER' && otherMethod.text.trim().isEmpty)) {
              setState(() => error = s.validAmountRequired);
              return;
            }
            Navigator.pop(
              context,
              _PaymentInput(
                value,
                paymentMethod == 'OTHER' ? null : paymentMethod,
                paymentMethod == 'OTHER' ? otherMethod.text.trim() : '',
              ),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _FilterDialog extends StatefulWidget {
  const _FilterDialog({
    required this.value,
    required this.ships,
    required this.trips,
  });
  final ClientFilters value;
  final List<RelationOption> ships;
  final Map<String, List<RelationOption>> trips;
  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  DateTime? start;
  DateTime? end;
  String? shipId;
  String? tripId;
  String? type;
  @override
  void initState() {
    super.initState();
    start = widget.value.startDate;
    end = widget.value.endDate;
    shipId = widget.value.shipId;
    tripId = widget.value.tripId;
    type = widget.value.type;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final availableTrips = shipId == null
        ? const <RelationOption>[]
        : widget.trips[shipId] ?? [];
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
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            initialValue: shipId,
            decoration: InputDecoration(labelText: s.shipName),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(s.all)),
              ...widget.ships.map(
                (ship) =>
                    DropdownMenuItem(value: ship.id, child: Text(ship.name)),
              ),
            ],
            onChanged: (value) => setState(() {
              shipId = value;
              tripId = null;
            }),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            initialValue: tripId,
            decoration: InputDecoration(labelText: s.trip),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(s.all)),
              ...availableTrips.map(
                (trip) =>
                    DropdownMenuItem(value: trip.id, child: Text(trip.name)),
              ),
            ],
            onChanged: shipId == null
                ? null
                : (value) => setState(() => tripId = value),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String?>(
            initialValue: type,
            decoration: InputDecoration(labelText: s.transactionType),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(s.all)),
              DropdownMenuItem(
                value: 'CLIENT_PURCHASE',
                child: Text(s.purchase),
              ),
              DropdownMenuItem(value: 'CLIENT_PAYMENT', child: Text(s.payment)),
            ],
            onChanged: (value) => type = value,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const ClientFilters()),
          child: Text(s.clearFilters),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            ClientFilters(
              startDate: start,
              endDate: end,
              shipId: shipId,
              tripId: tripId,
              type: type,
            ),
          ),
          child: Text(s.apply),
        ),
      ],
    );
  }
}
