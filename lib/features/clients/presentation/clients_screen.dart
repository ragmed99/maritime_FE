import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/formatters/money_formatter.dart';
import '../../../core/models/account_position.dart';
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
        return const Center(child: CircularProgressIndicator());
      }
      if (widget.controller.status == ClientsStatus.error) {
        return _StateMessage(
          message: s.clientsLoadError,
          action: s.retry,
          onTap: widget.controller.load,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.clients,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.controller.load,
                    tooltip: s.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _edit(),
                    icon: const Icon(Icons.add),
                    label: Text(s.addClient),
                  ),
                ],
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
                _StateMessage(
                  message: widget.controller.query.isEmpty
                      ? s.noClients
                      : s.noClientSearchResults,
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
                        leading: const CircleAvatar(
                          child: Icon(Icons.person_outline),
                        ),
                        title: Text(client.name),
                        subtitle: Text(client.phone),
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
  void _open(ClientRecord client) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ClientDetailsScreen(
        client: client,
        repository: widget.controller.repository,
      ),
    ),
  );
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
      builder: (_) => AlertDialog(
        title: Text(s.deleteClient),
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
                (client) => DataRow(
                  onSelectChanged: (_) => onOpen(client),
                  cells: [
                    DataCell(Text(client.name)),
                    DataCell(Text(client.phone)),
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client.name),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: s.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : failed
          ? _StateMessage(
              message: s.clientDetailsError,
              action: s.retry,
              onTap: _load,
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
                        child: Wrap(
                          runSpacing: 12,
                          spacing: 30,
                          children: [
                            SizedBox(
                              width: 260,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.client.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  if (widget.client.phone.isNotEmpty)
                                    Text('${s.phone}: ${widget.client.phone}'),
                                ],
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
                        FilledButton.icon(
                          onPressed: () => _add('CLIENT_PURCHASE'),
                          icon: const Icon(Icons.shopping_cart_outlined),
                          label: Text(s.addPurchase),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _add('CLIENT_PAYMENT'),
                          icon: const Icon(Icons.payments_outlined),
                          label: Text(s.addPayment),
                        ),
                        OutlinedButton.icon(
                          onPressed: _filter,
                          icon: const Icon(Icons.filter_alt_outlined),
                          label: Text(s.filters),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      s.clientTransactions,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (data!.transactions.isEmpty)
                      _StateMessage(message: s.noClientTransactions)
                    else
                      _Transactions(
                        rows: data!.transactions,
                        desktop: constraints.maxWidth >= 900,
                        locale: locale,
                      ),
                  ],
                ),
              ),
            ),
    );
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

  Future<void> _add(String type) async {
    final input = await showDialog<_PurchaseInput>(
      context: context,
      builder: (_) => _PurchaseDialog(type: type, ships: ships, trips: trips),
    );
    if (input == null) return;
    try {
      await widget.repository.addTransaction(
        clientId: widget.client.id,
        type: type,
        amount: input.amount,
        date: input.date,
        description: input.description,
        shipId: input.shipId,
        tripId: input.tripId,
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

class _Balance extends StatelessWidget {
  const _Balance({required this.position});
  final AccountPosition position;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final color = position.theyOweUs > 0
        ? Colors.red.shade700
        : position.weOweThem > 0
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${s.theyOweUs}: ${formatMru(position.theyOweUs, locale)}',
            style: TextStyle(color: Colors.red.shade700),
          ),
          Text(
            '${s.weOweThem}: ${formatMru(position.weOweThem, locale)}',
            style: TextStyle(color: Colors.green.shade700),
          ),
          const SizedBox(height: 6),
          Text(s.currentBalance),
          Text(
            formatMru(position.balance.abs(), locale),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            position.theyOweUs > 0
                ? s.clientOwesUs
                : position.weOweThem > 0
                ? s.clientCredit
                : s.balanced,
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}

class _Transactions extends StatelessWidget {
  const _Transactions({
    required this.rows,
    required this.desktop,
    required this.locale,
  });
  final List<ClientTransactionRow> rows;
  final bool desktop;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    String typeLabel(ClientTransactionRow row) =>
        row.type == 'CLIENT_PURCHASE' ? s.purchase : s.payment;
    if (!desktop) {
      return Column(
        children: rows
            .map(
              (row) => Card(
                child: ListTile(
                  leading: Icon(
                    row.type == 'CLIENT_PURCHASE'
                        ? Icons.shopping_cart_outlined
                        : Icons.payments_outlined,
                  ),
                  title: Text(typeLabel(row)),
                  subtitle: Text(
                    '${DateFormat.yMd(locale).format(row.date)} · ${row.time.substring(0, 5)}${row.description.isEmpty ? '' : '\n${row.description}'}${row.ship == null ? '' : '\n${s.shipName}: ${row.ship}'}${row.trip == null ? '' : ' · ${s.trip}: ${row.trip}'}${row.recordedBy == null ? '' : '\n${s.recordedBy}: ${row.recordedBy}'}',
                  ),
                  trailing: Text(formatMru(row.amount, locale)),
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
            s.shipName,
            s.trip,
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
                    DataCell(Text(typeLabel(row))),
                    DataCell(Text(row.description)),
                    DataCell(Text(row.ship ?? '—')),
                    DataCell(Text(row.trip ?? '—')),
                    DataCell(Text(row.recordedBy ?? '—')),
                    DataCell(Text(formatMru(row.amount, locale))),
                  ],
                ),
              )
              .toList(),
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
    return AlertDialog(
      title: Text(widget.client == null ? s.addClient : s.editClient),
      content: SizedBox(
        width: 420,
        child: Column(
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

class _PurchaseInput {
  const _PurchaseInput(
    this.amount,
    this.date,
    this.description,
    this.shipId,
    this.tripId,
  );
  final double amount;
  final DateTime date;
  final String description;
  final String? shipId;
  final String? tripId;
}

class _PurchaseDialog extends StatefulWidget {
  const _PurchaseDialog({
    required this.type,
    required this.ships,
    required this.trips,
  });
  final String type;
  final List<RelationOption> ships;
  final Map<String, List<RelationOption>> trips;
  @override
  State<_PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<_PurchaseDialog> {
  final amount = TextEditingController();
  final description = TextEditingController();
  DateTime date = DateTime.now();
  String? shipId;
  String? tripId;
  String? error;
  bool get purchase => widget.type == 'CLIENT_PURCHASE';
  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final availableTrips = shipId == null
        ? const <RelationOption>[]
        : widget.trips[shipId] ?? [];
    return AlertDialog(
      title: Text(purchase ? s.addPurchase : s.addPayment),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                decoration: InputDecoration(labelText: s.amountMru),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: description,
                decoration: InputDecoration(labelText: s.description),
              ),
              ListTile(
                title: Text(s.date),
                subtitle: Text(DateFormat.yMd(locale).format(date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: date,
                  );
                  if (value != null) setState(() => date = value);
                },
              ),
              if (purchase) ...[
                DropdownButtonFormField<String?>(
                  initialValue: shipId,
                  decoration: InputDecoration(labelText: s.shipOptional),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(s.none)),
                    ...widget.ships.map(
                      (ship) => DropdownMenuItem(
                        value: ship.id,
                        child: Text(ship.name),
                      ),
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
                  decoration: InputDecoration(labelText: s.tripOptional),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(s.none)),
                    ...availableTrips.map(
                      (trip) => DropdownMenuItem(
                        value: trip.id,
                        child: Text(trip.name),
                      ),
                    ),
                  ],
                  onChanged: shipId == null
                      ? null
                      : (value) => setState(() => tripId = value),
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(amount.text.replaceAll(',', '.'));
            if (value == null || value <= 0) {
              setState(() => error = s.validAmountRequired);
              return;
            }
            Navigator.pop(
              context,
              _PurchaseInput(
                value,
                date,
                description.text.trim(),
                purchase ? shipId : null,
                purchase ? tripId : null,
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    final availableTrips = shipId == null
        ? const <RelationOption>[]
        : widget.trips[shipId] ?? [];
    return AlertDialog(
      title: Text(s.filters),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(s.startDate),
                subtitle: Text(
                  start == null
                      ? s.allDates
                      : DateFormat.yMd(locale).format(start!),
                ),
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: start ?? DateTime.now(),
                  );
                  if (value != null) setState(() => start = value);
                },
              ),
              ListTile(
                title: Text(s.endDate),
                subtitle: Text(
                  end == null
                      ? s.allDates
                      : DateFormat.yMd(locale).format(end!),
                ),
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    firstDate: start ?? DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: end ?? DateTime.now(),
                  );
                  if (value != null) setState(() => end = value);
                },
              ),
              DropdownButtonFormField<String?>(
                initialValue: shipId,
                decoration: InputDecoration(labelText: s.shipName),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(s.all)),
                  ...widget.ships.map(
                    (ship) => DropdownMenuItem(
                      value: ship.id,
                      child: Text(ship.name),
                    ),
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
                    (trip) => DropdownMenuItem(
                      value: trip.id,
                      child: Text(trip.name),
                    ),
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
                  DropdownMenuItem(
                    value: 'CLIENT_PAYMENT',
                    child: Text(s.payment),
                  ),
                ],
                onChanged: (value) => type = value,
              ),
            ],
          ),
        ),
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

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, this.action, this.onTap});
  final String message;
  final String? action;
  final Future<void> Function()? onTap;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onTap, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
