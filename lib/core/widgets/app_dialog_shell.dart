import 'package:flutter/material.dart';

/// Consistent dialog chrome (icon + title + close button, responsive width,
/// unified padding) wrapped around a real [AlertDialog] so every add/edit/
/// delete/filter dialog in the app shares the same shape without having to
/// rewrite each dialog's fields/controllers.
class AppDialogShell extends StatelessWidget {
  const AppDialogShell({
    required this.title,
    required this.actions,
    this.icon,
    this.content,
    this.scrollable = true,
    super.key,
  });

  final String title;
  final IconData? icon;
  final Widget? content;
  final List<Widget> actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    return AlertDialog(
      scrollable: scrollable,
      insetPadding: const EdgeInsets.all(24),
      titlePadding: const EdgeInsets.fromLTRB(24, 22, 12, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      title: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: scheme.primary, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: Navigator.of(context).pop,
            tooltip: MaterialLocalizations.of(context).closeButtonLabel,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      content: content == null
          ? null
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width < 600 ? width - 48 : 520,
              ),
              child: content,
            ),
      actions: actions,
    );
  }
}
