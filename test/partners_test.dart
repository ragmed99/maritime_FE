import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/core/config/app_environment.dart';
import 'package:maritime_frontend/core/network/api_client.dart';
import 'package:maritime_frontend/core/models/account_position.dart';
import 'package:maritime_frontend/core/storage/token_storage.dart';
import 'package:maritime_frontend/core/theme/app_theme.dart';
import 'package:maritime_frontend/features/partners/application/partners_controller.dart';
import 'package:maritime_frontend/features/partners/data/partners_repository.dart';
import 'package:maritime_frontend/features/partners/domain/partner_models.dart';
import 'package:maritime_frontend/features/partners/presentation/partners_screen.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

void main() {
  test('partner transaction parses amount, time, and audit creator', () {
    final row = PartnerTransaction.fromJson({
      'id': 'transaction-1',
      'transaction_type': 'PARTNER_LOAN_RECEIVED',
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

  testWidgets('partners list displays contact data and supports search', (
    tester,
  ) async {
    final controller = _controller();
    controller.status = PartnersStatus.loaded;
    controller.partners = const [
      PartnerRecord(
        id: 'partner-1',
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
      find.text('Aucun partenaire ne correspond à la recherche.'),
      findsOneWidget,
    );
  });

  testWidgets('partner balance displays all three directions', (tester) async {
    await tester.pumpWidget(
      const _BalanceHarness(
        value: AccountPosition(theyOweUs: 50, weOweThem: 0, balance: 50),
      ),
    );
    expect(find.text('Débit'), findsWidgets);

    await tester.pumpWidget(
      const _BalanceHarness(
        value: AccountPosition(theyOweUs: 0, weOweThem: 50, balance: -50),
      ),
    );
    expect(find.text('Crédit'), findsWidgets);

    await tester.pumpWidget(
      const _BalanceHarness(
        value: AccountPosition(theyOweUs: 0, weOweThem: 0, balance: 0),
      ),
    );
    expect(find.text('Solde nul'), findsOneWidget);
  });
}

PartnersController _controller() {
  const environment = AppEnvironment(
    flavor: AppFlavor.development,
    apiBaseUrl: 'https://test.example/api/',
  );
  return PartnersController(
    PartnersRepository(ApiClient(environment, _MemoryTokenStore())),
  );
}

class _Harness extends StatelessWidget {
  const _Harness({required this.controller});
  final PartnersController controller;

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
    home: Scaffold(body: PartnersScreen(controller: controller)),
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
    home: Scaffold(body: PartnerBalance(value: value)),
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
