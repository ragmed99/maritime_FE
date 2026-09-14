import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleController extends ChangeNotifier {
  LocaleController({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'preferred_language';
  final FlutterSecureStorage _storage;
  Locale _locale = const Locale('fr');
  Locale get locale => _locale;

  Future<void> initialize() async {
    final code = await _storage.read(key: _storageKey);
    if (code == 'ar' || code == 'fr') {
      _locale = Locale(code!);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale value) async {
    if (value == _locale) return;
    _locale = value;
    notifyListeners();
    await _storage.write(key: _storageKey, value: value.languageCode);
  }
}
