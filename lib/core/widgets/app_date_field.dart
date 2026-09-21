import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A bordered, input-styled date field (matching `InputDecorationTheme`)
/// that opens [showDatePicker] on tap — replaces the "`ListTile` that opens
/// a date picker" pattern used across every add/edit/filter dialog.
class AppDateField extends StatelessWidget {
  const AppDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.placeholder,
    super.key,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          firstDate: firstDate ?? DateTime(2000),
          lastDate: lastDate ?? DateTime(2100),
          initialDate: value ?? DateTime.now(),
        );
        if (selected != null) onChanged(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
        ),
        child: Text(
          value == null
              ? (placeholder ?? '—')
              : DateFormat.yMd(locale).format(value!),
        ),
      ),
    );
  }
}
