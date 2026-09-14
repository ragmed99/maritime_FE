import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/formatters/money_formatter.dart';
import '../application/partners_controller.dart';
import '../data/partners_repository.dart';
import '../domain/partner_models.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({required this.controller, super.key});

  final PartnersController controller;

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.status == PartnersStatus.idle) {
      widget.controller.load();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final s = AppLocalizations.of(context);
      if (widget.controller.status == PartnersStatus.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (widget.controller.status == PartnersStatus.error) {
        return _StateMessage(
          message: s.partnersLoadError,
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
                      s.partners,
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
                    onPressed: _edit,
                    icon: const Icon(Icons.add),
                    label: Text(s.addPartner),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              TextField(
                onChanged: widget.controller.search,
                decoration: InputDecoration(
                  labelText: s.searchPartners,
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 18),
              if (rows.isEmpty)
                _StateMessage(
                  message: widget.controller.query.isEmpty
                      ? s.noPartners
                      : s.noPartnerSearchResults,
                )
              else if (constraints.maxWidth >= 900)
                _PartnerTable(
                  rows: rows,
                  onOpen: _open,
                  onEdit: _edit,
                  onDelete: _delete,
                )
              else
                ...rows.map(
                  (partner) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.handshake_outlined),
                        ),
                        title: Text(partner.name),
                        subtitle: Text(partner.phone),
                        onTap: () => _open(partner),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) => value == 'edit'
                              ? _edit(partner)
                              : _delete(partner),
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

  void _open(PartnerRecord partner) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PartnerDetailsScreen(
        partner: partner,
        repository: widget.controller.repository,
      ),
    ),
  );

  Future<void> _edit([PartnerRecord? partner]) async {
    final input = await showDialog<_PartnerInput>(
      context: context,
      builder: (_) => _PartnerDialog(partner: partner),
    );
    if (input == null) return;
    try {
      await widget.controller.save(
        partner: partner,
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

  Future<void> _delete(PartnerRecord partner) async {
    final s = AppLocalizations.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(s.deletePartner),
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
        await widget.controller.delete(partner.id);
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

class _PartnerTable extends StatelessWidget {
  const _PartnerTable({
    required this.rows,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PartnerRecord> rows;
  final void Function(PartnerRecord) onOpen;
  final void Function([PartnerRecord?]) onEdit;
  final void Function(PartnerRecord) onDelete;

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
                (partner) => DataRow(
                  onSelectChanged: (_) => onOpen(partner),
                  cells: [
                    DataCell(Text(partner.name)),
                    DataCell(Text(partner.phone)),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => onEdit(partner),
                            tooltip: s.edit,
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            onPressed: () => onDelete(partner),
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

class PartnerDetailsScreen extends StatefulWidget {
  const PartnerDetailsScreen({
    required this.partner,
    required this.repository,
    super.key,
  });

  final PartnerRecord partner;
  final PartnersRepository repository;

  @override
  State<PartnerDetailsScreen> createState() => _PartnerDetailsScreenState();
}

class _PartnerDetailsScreenState extends State<PartnerDetailsScreen> {
  double balance = 0;
  List<PartnerTransaction> transactions = [];
  DateTime? startDate;
  DateTime? endDate;
  bool loading = true;
  bool failed = false;

  List<PartnerTransaction> get visibleTransactions => transactions.where((row) {
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
        widget.repository.balance(widget.partner.id),
        widget.repository.transactions(widget.partner.id),
      ]);
      balance = values[0] as double;
      transactions = values[1] as List<PartnerTransaction>;
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
        title: Text(widget.partner.name),
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
              message: s.partnerDetailsError,
              action: s.retry,
              onTap: _load,
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
                        child: Wrap(
                          spacing: 30,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: 280,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.partner.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                  if (widget.partner.phone.isNotEmpty)
                                    Text('${s.phone}: ${widget.partner.phone}'),
                                ],
                              ),
                            ),
                            PartnerBalance(value: balance),
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
                          onPressed: () => _add('PARTNER_LOAN_RECEIVED'),
                          icon: const Icon(Icons.south_west),
                          label: Text(s.borrowFromPartner),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () => _add('PARTNER_LOAN_GIVEN'),
                          icon: const Icon(Icons.north_east),
                          label: Text(s.lendToPartner),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _add('PARTNER_REPAYMENT_PAID'),
                          icon: const Icon(Icons.reply),
                          label: Text(s.repayPartner),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _add('PARTNER_REPAYMENT_RECEIVED'),
                          icon: const Icon(Icons.call_received),
                          label: Text(s.receiveRepayment),
                        ),
                        OutlinedButton.icon(
                          onPressed: _filter,
                          icon: const Icon(Icons.date_range_outlined),
                          label: Text(s.filters),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      s.partnerTransactions,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    if (visibleTransactions.isEmpty)
                      _StateMessage(message: s.noPartnerTransactions)
                    else
                      _Transactions(
                        rows: visibleTransactions,
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

  Future<void> _add(String type) async {
    final input = await showDialog<_TransactionInput>(
      context: context,
      builder: (_) => _TransactionDialog(type: type),
    );
    if (input == null) return;
    try {
      await widget.repository.addTransaction(
        partnerId: widget.partner.id,
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

class PartnerBalance extends StatelessWidget {
  const PartnerBalance({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final color = value > 0
        ? Colors.red.shade700
        : value < 0
        ? Colors.green.shade700
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final label = value > 0
        ? s.partnerOwesUs
        : value < 0
        ? s.weOwePartner
        : s.balanced;
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.currentBalance),
          Text(
            formatMru(
              value.abs(),
              Localizations.localeOf(context).toLanguageTag(),
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: TextStyle(color: color)),
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

  final List<PartnerTransaction> rows;
  final bool desktop;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    String label(String type) => switch (type) {
      'PARTNER_LOAN_RECEIVED' => s.loanReceived,
      'PARTNER_LOAN_GIVEN' => s.loanGiven,
      'PARTNER_REPAYMENT_PAID' => s.repaymentPaid,
      _ => s.repaymentReceived,
    };
    String when(PartnerTransaction row) =>
        '${DateFormat.yMd(locale).format(row.date)} ${DateFormat.Hm(locale).format(row.time.toLocal())}';
    if (!desktop) {
      return Column(
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  child: ListTile(
                    title: Text(label(row.type)),
                    subtitle: Text(
                      '${when(row)}${row.description.isEmpty ? '' : '\n${row.description}'}${row.recordedBy == null ? '' : '\n${s.recordedBy}: ${row.recordedBy}'}',
                    ),
                    trailing: Text(formatMru(row.amount, locale)),
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
            s.dateTime,
            s.transactionType,
            s.description,
            s.recordedBy,
            s.amountMru,
          ].map((text) => DataColumn(label: Text(text))).toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(Text(when(row))),
                    DataCell(Text(label(row.type))),
                    DataCell(Text(row.description)),
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

class _PartnerInput {
  const _PartnerInput(this.name, this.phone);
  final String name;
  final String phone;
}

class _PartnerDialog extends StatefulWidget {
  const _PartnerDialog({this.partner});
  final PartnerRecord? partner;

  @override
  State<_PartnerDialog> createState() => _PartnerDialogState();
}

class _PartnerDialogState extends State<_PartnerDialog> {
  late final name = TextEditingController(text: widget.partner?.name);
  late final phone = TextEditingController(text: widget.partner?.phone);
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
      title: Text(widget.partner == null ? s.addPartner : s.editPartner),
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
              setState(() => error = s.partnerValidationError);
              return;
            }
            Navigator.pop(
              context,
              _PartnerInput(name.text.trim(), phone.text.trim()),
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
  DateTime date = DateTime.now();
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    final title = switch (widget.type) {
      'PARTNER_LOAN_RECEIVED' => s.borrowFromPartner,
      'PARTNER_LOAN_GIVEN' => s.lendToPartner,
      'PARTNER_REPAYMENT_PAID' => s.repayPartner,
      _ => s.receiveRepayment,
    };
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
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
                final selected = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  initialDate: date,
                );
                if (selected != null) setState(() => date = selected);
              },
            ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
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
            if (value == null || value <= 0) {
              setState(() => error = s.validAmountRequired);
              return;
            }
            Navigator.pop(
              context,
              _TransactionInput(value, date, description.text.trim()),
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
    final locale = Localizations.localeOf(context).toLanguageTag();
    return AlertDialog(
      title: Text(s.filters),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DateTile(
              label: s.startDate,
              value: start,
              locale: locale,
              onChanged: (value) => setState(() => start = value),
            ),
            _DateTile(
              label: s.endDate,
              value: end,
              locale: locale,
              onChanged: (value) => setState(() => end = value),
            ),
          ],
        ),
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

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.value,
    required this.locale,
    required this.onChanged,
  });
  final String label;
  final DateTime? value;
  final String locale;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: Text(
      value == null
          ? AppLocalizations.of(context).allDates
          : DateFormat.yMd(locale).format(value!),
    ),
    trailing: const Icon(Icons.calendar_today),
    onTap: () async {
      final selected = await showDatePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        initialDate: value ?? DateTime.now(),
      );
      if (selected != null) onChanged(selected);
    },
  );
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, this.action, this.onTap});
  final String message;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (action != null && onTap != null) ...[
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onTap, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
