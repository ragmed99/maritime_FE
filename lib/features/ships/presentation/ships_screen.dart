import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/formatters/money_formatter.dart';
import '../application/ships_controller.dart';
import '../data/ships_repository.dart';
import '../domain/ship_models.dart';

class ShipsScreen extends StatefulWidget {
  const ShipsScreen({required this.controller, super.key});
  final ShipsController controller;
  @override
  State<ShipsScreen> createState() => _ShipsScreenState();
}

class _ShipsScreenState extends State<ShipsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.status == LoadStatus.idle) widget.controller.load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final strings = AppLocalizations.of(context);
      if (widget.controller.status == LoadStatus.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (widget.controller.status == LoadStatus.error) {
        return _MessageState(
          message: strings.shipsLoadError,
          action: strings.retry,
          onPressed: widget.controller.load,
        );
      }
      return RefreshIndicator(
        onRefresh: widget.controller.load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 900;
            final ships = widget.controller.filteredShips;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.ships,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: strings.refresh,
                      onPressed: widget.controller.load,
                      icon: const Icon(Icons.refresh),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _editShip(),
                      icon: const Icon(Icons.add),
                      label: Text(strings.addShip),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: widget.controller.search,
                  decoration: InputDecoration(
                    labelText: strings.searchShips,
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 18),
                if (ships.isEmpty)
                  _MessageState(
                    message: widget.controller.query.isEmpty
                        ? strings.noShips
                        : strings.noSearchResults,
                  )
                else if (desktop)
                  _ShipTable(
                    ships: ships,
                    onOpen: _openShip,
                    onEdit: _editShip,
                    onDelete: _deleteShip,
                  )
                else
                  ...ships.map(
                    (ship) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.directions_boat_outlined),
                          ),
                          title: Text(ship.name),
                          subtitle: Text(
                            '${strings.owner}: ${ship.ownerName}\n${strings.registrationNumber}: ${ship.registrationNumber}',
                          ),
                          onTap: () => _openShip(ship),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => value == 'edit'
                                ? _editShip(ship)
                                : _deleteShip(ship),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text(strings.edit),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text(strings.delete),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    },
  );

  Future<void> _editShip([ShipRecord? ship]) async {
    try {
      await widget.controller.refreshOwners();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).shipsLoadError)),
        );
      }
      return;
    }
    if (!mounted) return;
    final data = await showDialog<_ShipInput>(
      context: context,
      builder: (_) => _ShipDialog(ship: ship, owners: widget.controller.owners),
    );
    if (data == null) return;
    await widget.controller.saveShip(
      id: ship?.id,
      name: data.name,
      registration: data.registration,
      ownerId: data.ownerId,
    );
  }

  Future<void> _deleteShip(ShipRecord ship) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(strings.deleteShip),
        content: Text(strings.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );
    if (confirmed == true) await widget.controller.deleteShip(ship.id);
  }

  void _openShip(ShipRecord ship) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ShipDetailsScreen(
        ship: ship,
        repository: widget.controller.repository,
      ),
    ),
  );
}

