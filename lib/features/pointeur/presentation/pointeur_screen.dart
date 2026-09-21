import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_dialog_shell.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/list_header_bar.dart';
import '../../../core/widgets/section_header.dart';
import '../../administration/data/administration_repository.dart';
import '../../auth/application/auth_controller.dart';
import '../../settings/application/locale_controller.dart';
import '../../settings/application/theme_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../ships/data/ships_repository.dart';
import '../../ships/domain/ship_models.dart';

class PointeurScreen extends StatelessWidget {
  const PointeurScreen({
    required this.repository,
    required this.authController,
    required this.localeController,
    required this.themeController,
    required this.administrationRepository,
    super.key,
  });

  final ShipsRepository repository;
  final AuthController authController;
  final LocaleController localeController;
  final ThemeController themeController;
  final AdministrationRepository administrationRepository;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(arabic ? 'واجهة مسجل المشتريات' : 'Espace pointeur'),
        actions: [
          IconButton(
            tooltip: s.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(s.settings)),
                  body: SettingsScreen(
                    controller: localeController,
                    themeController: themeController,
                    repository: administrationRepository,
                    showAppearance: false,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: s.logout,
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ShipsScreen(repository: repository),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_boat_outlined, size: 42),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          arabic
                              ? 'قائمة السفن'
                              : 'Accéder à la liste des navires',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.logout),
        content: Text(s.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(s.confirmLogout),
          ),
        ],
      ),
    );
    if (confirmed == true) await authController.logout();
  }
}

class _ShipsScreen extends StatefulWidget {
  const _ShipsScreen({required this.repository});
  final ShipsRepository repository;
  @override
  State<_ShipsScreen> createState() => _ShipsScreenState();
}

