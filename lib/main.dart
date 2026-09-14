import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/app_environment.dart';
import 'core/network/api_client.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/application/auth_controller.dart';
import 'features/administration/data/administration_repository.dart';
import 'features/clients/application/clients_controller.dart';
import 'features/clients/data/clients_repository.dart';
import 'features/dashboard/application/dashboard_controller.dart';
import 'features/dashboard/data/dashboard_repository.dart';
import 'features/partners/application/partners_controller.dart';
import 'features/partners/data/partners_repository.dart';
import 'features/reports/data/reports_repository.dart';
import 'features/owners/application/owners_controller.dart';
import 'features/owners/data/owners_repository.dart';
import 'features/settings/application/locale_controller.dart';
import 'features/ships/application/ships_controller.dart';
import 'features/ships/data/ships_repository.dart';
import 'features/transactions/application/transactions_controller.dart';
import 'features/transactions/data/transactions_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(AppEnvironment.current, tokenStorage);
  final authController = AuthController(apiClient, tokenStorage);
  final administrationRepository = AdministrationRepository(apiClient);
  final dashboardController = DashboardController(
    DashboardRepository(apiClient),
  );
  final shipsController = ShipsController(ShipsRepository(apiClient));
  final clientsController = ClientsController(ClientsRepository(apiClient));
  final partnersController = PartnersController(PartnersRepository(apiClient));
  final ownersController = OwnersController(OwnersRepository(apiClient));
  final transactionsController = TransactionsController(
    TransactionsRepository(apiClient),
    onChanged: dashboardController.load,
  );
  final reportsRepository = ReportsRepository(apiClient);
  final localeController = LocaleController();
  await localeController.initialize();
  runApp(
    MaritimeApp(
      authController: authController,
      dashboardController: dashboardController,
      shipsController: shipsController,
      clientsController: clientsController,
      partnersController: partnersController,
      ownersController: ownersController,
      transactionsController: transactionsController,
      reportsRepository: reportsRepository,
      administrationRepository: administrationRepository,
      localeController: localeController,
    ),
  );
  await authController.initialize();
}