class _ShipTable extends StatelessWidget {
  const _ShipTable({
    required this.ships,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });
  final List<ShipRecord> ships;
  final void Function(ShipRecord) onOpen;
  final void Function([ShipRecord?]) onEdit;
  final void Function(ShipRecord) onDelete;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            s.shipName,
            s.registrationNumber,
            s.owner,
            s.actions,
          ].map((e) => DataColumn(label: Text(e))).toList(),
          rows: ships
              .map(
                (ship) => DataRow(
                  onSelectChanged: (_) => onOpen(ship),
                  cells: [
                    DataCell(Text(ship.name)),
                    DataCell(Text(ship.registrationNumber)),
                    DataCell(Text(ship.ownerName)),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: s.edit,
                            onPressed: () => onEdit(ship),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: s.delete,
                            onPressed: () => onDelete(ship),
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

class ShipDetailsScreen extends StatefulWidget {
  const ShipDetailsScreen({
    required this.ship,
    required this.repository,
    super.key,
  });
  final ShipRecord ship;
  final ShipsRepository repository;
  @override
  State<ShipDetailsScreen> createState() => _ShipDetailsScreenState();
}

class _ShipDetailsScreenState extends State<ShipDetailsScreen> {
  Financials? financials;
  List<TripRecord> trips = [];
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
      final values = await Future.wait([
        widget.repository.shipFinancials(widget.ship.id),
        widget.repository.trips(widget.ship.id),
      ]);
      financials = values[0] as Financials;
      trips = values[1] as List<TripRecord>;
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
        title: Text(widget.ship.name),
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
          ? _MessageState(
              message: s.shipDetailsError,
              action: s.retry,
              onPressed: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Card(
                    child: ListTile(
                      title: Text(widget.ship.name),
                      subtitle: Text(
                        '${s.registrationNumber}: ${widget.ship.registrationNumber}\n${s.owner}: ${widget.ship.ownerName}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FinancialCards(value: financials!),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          s.trips,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () => _editTrip(),
                        icon: const Icon(Icons.add),
                        label: Text(s.addTrip),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (trips.isEmpty)
                    _MessageState(message: s.noTrips)
                  else
                    ...trips.map(
                      (trip) => _TripCard(
                        trip: trip,
                        repository: widget.repository,
                        onChanged: _load,
                        onEdit: () => _editTrip(trip),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _editTrip([TripRecord? trip]) async {
    final input = await showDialog<_TripInput>(
      context: context,
      builder: (_) => _TripDialog(trip: trip),
    );
    if (input == null) return;
    await widget.repository.saveTrip(
      id: trip?.id,
      shipId: widget.ship.id,
      departureDate: input.departure,
      origin: input.origin,
      destination: input.destination,
      notes: input.notes,
      expenses: input.expenses,
      revenues: input.revenues,
    );
    await _load();
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.repository,
    required this.onChanged,
    required this.onEdit,
  });
  final TripRecord trip;
  final ShipsRepository repository;
  final Future<void> Function() onChanged;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final f = DateFormat.yMd(locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          title: Text(f.format(trip.departureDate)),
          subtitle: Text(
            '${s.totalRevenue}: ${formatMru(trip.financials!.revenue, locale)} · ${s.totalExpenses}: ${formatMru(trip.financials!.expenses, locale)}\n${s.profitLoss}: ${formatMru(trip.financials!.profit, locale)}',
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TripDetailsScreen(trip: trip, repository: repository),
            ),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'edit') {
                onEdit();
              } else {
                await repository.deleteTrip(trip.id);
                await onChanged();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Text(s.edit)),
              PopupMenuItem(value: 'delete', child: Text(s.delete)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinancialCards extends StatelessWidget {
  const _FinancialCards({required this.value});
  final Financials value;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children:
          [
                (s.totalRevenue, value.revenue),
                (s.totalExpenses, value.expenses),
                (s.profitLoss, value.profit),
              ]
              .map(
                (item) => SizedBox(
                  width: 220,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.$1),
                          const SizedBox(height: 8),
                          Text(
                            formatMru(item.$2, locale),
                            style: Theme.of(context).textTheme.titleLarge,
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

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({
    required this.trip,
    required this.repository,
    super.key,
  });
  final TripRecord trip;
  final ShipsRepository repository;
  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  List<TripTransaction> transactions = [];
  List<ClientOption> clients = [];
  Financials? financials;
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
      final values = await Future.wait([
        widget.repository.transactions(widget.trip.id),
        widget.repository.clients(),
        widget.repository.tripFinancials(widget.trip.id),
      ]);
      transactions = values[0] as List<TripTransaction>;
      clients = values[1] as List<ClientOption>;
      financials = values[2] as Financials;
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
        title: Text(s.tripDetails),
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
          ? _MessageState(
              message: s.tripDetailsError,
              action: s.retry,
              onPressed: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 28,
                        runSpacing: 12,
                        children: [
                          _TripDate(
                            label: s.date,
                            value: DateFormat.yMd(
                              locale,
                            ).format(widget.trip.departureDate),
                          ),
                          if (widget.trip.origin.isNotEmpty)
                            _TripDate(
                              label: s.origin,
                              value: widget.trip.origin,
                            ),
                          if (widget.trip.destination.isNotEmpty)
                            _TripDate(
                              label: s.destination,
                              value: widget.trip.destination,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FinancialCards(value: financials!),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _add('SHIP_REVENUE'),
                        icon: const Icon(Icons.add),
                        label: Text(s.addRevenue),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _add('SHIP_EXPENSE'),
                        icon: const Icon(Icons.remove),
                        label: Text(s.addExpense),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _add('CLIENT_PURCHASE'),
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: Text(s.addClientPurchase),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    s.tripTransactions,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (transactions.isEmpty)
                    _MessageState(message: s.noTripTransactions)
                  else
                    ...transactions.map(
                      (item) => Card(
                        child: ListTile(
                          leading: Icon(
                            item.type == 'SHIP_REVENUE'
                                ? Icons.arrow_downward
                                : item.type == 'SHIP_EXPENSE'
                                ? Icons.arrow_upward
                                : Icons.shopping_cart_outlined,
                          ),
                          title: Text(_typeLabel(s, item.type)),
                          subtitle: Text(
                            '${DateFormat.yMd(locale).format(item.date)}${item.description.isEmpty ? '' : ' · ${item.description}'}${item.clientName == null ? '' : '\n${s.client}: ${item.clientName}'}',
                          ),
                          trailing: Text(formatMru(item.amount, locale)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  String _typeLabel(AppLocalizations s, String type) => switch (type) {
    'SHIP_REVENUE' => s.revenue,
    'SHIP_EXPENSE' => s.expense,
    'CLIENT_PURCHASE' => s.clientPurchase,
    _ => type,
  };
  Future<void> _add(String type) async {
    final input = await showDialog<_TransactionInput>(
      context: context,
      builder: (_) => _TransactionDialog(type: type, clients: clients),
    );
    if (input == null) return;
    await widget.repository.addTransaction(
      type: type,
      shipId: widget.trip.shipId,
      tripId: widget.trip.id,
      amount: input.amount,
      date: input.date,
      description: input.description,
      clientId: input.clientId,
    );
    await _load();
  }
}

class _TripDate extends StatelessWidget {
  const _TripDate({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    ),
  );
}

class _ShipInput {
  const _ShipInput(this.name, this.registration, this.ownerId);
  final String name;
  final String registration;
  final String ownerId;
}

class _ShipDialog extends StatefulWidget {
  const _ShipDialog({required this.ship, required this.owners});
  final ShipRecord? ship;
  final List<OwnerOption> owners;
  @override
  State<_ShipDialog> createState() => _ShipDialogState();
}

class _ShipDialogState extends State<_ShipDialog> {
  late final TextEditingController name = TextEditingController(
    text: widget.ship?.name,
  );
  late final TextEditingController registration = TextEditingController(
    text: widget.ship?.registrationNumber,
  );
  String? ownerId;
  String? error;
  @override
  void initState() {
    super.initState();
    ownerId =
        widget.ship?.ownerId ??
        (widget.owners.isEmpty ? null : widget.owners.first.id);
  }

  @override
  void dispose() {
    name.dispose();
    registration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.ship == null ? s.addShip : s.editShip),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: s.shipName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: registration,
              decoration: InputDecoration(labelText: s.registrationNumber),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: ownerId,
              decoration: InputDecoration(labelText: s.owner),
              items: widget.owners
                  .map(
                    (owner) => DropdownMenuItem(
                      value: owner.id,
                      child: Text(owner.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => ownerId = value),
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
            if (name.text.trim().isEmpty ||
                registration.text.trim().isEmpty ||
                ownerId == null) {
              setState(() => error = s.requiredFields);
              return;
            }
            Navigator.pop(
              context,
              _ShipInput(name.text.trim(), registration.text.trim(), ownerId!),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _TripInput {
  const _TripInput(
    this.departure,
    this.origin,
    this.destination,
    this.notes,
    this.expenses,
    this.revenues,
  );
  final DateTime departure;
  final String origin;
  final String destination;
  final String notes;
  final List<TripFinancialEntry> expenses;
  final List<TripFinancialEntry> revenues;
}

class _EntryDraft {
  final amount = TextEditingController();
  final description = TextEditingController();
  void dispose() {
    amount.dispose();
    description.dispose();
  }
}

class _TripDialog extends StatefulWidget {
  const _TripDialog({this.trip});
  final TripRecord? trip;
  @override
  State<_TripDialog> createState() => _TripDialogState();
}

class _TripDialogState extends State<_TripDialog> {
  late DateTime departure = widget.trip?.departureDate ?? DateTime.now();
  final expenses = <_EntryDraft>[];
  final revenues = <_EntryDraft>[];
  String? validationError;
  late final TextEditingController origin = TextEditingController(
    text: widget.trip?.origin,
  );
  late final TextEditingController destination = TextEditingController(
    text: widget.trip?.destination,
  );
  late final TextEditingController notes = TextEditingController(
    text: widget.trip?.notes,
  );
  @override
  void dispose() {
    origin.dispose();
    destination.dispose();
    notes.dispose();
    for (final entry in [...expenses, ...revenues]) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return AlertDialog(
      title: Text(widget.trip == null ? s.addTrip : s.editTrip),
      content: SizedBox(
        width: 430,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(s.date),
                subtitle: Text(DateFormat.yMd(locale).format(departure)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final value = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    initialDate: departure,
                  );
                  if (value != null) setState(() => departure = value);
                },
              ),
              TextField(
                controller: origin,
                decoration: InputDecoration(labelText: s.origin),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: destination,
                decoration: InputDecoration(labelText: s.destination),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notes,
                decoration: InputDecoration(labelText: s.notes),
                maxLines: 2,
              ),
              if (widget.trip == null) ...[
                const SizedBox(height: 18),
                _financialEntries(
                  s.openingExpenses,
                  s.addExpenseLine,
                  expenses,
                ),
                const SizedBox(height: 14),
                _financialEntries(
                  s.openingRevenues,
                  s.addRevenueLine,
                  revenues,
                ),
              ],
              if (validationError != null) ...[
                const SizedBox(height: 12),
                Text(
                  validationError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(s.save)),
      ],
    );
  }

  Widget _financialEntries(
    String title,
    String addLabel,
    List<_EntryDraft> entries,
  ) {
    final s = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        ...entries.indexed.map(
          (item) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: item.$2.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: s.amountMru),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: item.$2.description,
                  decoration: InputDecoration(labelText: s.description),
                ),
              ),
              IconButton(
                onPressed: () {
                  final removed = entries.removeAt(item.$1);
                  removed.dispose();
                  setState(() {});
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
            ],
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: () => setState(() => entries.add(_EntryDraft())),
            icon: const Icon(Icons.add),
            label: Text(addLabel),
          ),
        ),
      ],
    );
  }

  void _save() {
    final s = AppLocalizations.of(context);
    List<TripFinancialEntry>? convert(
      List<_EntryDraft> entries, {
      required bool requireDetails,
    }) {
      final result = <TripFinancialEntry>[];
      for (final entry in entries) {
        final amount = double.tryParse(entry.amount.text.replaceAll(',', '.'));
        if (amount == null || amount <= 0) {
          validationError = s.invalidAmount;
          return null;
        }
        final details = entry.description.text.trim();
        if (requireDetails && details.isEmpty) {
          validationError = s.expenseDetailsRequired;
          return null;
        }
        result.add(TripFinancialEntry(amount: amount, description: details));
      }
      return result;
    }

    final expenseValues = convert(expenses, requireDetails: true);
    final revenueValues = convert(revenues, requireDetails: false);
    if (expenseValues == null || revenueValues == null) {
      setState(() {});
      return;
    }
    Navigator.pop(
      context,
      _TripInput(
        departure,
        origin.text.trim(),
        destination.text.trim(),
        notes.text.trim(),
        expenseValues,
        revenueValues,
      ),
    );
  }
}

class _TransactionInput {
  const _TransactionInput(
    this.amount,
    this.date,
    this.description,
    this.clientId,
  );
  final double amount;
  final DateTime date;
  final String description;
  final String? clientId;
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({required this.type, required this.clients});
  final String type;
  final List<ClientOption> clients;
  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final amount = TextEditingController();
  final description = TextEditingController();
  DateTime date = DateTime.now();
  String? clientId;
  String? error;
  @override
  void initState() {
    super.initState();
    if (widget.clients.isNotEmpty) clientId = widget.clients.first.id;
  }

  @override
  void dispose() {
    amount.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final purchase = widget.type == 'CLIENT_PURCHASE';
    final locale = Localizations.localeOf(context).toLanguageTag();
    return AlertDialog(
      title: Text(_title(s)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: s.amountMru),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: description,
              decoration: InputDecoration(labelText: s.description),
            ),
            const SizedBox(height: 6),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(s.date),
              subtitle: Text(DateFormat.yMd(locale).format(date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDate: date,
                );
                if (selected != null) setState(() => date = selected);
              },
            ),
            if (purchase) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: clientId,
                decoration: InputDecoration(labelText: s.client),
                items: widget.clients
                    .map(
                      (client) => DropdownMenuItem(
                        value: client.id,
                        child: Text(client.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => clientId = value,
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () {
            final value = double.tryParse(amount.text.replaceAll(',', '.'));
            if (value == null || value <= 0 || (purchase && clientId == null)) {
              setState(() => error = s.validAmountRequired);
              return;
            }
            Navigator.pop(
              context,
              _TransactionInput(
                value,
                date,
                description.text.trim(),
                purchase ? clientId : null,
              ),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }

  String _title(AppLocalizations s) => switch (widget.type) {
    'SHIP_REVENUE' => s.addRevenue,
    'SHIP_EXPENSE' => s.addExpense,
    _ => s.addClientPurchase,
  };
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.message, this.action, this.onPressed});
  final String message;
  final String? action;
  final Future<void> Function()? onPressed;
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
            FilledButton(onPressed: onPressed, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
