import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/auth/domain/current_user.dart';
import '../config/app_environment.dart';
import '../storage/token_storage.dart';

enum ApiAuthError { invalidCredentials, network, server }

class ApiAuthException implements Exception {
  const ApiAuthException(this.kind);
  final ApiAuthError kind;
}

class ApiClient {
  ApiClient(AppEnvironment environment, this._tokenStorage, {Dio? dio})
    : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: _apiRoot(environment.apiBaseUrl),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    );
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
  }

  final Dio _dio;
  final TokenStore _tokenStorage;
  Future<bool>? _refreshInProgress;
  FutureOr<void> Function()? onSessionExpired;

  static String _apiRoot(String configuredUrl) {
    final normalized = configuredUrl.endsWith('/')
        ? configuredUrl
        : '$configuredUrl/';
    final uri = Uri.parse(normalized);
    if (uri.path == '/' || uri.path.isEmpty) return '${normalized}api/';
    return normalized;
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['skipAuth'] != true) {
      final token = await _tokenStorage.readAccessToken();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final request = error.requestOptions;
    final shouldRefresh =
        error.response?.statusCode == 401 &&
        request.extra['skipRefresh'] != true &&
        request.extra['retried'] != true;
    if (!shouldRefresh) {
      handler.next(error);
      return;
    }

    final refreshed = await (_refreshInProgress ??= _refreshAccessToken());
    _refreshInProgress = null;
    if (!refreshed) {
      await _expireSession();
      handler.next(error);
      return;
    }

    try {
      request.extra['retried'] = true;
      request.headers['Authorization'] =
          'Bearer ${await _tokenStorage.readAccessToken()}';
      handler.resolve(await _dio.fetch<dynamic>(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshAccessToken() async {
    final refresh = await _tokenStorage.readRefreshToken();
    if (refresh == null) return false;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/refresh/',
        data: {'refresh': refresh},
        options: Options(extra: const {'skipAuth': true, 'skipRefresh': true}),
      );
      final data = response.data!;
      await _tokenStorage.saveTokens(
        access: data['access'] as String,
        refresh: data['refresh'] as String? ?? refresh,
      );
      return true;
    } on DioException {
      return false;
    }
  }

  Future<void> _expireSession() async {
    await _tokenStorage.clear();
    await onSessionExpired?.call();
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        'auth/login/',
        data: {'username': username, 'password': password},
        options: Options(extra: const {'skipAuth': true, 'skipRefresh': true}),
      );
      await _tokenStorage.saveTokens(
        access: response.data!['access'] as String,
        refresh: response.data!['refresh'] as String,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        throw const ApiAuthException(ApiAuthError.invalidCredentials);
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw const ApiAuthException(ApiAuthError.network);
      }
      throw const ApiAuthException(ApiAuthError.server);
    }
  }

  Future<CurrentUser> currentUser() async {
    final response = await _dio.get<Map<String, dynamic>>('auth/me/');
    return CurrentUser.fromJson(response.data!);
  }

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) =>
      _dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post<T>(path, data: data);

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _dio.patch<T>(path, data: data);

  Future<void> delete(String path) async {
    await _dio.delete<void>(path);
  }

  Future<List<int>> download(String path, {Map<String, dynamic>? query}) async {
    final response = await _dio.get<List<int>>(
      path,
      queryParameters: query,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data!;
  }
}
