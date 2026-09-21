import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../../features/auth/domain/current_user.dart';
import '../config/app_environment.dart';
import '../storage/token_storage.dart';
import '../offline/offline_store.dart';

enum ApiAuthError { invalidCredentials, network, server }

class ApiAuthException implements Exception {
  const ApiAuthException(this.kind);
  final ApiAuthError kind;
}

class ApiClient extends ChangeNotifier {
  ApiClient(
    AppEnvironment environment,
    this._tokenStorage, {
    OfflineStore? offlineStore,
    Dio? dio,
  }) : _offlineStore = offlineStore ?? OfflineStore.memory(),
       _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: _apiRoot(environment.apiBaseUrl),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: const {'Accept': 'application/json'},
    );
    _dio.interceptors.add(
      InterceptorsWrapper(onRequest: _onRequest, onError: _onError),
    );
    if (dio == null) {
      Connectivity().onConnectivityChanged.listen((results) {
        final disconnected = results.contains(ConnectivityResult.none);
        _setOffline(disconnected);
        if (!disconnected) unawaited(synchronizeAll());
      });
    }
  }

  final Dio _dio;
  final TokenStore _tokenStorage;
  final OfflineStore _offlineStore;
  Future<bool>? _refreshInProgress;
  Future<void>? _syncInProgress;
  CurrentUser? _activeUser;
  bool _syncing = false;
  bool _offline = false;
  FutureOr<void> Function()? onSessionExpired;

  bool get isSyncing => _syncing;
  bool get isOffline => _offline;
  bool get hasPendingSync => pendingSyncCount > 0;

  void _setOffline(bool value) {
    if (_offline == value) return;
    _offline = value;
    notifyListeners();
  }

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

    bool refreshed;
    try {
      refreshed = await (_refreshInProgress ??= _refreshAccessToken());
    } on DioException {
      // A temporary API/network failure must not destroy a valid session.
      handler.next(error);
      return;
    } finally {
      _refreshInProgress = null;
    }
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
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 400 || status == 401 || status == 403) return false;
      rethrow;
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
    final response = await get<Map<String, dynamic>>('auth/me/');
    final user = CurrentUser.fromJson(response.data!);
    _offlineStore.setScope(user.id);
    _activeUser = user;
    await syncPending();
    await _warmOfflineData(user);
    return user;
  }

  Future<void> _warmOfflineData(CurrentUser user) async {
    try {
      final ships = await _allRows('ships/');
      final trips = await _allRows('trips/');
      final clients = await _allRows('clients/');
      await Future.wait([
        for (final trip in trips)
          get<List<dynamic>>('trips/${trip['id']}/purchases/'),
      ]);
      if (user.isPointeur) return;
      final owners = await _allRows('owners/');
      final partners = await _allRows('partners/');
      await Future.wait([
        _allRows('transactions/'),
        get<Map<String, dynamic>>('dashboard/'),
        get<Map<String, dynamic>>('financial-summary/'),
        get<Map<String, dynamic>>('reports/ships/'),
        get<Map<String, dynamic>>('reports/clients/'),
        get<Map<String, dynamic>>('reports/partners/'),
        for (final ship in ships)
          get<Map<String, dynamic>>('ships/${ship['id']}/financials/'),
        for (final trip in trips)
          get<Map<String, dynamic>>('trips/${trip['id']}/financials/'),
        for (final client in clients)
          get<Map<String, dynamic>>('clients/${client['id']}/balance/'),
        for (final client in clients)
          get<Map<String, dynamic>>('clients/${client['id']}/statement/'),
        for (final owner in owners)
          get<Map<String, dynamic>>('owners/${owner['id']}/balance/'),
        for (final owner in owners)
          _allRows('transactions/?owner_account=${owner['id']}'),
        for (final partner in partners)
          get<Map<String, dynamic>>('partners/${partner['id']}/balance/'),
      ]);
    } catch (_) {
      // Warming is best-effort. Normal screen requests still use cached data.
    }
  }

  Future<List<Map<String, dynamic>>> _allRows(String firstPath) async {
    final rows = <Map<String, dynamic>>[];
    String? next = firstPath;
    while (next != null) {
      final response = await get<Map<String, dynamic>>(next);
      final data = response.data!;
      rows.addAll(
        (data['results'] as List<dynamic>).cast<Map<String, dynamic>>(),
      );
      next = data['next'] as String?;
    }
    return rows;
  }

  String _cacheKey(String path, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return path;
    final entries = query.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return '$path?${entries.map((entry) => '${entry.key}=${entry.value}').join('&')}';
  }

  bool _isOffline(DioException error) =>
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.sendTimeout;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query}) async {
    final key = _cacheKey(path, query);
    try {
      final response = await _dio.get<T>(path, queryParameters: query);
      _setOffline(false);
      _offlineStore.cache(key, response.data);
      if (hasPendingSync) unawaited(syncPending());
      return response;
    } on DioException catch (error) {
      if (!_isOffline(error)) rethrow;
      _setOffline(true);
      final cached = _offlineStore.read(key);
      if (cached == null) rethrow;
      return Response<T>(
        requestOptions: error.requestOptions,
        data: cached as T,
        extra: const {'offline': true},
      );
    }
  }

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _write<T>('POST', path, data);

  Future<Response<T>> patch<T>(String path, {Object? data}) =>
      _write<T>('PATCH', path, data);

  Future<void> delete(String path) async {
    await _write<void>('DELETE', path, null);
  }

  Future<Response<T>> _write<T>(
    String method,
    String path,
    Object? data,
  ) async {
    final payload = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    if (method == 'POST') payload.putIfAbsent('id', OfflineStore.newUuid);
    try {
      final response = await _dio.request<T>(
        path,
        data: data is Map ? payload : data,
        options: Options(method: method),
      );
      _setOffline(false);
      final result = response.data is Map
          ? Map<String, dynamic>.from(response.data! as Map)
          : payload;
      _offlineStore.applyMutation(method, path, payload, result);
      if (hasPendingSync) unawaited(syncPending());
      return response;
    } on DioException catch (error) {
      if (!_isOffline(error)) rethrow;
      _setOffline(true);
      if (path.startsWith('users/') || path.startsWith('config/')) rethrow;
      _offlineStore.enqueue(method, path, data is Map ? payload : data);
      notifyListeners();
      final result = <String, dynamic>{
        ...payload,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'created_by': null,
      };
      _offlineStore.applyMutation(method, path, payload, result);
      return Response<T>(
        requestOptions: error.requestOptions,
        data: method == 'DELETE' ? null : result as T,
        statusCode: 202,
        extra: const {'offline': true, 'queued': true},
      );
    }
  }

  Future<void> syncPending() {
    final active = _syncInProgress;
    if (active != null) return active;
    _syncing = true;
    notifyListeners();
    final operation = _performSync().whenComplete(() {
      _syncing = false;
      _syncInProgress = null;
      notifyListeners();
    });
    _syncInProgress = operation;
    return operation;
  }

  Future<void> synchronizeAll() async {
    await syncPending();
    final user = _activeUser;
    if (!_offline && user != null) await _warmOfflineData(user);
  }

  Future<void> _performSync() async {
    for (final request in _offlineStore.queued()) {
      try {
        await _dio.request<dynamic>(
          request.path,
          data: request.data,
          options: Options(method: request.method),
        );
        _setOffline(false);
        _offlineStore.completed(request.id);
        notifyListeners();
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        if (request.method == 'POST' && status == 400) {
          final body = request.data;
          final id = body is Map ? body['id']?.toString() : null;
          if (id != null) {
            try {
              await _dio.get<dynamic>('${request.path}$id/');
              _offlineStore.completed(request.id);
              notifyListeners();
              continue;
            } on DioException {
              // This is a genuine conflict, not an already-uploaded UUID.
            }
          }
        }
        _offlineStore.failed(request.id, error.message ?? error.toString());
        if (_isOffline(error)) _setOffline(true);
        if (_isOffline(error) || error.response?.statusCode == 401) return;
        // Preserve rejected operations for inspection instead of losing data.
        return;
      }
    }
  }

  int get pendingSyncCount => _offlineStore.pendingCount;

  Future<List<int>> download(String path, {Map<String, dynamic>? query}) async {
    final key = 'download:${_cacheKey(path, query)}';
    try {
      final response = await _dio.get<List<int>>(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      );
      _offlineStore.cache(key, base64Encode(response.data!));
      return response.data!;
    } on DioException catch (error) {
      if (!_isOffline(error)) rethrow;
      final cached = _offlineStore.read(key);
      if (cached is! String) rethrow;
      return base64Decode(cached);
    }
  }
}
