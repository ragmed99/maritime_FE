import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _storageKey = 'preferred_theme_mode';
  final FlutterSecureStorage _storage;
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  Future<void> initialize() async {
    final value = await _storage.read(key: _storageKey);
    final resolved = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    if (resolved != _mode) {
      _mode = resolved;
      notifyListeners();
    }
  }

  Future<void> setMode(ThemeMode value) async {
    if (value == _mode) return;
    _mode = value;
    notifyListeners();
    await _storage.write(key: _storageKey, value: value.name);
  }
}
