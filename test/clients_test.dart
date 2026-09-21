import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/core/config/app_environment.dart';
import 'package:maritime_frontend/core/network/api_client.dart';
import 'package:maritime_frontend/core/storage/token_storage.dart';
import 'package:maritime_frontend/core/theme/app_theme.dart';
import 'package:maritime_frontend/features/clients/application/clients_controller.dart';
import 'package:maritime_frontend/features/clients/data/clients_repository.dart';
import 'package:maritime_frontend/features/clients/domain/client_models.dart';
import 'package:maritime_frontend/features/clients/presentation/clients_screen.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

void main() {
  test('statement row parses backend relations and audit creator', () {
    final row = ClientTransactionRow.fromJson({
      'id': 'transaction-1',
      'transaction_type': 'CLIENT_PURCHASE',
      'amount': '225.50',
      'date': '2026-09-13',
      'time': '14:20:00',
      'description': 'Poisson',
      'ship': {'id': 'ship-1', 'name': 'Al Bahri'},
      'trip': {'id': 'trip-1', 'departure_date': '2026-09-10'},
      'created_by': {'id': 1, 'username': 'captain'},
    });

    expect(row.amount, 225.50);
    expect(row.ship, 'Al Bahri');
    expect(row.trip, '2026-09-10');
    expect(row.recordedBy, 'captain');
  });

  testWidgets('clients list displays contact data and supports search', (
    tester,
  ) async {
    final controller = _controller();
    controller.status = ClientsStatus.loaded;
    controller.clients = const [
      ClientRecord(
        id: 'client-1',
        name: 'Marché Central',
        phone: '+222 12345678',
      ),
    ];
    await tester.pumpWidget(_Harness(controller: controller));

    expect(find.text('Marché Central'), findsOneWidget);
    expect(find.textContaining('+222 12345678'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Introuvable');
    await tester.pump();
    expect(find.text('Marché Central'), findsNothing);
    expect(
      find.text('Aucun client ne correspond à la recherche.'),
      findsOneWidget,
    );
  });
}

ClientsController _controller() {
  const environment = AppEnvironment(
    flavor: AppFlavor.development,
    apiBaseUrl: 'https://test.example/api/',
  );
  return ClientsController(
    ClientsRepository(ApiClient(environment, _MemoryTokenStore())),
  );
}

class _Harness extends StatelessWidget {
  const _Harness({required this.controller});
  final ClientsController controller;
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
    home: Scaffold(body: ClientsScreen(controller: controller)),
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
