import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../data/administration_repository.dart';
import '../domain/administration_models.dart';

class AdministrationScreen extends StatelessWidget {
  const AdministrationScreen({
    required this.repository,
    required this.isAdmin,
    super.key,
  });
  final AdministrationRepository repository;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          s.administration,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            if (isAdmin)
              _AdminCard(
                icon: Icons.manage_accounts_outlined,
                title: s.userManagement,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UsersScreen(repository: repository),
                  ),
                ),
              ),
            _AdminCard(
              icon: Icons.history_outlined,
              title: s.auditLogs,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AuditLogsScreen(repository: repository),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 360,
    height: 120,
    child: Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 36),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    ),
  );
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({required this.repository, super.key});
  final AdministrationRepository repository;
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<ManagedUser> users = [];
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
      users = await widget.repository.users();
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
        title: Text(s.userManagement),
        actions: [
          IconButton(
            onPressed: _load,
            tooltip: s.refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.person_add_outlined),
        label: Text(s.createUser),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : failed
          ? _StateMessage(
              message: s.usersLoadError,
              action: s.retry,
              onTap: _load,
            )
          : users.isEmpty
          ? _StateMessage(message: s.noUsers)
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 850) {
                  return ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Card(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns:
                                [
                                      s.username,
                                      s.phone,
                                      s.role,
                                      s.status,
                                      s.actions,
                                    ]
                                    .map(
                                      (label) => DataColumn(label: Text(label)),
                                    )
                                    .toList(),
                            rows: users
                                .map(
                                  (user) => DataRow(
                                    cells: [
                                      DataCell(Text(user.username)),
                                      DataCell(Text(user.phone)),
                                      DataCell(
                                        Text(
                                          user.isStaff
                                              ? s.administrator
                                              : s.normalUser,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          user.isActive ? s.active : s.inactive,
                                        ),
                                      ),
                                      DataCell(
                                        _UserActions(
                                          user: user,
                                          onStatus: () => _status(user),
                                          onPassword: () => _password(user),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: users
                        .map(
                          (user) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Text(
                                    user.username.characters.first
                                        .toUpperCase(),
                                  ),
                                ),
                                title: Text(user.username),
                                subtitle: Text(
                                  '${user.phone}\n${user.isStaff ? s.administrator : s.normalUser} · ${user.isActive ? s.active : s.inactive}',
                                ),
                                isThreeLine: true,
                                trailing: _UserActions(
                                  user: user,
                                  onStatus: () => _status(user),
                                  onPassword: () => _password(user),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _create() async {
    final value = await showDialog<_UserInput>(
      context: context,
      builder: (_) => const _UserDialog(),
    );
    if (value == null) return;
    try {
      await widget.repository.createUser(
        username: value.username,
        password: value.password,
        phone: value.phone,
      );
      await _load();
    } catch (_) {
      if (mounted) _message(AppLocalizations.of(context).userSaveError);
    }
  }

  Future<void> _status(ManagedUser user) async {
    try {
      await widget.repository.setActive(user.id, !user.isActive);
      await _load();
    } catch (_) {
      if (mounted) _message(AppLocalizations.of(context).userSaveError);
    }
  }

  Future<void> _password(ManagedUser user) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) =>
          _PasswordDialog(title: AppLocalizations.of(context).resetPassword),
    );
    if (password == null) return;
    try {
      await widget.repository.resetPassword(user.id, password);
      if (mounted) _message(AppLocalizations.of(context).passwordResetSuccess);
    } catch (_) {
      if (mounted) _message(AppLocalizations.of(context).passwordResetError);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _UserActions extends StatelessWidget {
  const _UserActions({
    required this.user,
    required this.onStatus,
    required this.onPassword,
  });
  final ManagedUser user;
  final VoidCallback onStatus;
  final VoidCallback onPassword;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      onSelected: (value) => value == 'status' ? onStatus() : onPassword(),
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'status',
          child: Text(user.isActive ? s.deactivate : s.activate),
        ),
        PopupMenuItem(value: 'password', child: Text(s.resetPassword)),
      ],
    );
  }
}

class _UserInput {
  const _UserInput(this.username, this.password, this.phone);
  final String username, password, phone;
}

class _UserDialog extends StatefulWidget {
  const _UserDialog();
  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final username = TextEditingController(),
      password = TextEditingController(),
      phone = TextEditingController();
  bool obscure = true;
  String? error;
  @override
  void dispose() {
    username.dispose();
    password.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(s.createUser),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: username,
                decoration: InputDecoration(labelText: s.username),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: s.phone),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: password,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: s.password,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
            if (username.text.trim().isEmpty || password.text.length < 6) {
              setState(() => error = s.userValidationError);
              return;
            }
            Navigator.pop(
              context,
              _UserInput(
                username.text.trim(),
                password.text,
                phone.text.trim(),
              ),
            );
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.title});
  final String title;
  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final password = TextEditingController(), confirm = TextEditingController();
  String? error;
  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: password,
              obscureText: true,
              decoration: InputDecoration(labelText: s.newPassword),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration: InputDecoration(labelText: s.confirmPassword),
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
            if (password.text.length < 6 || password.text != confirm.text) {
              setState(() => error = s.passwordValidationError);
              return;
            }
            Navigator.pop(context, password.text);
          },
          child: Text(s.save),
        ),
      ],
    );
  }
}

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({required this.repository, super.key});
  final AdministrationRepository repository;
  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  List<AuditRecord> rows = [];
  List<ManagedUser> managedUsers = [];
  AuditFilters filters = const AuditFilters();
  int page = 1;
  bool loading = true, failed = false, hasMore = false, loadingMore = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool append = false}) async {
    if (append) {
      if (!hasMore || loadingMore) return;
      setState(() => loadingMore = true);
      page++;
    } else {
      setState(() {
        loading = true;
        failed = false;
        page = 1;
      });
    }
    try {
      managedUsers = managedUsers.isEmpty
          ? await widget.repository.users()
          : managedUsers;
      final result = await widget.repository.audit(filters, page);
      if (append) {
        rows.addAll(result.rows);
      } else {
        rows = result.rows;
      }
      hasMore = result.hasMore;
    } catch (_) {
      if (append) {
        page--;
      } else {
        failed = true;
      }
    }
    if (mounted) {
      setState(() {
        loading = false;
        loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(s.auditLogs),
        actions: [
          IconButton(
            onPressed: _filter,
            tooltip: s.filters,
            icon: const Icon(Icons.filter_alt_outlined),
          ),
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
              message: s.auditLoadError,
              action: s.retry,
              onTap: _load,
            )
          : rows.isEmpty
          ? _StateMessage(message: s.noAuditLogs)
          : LayoutBuilder(
              builder: (context, constraints) => ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (constraints.maxWidth >= 950)
                    _AuditTable(rows: rows)
                  else
                    ...rows.map((row) => _AuditCard(row: row)),
                  if (hasMore)
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: loadingMore
                            ? null
                            : () => _load(append: true),
                        icon: loadingMore
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.expand_more),
                        label: Text(s.loadMore),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _filter() async {
    final result = await showDialog<AuditFilters>(
      context: context,
      builder: (_) => _AuditFilterDialog(value: filters, users: managedUsers),
    );
    if (result != null) {
      filters = result;
      await _load();
    }
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.row});
  final AuditRecord row;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context),
        locale = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ExpansionTile(
          title: Text('${_action(s, row.action)} · ${row.entity}'),
          subtitle: Text(
            '${DateFormat.yMd(locale).add_Hm().format(row.timestamp.toLocal())}\n${s.user}: ${row.username ?? s.systemUser}',
          ),
          childrenPadding: const EdgeInsets.all(16),
          children: [
            SelectableText(
              '${s.entityId}: ${row.entityId}\n\n${s.oldValues}:\n${_json(row.oldValues)}\n\n${s.newValues}:\n${_json(row.newValues)}',
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.rows});
  final List<AuditRecord> rows;
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context),
        locale = Localizations.localeOf(context).toLanguageTag();
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            s.dateTime,
            s.user,
            s.action,
            s.entity,
            s.entityId,
            s.oldValues,
            s.newValues,
          ].map((label) => DataColumn(label: Text(label))).toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        DateFormat.yMd(
                          locale,
                        ).add_Hm().format(row.timestamp.toLocal()),
                      ),
                    ),
                    DataCell(Text(row.username ?? s.systemUser)),
                    DataCell(Text(_action(s, row.action))),
                    DataCell(Text(row.entity)),
                    DataCell(SelectableText(row.entityId)),
                    DataCell(
                      SizedBox(
                        width: 260,
                        child: SelectableText(_json(row.oldValues)),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 260,
                        child: SelectableText(_json(row.newValues)),
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

String _json(Map<String, dynamic> value) =>
    const JsonEncoder.withIndent('  ').convert(value);
String _action(AppLocalizations s, String value) => switch (value) {
  'CREATE' => s.createAction,
  'UPDATE' => s.updateAction,
  _ => s.deleteAction,
};

class _AuditFilterDialog extends StatefulWidget {
  const _AuditFilterDialog({required this.value, required this.users});
  final AuditFilters value;
  final List<ManagedUser> users;
  @override
  State<_AuditFilterDialog> createState() => _AuditFilterDialogState();
}

class _AuditFilterDialogState extends State<_AuditFilterDialog> {
  late int? user = widget.value.userId;
  late String? action = widget.value.action;
  late final entity = TextEditingController(text: widget.value.entity);
  late DateTime? start = widget.value.start, end = widget.value.end;
  @override
  void dispose() {
    entity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(s.filters),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int?>(
                initialValue: user,
                decoration: InputDecoration(labelText: s.user),
                items: [
                  DropdownMenuItem<int?>(value: null, child: Text(s.all)),
                  ...widget.users.map(
                    (item) => DropdownMenuItem<int?>(
                      value: item.id,
                      child: Text(item.username),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => user = value),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                initialValue: action,
                decoration: InputDecoration(labelText: s.action),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(s.all)),
                  DropdownMenuItem(
                    value: 'CREATE',
                    child: Text(s.createAction),
                  ),
                  DropdownMenuItem(
                    value: 'UPDATE',
                    child: Text(s.updateAction),
                  ),
                  DropdownMenuItem(
                    value: 'DELETE',
                    child: Text(s.deleteAction),
                  ),
                ],
                onChanged: (value) => setState(() => action = value),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: entity,
                decoration: InputDecoration(labelText: s.entity),
              ),
              _DateTile(
                label: s.startDate,
                value: start,
                onChanged: (value) => setState(() => start = value),
              ),
              _DateTile(
                label: s.endDate,
                value: end,
                onChanged: (value) => setState(() => end = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, const AuditFilters()),
          child: Text(s.clearFilters),
        ),
        FilledButton(
          onPressed: () {
            if (start != null && end != null && start!.isAfter(end!)) return;
            Navigator.pop(
              context,
              AuditFilters(
                userId: user,
                action: action,
                entity: entity.text,
                start: start,
                end: end,
              ),
            );
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
    required this.onChanged,
  });
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(label),
    subtitle: Text(
      value == null
          ? AppLocalizations.of(context).allDates
          : DateFormat.yMd(
              Localizations.localeOf(context).toLanguageTag(),
            ).format(value!),
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
