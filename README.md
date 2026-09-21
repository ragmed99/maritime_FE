# Tar Fishing Frontend

Flutter foundation targeting Android, iOS, and Windows. French is the default
locale; Arabic is supported with Flutter's automatic RTL directionality.

## Environments

Development defaults to Django at `http://127.0.0.1:8000`, so the Linux app can
be started without compile-time arguments:

```bash
flutter run -d linux
```

The development URL can still be overridden when needed. Staging requires an
explicit URL. Production defaults to the deployed Vultr HTTPS API:
`https://maritime-api.cliniquedouane.com`.

```bash
flutter run --dart-define=DEV_API_URL=http://10.0.2.2:8000

flutter build apk --dart-define=APP_ENV=staging \
  --dart-define=STAGING_API_URL=https://staging.example.com/api/

flutter build apk --release --dart-define=APP_ENV=production
flutter build windows --release --dart-define=APP_ENV=production
flutter build linux --release --dart-define=APP_ENV=production
flutter build ios --release --dart-define=APP_ENV=production
```

## Android release signing

Never publish an APK signed with Flutter's debug key. Create a private upload
keystore and add `android/key.properties` (ignored by Git):

```properties
storePassword=<store-password>
keyPassword=<key-password>
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Then build the Play Store bundle:

```bash
flutter build appbundle --release --dart-define=APP_ENV=production
```

Keep the keystore and passwords backed up outside the repository. Without
`key.properties`, local release builds remain unsigned rather than using an
unsafe debug signature.

`PRODUCTION_API_URL` remains available for controlled production overrides, but
production validation requires an absolute HTTPS URL:

```bash
flutter build apk --release --dart-define=APP_ENV=production \
  --dart-define=PRODUCTION_API_URL=https://maritime-api.cliniquedouane.com
```

Use `127.0.0.1` instead of Android emulator host `10.0.2.2` when running the
Windows or Linux desktop client against local Django. Android emulators normally
use `DEV_API_URL=http://10.0.2.2:8000`; physical devices need the development
machine's LAN address.
