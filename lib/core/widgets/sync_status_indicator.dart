import 'package:flutter/material.dart';

import '../network/api_client.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({required this.api, super.key});

  final ApiClient api;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: api,
    builder: (context, _) {
      final pending = api.pendingSyncCount;
      if (!api.isSyncing && !api.isOffline && pending == 0) {
        return const SizedBox.shrink();
      }
      final arabic = Localizations.localeOf(context).languageCode == 'ar';
      final text = api.isSyncing
          ? (arabic ? 'جاري المزامنة…' : 'Synchronisation…')
          : pending > 0
          ? (arabic
                ? '$pending عمليات غير مزامنة'
                : '$pending non synchronisé(s)')
          : (arabic ? 'وضع عدم الاتصال' : 'Mode hors connexion');
      final color = api.isOffline
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.tertiary;
      return SafeArea(
        minimum: const EdgeInsets.only(top: 6),
        child: Material(
          color: color,
          elevation: 5,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: api.isSyncing ? null : api.synchronizeAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (api.isSyncing)
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  else
                    const Icon(
                      Icons.sync_problem,
                      color: Colors.white,
                      size: 19,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
