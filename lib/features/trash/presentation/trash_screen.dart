import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/trash_repository.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({required this.repository, super.key});
  final TrashRepository repository;

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<TrashRecord> rows = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      rows = await widget.repository.records();
    } catch (_) {
      error = 'load';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: FilledButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: Text(ar ? 'إعادة المحاولة' : 'Réessayer'),
        ),
      );
    }
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline, size: 54),
            const SizedBox(height: 12),
            Text(ar ? 'سلة المحذوفات فارغة' : 'La corbeille est vide'),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          return Card(
            child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(row.label),
              subtitle: Text(
                '${_kind(row.kind, ar)} · ${DateFormat.yMd(Localizations.localeOf(context).toLanguageTag()).add_Hm().format(row.deletedAt.toLocal())}',
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    tooltip: ar ? 'استعادة' : 'Restaurer',
                    onPressed: () => _restore(row),
                    icon: const Icon(Icons.restore),
                  ),
                  IconButton(
                    tooltip: ar ? 'حذف نهائي' : 'Supprimer définitivement',
                    onPressed: () => _purge(row),
                    icon: const Icon(Icons.delete_forever),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _kind(String value, bool ar) => switch (value) {
    'owner' => ar ? 'مالك' : 'Propriétaire',
    'ship' => ar ? 'سفينة' : 'Navire',
    'trip' => ar ? 'رحلة' : 'Voyage',
    'client' => ar ? 'عميل' : 'Client',
    'partner' => ar ? 'شريك' : 'Partenaire',
    _ => ar ? 'معاملة' : 'Transaction',
  };

  Future<void> _restore(TrashRecord row) async {
    await widget.repository.restore(row.batch);
    await _load();
  }

  Future<void> _purge(TrashRecord row) async {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ar ? 'حذف نهائي' : 'Suppression définitive'),
        content: Text(
          ar
              ? 'لن يمكن استعادة هذه البيانات. هل تريد المتابعة؟'
              : 'Ces données ne pourront plus être restaurées. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(ar ? 'إلغاء' : 'Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(ar ? 'حذف' : 'Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.purge(row.batch);
    await _load();
  }
}
