import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/administration/data/administration_repository.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/clients/application/clients_controller.dart';
import '../features/dashboard/presentation/main_shell.dart';
import '../features/dashboard/application/dashboard_controller.dart';
import '../features/partners/application/partners_controller.dart';
import '../features/owners/application/owners_controller.dart';
import '../features/reports/data/reports_repository.dart';
import '../features/settings/application/locale_controller.dart';
import '../features/ships/application/ships_controller.dart';
import '../features/transactions/application/transactions_controller.dart';

class MaritimeApp extends StatelessWidget {
  const MaritimeApp({
    required this.authController,
    required this.dashboardController,
    required this.shipsController,
    required this.clientsController,
    required this.partnersController,
    required this.ownersController,
    required this.transactionsController,
    required this.reportsRepository,
    required this.administrationRepository,
    required this.localeController,
    super.key,
  });

  final AuthController authController;
  final DashboardController dashboardController;
  final ShipsController shipsController;
  final ClientsController clientsController;
  final PartnersController partnersController;
  final OwnersController ownersController;
  final TransactionsController transactionsController;
  final ReportsRepository reportsRepository;
  final AdministrationRepository administrationRepository;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([authController, localeController]),
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        locale: localeController.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF075E78),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          cardTheme: const CardThemeData(margin: EdgeInsets.zero),
        ),
        home: switch (authController.status) {
          AuthStatus.initializing => const SplashScreen(),
          AuthStatus.unauthenticated => LoginScreen(controller: authController),
          AuthStatus.authenticated => MainShell(
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
        },
      ),
    );
  }
}
