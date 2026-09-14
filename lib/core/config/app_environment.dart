enum AppFlavor { development, staging, production }

class AppEnvironment {
  const AppEnvironment({required this.flavor, required this.apiBaseUrl});
  final AppFlavor flavor;
  final String apiBaseUrl;

  static AppEnvironment get current {
    const name = String.fromEnvironment('APP_ENV', defaultValue: 'development');
    const development = String.fromEnvironment(
      'DEV_API_URL',
      defaultValue: 'http://127.0.0.1:8000',
    );
    const staging = String.fromEnvironment('STAGING_API_URL');
    const production = String.fromEnvironment(
      'PRODUCTION_API_URL',
      defaultValue: 'https://maritime-api.cliniquedouane.com',
    );
    return resolve(
      name: name,
      developmentUrl: development,
      stagingUrl: staging,
      productionUrl: production,
    );
  }

  static AppEnvironment resolve({
    required String name,
    required String developmentUrl,
    required String stagingUrl,
    required String productionUrl,
  }) {
    final flavor = AppFlavor.values.firstWhere(
      (value) => value.name == name,
      orElse: () => throw StateError('Unknown APP_ENV: $name'),
    );
    final apiBaseUrl = switch (flavor) {
      AppFlavor.development => developmentUrl,
      AppFlavor.staging => stagingUrl,
      AppFlavor.production => productionUrl,
    };
    if (flavor != AppFlavor.development && apiBaseUrl.isEmpty) {
      throw StateError('API URL is required for the selected APP_ENV.');
    }
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError('A valid absolute API URL is required.');
    }
    if (flavor == AppFlavor.production && uri.scheme != 'https') {
      throw StateError('Production API URL must use HTTPS.');
    }
    return AppEnvironment(flavor: flavor, apiBaseUrl: apiBaseUrl);
  }
}
