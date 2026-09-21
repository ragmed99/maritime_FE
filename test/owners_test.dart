import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/core/config/app_environment.dart';
import 'package:maritime_frontend/core/network/api_client.dart';
import 'package:maritime_frontend/core/models/account_position.dart';
import 'package:maritime_frontend/core/storage/token_storage.dart';
import 'package:maritime_frontend/core/theme/app_theme.dart';
import 'package:maritime_frontend/features/owners/application/owners_controller.dart';
import 'package:maritime_frontend/features/owners/data/owners_repository.dart';
import 'package:maritime_frontend/features/owners/domain/owner_models.dart';
import 'package:maritime_frontend/features/owners/presentation/owners_screen.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

void main() {
  test('owner transaction parses amount, time, and audit creator', () {
    final row = OwnerTransaction.fromJson({
      'id': 'transaction-1',
      'transaction_type': 'OWNER_DEPOSIT',
      'amount': '225.50',
      'transaction_date': '2026-09-13',
      'created_at': '2026-09-13T14:20:00Z',
      'description': 'Avance',
      'created_by': {'id': 1, 'username': 'captain'},
    });

    expect(row.amount, 225.50);
    expect(row.time.toUtc().hour, 14);
    expect(row.recordedBy, 'captain');
  });

  test('owner ship parses backend relationship data', () {
    final ship = OwnerShip.fromJson({
      'id': 'ship-1',
      'name': 'Al Bahri',
      'owner': 'owner-1',
    });
    expect(ship.name, 'Al Bahri');
  });

  testWidgets('owners list displays contact data and supports search', (
    tester,
  ) async {
    final controller = _controller();
    controller.status = OwnersStatus.loaded;
    controller.owners = const [
      OwnerRecord(
        id: 'owner-1',
        name: 'Coopérative du Port',
        phone: '+222 12345678',
      ),
    ];
    await tester.pumpWidget(_Harness(controller: controller));

    expect(find.text('Coopérative du Port'), findsOneWidget);
    expect(find.textContaining('+222 12345678'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Introuvable');
    await tester.pump();
    expect(find.text('Coopérative du Port'), findsNothing);
    expect(
      find.text('Aucun propriétaire ne correspond à la recherche.'),
      findsOneWidget,
    );
  });

  testWidgets('owner balance displays all three directions', (tester) async {
    await tester.pumpWidget(
      const _BalanceHarness(
        value: AccountPosition(theyOweUs: 0, weOweThem: 50, balance: 50),
      ),
    );
    expect(find.text('L’entreprise doit au propriétaire'), findsOneWidget);

    await tester.pumpWidget(
      const _BalanceHarness(
        value: AccountPosition(theyOweUs: 50, weOweThem: 0, balance: -50),
      ),
    );
    expect(find.text('Le propriétaire doit à l’entreprise'), findsOneWidget);

    await tester.pumpWidget(
      const _BalanceHarness(
        value: AccountPosition(theyOweUs: 0, weOweThem: 0, balance: 0),
      ),
    );
    expect(find.text('Solde nul'), findsOneWidget);
  });
}

OwnersController _controller() {
  const environment = AppEnvironment(
    flavor: AppFlavor.development,
    apiBaseUrl: 'https://test.example/api/',
  );
  return OwnersController(
    OwnersRepository(ApiClient(environment, _MemoryTokenStore())),
  );
}

class _Harness extends StatelessWidget {
  const _Harness({required this.controller});
  final OwnersController controller;

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
    home: Scaffold(body: OwnersScreen(controller: controller)),
  );
}

class _BalanceHarness extends StatelessWidget {
  const _BalanceHarness({required this.value});
  final AccountPosition value;

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
    home: Scaffold(body: OwnerBalance(value: value)),
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
