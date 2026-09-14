import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/features/dashboard/application/dashboard_controller.dart';
import 'package:maritime_frontend/features/dashboard/data/dashboard_repository.dart';
import 'package:maritime_frontend/features/dashboard/domain/dashboard_models.dart';
import 'package:maritime_frontend/features/dashboard/presentation/dashboard_screen.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

void main() {
  testWidgets('dashboard renders API values, summaries, and refresh control', (
    tester,
  ) async {
    final source = FakeDashboardSource(sampleData);
    final controller = DashboardController(source);
    await tester.pumpWidget(_Harness(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Espèces attendues'), findsOneWidget);
    expect(find.textContaining('1 234,50'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(source.calls, 2);

    await tester.scrollUntilVisible(find.text('Navire Horizon'), 500);
    expect(find.text('Navire Horizon'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Le client nous doit'), 500);
    expect(find.text('Le client nous doit'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Nous devons au partenaire'),
      500,
    );
    expect(find.text('Nous devons au partenaire'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('dashboard exposes translated empty states', (tester) async {
    final empty = DashboardData(
      metrics: sampleData.metrics,
      ships: const [],
      clients: const [],
      partners: const [],
    );
    await tester.pumpWidget(
      _Harness(controller: DashboardController(FakeDashboardSource(empty))),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Aucun navire à afficher.'), 500);
    expect(find.text('Aucun navire à afficher.'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Aucun client à afficher.'), 500);
    expect(find.text('Aucun client à afficher.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Aucun partenaire à afficher.'),
      500,
    );
    expect(find.text('Aucun partenaire à afficher.'), findsOneWidget);
  });

  testWidgets('dashboard exposes a localized error and retry state', (
    tester,
  ) async {
    final source = FailingDashboardSource();
    await tester.pumpWidget(_Harness(controller: DashboardController(source)));
    await tester.pumpAndSettle();

    expect(
      find.text('Impossible de charger le tableau de bord.'),
      findsOneWidget,
    );
    expect(find.text('Réessayer'), findsOneWidget);
  });
}

const sampleData = DashboardData(
  metrics: DashboardMetrics(
    expectedCash: 1234.50,
    peopleOweUs: 400,
    weOwePeople: 125,
    netPosition: 1509.50,
    totalRevenue: 2000,
    totalExpenses: 500,
    profitLoss: 1500,
  ),
  ships: [
    ShipSummary(
      name: 'Navire Horizon',
      revenue: 2000,
      expenses: 500,
      profitLoss: 1500,
    ),
  ],
  clients: [ClientSummary(name: 'Client Débit', balance: 125)],
  partners: [PartnerSummary(name: 'Partenaire Crédit', balance: -75)],
);

class FakeDashboardSource implements DashboardDataSource {
  FakeDashboardSource(this.data);
  final DashboardData data;
  int calls = 0;
  @override
  Future<DashboardData> fetchDashboard() async {
    calls++;
    return data;
  }
}

class FailingDashboardSource implements DashboardDataSource {
  @override
  Future<DashboardData> fetchDashboard() => throw Exception();
}

class _Harness extends StatelessWidget {
  const _Harness({required this.controller});
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: DashboardScreen(controller: controller)),
    );
  }
}
