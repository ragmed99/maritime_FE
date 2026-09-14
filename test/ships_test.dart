import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/core/config/app_environment.dart';
import 'package:maritime_frontend/core/network/api_client.dart';
import 'package:maritime_frontend/core/storage/token_storage.dart';
import 'package:maritime_frontend/features/ships/application/ships_controller.dart';
import 'package:maritime_frontend/features/ships/data/ships_repository.dart';
import 'package:maritime_frontend/features/ships/domain/ship_models.dart';
import 'package:maritime_frontend/features/ships/presentation/ships_screen.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

void main() {
  test(
    'financial models parse Django decimal strings without calculating totals',
    () {
      final ship = Financials.ship({
        'total_revenue': '1200.50',
        'total_expenses': '300.25',
        'profit': '900.25',
      });
      final trip = Financials.trip({
        'revenue': '500.00',
        'expenses': '125.00',
        'profit': '375.00',
      });

      expect(ship.revenue, 1200.50);
      expect(ship.profit, 900.25);
      expect(trip.expenses, 125);
      expect(trip.profit, 375);
    },
  );

  testWidgets('ships list shows owner and filters by ship name', (
    tester,
  ) async {
    final controller = _controller();
    controller.status = LoadStatus.loaded;
    controller.ships = const [
      ShipRecord(
        id: 'ship-1',
        name: 'Al Bahri',
        registrationNumber: 'MR-001',
        ownerId: 'owner-1',
        ownerName: 'Amina Shipping',
      ),
    ];

    await tester.pumpWidget(_Harness(controller: controller));
    expect(find.text('Al Bahri'), findsOneWidget);
    expect(find.textContaining('Amina Shipping'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Atlantique');
    await tester.pump();
    expect(find.text('Al Bahri'), findsNothing);
    expect(
      find.text('Aucun navire ne correspond à la recherche.'),
      findsOneWidget,
    );
  });
}

ShipsController _controller() {
  const environment = AppEnvironment(
    flavor: AppFlavor.development,
    apiBaseUrl: 'https://test.example/api/',
  );
  return ShipsController(
    ShipsRepository(ApiClient(environment, _MemoryTokenStore())),
  );
}

class _Harness extends StatelessWidget {
  const _Harness({required this.controller});
  final ShipsController controller;
  @override
  Widget build(BuildContext context) => MaterialApp(
    locale: const Locale('fr'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: ShipsScreen(controller: controller)),
  );
}

class _MemoryTokenStore implements TokenStore {
  @override
  Future<void> clear() async {}
  @override
  Future<String?> readAccessToken() async => null;
  @override
  Future<String?> readRefreshToken() async => null;
  @override
  Future<void> saveAccessToken(String access) async {}
  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {}
}
