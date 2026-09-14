import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/features/administration/domain/administration_models.dart';
import 'package:maritime_frontend/features/settings/application/locale_controller.dart';

void main() {
  test('managed user parses admin and active status', () {
    final user = ManagedUser.fromJson({
      'id': 7,
      'username': 'admin',
      'phone': '+222 12345678',
      'is_active': true,
      'is_staff': true,
    });
    expect(user.isStaff, isTrue);
    expect(user.isActive, isTrue);
    expect(user.username, 'admin');
    expect(user.phone, '+222 12345678');
  });

  test('audit filters serialize all supported backend filters', () {
    final query = AuditFilters(
      userId: 4,
      action: 'UPDATE',
      entity: 'Transaction',
      start: DateTime(2026, 9, 1),
      end: DateTime(2026, 9, 30),
    ).toQuery(2);
    expect(query, {
      'page': 2,
      'user': 4,
      'action': 'UPDATE',
      'entity': 'Transaction',
      'start_date': '2026-09-01',
      'end_date': '2026-09-30',
    });
  });

  test('selected Arabic locale is persisted and restored', () async {
    FlutterSecureStorage.setMockInitialValues({});
    const storage = FlutterSecureStorage();
    final first = LocaleController(storage: storage);
    await first.setLocale(const Locale('ar'));

    final restored = LocaleController(storage: storage);
    await restored.initialize();
    expect(restored.locale, const Locale('ar'));
  });
}
