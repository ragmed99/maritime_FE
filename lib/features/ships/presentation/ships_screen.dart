import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/formatters/money_formatter.dart';
import '../../../core/files/pdf_export.dart';
import '../../../core/widgets/app_date_field.dart';
import '../../../core/widgets/app_dialog_shell.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/home_button.dart';
import '../../../core/widgets/list_header_bar.dart';
import '../../../core/widgets/metric_card.dart';
import '../../../core/widgets/money_text.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/transaction_row_actions.dart';
import '../application/ships_controller.dart';
import '../data/ships_repository.dart';
import '../domain/ship_models.dart';

const _pendingPriceColor = Color(0xFFFFE3E3);

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
        return AppStateView.loading();
      }
      if (widget.controller.status == LoadStatus.error) {
        return AppStateView.error(
          message: strings.shipsLoadError,
          retryLabel: strings.retry,
          onRetry: widget.controller.load,
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
                ListHeaderBar(
                  title: strings.ships,
                  onRefresh: widget.controller.load,
                  refreshTooltip: strings.refresh,
                  onAdd: () => _editShip(),
                  addLabel: strings.addShip,
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
                  AppStateView.empty(
                    message: widget.controller.query.isEmpty
                        ? strings.noShips
                        : strings.noSearchResults,
                    icon: Icons.directions_boat_outlined,
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
                        color: ship.financials.hasUnpricedPurchases
                            ? _pendingPriceColor
                            : null,
                        child: ListTile(
                          leading: InitialsAvatar(
                            ship.name,
                            icon: Icons.directions_boat_outlined,
                          ),
                          title: Text(ship.name),
                          subtitle: Text(
                            '${strings.owner}: ${ship.ownerName}\n'
                            '${strings.outcome}: ${formatMru(ship.financials.revenue, Localizations.localeOf(context).toLanguageTag())}',
                          ),
                          isThreeLine: false,
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
    var ownerId = data.ownerId;
    if (data.newOwnerName != null) {
      final owner = await widget.controller.repository.createOwner(
        name: data.newOwnerName!,
        phone: data.newOwnerPhone,
      );
      ownerId = owner.id;
    }
    await widget.controller.saveShip(
      id: ship?.id,
      name: data.name,
      ownerId: ownerId!,
    );
  }

  Future<void> _deleteShip(ShipRecord ship) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AppDialogShell(
        title: strings.deleteShip,
        icon: Icons.delete_outline,
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

  Future<void> _openShip(ShipRecord ship) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ShipDetailsScreen(
          ship: ship,
          repository: widget.controller.repository,
        ),
      ),
    );
    await widget.controller.load();
  }
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            s.shipName,
            s.owner,
            s.outcome,
            s.actions,
          ].map((e) => DataColumn(label: Text(e))).toList(),
          rows: ships
              .map(
                (ship) => DataRow(
                  color: WidgetStatePropertyAll(
                    ship.financials.hasUnpricedPurchases
                        ? _pendingPriceColor
                        : null,
                  ),
                  onSelectChanged: (_) => onOpen(ship),
                  cells: [
                    DataCell(Text(ship.name)),
                    DataCell(Text(ship.ownerName)),
                    DataCell(
                      MoneyText(ship.financials.revenue, locale: locale),
                    ),
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
              message: s.shipDetailsError,
              retryLabel: s.retry,
              onRetry: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final desktop = constraints.maxWidth >= 900;
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Card(
                        child: ListTile(
                          leading: InitialsAvatar(
                            widget.ship.name,
                            icon: Icons.directions_boat_outlined,
                          ),
                          title: Text(widget.ship.name),
                          subtitle: Text(
                            '${s.owner}: ${widget.ship.ownerName}',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SectionHeader(
                        s.trips,
                        trailing: FilledButton.icon(
                          onPressed: () => _editTrip(),
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
                      else if (desktop)
                        _TripTable(
                          trips: trips,
                          shipName: widget.ship.name,
                          repository: widget.repository,
                          onChanged: _load,
                          onEdit: (trip) => _editTrip(trip),
                        )
                      else
                        ...trips.map(
                          (trip) => _TripCard(
                            trip: trip,
                            shipName: widget.ship.name,
                            repository: widget.repository,
                            onChanged: _load,
                            onEdit: () => _editTrip(trip),
                          ),
                        ),
                    ],
                  );
                },
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
    );
    await _load();
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.shipName,
    required this.repository,
    required this.onChanged,
    required this.onEdit,
  });
  final TripRecord trip;
  final String shipName;
  final ShipsRepository repository;
  final Future<void> Function() onChanged;
  final VoidCallback onEdit;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final color = Theme.of(context).colorScheme.primary;
    final f = DateFormat.yMd(locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        color: trip.financials!.hasUnpricedPurchases
            ? _pendingPriceColor
            : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            foregroundColor: color,
            child: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          title: Text(f.format(trip.departureDate)),
          subtitle: Text(
            '${s.outcome}: ${_amount(trip.financials!.revenue, locale)}',
          ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TripDetailsScreen(
                  trip: trip,
                  shipName: shipName,
                  repository: repository,
                ),
              ),
            );
            await onChanged();
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MoneyText(
                trip.financials!.revenue,
                locale: locale,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'edit') {
                    onEdit();
                  } else {
                    try {
                      await repository.deleteTrip(trip.id);
                      await onChanged();
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(s.saveError)));
                      }
                    }
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'edit', child: Text(s.edit)),
                  PopupMenuItem(value: 'delete', child: Text(s.delete)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _amount(double value, String locale) => formatMru(value, locale);
}

