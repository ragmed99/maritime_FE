import 'package:flutter/material.dart';
import 'package:maritime_frontend/l10n/app_localizations.dart';

import '../application/locale_controller.dart';
import '../application/theme_controller.dart';
import '../../administration/data/administration_repository.dart';
import '../../administration/domain/administration_models.dart';
import '../../../core/widgets/app_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.controller,
    required this.themeController,
    required this.repository,
    super.key,
  });
  final LocaleController controller;
  final ThemeController themeController;
  final AdministrationRepository repository;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  CompanyConfig? config;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      config = await widget.repository.companyConfig();
    } catch (_) {
      config = null;
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Center(child: AppLogo(size: 120)),
        const SizedBox(height: 12),
        Text(
          strings.settings,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language_outlined),
            title: Text(strings.language),
            trailing: DropdownButton<Locale>(
              value: widget.controller.locale,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              onChanged: (value) {
                if (value != null) widget.controller.setLocale(value);
              },
              items: [
                DropdownMenuItem(
                  value: const Locale('fr'),
                  child: Text(strings.french),
                ),
                DropdownMenuItem(
                  value: const Locale('ar'),
                  child: Text(strings.arabic),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.palette_outlined),
                    const SizedBox(width: 16),
                    Text(
                      strings.appearance,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: widget.themeController,
                  builder: (context, _) => SegmentedButton<ThemeMode>(
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(strings.themeSystem),
                        icon: const Icon(Icons.brightness_auto_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(strings.themeLight),
                        icon: const Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(strings.themeDark),
                        icon: const Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {widget.themeController.mode},
                    onSelectionChanged: (selection) =>
                        widget.themeController.setMode(selection.first),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : config == null
                ? Text(strings.companySettingsError)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.companyInformation,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.business_outlined),
                        title: Text(strings.companyName),
                        subtitle: Text(strings.appName),
                      ),
                      if (config!.phone.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.phone_outlined),
                          title: Text(strings.phone),
                          subtitle: Text(config!.phone),
                        ),
                      if (config!.address.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.location_on_outlined),
                          title: Text(strings.address),
                          subtitle: Text(config!.address),
                        ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
