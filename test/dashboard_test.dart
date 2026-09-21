import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/core/theme/app_theme.dart';
import 'package:maritime_frontend/features/dashboard/application/dashboard_controller.dart';
import 'package:maritime_frontend/features/dashboard/data/dashboard_repository.dart';
import 'package:maritime_frontend/features/dashboard/domain/dashboard_models.dart';
import 'package:maritime_frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

void main() {
  testWidgets('home shows all requested shortcuts', (tester) async {
    int? selected;
    await tester.pumpWidget(_Harness(onNavigate: (value) => selected = value));

    for (final label in [
      'Navires',
      'Clients',
      'Propriétaires',
      'Partenaires',
      'Statistiques',
      'Historique des transactions',
      'Dettes et prêts',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.byType(Card), findsNWidgets(7));
    expect(find.text('Espèces attendues'), findsNothing);

    await tester.tap(find.text('Navires'));
    expect(selected, 2);
    await tester.tap(find.text('Statistiques'));
    expect(selected, 1);
  });
}

class _EmptySource implements DashboardDataSource {
  @override
  Future<DashboardData> fetchDashboard() async => const DashboardData(
    metrics: DashboardMetrics(
      expectedCash: 0,
      peopleOweUs: 0,
      weOwePeople: 0,
      netPosition: 0,
      totalRevenue: 0,
      totalExpenses: 0,
      profitLoss: 0,
    ),
    ships: [],
    clients: [],
    partners: [],
    positions: [],
  );
}

class _Harness extends StatelessWidget {
  const _Harness({required this.onNavigate});
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: DashboardScreen(
        controller: DashboardController(_EmptySource()),
        onNavigate: onNavigate,
      ),
    ),
  );
}