class _TripTable extends StatelessWidget {
  const _TripTable({
    required this.trips,
    required this.shipName,
    required this.repository,
    required this.onChanged,
    required this.onEdit,
  });
  final List<TripRecord> trips;
  final String shipName;
  final ShipsRepository repository;
  final Future<void> Function() onChanged;
  final void Function(TripRecord) onEdit;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final f = DateFormat.yMd(locale);
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            s.date,
            s.outcome,
            s.actions,
          ].map((label) => DataColumn(label: Text(label))).toList(),
          rows: trips
              .map(
                (trip) => DataRow(
                  color: WidgetStatePropertyAll(
                    trip.financials!.hasUnpricedPurchases
                        ? _pendingPriceColor
                        : null,
                  ),
                  onSelectChanged: (_) async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TripDetailsScreen(
                          trip: trip,
                          shipName: shipName,
                          repository: repository,
                        ),
                      ),
                    );
                    await onChanged();
                  },
                  cells: [
                    DataCell(Text(f.format(trip.departureDate))),
                    DataCell(
                      MoneyText(trip.financials!.revenue, locale: locale),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: s.edit,
                            onPressed: () => onEdit(trip),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: s.delete,
                            onPressed: () async {
                              try {
                                await repository.deleteTrip(trip.id);
                                await onChanged();
                              } catch (_) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(s.saveError)),
                                  );
                                }
                              }
                            },
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

