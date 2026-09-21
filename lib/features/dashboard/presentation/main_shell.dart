import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/initials_avatar.dart';
import '../../../core/widgets/home_button.dart';

import '../../auth/application/auth_controller.dart';
import '../../administration/data/administration_repository.dart';
import '../../administration/presentation/administration_screen.dart';
import '../../clients/application/clients_controller.dart';
import '../../clients/presentation/clients_screen.dart';
import '../../partners/application/partners_controller.dart';
import '../../partners/presentation/partners_screen.dart';
import '../../pointeur/presentation/pointeur_screen.dart';
import '../../owners/application/owners_controller.dart';
import '../../owners/presentation/owners_screen.dart';
import '../../reports/data/reports_repository.dart';
import '../../settings/application/locale_controller.dart';
import '../../settings/application/theme_controller.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../ships/application/ships_controller.dart';
import '../../ships/presentation/ships_screen.dart';
import '../../statistics/presentation/ship_statistics_screen.dart';
import '../../transactions/application/transactions_controller.dart';
import '../../transactions/presentation/transactions_screen.dart';
import 'dashboard_screen.dart';
import 'money_owed_screen.dart';
import '../application/dashboard_controller.dart';

Future<void> _confirmLogout(
  BuildContext context,
  AuthController authController,
) async {
  final strings = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(strings.logout),
      content: Text(strings.logoutConfirmation),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(strings.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(strings.confirmLogout),
        ),
      ],
    ),
  );
  if (confirmed == true) await authController.logout();
}

/// Destinations, in display order, grouped into three logical sections:
/// Overview (0-1), Ledger (2-6), System (7-8). The four busiest Ledger/
/// Overview screens get a permanent slot on the mobile bottom bar; the rest
/// live behind "More".
const _kPrimaryMobileIndexes = [0, 2, 3, 6];

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
  void initState() {
    super.initState();
    if (widget.authController.currentUser?.isStaff != true &&
        widget.themeController.mode != ThemeMode.light) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.themeController.setMode(ThemeMode.light),
      );
    }
  }

  void _selectAdminDestination(int value) {
    setState(() => _selected = value);
    switch (value) {
      case 0:
        widget.dashboardController.load();
        return;
      case 1:
        widget.shipsController.load();
        return;
      case 2:
        widget.shipsController.load();
        return;
      case 3:
        widget.clientsController.load();
        return;
      case 4:
        widget.partnersController.load();
        return;
      case 5:
        widget.ownersController.load();
        return;
      case 6:
        widget.transactionsController.load();
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (widget.authController.currentUser?.isPointeur == true) {
      return PointeurScreen(
        repository: widget.shipsController.repository,
        authController: widget.authController,
        localeController: widget.localeController,
        themeController: widget.themeController,
        administrationRepository: widget.administrationRepository,
      );
    }
    final isAdmin = widget.authController.currentUser?.isStaff == true;
    if (!isAdmin) {
      return _UserHomeShell(
        authController: widget.authController,
        dashboardController: widget.dashboardController,
        shipsController: widget.shipsController,
        clientsController: widget.clientsController,
        ownersController: widget.ownersController,
        partnersController: widget.partnersController,
        transactionsController: widget.transactionsController,
        localeController: widget.localeController,
        themeController: widget.themeController,
        administrationRepository: widget.administrationRepository,
      );
    }
    final adminItems = <_NavItem>[
      _NavItem(strings.dashboard, Icons.dashboard_outlined, Icons.dashboard),
      _NavItem(
        Localizations.localeOf(context).languageCode == 'ar'
            ? 'الإحصائيات'
            : 'Statistiques',
        Icons.assessment_outlined,
        Icons.assessment,
      ),
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
      _NavItem(
        strings.administration,
        Icons.admin_panel_settings_outlined,
        Icons.admin_panel_settings,
      ),
      _NavItem(strings.settings, Icons.settings_outlined, Icons.settings),
    ];
    final adminScreens = <Widget>[
      DashboardScreen(
        controller: widget.dashboardController,
        onNavigate: (index) {
          if (index == 9) {
            widget.dashboardController.load();
            final arabic = Localizations.localeOf(context).languageCode == 'ar';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: Text(arabic ? 'الديون والقروض' : 'Dettes et prêts'),
                    actions: const [HomeButton(), SizedBox(width: 8)],
                  ),
                  body: MoneyOwedScreen(controller: widget.dashboardController),
                ),
              ),
            );
            return;
          }
          _selectAdminDestination(index);
        },
      ),
      ShipStatisticsScreen(controller: widget.shipsController),
      ShipsScreen(controller: widget.shipsController),
      ClientsScreen(controller: widget.clientsController),
      PartnersScreen(controller: widget.partnersController),
      OwnersScreen(controller: widget.ownersController),
      TransactionsScreen(controller: widget.transactionsController),
      AdministrationScreen(
        repository: widget.administrationRepository,
        isAdmin: widget.authController.currentUser?.isStaff == true,
      ),
      SettingsScreen(
        controller: widget.localeController,
        themeController: widget.themeController,
        repository: widget.administrationRepository,
        showAppearance: true,
      ),
    ];
    final items = adminItems;
    final screens = adminScreens;

    return LayoutBuilder(
      builder: (context, constraints) {
        // The rail has nine destinations and cannot scroll. Use the mobile
        // navigation when a wide window is too short to show them safely.
        final desktop =
            constraints.maxWidth >= 900 && constraints.maxHeight >= 700;
        if (desktop) {
          return _DesktopShell(
            extended: constraints.maxWidth >= 1200,
            selected: _selected,
            items: items,
            screens: screens,
            authController: widget.authController,
            themeController: widget.themeController,
            showThemeControls: true,
            onSelected: _selectAdminDestination,
          );
        }
        return _MobileShell(
          selected: _selected,
          items: items,
          screens: screens,
          authController: widget.authController,
          primaryIndexes: _kPrimaryMobileIndexes,
          onSelected: _selectAdminDestination,
        );
      },
    );
  }
}