class _ShipsScreenState extends State<_ShipsScreen> {
  List<ShipRecord> ships = [];
  bool loading = true;
  String query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    ships = await widget.repository.pointeurShips();
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final visible = ships
        .where((ship) => ship.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(s.ships)),
      body: loading
          ? AppStateView.loading()
          : RefreshIndicator(
              onRefresh: _load,
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    ListHeaderBar(
                      title: s.ships,
                      onRefresh: _load,
                      refreshTooltip: s.refresh,
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      onChanged: (value) => setState(() => query = value),
                      decoration: InputDecoration(
                        labelText: s.searchShips,
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (visible.isEmpty)
                      AppStateView.empty(
                        message: query.isEmpty ? s.noShips : s.noSearchResults,
                        icon: Icons.directions_boat_outlined,
                      )
                    else if (constraints.maxWidth >= 900)
                      Card(
                        child: DataTable(
                          columns: [s.shipName, s.owner]
                              .map((label) => DataColumn(label: Text(label)))
                              .toList(),
                          rows: visible
                              .map(
                                (ship) => DataRow(
                                  onSelectChanged: (_) => _open(ship),
                                  cells: [
                                    DataCell(Text(ship.name)),
                                    DataCell(Text(ship.ownerName)),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      )
                    else
                      ...visible.map(
                        (ship) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              leading: InitialsAvatar(
                                ship.name,
                                icon: Icons.directions_boat_outlined,
                              ),
                              title: Text(ship.name),
                              subtitle: Text('${s.owner}: ${ship.ownerName}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _open(ship),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  void _open(ShipRecord ship) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => _TripsScreen(repository: widget.repository, ship: ship),
    ),
  );
}

class _TripsScreen extends StatefulWidget {
  const _TripsScreen({required this.repository, required this.ship});
  final ShipsRepository repository;
  final ShipRecord ship;
  @override
  State<_TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<_TripsScreen> {
  List<TripRecord> trips = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    trips = await widget.repository.pointeurTrips(widget.ship.id);
    if (mounted) setState(() => loading = false);
  }

  Future<void> _createTrip() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: DateTime.now(),
    );
    if (selected == null) return;
    await widget.repository.saveTrip(
      shipId: widget.ship.id,
      departureDate: selected,
    );
    await _load();
  }

  Future<void> _editTrip(TripRecord trip) async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDate: trip.departureDate,
    );
    if (selected == null) return;
    await widget.repository.saveTrip(
      id: trip.id,
      shipId: widget.ship.id,
      departureDate: selected,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final date = DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Scaffold(
      appBar: AppBar(title: Text(widget.ship.name)),
      body: loading
          ? AppStateView.loading()
          : RefreshIndicator(
              onRefresh: _load,
              child: LayoutBuilder(
                builder: (context, constraints) => ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                  children: [
                    Card(
                      child: ListTile(
                        leading: InitialsAvatar(
                          widget.ship.name,
                          icon: Icons.directions_boat_outlined,
                        ),
                        title: Text(widget.ship.name),
                        subtitle: Text('${s.owner}: ${widget.ship.ownerName}'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SectionHeader(
                      s.trips,
                      trailing: FilledButton.icon(
                        onPressed: _createTrip,
                        icon: const Icon(Icons.add),
                        label: Text(s.addTrip),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (trips.isEmpty)
                      AppStateView.empty(
                        message: s.noTrips,
                        icon: Icons.map_outlined,
                      )
                    else if (constraints.maxWidth >= 900)
                      Card(
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text(s.date)),
                            DataColumn(label: Text(s.actions)),
                          ],
                          rows: trips
                              .map(
                                (trip) => DataRow(
                                  onSelectChanged: (_) => _openTrip(trip),
                                  cells: [
                                    DataCell(
                                      Text(date.format(trip.departureDate)),
                                    ),
                                    DataCell(
                                      IconButton(
                                        tooltip: s.edit,
                                        onPressed: () => _editTrip(trip),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      )
                    else
                      ...trips.map(
                        (trip) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.14),
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                child: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 18,
                                ),
                              ),
                              title: Text(date.format(trip.departureDate)),
                              trailing: IconButton(
                                tooltip: s.edit,
                                onPressed: () => _editTrip(trip),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              onTap: () => _openTrip(trip),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _openTrip(TripRecord trip) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _TripScreen(
          repository: widget.repository,
          ship: widget.ship,
          trip: trip,
        ),
      ),
    );
    await _load();
  }
}

class _TripScreen extends StatefulWidget {
  const _TripScreen({
    required this.repository,
    required this.ship,
    required this.trip,
  });
  final ShipsRepository repository;
  final ShipRecord ship;
  final TripRecord trip;
  @override
  State<_TripScreen> createState() => _TripScreenState();
}

class _TripScreenState extends State<_TripScreen> {
  List<PointeurPurchase> purchases = [];
  List<ClientOption> clients = [];
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final values = await Future.wait([
      widget.repository.pointeurPurchases(widget.trip.id),
      widget.repository.clients(),
    ]);
    purchases = values[0] as List<PointeurPurchase>;
    clients = values[1] as List<ClientOption>;
    if (mounted) setState(() => loading = false);
  }

  Future<void> _addPurchase() async {
    final input = await showDialog<_OrderBatchInput>(
      context: context,
      builder: (_) => _OrderDialog(clients: clients),
    );
    if (input == null) return;
    setState(() => saving = true);
    try {
      for (final purchase in input.purchases) {
        var clientId = purchase.clientId;
        if (purchase.newClientName != null) {
          clientId = (await widget.repository.createClient(
            purchase.newClientName!,
          )).id;
        }
        for (final line in purchase.lines) {
          await widget.repository.addPendingPurchase(
            shipId: widget.ship.id,
            tripId: widget.trip.id,
            clientId: clientId!,
            description: line.$1,
            quantity: line.$2,
            date: widget.trip.departureDate,
          );
        }
      }
      await _load();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _editPurchase(PointeurPurchase purchase) async {
    final input = await showDialog<_PurchaseEditInput>(
      context: context,
      builder: (_) => _PurchaseEditDialog(purchase: purchase, clients: clients),
    );
    if (input == null) return;
    setState(() => saving = true);
    try {
      await widget.repository.updatePendingPurchase(
        transactionId: purchase.id,
        clientId: input.clientId,
        description: input.description,
        quantity: input.quantity,
      );
      await _load();
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.ship.name} · ${DateFormat.yMd(locale).format(widget.trip.departureDate)}',
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: saving ? null : _addPurchase,
        icon: const Icon(Icons.add_shopping_cart_outlined),
        label: Text(s.addClientPurchase),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _PointeurTripLedgerSheet(
                    shipName: widget.ship.name,
                    date: widget.trip.departureDate,
                    purchases: purchases,
                    onEdit: saving ? null : _editPurchase,
                  ),
                ],
              ),
            ),
    );
  }
}

class _PointeurTripLedgerSheet extends StatelessWidget {
  const _PointeurTripLedgerSheet({
    required this.shipName,
    required this.date,
    required this.purchases,
    required this.onEdit,
  });

  final String shipName;
  final DateTime date;
  final List<PointeurPurchase> purchases;
  final ValueChanged<PointeurPurchase>? onEdit;

  String _number(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.replaceFirst(RegExp(r'\.?0+$'), '').replaceAll('.', ',');
  }

  Widget _cell(String value, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    child: Text(
      value,
      style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w400),
    ),
  );

  TableRow _row(List<Widget> cells, {Color? color}) => TableRow(
    decoration: color == null ? null : BoxDecoration(color: color),
    children: cells,
  );

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final groups = <String, List<PointeurPurchase>>{};
    for (final purchase in purchases) {
      groups.putIfAbsent(purchase.clientName, () => []).add(purchase);
    }
    final totalQuantity = purchases.fold<double>(
      0,
      (sum, purchase) => sum + purchase.quantity,
    );
    final palette = <Color>[
      const Color(0xFFFFF3B0),
      const Color(0xFFD9EFCB),
      const Color(0xFFFFD2A8),
      const Color(0xFFD6E8FF),
      const Color(0xFFE7D7F5),
      const Color(0xFFFFD9E1),
    ];
    if (MediaQuery.sizeOf(context).width < 700) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            shipName,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(DateFormat('dd/MM/yyyy').format(date)),
          const SizedBox(height: 12),
          ...groups.entries.indexed.expand((indexed) {
            final group = indexed.$2;
            final color = palette[indexed.$1 % palette.length];
            return [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 6),
                child: Text(
                  group.key,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              ...group.value.map(
                (row) => Card(
                  color: color,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(row.description),
                    subtitle: Text('${s.quantity}: ${_number(row.quantity)}'),
                    trailing: IconButton(
                      tooltip: s.edit,
                      onPressed: onEdit == null ? null : () => onEdit!(row),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ),
                ),
              ),
            ];
          }),
          Card(
            child: ListTile(
              title: Text(
                s.total,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              trailing: Text(
                _number(totalQuantity),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      );
    }
    const widths = <int, TableColumnWidth>{
      0: FixedColumnWidth(270),
      1: FixedColumnWidth(120),
      2: FixedColumnWidth(70),
    };
    final border = TableBorder.all(color: Theme.of(context).dividerColor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 626,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(DateFormat('dd/MM/yyyy').format(date)),
                const SizedBox(height: 12),
                Table(
                  border: border,
                  columnWidths: widths,
                  children: [
                    _row([
                      _cell(s.species, bold: true),
                      _cell(s.quantity, bold: true),
                      Center(child: Text(s.actions)),
                    ]),
                  ],
                ),
                ...groups.entries.indexed.map((indexed) {
                  final group = indexed.$2;
                  final color = palette[indexed.$1 % palette.length];
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 460,
                          child: Table(
                            border: border,
                            columnWidths: widths,
                            children: group.value
                                .map(
                                  (row) => _row([
                                    _cell(row.description),
                                    _cell(_number(row.quantity)),
                                    Center(
                                      child: IconButton(
                                        tooltip: s.edit,
                                        onPressed: onEdit == null
                                            ? null
                                            : () => onEdit!(row),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ], color: color),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 150,
                          child: Center(
                            child: Text(
                              group.key,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(
                  width: 460,
                  child: Table(
                    border: border,
                    columnWidths: widths,
                    children: [
                      _row([
                        _cell(s.total, bold: true),
                        _cell(_number(totalQuantity), bold: true),
                        _cell(''),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseEditInput {
  const _PurchaseEditInput(this.clientId, this.description, this.quantity);
  final String clientId;
  final String description;
  final double quantity;
}

class _PurchaseEditDialog extends StatefulWidget {
  const _PurchaseEditDialog({required this.purchase, required this.clients});
  final PointeurPurchase purchase;
  final List<ClientOption> clients;

  @override
  State<_PurchaseEditDialog> createState() => _PurchaseEditDialogState();
}

class _PurchaseEditDialogState extends State<_PurchaseEditDialog> {
  late String? clientId =
      widget.purchase.clientId ??
      (widget.clients.isEmpty ? null : widget.clients.first.id);
  late final description = TextEditingController(
    text: widget.purchase.description,
  );
  late final quantity = TextEditingController(
    text: widget.purchase.quantity.toStringAsFixed(2),
  );
  String? error;

  @override
  void dispose() {
    description.dispose();
    quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AppDialogShell(
      title: s.edit,
      icon: Icons.edit_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            onChanged: (value) => setState(() => clientId = value),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: description,
            decoration: InputDecoration(labelText: s.description),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: quantity,
            decoration: InputDecoration(
              labelText: s.quantity,
              suffixText: 'kg',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            final value = double.tryParse(quantity.text.replaceAll(',', '.'));
            if (clientId == null ||
                description.text.trim().isEmpty ||
                value == null ||
                value <= 0) {
              setState(() => error = s.validAmountRequired);
              return;
            }
            Navigator.pop(
              context,
              _PurchaseEditInput(clientId!, description.text.trim(), value),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _OrderInput {
  const _OrderInput(this.clientId, this.newClientName, this.lines);
  final String? clientId;
  final String? newClientName;
  final List<(String, double)> lines;
}

class _OrderBatchInput {
  const _OrderBatchInput(this.purchases);
  final List<_OrderInput> purchases;
}

class _OrderDialog extends StatefulWidget {
  const _OrderDialog({required this.clients});
  final List<ClientOption> clients;
  @override
  State<_OrderDialog> createState() => _OrderDialogState();
}

class _OrderDialogState extends State<_OrderDialog> {
  final completed = <_OrderInput>[];
  String? clientId;
  bool newClient = false;
  final clientName = TextEditingController();
  final lines = <(TextEditingController, TextEditingController)>[];
  String? error;

  @override
  void initState() {
    super.initState();
    clientId = widget.clients.isEmpty ? null : widget.clients.first.id;
    _addLine();
  }

  void _addLine() =>
      lines.add((TextEditingController(), TextEditingController()));

  @override
  void dispose() {
    clientName.dispose();
    for (final line in lines) {
      line.$1.dispose();
      line.$2.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return AppDialogShell(
      title: '${s.addClientPurchase} ${completed.length + 1}',
      icon: Icons.shopping_cart_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: completed.isEmpty ? null : _goToPreviousPurchase,
                tooltip: arabic ? 'الشراء السابق' : 'Achat précédent',
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  arabic
                      ? 'الشراء ${completed.length + 1}'
                      : 'Achat ${completed.length + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          if (completed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                arabic
                    ? 'تمت إضافة ${completed.length} عمليات شراء'
                    : '${completed.length} achat(s) préparé(s)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          if (!newClient)
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
            )
          else
            TextField(
              controller: clientName,
              decoration: InputDecoration(labelText: s.name),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(() => newClient = !newClient),
              icon: const Icon(Icons.person_add_outlined),
              label: Text(newClient ? s.cancel : s.addClient),
            ),
          ),
          ...lines.indexed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: entry.$2.$1,
                      decoration: InputDecoration(labelText: s.description),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: entry.$2.$2,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: '${s.quantity} (kg)',
                      ),
                    ),
                  ),
                  if (lines.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() {
                        final removed = lines.removeAt(entry.$1);
                        removed.$1.dispose();
                        removed.$2.dispose();
                      }),
                    ),
                ],
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(_addLine),
              icon: const Icon(Icons.add),
              label: Text(s.addPurchaseLine),
            ),
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const Divider(height: 24),
          OutlinedButton.icon(
            onPressed: _addAnotherPurchase,
            icon: const Icon(Icons.add_shopping_cart_outlined),
            label: Text(arabic ? 'إضافة شراء آخر' : 'Ajouter un autre achat'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(onPressed: _saveAll, child: Text(s.save)),
      ],
    );
  }

  _OrderInput? _readCurrent() {
    final values = <(String, double)>[];
    for (final line in lines) {
      final description = line.$1.text.trim();
      final quantity = double.tryParse(line.$2.text.replaceAll(',', '.'));
      if (description.isEmpty || quantity == null || quantity <= 0) {
        setState(
          () => error = AppLocalizations.of(context).validAmountRequired,
        );
        return null;
      }
      values.add((description, quantity));
    }
    final name = clientName.text.trim();
    if ((!newClient && clientId == null) || (newClient && name.isEmpty)) {
      setState(() => error = AppLocalizations.of(context).validAmountRequired);
      return null;
    }
    return _OrderInput(
      newClient ? null : clientId,
      newClient ? name : null,
      values,
    );
  }

  void _addAnotherPurchase() {
    final purchase = _readCurrent();
    if (purchase == null) return;
    setState(() {
      completed.add(purchase);
      _clearLines();
      lines.add((TextEditingController(), TextEditingController()));
      clientId = widget.clients.isEmpty ? null : widget.clients.first.id;
      newClient = false;
      clientName.clear();
      error = null;
    });
  }

  void _goToPreviousPurchase() {
    if (completed.isEmpty) return;
    final previous = completed.removeLast();
    _clearLines();
    for (final value in previous.lines) {
      lines.add((
        TextEditingController(text: value.$1),
        TextEditingController(text: _editableNumber(value.$2)),
      ));
    }
    clientId = previous.clientId;
    newClient = previous.newClientName != null;
    clientName.text = previous.newClientName ?? '';
    error = null;
    setState(() {});
  }

  void _clearLines() {
    for (final line in lines) {
      line.$1.dispose();
      line.$2.dispose();
    }
    lines.clear();
  }

  String _editableNumber(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  void _saveAll() {
    final purchase = _readCurrent();
    if (purchase == null) return;
    Navigator.pop(context, _OrderBatchInput([...completed, purchase]));
  }
}
