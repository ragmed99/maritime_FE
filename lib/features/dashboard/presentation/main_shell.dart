import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';
import '../../../core/widgets/app_logo.dart';

import '../../auth/application/auth_controller.dart';
import '../../administration/data/administration_repository.dart';
import '../../administration/presentation/administration_screen.dart';
import '../../clients/application/clients_controller.dart';
import '../../clients/presentation/clients_screen.dart';
import '../../partners/application/partners_controller.dart';
import '../../partners/presentation/partners_screen.dart';
import '../../owners/application/owners_controller.dart';
import '../../owners/presentation/owners_screen.dart';
import '../../reports/data/reports_repository.dart';
import '../../reports/presentation/reports_screen.dart';
import '../../settings/application/locale_controller.dart';
import '../../settings/application/theme_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../ships/application/ships_controller.dart';
import '../../ships/presentation/ships_screen.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/presentation/transactions_screen.dart';
import 'dashboard_screen.dart';
import '../application/dashboard_controller.dart';

class MainShell extends StatefulWidget {
  const MainShell({
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
    required this.themeController,
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
  final ThemeController themeController;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final items = <_NavItem>[
      _NavItem(strings.dashboard, Icons.dashboard_outlined, Icons.dashboard),
      _NavItem(
        strings.ships,
        Icons.directions_boat_outlined,
        Icons.directions_boat,
      ),
      _NavItem(strings.clients, Icons.people_outline, Icons.people),
      _NavItem(strings.partners, Icons.handshake_outlined, Icons.handshake),
      _NavItem(strings.owners, Icons.badge_outlined, Icons.badge),
      _NavItem(
        strings.transactions,
        Icons.receipt_long_outlined,
        Icons.receipt_long,
      ),
      _NavItem(strings.reports, Icons.assessment_outlined, Icons.assessment),
    ];
    items.add(
      _NavItem(
        strings.administration,
        Icons.admin_panel_settings_outlined,
        Icons.admin_panel_settings,
      ),
    );
    items.add(
      _NavItem(strings.settings, Icons.settings_outlined, Icons.settings),
    );
    final screens = <Widget>[
      DashboardScreen(controller: widget.dashboardController),
      ShipsScreen(controller: widget.shipsController),
      ClientsScreen(controller: widget.clientsController),
      PartnersScreen(controller: widget.partnersController),
      OwnersScreen(controller: widget.ownersController),
      TransactionsScreen(controller: widget.transactionsController),
      ReportsScreen(repository: widget.reportsRepository),
    ];
    screens.add(
      AdministrationScreen(
        repository: widget.administrationRepository,
        isAdmin: widget.authController.currentUser?.isStaff == true,
      ),
    );
    screens.add(
      SettingsScreen(
        controller: widget.localeController,
        themeController: widget.themeController,
        repository: widget.administrationRepository,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  extended: constraints.maxWidth >= 1200,
                  selectedIndex: _selected,
                  onDestinationSelected: (value) =>
                      setState(() => _selected = value),
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const AppLogo(size: 52),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: IconButton(
                          tooltip: strings.logout,
                          onPressed: widget.authController.logout,
                          icon: const Icon(Icons.logout),
                        ),
                      ),
                    ),
                  ),
                  destinations: items
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1600),
                      child: _AnimatedScreen(
                        index: _selected,
                        child: screens[_selected],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                items[_selected].label,
                key: ValueKey(_selected),
              ),
            ),
          ),
          drawer: NavigationDrawer(
            selectedIndex: _selected,
            onDestinationSelected: (value) {
              setState(() => _selected = value);
              Navigator.pop(context);
            },
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 16, 12),
                child: Row(
                  children: [
                    const AppLogo(size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.appName,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
              ...items.map(
                (item) => NavigationDrawerDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.selectedIcon),
                  label: Text(item.label),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(strings.logout),
                onTap: widget.authController.logout,
              ),
            ],
          ),
          body: _AnimatedScreen(index: _selected, child: screens[_selected]),
        );
      },
    );
  }
}

/// Fades and slightly slides the new screen in when the selected
/// destination changes, so navigation feels smooth rather than abrupt.
class _AnimatedScreen extends StatelessWidget {
  const _AnimatedScreen({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 220),
    switchInCurve: Curves.easeOut,
    switchOutCurve: Curves.easeIn,
    transitionBuilder: (widget, animation) => FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(animation),
        child: widget,
      ),
    ),
    child: KeyedSubtree(key: ValueKey(index), child: child),
  );
}

class _NavItem {
  const _NavItem(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
