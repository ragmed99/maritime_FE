import 'package:flutter/material.dart';

/// Title + refresh + primary "add" action, shared by every list screen.
/// Collapses the add button to icon-only under [narrowWidth] so it never
/// wraps awkwardly on phones.
class ListHeaderBar extends StatelessWidget {
  const ListHeaderBar({
    required this.title,
    required this.onRefresh,
    required this.refreshTooltip,
    this.onAdd,
    this.addLabel,
    this.trailing,
    super.key,
  });

  final String title;
  final VoidCallback onRefresh;
  final String refreshTooltip;
  final VoidCallback? onAdd;
  final String? addLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 420;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
        IconButton(
          onPressed: onRefresh,
          tooltip: refreshTooltip,
          icon: const Icon(Icons.refresh),
        ),
        if (onAdd != null && addLabel != null) ...[
          const SizedBox(width: 4),
          narrow
              ? IconButton.filled(
                  onPressed: onAdd,
                  tooltip: addLabel,
                  icon: const Icon(Icons.add),
                )
              : FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: Text(addLabel!),
                ),
        ],
      ],
    );
  }
}
