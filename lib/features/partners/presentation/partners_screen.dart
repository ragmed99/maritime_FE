import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../../../core/formatters/money_formatter.dart';
import '../../../core/files/pdf_export.dart';
import '../../../core/models/account_position.dart';
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
import '../../../core/widgets/transaction_row_actions.dart'
    show TransactionRowActions, confirmLinkedTransactionChange;
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
        return AppStateView.loading();
      }
      if (widget.controller.status == PartnersStatus.error) {
        return AppStateView.error(
          message: s.partnersLoadError,
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
                title: s.partners,
                onRefresh: widget.controller.load,
                refreshTooltip: s.refresh,
                onAdd: _edit,
                addLabel: s.addPartner,
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
                AppStateView.empty(
                  message: widget.controller.query.isEmpty
                      ? s.noPartners
                      : s.noPartnerSearchResults,
                  icon: Icons.handshake_outlined,
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
                        leading: InitialsAvatar(
                          partner.name,
                          icon: Icons.handshake_outlined,
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

  Future<void> _open(PartnerRecord partner) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PartnerDetailsScreen(
          partner: partner,
          repository: widget.controller.repository,
        ),
      ),
    );
    await widget.controller.load();
  }

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
      builder: (_) => AppDialogShell(
        title: s.deletePartner,
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
  AccountPosition balance = const AccountPosition(
    theyOweUs: 0,
    weOweThem: 0,
    balance: 0,
  );
  List<PartnerTransaction> transactions = [];
  DateTime? startDate;
  DateTime? endDate;
  bool loading = true;
  bool failed = false;
  bool sharingPdf = false;

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
      balance = values[0] as AccountPosition;
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
              message: s.partnerDetailsError,
              retryLabel: s.retry,
              onRetry: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: LayoutBuilder(
                builder: (context, _) => ListView(
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
                        FilledButton.tonalIcon(
                          onPressed: () => _add('PARTNER_LOAN_GIVEN'),
                          icon: const Icon(Icons.remove_circle_outline),
                          label: Text(_partnerText(context, 'Débit', 'مدين')),
                        ),
                        FilledButton.icon(
                          onPressed: () => _add('PARTNER_LOAN_RECEIVED'),
                          icon: const Icon(Icons.add_circle_outline),
                          label: Text(_partnerText(context, 'Crédit', 'دائن')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _add('PARTNER_SHARE'),
                          icon: const Icon(Icons.percent),
                          label: Text(
                            _partnerText(
                              context,
                              'Pourcentage de part',
                              'نسبة الشراكة',
                            ),
                          ),
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
                          label: Text(
                            _partnerText(context, 'Générer PDF', 'إنشاء PDF'),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _filter,
                          icon: const Icon(Icons.date_range_outlined),
                          label: Text(s.filters),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SectionHeader(s.partnerTransactions),
                    const SizedBox(height: 12),
                    if (visibleTransactions.isEmpty)
                      AppStateView.empty(
                        message: s.noPartnerTransactions,
                        icon: Icons.receipt_long_outlined,
                      )
                    else
                      _Transactions(
                        rows: visibleTransactions,
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
        widget.partner.id,
        startDate: startDate,
        endDate: endDate,
      );
      final savedPath = await exportPdf(
        bytes: bytes,
        filename: 'partner-${widget.partner.name}.pdf',
        title: widget.partner.name,
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
        partnerId: widget.partner.id,
        // A calculated share is a credit on the partner's account.
        type: type == 'PARTNER_SHARE' ? 'PARTNER_LOAN_RECEIVED' : type,
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

  Future<void> _editTransaction(PartnerTransaction row) async {
    final input = await showDialog<_TransactionInput>(
      context: context,
      builder: (_) => _TransactionDialog(type: row.type, transaction: row),
    );
    if (input == null || !mounted) return;
    if (!await confirmLinkedTransactionChange(context, deleting: false)) {
      return;
    }
    try {
      await widget.repository.updateTransaction(
        id: row.id,
        amount: input.amount,
        date: row.date,
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

  Future<void> _deleteTransaction(PartnerTransaction row) async {
    final s = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteTransaction),
        content: Text(
          '${s.deleteTransactionConfirmation}\n\nCette action modifiera également les comptes liés.',
        ),
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
    if (confirmed != true) return;
    try {
      await widget.repository.deleteTransaction(row.id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).transactionDeleteError),
          ),
        );
      }
    }
  }
}

class PartnerBalance extends StatelessWidget {
  const PartnerBalance({required this.value, super.key});

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
        ? _partnerText(context, 'Débit', 'مدين')
        : value.weOweThem > 0
        ? _partnerText(context, 'Crédit', 'دائن')
        : s.balanced;
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            children: [
              Text('${_partnerText(context, 'Débit', 'مدين')}: '),
              MoneyText(
                value.theyOweUs,
                locale: locale,
                style: TextStyle(color: money.negative),
              ),
            ],
          ),
          Wrap(
            children: [
              Text('${_partnerText(context, 'Crédit', 'دائن')}: '),
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

class _Transactions extends StatelessWidget {
  const _Transactions({
    required this.rows,
    required this.locale,
    required this.onEdit,
    required this.onDelete,
  });

  final List<PartnerTransaction> rows;
  final String locale;
  final ValueChanged<PartnerTransaction> onEdit;
  final ValueChanged<PartnerTransaction> onDelete;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final money = context.moneyColors;
    String label(String type) => switch (type) {
      'PARTNER_LOAN_RECEIVED' ||
      'PARTNER_REPAYMENT_RECEIVED' => _partnerText(context, 'Crédit', 'دائن'),
      _ => _partnerText(context, 'Débit', 'مدين'),
    };
    bool isCredit(String type) =>
        type == 'PARTNER_LOAN_RECEIVED' || type == 'PARTNER_REPAYMENT_RECEIVED';
    Color tint(String type) => switch (type) {
      'PARTNER_LOAN_RECEIVED' || 'PARTNER_REPAYMENT_RECEIVED' => money.positive,
      _ => money.negative,
    };
    final credit = rows
        .where((row) => isCredit(row.type))
        .fold<double>(0, (sum, row) => sum + row.amount);
    final debit = rows
        .where((row) => !isCredit(row.type))
        .fold<double>(0, (sum, row) => sum + row.amount);
    final signedTotal = credit - debit;
    final total = signedTotal.abs();
    final totalColor = signedTotal > 0
        ? money.positive
        : signedTotal < 0
        ? money.negative
        : money.neutral;

    if (MediaQuery.sizeOf(context).width < 700) {
      return Column(
        children: [
          ...rows.map(
            (row) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  row.description.isEmpty ? label(row.type) : row.description,
                ),
                subtitle: MoneyText(
                  row.amount,
                  locale: locale,
                  style: TextStyle(
                    color: tint(row.type),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: TransactionRowActions(
                  onEdit: () => onEdit(row),
                  onDelete: () => onDelete(row),
                ),
              ),
            ),
          ),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            child: ListTile(
              title: Text(
                s.total,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              trailing: MoneyText(
                total,
                locale: locale,
                style: TextStyle(
                  color: totalColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 720,
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
            children: [
              _partnerRow(
                context,
                description: s.description,
                amount: s.amount,
                actions: const SizedBox.shrink(),
                bold: true,
                background: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              ...rows.map(
                (row) => _partnerRow(
                  context,
                  description: row.description.isEmpty
                      ? label(row.type)
                      : row.description,
                  amount: formatMru(row.amount, locale),
                  amountColor: tint(row.type),
                  actions: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: s.edit,
                        onPressed: () => onEdit(row),
                        icon: const Icon(Icons.edit_outlined, size: 20),
                      ),
                      IconButton(
                        tooltip: s.delete,
                        onPressed: () => onDelete(row),
                        icon: const Icon(Icons.delete_outline, size: 20),
                      ),
                    ],
                  ),
                ),
              ),
              _partnerRow(
                context,
                description: s.total,
                amount: formatMru(total, locale),
                actions: const SizedBox.shrink(),
                bold: true,
                amountColor: totalColor,
                background: Theme.of(context).colorScheme.surfaceContainerHigh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _partnerRow(
    BuildContext context, {
    required String description,
    required String amount,
    required Widget actions,
    bool bold = false,
    Color? amountColor,
    Color? background,
  }) => TableRow(
    decoration: background == null ? null : BoxDecoration(color: background),
    children: [
      _partnerCell(description, bold: bold),
      _partnerCell(amount, bold: bold, color: amountColor),
      actions,
    ],
  );

  Widget _partnerCell(String value, {bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      );
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
    return AppDialogShell(
      title: widget.partner == null ? s.addPartner : s.editPartner,
      icon: Icons.handshake_outlined,
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
  const _TransactionDialog({required this.type, this.transaction});
  final String type;
  final PartnerTransaction? transaction;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  late final amount = TextEditingController(
    text: widget.transaction?.amount.toStringAsFixed(2),
  );
  final percentage = TextEditingController();
  late final description = TextEditingController(
    text: widget.transaction?.description,
  );
  String? error;

  @override
  void dispose() {
    amount.dispose();
    percentage.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final isShare = widget.type == 'PARTNER_SHARE';
    final title = widget.type == 'PARTNER_LOAN_RECEIVED'
        ? _partnerText(context, 'Crédit', 'دائن')
        : widget.type == 'PARTNER_LOAN_GIVEN'
        ? _partnerText(context, 'Débit', 'مدين')
        : _partnerText(context, 'Pourcentage de part', 'نسبة الشراكة');
    return AppDialogShell(
      title: title,
      icon: Icons.payments_outlined,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amount,
            decoration: InputDecoration(
              labelText: isShare
                  ? _partnerText(
                      context,
                      'Montant de base (MRU)',
                      'المبلغ الأساسي (MRU)',
                    )
                  : s.amountMru,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          if (isShare) ...[
            const SizedBox(height: 10),
            TextField(
              controller: percentage,
              decoration: InputDecoration(
                labelText: _partnerText(
                  context,
                  'Pourcentage (%)',
                  'النسبة (%)',
                ),
                suffixText: '%',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: description,
            decoration: InputDecoration(
              labelText: _partnerText(
                context,
                'Description (facultative)',
                'الوصف (اختياري)',
              ),
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
            final baseValue = double.tryParse(amount.text.replaceAll(',', '.'));
            final percentValue = double.tryParse(
              percentage.text.replaceAll(',', '.'),
            );
            final value = isShare && baseValue != null && percentValue != null
                ? baseValue * percentValue / 100
                : baseValue;
            if (baseValue == null ||
                baseValue <= 0 ||
                value == null ||
                value <= 0 ||
                (isShare &&
                    (percentValue == null ||
                        percentValue <= 0 ||
                        percentValue > 100))) {
              setState(() => error = s.validAmountRequired);
              return;
            }
            final calculation = isShare
                ? '${_partnerText(context, 'Part', 'حصة')} ${percentValue!.toStringAsFixed(2)}% × ${baseValue.toStringAsFixed(2)} MRU'
                : '';
            final note = description.text.trim();
            final savedDescription = isShare
                ? '$calculation${note.isEmpty ? '' : ' — $note'}'
                : note;
            Navigator.pop(
              context,
              _TransactionInput(value, DateTime.now(), savedDescription),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

String _partnerText(BuildContext context, String french, String arabic) =>
    Localizations.localeOf(context).languageCode == 'ar' ? arabic : french;

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
