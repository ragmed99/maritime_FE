import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/core/config/app_environment.dart';

void main() {
  test('development works without dart defines', () {
    final environment = AppEnvironment.current;

    expect(environment.flavor, AppFlavor.development);
    expect(environment.apiBaseUrl, 'http://127.0.0.1:8000');
  });

  test('production defaults to the deployed HTTPS API', () {
    final environment = AppEnvironment.resolve(
      name: 'production',
      developmentUrl: 'http://127.0.0.1:8000',
      stagingUrl: '',
      productionUrl: 'https://maritime-api.cliniquedouane.com',
    );

    expect(environment.flavor, AppFlavor.production);
    expect(environment.apiBaseUrl, 'https://maritime-api.cliniquedouane.com');
  });

  test('production rejects non-HTTPS URLs', () {
    expect(
      () => AppEnvironment.resolve(
        name: 'production',
        developmentUrl: 'http://127.0.0.1:8000',
        stagingUrl: '',
        productionUrl: 'http://maritime-api.cliniquedouane.com',
      ),
      throwsStateError,
    );
  });

  test('staging still requires an explicitly configured URL', () {
    expect(
      () => AppEnvironment.resolve(
        name: 'staging',
        developmentUrl: 'http://127.0.0.1:8000',
        stagingUrl: '',
        productionUrl: 'https://maritime-api.cliniquedouane.com',
      ),
      throwsStateError,
    );
  });
}
