import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/core/config/app_environment.dart';
import 'package:maritime_frontend/core/network/api_client.dart';
import 'package:maritime_frontend/core/storage/token_storage.dart';
import 'package:maritime_frontend/features/auth/application/auth_controller.dart';

void main() {
  const environment = AppEnvironment(
    flavor: AppFlavor.development,
    apiBaseUrl: 'https://test.example/api/',
  );

  test('successful login stores tokens and loads current user', () async {
    final storage = MemoryTokenStore();
    final adapter = FakeAdapter((request) {
      if (request.path == 'auth/login/') {
        return response({'access': 'access-token', 'refresh': 'refresh-token'});
      }
      expect(request.headers['Authorization'], 'Bearer access-token');
      return response(userJson);
    });
    final controller = buildController(environment, storage, adapter);

    await controller.login('captain', 'secret');

    expect(controller.status, AuthStatus.authenticated);
    expect(controller.currentUser?.username, 'captain');
    expect(storage.access, 'access-token');
    expect(storage.refresh, 'refresh-token');
  });

  test('wrong password returns translated error category', () async {
    final storage = MemoryTokenStore();
    final adapter = FakeAdapter(
      (_) => response({'detail': 'invalid'}, status: 401),
    );
    final controller = buildController(environment, storage, adapter);

    await controller.login('captain', 'wrong');

    expect(controller.status, AuthStatus.initializing);
    expect(controller.error, AuthError.invalidCredentials);
    expect(storage.access, isNull);
  });

  test('disabled user is rejected as an inactive credential', () async {
    final storage = MemoryTokenStore();
    final adapter = FakeAdapter(
      (_) => response({'detail': 'No active account found'}, status: 401),
    );
    final controller = buildController(environment, storage, adapter);

    await controller.login('disabled', 'secret');

    expect(controller.error, AuthError.invalidCredentials);
    expect(controller.currentUser, isNull);
  });

  test('expired access token triggers the refresh endpoint', () async {
    final storage = MemoryTokenStore(
      access: 'expired',
      refresh: 'valid-refresh',
    );
    var refreshCalls = 0;
    final adapter = FakeAdapter((request) {
      if (request.path == 'auth/refresh/') {
        refreshCalls++;
        return response({'access': 'renewed'});
      }
      if (request.headers['Authorization'] == 'Bearer expired') {
        return response({'detail': 'expired'}, status: 401);
      }
      return response(userJson);
    });
    final controller = buildController(environment, storage, adapter);

    await controller.initialize();

    expect(refreshCalls, 1);
    expect(storage.access, 'renewed');
    expect(controller.status, AuthStatus.authenticated);
  });

  test(
    'refreshed token is attached when retrying the failed request',
    () async {
      final storage = MemoryTokenStore(access: 'old', refresh: 'refresh');
      var retriedWithNewToken = false;
      final adapter = FakeAdapter((request) {
        if (request.path == 'auth/refresh/') return response({'access': 'new'});
        if (request.headers['Authorization'] == 'Bearer old') {
          return response({}, status: 401);
        }
        retriedWithNewToken = request.headers['Authorization'] == 'Bearer new';
        return response(userJson);
      });
      final controller = buildController(environment, storage, adapter);

      await controller.initialize();

      expect(retriedWithNewToken, isTrue);
      expect(controller.currentUser?.id, 1);
    },
  );

  test('failed refresh clears tokens and logs out', () async {
    final storage = MemoryTokenStore(
      access: 'expired',
      refresh: 'expired-refresh',
    );
    final adapter = FakeAdapter((_) => response({}, status: 401));
    final controller = buildController(environment, storage, adapter);

    await controller.initialize();

    expect(controller.status, AuthStatus.unauthenticated);
    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
  });

  test('logout clears secure tokens and current user', () async {
    final storage = MemoryTokenStore(access: 'access', refresh: 'refresh');
    final adapter = FakeAdapter((_) => response(userJson));
    final controller = buildController(environment, storage, adapter);
    await controller.initialize();

    await controller.logout();

    expect(controller.status, AuthStatus.unauthenticated);
    expect(controller.currentUser, isNull);
    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
  });
}

const userJson = {
  'id': 1,
  'username': 'captain',
  'email': 'captain@example.com',
  'is_staff': false,
  'is_active': true,
};

AuthController buildController(
  AppEnvironment environment,
  MemoryTokenStore storage,
  FakeAdapter adapter,
) {
  final dio = Dio()..httpClientAdapter = adapter;
  return AuthController(ApiClient(environment, storage, dio: dio), storage);
}

ResponseBody response(Object data, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(data),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.handler);
  final ResponseBody Function(RequestOptions request) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => handler(options);

  @override
  void close({bool force = false}) {}
}

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore({this.access, this.refresh});
  String? access;
  String? refresh;

  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }

  @override
  Future<String?> readAccessToken() async => access;

  @override
  Future<String?> readRefreshToken() async => refresh;

  @override
  Future<void> saveAccessToken(String value) async => access = value;

  @override
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    this.access = access;
    this.refresh = refresh;
  }
}