class _UserHomeShell extends StatelessWidget {
  const _UserHomeShell({
    required this.authController,
    required this.dashboardController,
    required this.shipsController,
    required this.clientsController,
    required this.ownersController,
    required this.partnersController,
    required this.transactionsController,
    required this.localeController,
    required this.themeController,
    required this.administrationRepository,
  });

  final AuthController authController;
  final DashboardController dashboardController;
  final ShipsController shipsController;
  final ClientsController clientsController;
  final OwnersController ownersController;
  final PartnersController partnersController;
  final TransactionsController transactionsController;
  final LocaleController localeController;
  final ThemeController themeController;
  final AdministrationRepository administrationRepository;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(10),
          child: AppLogo(size: 32),
        ),
        title: Text(s.appName),
        actions: [
          IconButton(
            tooltip: s.settings,
            onPressed: () => _open(
              context,
              s.settings,
              SettingsScreen(
                controller: localeController,
                themeController: themeController,
                repository: administrationRepository,
                showAppearance: false,
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
          _AccountMenu(authController: authController),
          const SizedBox(width: 8),
        ],
      ),
      body: DashboardScreen(
        controller: dashboardController,
        onNavigate: (destination) {
          switch (destination) {
            case 2:
              shipsController.load();
              _open(context, s.ships, ShipsScreen(controller: shipsController));
              return;
            case 3:
              clientsController.load();
              _open(
                context,
                s.clients,
                ClientsScreen(controller: clientsController),
              );
              return;
            case 5:
              ownersController.load();
              _open(
                context,
                s.owners,
                OwnersScreen(controller: ownersController),
              );
              return;
            case 4:
              partnersController.load();
              _open(
                context,
                s.partners,
                PartnersScreen(controller: partnersController),
              );
              return;
            case 1:
              shipsController.load();
              final label = Localizations.localeOf(context).languageCode == 'ar'
                  ? 'الإحصائيات'
                  : 'Statistiques';
              _open(
                context,
                label,
                ShipStatisticsScreen(controller: shipsController),
              );
              return;
            case 6:
              transactionsController.load();
              _open(
                context,
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'سجل المعاملات'
                    : 'Historique des transactions',
                TransactionsScreen(controller: transactionsController),
              );
              return;
            case 9:
              dashboardController.load();
              _open(
                context,
                Localizations.localeOf(context).languageCode == 'ar'
                    ? 'الديون والقروض'
                    : 'Dettes et prêts',
                MoneyOwedScreen(controller: dashboardController),
              );
              return;
          }
        },
      ),
    );
  }

  void _open(BuildContext context, String title, Widget child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text(title),
            actions: const [HomeButton(), SizedBox(width: 8)],
          ),
          body: child,
        ),
      ),
    );
  }
}

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.extended,
    required this.selected,
    required this.items,
    required this.screens,
    required this.authController,
    required this.themeController,
    required this.showThemeControls,
    required this.onSelected,
  });

  final bool extended;
  final int selected;
  final List<_NavItem> items;
  final List<Widget> screens;
  final AuthController authController;
  final ThemeController themeController;
  final bool showThemeControls;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            selectedIndex: selected,
            onDestinationSelected: onSelected,
            leading: Container(
              // NavigationRail lays out its leading widget with an unconstrained
              // width. Keep the brand header finite on desktop/Linux.
              width: extended ? 240 : 72,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                gradient: AppGradients.subtleTint(
                  scheme,
                  Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              child: extended
                  ? Row(
                      children: [
                        const AppLogo(size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            strings.appName,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : const Center(child: AppLogo(size: 36)),
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
            child: Column(
              children: [
                _DesktopTopBar(
                  title: items[selected].label,
                  authController: authController,
                  themeController: themeController,
                  showThemeControls: showThemeControls,
                ),
                const Divider(height: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1600),
                      child: _AnimatedScreen(
                        index: selected,
                        child: screens[selected],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Slim top bar for the desktop layout: page title, a quick theme-mode
/// toggle, and the same account menu the mobile app bar uses, so desktop no
/// longer relies solely on the rail's bottom icon for logout.
class _DesktopTopBar extends StatelessWidget {
  const _DesktopTopBar({
    required this.title,
    required this.authController,
    required this.themeController,
    required this.showThemeControls,
  });

  final String title;
  final AuthController authController;
  final ThemeController themeController;
  final bool showThemeControls;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    child: Row(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              title,
              key: ValueKey(title),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        if (showThemeControls) ...[
          _ThemeModeToggle(controller: themeController),
          const SizedBox(width: 8),
        ],
        _AccountMenu(authController: authController),
      ],
    ),
  );
}

class _ThemeModeToggle extends StatelessWidget {
  const _ThemeModeToggle({required this.controller});
  final ThemeController controller;

  static const _cycle = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final (icon, label) = switch (controller.mode) {
          ThemeMode.system => (
            Icons.brightness_auto_outlined,
            strings.themeSystem,
          ),
          ThemeMode.light => (Icons.light_mode_outlined, strings.themeLight),
          ThemeMode.dark => (Icons.dark_mode_outlined, strings.themeDark),
        };
        return IconButton(
          tooltip: label,
          icon: Icon(icon),
          onPressed: () {
            final next =
                _cycle[(_cycle.indexOf(controller.mode) + 1) % _cycle.length];
            controller.setMode(next);
          },
        );
      },
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.authController});
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final username = authController.currentUser?.username ?? '';
    return PopupMenuButton<String>(
      tooltip: username,
      offset: const Offset(0, 44),
      onSelected: (value) {
        if (value == 'logout') _confirmLogout(context, authController);
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(username, style: Theme.of(context).textTheme.titleSmall),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              const Icon(Icons.logout, size: 20),
              const SizedBox(width: 10),
              Text(strings.logout),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: InitialsAvatar(username.isEmpty ? '?' : username, size: 34),
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.selected,
    required this.items,
    required this.screens,
    required this.authController,
    required this.primaryIndexes,
    required this.onSelected,
  });

  final int selected;
  final List<_NavItem> items;
  final List<Widget> screens;
  final AuthController authController;
  final List<int> primaryIndexes;
  final ValueChanged<int> onSelected;

  int? get _barIndex {
    final position = primaryIndexes.indexOf(selected);
    return position == -1 ? null : position;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final moreItems = [
      for (var i = 0; i < items.length; i++)
        if (!primaryIndexes.contains(i)) i,
    ];
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(items[selected].label, key: ValueKey(selected)),
        ),
        actions: [_AccountMenu(authController: authController)],
      ),
      body: _AnimatedScreen(index: selected, child: screens[selected]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _barIndex ?? primaryIndexes.length,
        onDestinationSelected: (index) {
          if (index < primaryIndexes.length) {
            onSelected(primaryIndexes[index]);
            return;
          }
          _openMore(context, moreItems);
        },
        destinations: [
          for (final index in primaryIndexes)
            NavigationDestination(
              icon: Icon(items[index].icon),
              selectedIcon: Icon(items[index].selectedIcon),
              label: items[index].label,
            ),
          if (moreItems.isNotEmpty)
            NavigationDestination(
              icon: const Icon(Icons.more_horiz),
              selectedIcon: const Icon(Icons.more_horiz),
              label: strings.more,
            ),
        ],
      ),
    );
  }

  Future<void> _openMore(BuildContext context, List<int> moreItems) async {
    final strings = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final index in moreItems)
              ListTile(
                leading: Icon(
                  index == selected
                      ? items[index].selectedIcon
                      : items[index].icon,
                  color: index == selected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                title: Text(items[index].label),
                selected: index == selected,
                onTap: () => Navigator.pop(sheetContext, index),
              ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(strings.logout),
              onTap: () => Navigator.pop(sheetContext, -1),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (choice == -1) {
      await _confirmLogout(context, authController);
      return;
    }
    if (choice != null) onSelected(choice);
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
