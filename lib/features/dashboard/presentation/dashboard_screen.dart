import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../application/dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.controller, this.onNavigate, super.key});

  final DashboardController controller;
  final ValueChanged<int>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final statistic = Localizations.localeOf(context).languageCode == 'ar'
        ? 'الإحصائيات'
        : 'Statistiques';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final shortcuts = <(String, IconData, int)>[
      (s.ships, Icons.directions_boat_outlined, 2),
      (s.clients, Icons.people_outline, 3),
      (s.owners, Icons.badge_outlined, 5),
      (s.partners, Icons.handshake_outlined, 4),
      (statistic, Icons.bar_chart_outlined, 1),
      (
        isArabic ? 'سجل المعاملات' : 'Historique des transactions',
        Icons.history_outlined,
        6,
      ),
      (
        isArabic ? 'الديون والقروض' : 'Dettes et prêts',
        Icons.account_balance_wallet_outlined,
        9,
      ),
      (isArabic ? 'سلة المحذوفات' : 'Corbeille', Icons.delete_outline, 10),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 3
            : constraints.maxWidth >= 600
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - 48 - (columns - 1) * 16) / columns;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(s.appName, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: shortcuts
                  .map(
                    (item) => SizedBox(
                      width: width,
                      height: 170,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => onNavigate?.call(item.$3),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(item.$2, size: 42),
                                const SizedBox(height: 14),
                                Text(
                                  item.$1,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        );
      },
    );
  }
}