class _FinancialCards extends StatelessWidget {
  const _FinancialCards({required this.value});
  final Financials value;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final cards = [
      (
        s.outcome,
        value.revenue,
        Icons.shopping_basket_outlined,
        Theme.of(context).colorScheme.primary,
      ),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards
          .map(
            (item) => SizedBox(
              width: 220,
              child: MetricCard(
                label: item.$1,
                value: formatMru(item.$2, locale),
                icon: item.$3,
                accent: item.$4,
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
    required this.shipName,
    required this.repository,
    super.key,
  });
  final TripRecord trip;
  final String shipName;
  final ShipsRepository repository;
  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  List<TripTransaction> transactions = [];
  List<ClientOption> clients = [];
  Financials? financials;
  bool sharingPdf = false;
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
    return Scaffold(
      appBar: AppBar(
        title: Text(s.tripDetails),
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
              message: s.tripDetailsError,
              retryLabel: s.retry,
              onRetry: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _FinancialCards(value: financials!),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: () => _add('CLIENT_PURCHASE'),
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: Text(s.addClientPurchase),
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
                  const SizedBox(height: 18),
                  _TripLedgerSheet(
                    shipName: widget.shipName,
                    date: widget.trip.departureDate,
                    transactions: transactions,
                    onSetUnitPrice: _setUnitPrice,
                    onEdit: _editTransaction,
                    onDelete: _deleteTransaction,
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _add(String type) async {
    final input = await showDialog<_PurchaseBatchInput>(
      context: context,
      builder: (_) => _PurchaseOrderDialog(clients: clients),
    );
    if (input == null) return;
    for (final purchase in input.purchases) {
      var purchaseClientId = purchase.clientId;
      if (purchase.newClientName != null) {
        purchaseClientId = (await widget.repository.createClient(
          purchase.newClientName!,
        )).id;
      }
      for (final line in purchase.lines) {
        await widget.repository.addTransaction(
          type: type,
          shipId: widget.trip.shipId,
          tripId: widget.trip.id,
          amount: line.amount,
          date: widget.trip.departureDate,
          description: line.description,
          quantity: line.quantity,
          unitPrice: line.unitPrice,
          clientId: purchaseClientId,
        );
      }
    }
    await _load();
  }

  Future<void> _sharePdf() async {
    setState(() => sharingPdf = true);
    try {
      final language = Localizations.localeOf(context).languageCode;
      final bytes = await widget.repository.tripDetailsPdf(
        widget.trip.id,
        language,
      );
      final savedPath = await exportPdf(
        bytes: bytes,
        filename:
            '${widget.shipName}-${DateFormat('yyyy-MM-dd').format(widget.trip.departureDate)}.pdf',
        title: widget.shipName,
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

  Future<void> _setUnitPrice(TripTransaction transaction) async {
    final controller = TextEditingController();
    final s = AppLocalizations.of(context);
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(s.unitPrice),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: '${s.unitPrice} (MRU/kg)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(
                controller.text.replaceAll(',', '.'),
              );
              if (parsed != null && parsed > 0) {
                Navigator.pop(dialogContext, parsed);
              }
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await widget.repository.setPurchaseUnitPrice(transaction.id, value);
    await _load();
  }

  Future<void> _editTransaction(TripTransaction row) async {
    final input = await showDialog<_PurchaseRowEditInput>(
      context: context,
      builder: (_) => _PurchaseRowEditDialog(transaction: row),
    );
    if (input == null || !mounted) return;
    if (!await confirmLinkedTransactionChange(context, deleting: false)) {
      return;
    }
    await widget.repository.updatePurchase(
      row.id,
      quantity: input.quantity,
      unitPrice: input.unitPrice,
      description: input.description,
    );
    await _load();
  }

  Future<void> _deleteTransaction(TripTransaction row) async {
    if (!await confirmLinkedTransactionChange(context, deleting: true)) return;
    await widget.repository.deleteTransaction(row.id);
    await _load();
  }
}

class _PurchaseRowEditInput {
  const _PurchaseRowEditInput(this.description, this.quantity, this.unitPrice);
  final String description;
  final double quantity;
  final double unitPrice;
}

class _PurchaseRowEditDialog extends StatefulWidget {
  const _PurchaseRowEditDialog({required this.transaction});
  final TripTransaction transaction;

  @override
  State<_PurchaseRowEditDialog> createState() => _PurchaseRowEditDialogState();
}

class _PurchaseRowEditDialogState extends State<_PurchaseRowEditDialog> {
  late final description = TextEditingController(
    text: widget.transaction.description,
  );
  late final quantity = TextEditingController(
    text: widget.transaction.quantity?.toStringAsFixed(2),
  );
  late final unitPrice = TextEditingController(
    text: widget.transaction.unitPrice?.toStringAsFixed(2),
  );

  @override
  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(s.editTransaction),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: description,
            decoration: InputDecoration(labelText: s.species),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: s.quantity),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: unitPrice,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: s.unitPrice),
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
            final parsedQuantity = double.tryParse(
              quantity.text.replaceAll(',', '.'),
            );
            final parsedPrice = double.tryParse(
              unitPrice.text.replaceAll(',', '.'),
            );
            if (description.text.trim().isNotEmpty &&
                parsedQuantity != null &&
                parsedQuantity > 0 &&
                parsedPrice != null &&
                parsedPrice >= 0) {
              Navigator.pop(
                context,
                _PurchaseRowEditInput(
                  description.text.trim(),
                  parsedQuantity,
                  parsedPrice,
                ),
              );
            }
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _TripLedgerSheet extends StatelessWidget {
  const _TripLedgerSheet({
    required this.shipName,
    required this.date,
    required this.transactions,
    required this.onSetUnitPrice,
    required this.onEdit,
    required this.onDelete,
  });

  final String shipName;
  final DateTime date;
  final List<TripTransaction> transactions;
  final ValueChanged<TripTransaction> onSetUnitPrice;
  final ValueChanged<TripTransaction> onEdit;
  final ValueChanged<TripTransaction> onDelete;

  String _number(double value) {
    final fixed = value.toStringAsFixed(2);
    final compact = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    return compact.replaceAll('.', ',');
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

  TableRow _row(List<Widget> cells, {Color? color}) => TableRow(
    decoration: color == null ? null : BoxDecoration(color: color),
    children: cells,
  );

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final purchases = transactions
        .where((row) => row.type == 'CLIENT_PURCHASE')
        .toList();
    final purchaseGroups = <String, List<TripTransaction>>{};
    for (final purchase in purchases) {
      purchaseGroups
          .putIfAbsent(purchase.clientName ?? '—', () => [])
          .add(purchase);
    }
    final totalQuantity = purchases.fold<double>(
      0,
      (sum, row) => sum + (row.quantity ?? 0),
    );
    final totalRevenue = purchases.fold<double>(
      0,
      (sum, row) => sum + row.amount,
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
          ...purchaseGroups.entries.indexed.expand((indexed) {
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
                  color: row.unitPrice == null ? _pendingPriceColor : color,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.description,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            TransactionRowActions(
                              onEdit: () => onEdit(row),
                              onDelete: () => onDelete(row),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 16,
                          runSpacing: 6,
                          children: [
                            Text(
                              '${s.quantity}: ${_number(row.quantity ?? 0)}',
                            ),
                            row.unitPrice == null
                                ? TextButton.icon(
                                    onPressed: () => onSetUnitPrice(row),
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: Text(s.unitPrice),
                                  )
                                : Text(
                                    '${s.unitPrice}: ${_number(row.unitPrice!)}',
                                  ),
                            Text('${s.amount}: ${_number(row.amount)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          }),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: ListTile(
              title: Text(
                s.total,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text('${s.quantity}: ${_number(totalQuantity)}'),
              trailing: Text(
                _number(totalRevenue),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      );
    }
    const widths = <int, TableColumnWidth>{
      0: FixedColumnWidth(280),
      1: FixedColumnWidth(110),
      2: FixedColumnWidth(110),
      3: FixedColumnWidth(130),
    };
    final border = TableBorder.all(color: Theme.of(context).dividerColor);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 810,
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
                      _cell(s.unitPrice, bold: true),
                      _cell(s.amount, bold: true),
                    ]),
                  ],
                ),
                ...purchaseGroups.entries.indexed.map((indexed) {
                  final group = indexed.$2;
                  final color = palette[indexed.$1 % palette.length];
                  final subtotal = group.value.fold<double>(
                    0,
                    (sum, row) => sum + row.amount,
                  );
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 630,
                          child: Table(
                            border: border,
                            columnWidths: widths,
                            children: group.value
                                .map(
                                  (row) => _row(
                                    [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _cell(row.description),
                                          ),
                                          TransactionRowActions(
                                            onEdit: () => onEdit(row),
                                            onDelete: () => onDelete(row),
                                          ),
                                        ],
                                      ),
                                      _cell(_number(row.quantity ?? 0)),
                                      row.unitPrice == null
                                          ? TextButton.icon(
                                              onPressed: () =>
                                                  onSetUnitPrice(row),
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 16,
                                              ),
                                              label: Text(s.unitPrice),
                                            )
                                          : _cell(_number(row.unitPrice!)),
                                      _cell(
                                        _number(row.amount),
                                        align: TextAlign.end,
                                      ),
                                    ],
                                    color: row.unitPrice == null
                                        ? _pendingPriceColor
                                        : color,
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 150,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  group.key,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _number(subtotal),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                SizedBox(
                  width: 530,
                  child: Table(
                    border: border,
                    columnWidths: widths,
                    children: [
                      _row([
                        _cell(s.total, bold: true),
                        _cell(_number(totalQuantity), bold: true),
                        _cell(''),
                        _cell(
                          _number(totalRevenue),
                          bold: true,
                          align: TextAlign.end,
                        ),
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

class _ShipInput {
  const _ShipInput({
    required this.name,
    this.ownerId,
    this.newOwnerName,
    this.newOwnerPhone = '',
  });
  final String name;
  final String? ownerId;
  final String? newOwnerName;
  final String newOwnerPhone;
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
  final newOwnerName = TextEditingController();
  final newOwnerPhone = TextEditingController();
  String? ownerId;
  bool createOwner = false;
  String? error;
  @override
  void initState() {
    super.initState();
    ownerId =
        widget.ship?.ownerId ??
        (widget.owners.isEmpty ? null : widget.owners.first.id);
    createOwner = widget.ship == null && widget.owners.isEmpty;
  }

  @override
  void dispose() {
    name.dispose();
    newOwnerName.dispose();
    newOwnerPhone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AppDialogShell(
      title: widget.ship == null ? s.addShip : s.editShip,
      icon: Icons.directions_boat_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: InputDecoration(labelText: s.shipName),
          ),
          const SizedBox(height: 12),
          if (!createOwner)
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
            )
          else ...[
            TextField(
              controller: newOwnerName,
              decoration: InputDecoration(labelText: s.name),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newOwnerPhone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: s.phone),
            ),
          ],
          if (widget.ship == null) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: widget.owners.isEmpty && createOwner
                    ? null
                    : () => setState(() {
                        createOwner = !createOwner;
                        error = null;
                      }),
                icon: Icon(
                  createOwner ? Icons.list_alt_outlined : Icons.person_add,
                ),
                label: Text(createOwner ? s.owners : s.addOwner),
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
            if (name.text.trim().isEmpty ||
                (!createOwner && ownerId == null) ||
                (createOwner && newOwnerName.text.trim().isEmpty)) {
              setState(() => error = s.requiredFields);
              return;
            }
            Navigator.pop(
              context,
              _ShipInput(
                name: name.text.trim(),
                ownerId: createOwner ? null : ownerId,
                newOwnerName: createOwner ? newOwnerName.text.trim() : null,
                newOwnerPhone: createOwner ? newOwnerPhone.text.trim() : '',
              ),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _TripInput {
  const _TripInput(this.departure);
  final DateTime departure;
}

class _TripDialog extends StatefulWidget {
  const _TripDialog({this.trip});
  final TripRecord? trip;
  @override
  State<_TripDialog> createState() => _TripDialogState();
}

class _TripDialogState extends State<_TripDialog> {
  late DateTime departure = widget.trip?.departureDate ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AppDialogShell(
      title: widget.trip == null ? s.addTrip : s.editTrip,
      icon: Icons.map_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppDateField(
            label: s.date,
            value: departure,
            onChanged: (value) => setState(() => departure = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _TripInput(departure)),
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _TransactionInput {
  const _TransactionInput(this.lines, this.clientId, this.newClientName);
  final List<_TransactionLineInput> lines;
  final String? clientId;
  final String? newClientName;
}

class _TransactionLineInput {
  const _TransactionLineInput(
    this.description,
    this.amount, {
    this.quantity,
    this.unitPrice,
    this.clientId,
  });
  final String description;
  final double amount;
  final double? quantity;
  final double? unitPrice;
  final String? clientId;
}

class _TransactionLineDraft {
  _TransactionLineDraft({this.clientId});
  String? clientId;
  final description = TextEditingController();
  final amount = TextEditingController();
  final quantity = TextEditingController();
  final unitPrice = TextEditingController();

  void dispose() {
    description.dispose();
    amount.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}

class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({required this.type, required this.clients});
  final String type;
  final List<ClientOption> clients;
  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  late final List<_TransactionLineDraft> lines;
  final newClientName = TextEditingController();
  String? clientId;
  String? error;
  bool addingClient = false;
  @override
  void initState() {
    super.initState();
    if (widget.clients.isNotEmpty) clientId = widget.clients.first.id;
    lines = [_TransactionLineDraft(clientId: clientId)];
  }

  @override
  void dispose() {
    for (final line in lines) {
      line.dispose();
    }
    newClientName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final purchase = widget.type == 'CLIENT_PURCHASE';
    return AppDialogShell(
      title: _title(s),
      icon: purchase ? Icons.shopping_cart_outlined : Icons.payments_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (purchase) ...[
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(() => addingClient = !addingClient),
                icon: Icon(
                  addingClient ? Icons.close : Icons.person_add_outlined,
                ),
                label: Text(addingClient ? s.cancel : s.addClient),
              ),
            ),
            if (addingClient)
              TextField(
                controller: newClientName,
                decoration: InputDecoration(labelText: s.name),
              ),
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 12),
          ...lines.indexed.map((item) => _lineFields(s, item.$1, item.$2)),
          if (purchase)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed: () => setState(
                  () => lines.add(_TransactionLineDraft(clientId: clientId)),
                ),
                icon: const Icon(Icons.add),
                label: Text(s.addPurchaseLine),
              ),
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
            final newNameMissing =
                purchase && addingClient && newClientName.text.trim().isEmpty;
            final values = <_TransactionLineInput>[];
            for (final line in lines) {
              final description = line.description.text.trim();
              final quantity = purchase
                  ? double.tryParse(line.quantity.text.replaceAll(',', '.'))
                  : null;
              final unitPrice = purchase
                  ? double.tryParse(line.unitPrice.text.replaceAll(',', '.'))
                  : null;
              final amount = purchase
                  ? (quantity == null || unitPrice == null
                        ? null
                        : quantity * unitPrice)
                  : double.tryParse(line.amount.text.replaceAll(',', '.'));
              if (amount == null ||
                  amount <= 0 ||
                  description.isEmpty ||
                  (purchase && !addingClient && line.clientId == null)) {
                setState(() => error = s.validAmountRequired);
                return;
              }
              values.add(
                _TransactionLineInput(
                  description,
                  amount,
                  quantity: quantity,
                  unitPrice: unitPrice,
                  clientId: line.clientId,
                ),
              );
            }
            if (newNameMissing) {
              setState(() => error = s.validAmountRequired);
              return;
            }
            Navigator.pop(
              context,
              _TransactionInput(
                values,
                null,
                purchase && addingClient ? newClientName.text.trim() : null,
              ),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }

  Widget _lineFields(
    AppLocalizations s,
    int index,
    _TransactionLineDraft line,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      children: [
        if (widget.type == 'CLIENT_PURCHASE')
          DropdownButtonFormField<String>(
            initialValue: line.clientId,
            decoration: InputDecoration(labelText: s.client),
            items: widget.clients
                .map(
                  (client) => DropdownMenuItem(
                    value: client.id,
                    child: Text(client.name),
                  ),
                )
                .toList(),
            onChanged: addingClient ? null : (value) => line.clientId = value,
          ),
        if (widget.type == 'CLIENT_PURCHASE') const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: line.description,
                decoration: InputDecoration(labelText: s.description),
              ),
            ),
            const SizedBox(width: 8),
            if (widget.type == 'CLIENT_PURCHASE') ...[
              Expanded(
                child: TextField(
                  controller: line.quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: s.quantity),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: line.unitPrice,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: s.unitPrice),
                ),
              ),
            ] else
              Expanded(
                child: TextField(
                  controller: line.amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: s.amountMru),
                ),
              ),
            if (lines.length > 1)
              IconButton(
                onPressed: () {
                  final removed = lines.removeAt(index);
                  removed.dispose();
                  setState(() {});
                },
                icon: const Icon(Icons.remove_circle_outline),
              ),
          ],
        ),
        if (widget.type == 'CLIENT_PURCHASE') const Divider(height: 24),
      ],
    ),
  );

  String _title(AppLocalizations s) => switch (widget.type) {
    'SHIP_REVENUE' => s.addRevenue,
    'SHIP_EXPENSE' => s.addExpense,
    _ => s.addClientPurchase,
  };
}

class _PurchaseBatchInput {
  const _PurchaseBatchInput(this.purchases);
  final List<_ClientPurchaseInput> purchases;
}

class _ClientPurchaseInput {
  const _ClientPurchaseInput({
    required this.lines,
    this.clientId,
    this.newClientName,
  });
  final String? clientId;
  final String? newClientName;
  final List<_TransactionLineInput> lines;
}

class _PurchaseOrderDialog extends StatefulWidget {
  const _PurchaseOrderDialog({required this.clients});
  final List<ClientOption> clients;

  @override
  State<_PurchaseOrderDialog> createState() => _PurchaseOrderDialogState();
}

class _PurchaseOrderDialogState extends State<_PurchaseOrderDialog> {
  final completed = <_ClientPurchaseInput>[];
  final newClientName = TextEditingController();
  final lines = <_TransactionLineDraft>[_TransactionLineDraft()];
  String? clientId;
  String? error;
  bool addingClient = false;

  @override
  void initState() {
    super.initState();
    clientId = widget.clients.isEmpty ? null : widget.clients.first.id;
  }

  @override
  void dispose() {
    for (final line in lines) {
      line.dispose();
    }
    newClientName.dispose();
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
            onChanged: addingClient
                ? null
                : (value) => setState(() => clientId = value),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => setState(() {
                addingClient = !addingClient;
                error = null;
              }),
              icon: Icon(
                addingClient ? Icons.close : Icons.person_add_outlined,
              ),
              label: Text(addingClient ? s.cancel : s.addClient),
            ),
          ),
          if (addingClient)
            TextField(
              controller: newClientName,
              decoration: InputDecoration(labelText: s.name),
            ),
          const SizedBox(height: 12),
          ...lines.indexed.map((entry) => _itemRow(s, entry.$1, entry.$2)),
          TextButton.icon(
            onPressed: () => setState(() => lines.add(_TransactionLineDraft())),
            icon: const Icon(Icons.add),
            label: Text(s.addPurchaseLine),
          ),
          const Divider(height: 24),
          OutlinedButton.icon(
            onPressed: _addAnotherPurchase,
            icon: const Icon(Icons.add_shopping_cart_outlined),
            label: Text(arabic ? 'إضافة شراء آخر' : 'Ajouter un autre achat'),
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
        FilledButton(onPressed: _saveAll, child: Text(s.save)),
      ],
    );
  }

  Widget _itemRow(AppLocalizations s, int index, _TransactionLineDraft line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: line.description,
              decoration: InputDecoration(labelText: s.description),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: line.quantity,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: '${s.quantity} (kg)'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: line.unitPrice,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(labelText: '${s.unitPrice} (MRU/kg)'),
            ),
          ),
          if (lines.length > 1)
            IconButton(
              onPressed: () => setState(() {
                final removed = lines.removeAt(index);
                removed.dispose();
              }),
              icon: const Icon(Icons.remove_circle_outline),
            ),
        ],
      ),
    );
  }

  _ClientPurchaseInput? _readCurrent() {
    final s = AppLocalizations.of(context);
    final name = newClientName.text.trim();
    if ((!addingClient && clientId == null) || (addingClient && name.isEmpty)) {
      setState(() => error = s.validAmountRequired);
      return null;
    }
    final values = <_TransactionLineInput>[];
    for (final line in lines) {
      final description = line.description.text.trim();
      final quantity = double.tryParse(line.quantity.text.replaceAll(',', '.'));
      final unitPrice = double.tryParse(
        line.unitPrice.text.replaceAll(',', '.'),
      );
      if (description.isEmpty ||
          quantity == null ||
          quantity <= 0 ||
          unitPrice == null ||
          unitPrice <= 0) {
        setState(() => error = s.validAmountRequired);
        return null;
      }
      values.add(
        _TransactionLineInput(
          description,
          quantity * unitPrice,
          quantity: quantity,
          unitPrice: unitPrice,
        ),
      );
    }
    return _ClientPurchaseInput(
      clientId: addingClient ? null : clientId,
      newClientName: addingClient ? name : null,
      lines: values,
    );
  }

  void _addAnotherPurchase() {
    final purchase = _readCurrent();
    if (purchase == null) return;
    setState(() {
      completed.add(purchase);
      for (final line in lines) {
        line.dispose();
      }
      lines
        ..clear()
        ..add(_TransactionLineDraft());
      clientId = widget.clients.isEmpty ? null : widget.clients.first.id;
      addingClient = false;
      newClientName.clear();
      error = null;
    });
  }

  void _goToPreviousPurchase() {
    if (completed.isEmpty) return;
    final previous = completed.removeLast();
    for (final line in lines) {
      line.dispose();
    }
    lines.clear();
    for (final value in previous.lines) {
      final draft = _TransactionLineDraft();
      draft.description.text = value.description;
      draft.quantity.text = _editableNumber(value.quantity!);
      draft.unitPrice.text = _editableNumber(value.unitPrice!);
      lines.add(draft);
    }
    clientId = previous.clientId;
    addingClient = previous.newClientName != null;
    newClientName.text = previous.newClientName ?? '';
    error = null;
    setState(() {});
  }

  String _editableNumber(double value) =>
      value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  void _saveAll() {
    final purchase = _readCurrent();
    if (purchase == null) return;
    Navigator.pop(context, _PurchaseBatchInput([...completed, purchase]));
  }
}
