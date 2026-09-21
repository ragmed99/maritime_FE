import 'package:flutter/material.dart';

/// Unified loading / error / empty placeholder used across every list and
/// detail screen, replacing the near-identical `_StateMessage` widgets that
/// used to be duplicated per feature.
class AppStateView extends StatelessWidget {
  const AppStateView._({
    this.icon,
    this.message,
    this.actionLabel,
    this.onAction,
    this.isError = false,
    super.key,
  });

  factory AppStateView.loading({Key? key}) => AppStateView._(key: key);

  factory AppStateView.error({
    required String message,
    String? retryLabel,
    VoidCallback? onRetry,
    Key? key,
  }) => AppStateView._(
    icon: Icons.cloud_off_outlined,
    message: message,
    actionLabel: retryLabel,
    onAction: onRetry,
    isError: true,
    key: key,
  );

  factory AppStateView.empty({
    required String message,
    IconData icon = Icons.inbox_outlined,
    String? actionLabel,
    VoidCallback? onAction,
    Key? key,
  }) => AppStateView._(
    icon: icon,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    key: key,
  );

  final IconData? icon;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final scheme = Theme.of(context).colorScheme;
    final tint = isError ? scheme.error : scheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tint.withValues(alpha: 0.1),
              ),
              child: Icon(icon, size: 30, color: tint),
            ),
            const SizedBox(height: 16),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              isError
                  ? FilledButton.icon(
                      onPressed: onAction,
                      icon: const Icon(Icons.refresh),
                      label: Text(actionLabel!),
                    )
                  : OutlinedButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
            ],
          ],
        ),
      ),
    );
  }
}
