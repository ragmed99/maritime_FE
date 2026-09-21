import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../domain/current_user.dart';

enum AuthStatus { initializing, authenticated, unauthenticated }

enum AuthError { invalidCredentials, network, server }

class AuthController extends ChangeNotifier {
  AuthController(this._api, this._storage) {
    _api.onSessionExpired = handleSessionExpired;
  }

  final ApiClient _api;
  final TokenStore _storage;
  AuthStatus status = AuthStatus.initializing;
  AuthError? error;
  CurrentUser? currentUser;
  bool isLoading = false;

  ApiClient get api => _api;

  Future<void> initialize() async {
    final access = await _storage.readAccessToken();
    final refresh = await _storage.readRefreshToken();
    if (access == null && refresh == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      currentUser = await _api.currentUser();
      status = AuthStatus.authenticated;
    } on DioException catch (exception) {
      // ApiClient clears storage when the refresh token is truly rejected.
      // Keep tokens on transient server failures so reopening/retrying can recover.
      status = AuthStatus.unauthenticated;
      error =
          exception.type == DioExceptionType.connectionError ||
              exception.type == DioExceptionType.connectionTimeout ||
              exception.type == DioExceptionType.receiveTimeout
          ? AuthError.network
          : AuthError.server;
    } catch (_) {
      status = AuthStatus.unauthenticated;
      error = AuthError.server;
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      await _api.login(username, password);
      currentUser = await _api.currentUser();
      status = AuthStatus.authenticated;
    } on ApiAuthException catch (exception) {
      error = switch (exception.kind) {
        ApiAuthError.invalidCredentials => AuthError.invalidCredentials,
        ApiAuthError.network => AuthError.network,
        ApiAuthError.server => AuthError.server,
      };
    } on DioException catch (exception) {
      error = exception.type == DioExceptionType.connectionError
          ? AuthError.network
          : AuthError.server;
    } catch (_) {
      error = AuthError.server;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> handleSessionExpired() async {
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.clear();
    currentUser = null;
    error = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
