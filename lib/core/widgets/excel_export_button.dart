import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../files/pdf_export.dart';

/// "Excel / Share" button shown next to each statement's PDF button: fetches
/// the .xlsx with [download], then saves (Linux) or shares it.
class ExcelExportButton extends StatefulWidget {
  const ExcelExportButton({
    required this.download,
    required this.filename,
    required this.title,
    super.key,
  });

  final Future<Uint8List> Function() download;
  final String filename;
  final String title;

  @override
  State<ExcelExportButton> createState() => _ExcelExportButtonState();
}

class _ExcelExportButtonState extends State<ExcelExportButton> {
  bool sharing = false;

  Future<void> _share() async {
    setState(() => sharing = true);
    try {
      final bytes = await widget.download();
      final savedPath = await exportFile(
        bytes: bytes,
        filename: widget.filename,
        title: widget.title,
        mimeType: xlsxMimeType,
      );
      if (mounted && savedPath != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Excel: $savedPath')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).excelError)),
        );
      }
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: sharing ? null : _share,
    icon: sharing
        ? const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.table_chart_outlined),
    label: Text(AppLocalizations.of(context).downloadShareExcel),
  );
}
