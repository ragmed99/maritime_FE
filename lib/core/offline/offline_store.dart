import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

class QueuedRequest {
  const QueuedRequest({
    required this.id,
    required this.method,
    required this.path,
    required this.data,
  });
  final int id;
  final String method;
  final String path;
  final Object? data;
}

class OfflineStore {
  OfflineStore._(this._database);
  final Database _database;
  String _scope = 'anonymous';

  static Future<OfflineStore> open() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    final database = sqlite3.open(
      '${directory.path}${Platform.pathSeparator}tar_fishing_offline.sqlite',
    );
    database.execute('''
      CREATE TABLE IF NOT EXISTS response_cache (
        cache_key TEXT PRIMARY KEY,
        body TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        method TEXT NOT NULL,
        path TEXT NOT NULL,
        body TEXT,
        created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        scope TEXT NOT NULL DEFAULT 'anonymous'
      )
    ''');
    final columns = database
        .select('PRAGMA table_info(sync_queue)')
        .map((row) => row['name'])
        .toSet();
    if (!columns.contains('scope')) {
      database.execute(
        "ALTER TABLE sync_queue ADD COLUMN scope TEXT NOT NULL DEFAULT 'anonymous'",
      );
    }
    return OfflineStore._(database);
  }

  factory OfflineStore.memory() {
    final database = sqlite3.openInMemory();
    database.execute('''
      CREATE TABLE response_cache (
        cache_key TEXT PRIMARY KEY, body TEXT NOT NULL, updated_at TEXT NOT NULL
      )
    ''');
    database.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT, method TEXT NOT NULL,
        path TEXT NOT NULL, body TEXT, created_at TEXT NOT NULL,
        attempts INTEGER NOT NULL DEFAULT 0, last_error TEXT,
        scope TEXT NOT NULL DEFAULT 'anonymous'
      )
    ''');
    return OfflineStore._(database);
  }

  void setScope(Object userId) {
    final next = 'user-$userId';
    if (_scope == next) return;
    _scope = next;
    final legacy = _database.select(
      "SELECT cache_key, body, updated_at FROM response_cache "
      "WHERE cache_key NOT LIKE '%::%' AND cache_key != 'auth/me/'",
    );
    for (final row in legacy) {
      _database.execute(
        '''INSERT OR IGNORE INTO response_cache(cache_key, body, updated_at)
           VALUES (?, ?, ?)''',
        ['$next::${row['cache_key']}', row['body'], row['updated_at']],
      );
    }
    _database.execute(
      "DELETE FROM response_cache WHERE cache_key NOT LIKE '%::%' "
      "AND cache_key != 'auth/me/'",
    );
    _database.execute(
      "UPDATE sync_queue SET scope = ? WHERE scope = 'anonymous'",
      [next],
    );
  }

  String _scoped(String key) => key == 'auth/me/' ? key : '$_scope::$key';

  Object? read(String key) {
    final rows = _database.select(
      'SELECT body FROM response_cache WHERE cache_key = ?',
      [_scoped(key)],
    );
    return rows.isEmpty ? null : jsonDecode(rows.first['body'] as String);
  }

  void cache(String key, Object? body) {
    if (body == null) return;
    _database.execute(
      '''INSERT OR REPLACE INTO response_cache(cache_key, body, updated_at)
         VALUES (?, ?, ?)''',
      [
        _scoped(key),
        jsonEncode(body),
        DateTime.now().toUtc().toIso8601String(),
      ],
    );
  }

  void enqueue(String method, String path, Object? body) {
    _database.execute(
      '''INSERT INTO sync_queue(method, path, body, created_at, scope)
         VALUES (?, ?, ?, ?, ?)''',
      [
        method,
        path,
        body == null ? null : jsonEncode(body),
        DateTime.now().toUtc().toIso8601String(),
        _scope,
      ],
    );
  }

  List<QueuedRequest> queued() => _database
      .select(
        'SELECT id, method, path, body FROM sync_queue WHERE scope = ? ORDER BY id',
        [_scope],
      )
      .map(
        (row) => QueuedRequest(
          id: row['id'] as int,
          method: row['method'] as String,
          path: row['path'] as String,
          data: row['body'] == null ? null : jsonDecode(row['body'] as String),
        ),
      )
      .toList();

  void completed(int id) =>
      _database.execute('DELETE FROM sync_queue WHERE id = ?', [id]);

  void failed(int id, String error) => _database.execute(
    'UPDATE sync_queue SET attempts = attempts + 1, last_error = ? WHERE id = ?',
    [error, id],
  );

  int get pendingCount =>
      (_database.select(
            'SELECT COUNT(*) AS count FROM sync_queue WHERE scope = ?',
            [_scope],
          ).first['count']
          as int);

  static String newUuid() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final value = bytes.map(hex).join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }

  void applyMutation(
    String method,
    String path,
    Map<String, dynamic> payload,
    Map<String, dynamic> result,
  ) {
    final cleanPath = Uri.parse(path).path.replaceFirst(RegExp(r'^/api/'), '');
    final segments = cleanPath
        .split('/')
        .where((part) => part.isNotEmpty)
        .toList();
    if (segments.isEmpty) return;
    final resource = segments.first;
    final id = (result['id'] ?? (segments.length > 1 ? segments[1] : null))
        ?.toString();
    final rows = _database.select(
      'SELECT cache_key, body FROM response_cache WHERE cache_key LIKE ?',
      ['$_scope::%'],
    );
    for (final row in rows) {
      final key = row['cache_key'] as String;
      final decoded = jsonDecode(row['body'] as String);
      var changed = false;
      if (method == 'POST' &&
          _isResourceList(key, resource) &&
          (resource != 'transactions' ||
              _matchesTransactionFilter(key, payload))) {
        changed = _prepend(decoded, result);
      } else if (id != null && (method == 'PATCH' || method == 'DELETE')) {
        changed = _changeById(decoded, id, payload, delete: method == 'DELETE');
      }
      if (resource == 'transactions' && method == 'POST') {
        final clientId = payload['client']?.toString();
        if (clientId != null && key.contains('clients/$clientId/statement/')) {
          final statementRows = decoded is Map<String, dynamic>
              ? decoded['transactions']
              : null;
          final createdAt =
              (result['created_at'] ?? DateTime.now().toUtc().toIso8601String())
                  .toString();
          changed =
              _prepend(statementRows, {
                ...result,
                'date': payload['transaction_date'],
                'time': createdAt.contains('T')
                    ? createdAt.split('T').last.substring(0, 5)
                    : '00:00',
                'ship': payload['ship'] == null
                    ? null
                    : {
                        'id': payload['ship'],
                        'name': _cachedName(
                          'ships',
                          payload['ship']?.toString(),
                        ),
                      },
                'trip': payload['trip'] == null
                    ? null
                    : {
                        'id': payload['trip'],
                        'departure_date': _cachedTripDate(
                          payload['trip']?.toString(),
                        ),
                      },
              }) ||
              changed;
        }
        final tripId = payload['trip']?.toString();
        if (tripId != null && key.contains('trips/$tripId/purchases/')) {
          changed =
              _prepend(decoded, {
                'id': result['id'],
                'description': payload['description'] ?? '',
                'quantity': payload['quantity'],
                'date': payload['transaction_date'],
                'client': {
                  'id': clientId,
                  'name': _cachedName('clients', clientId) ?? '—',
                },
              }) ||
              changed;
        }
      }
      if (changed) cache(key.split('::').last, decoded);
    }
    if (method == 'POST') _seedCreatedResource(resource, result);
    if (resource == 'transactions') _recalculateDerivedCaches();
  }

  void _seedCreatedResource(String resource, Map<String, dynamic> result) {
    final id = result['id']?.toString();
    if (id == null) return;
    const zeroBalance = {
      'they_owe_us': '0.00',
      'we_owe_them': '0.00',
      'balance': '0.00',
    };
    if (resource == 'clients') {
      cache('clients/$id/balance/', {...zeroBalance, 'client_id': id});
      cache('clients/$id/statement/', {
        'subject': result,
        'summary': {
          'total_purchases': '0.00',
          'total_payments': '0.00',
          'current_balance': '0.00',
        },
        'transactions': {'count': 0, 'next': null, 'results': <dynamic>[]},
      });
    } else if (resource == 'owners') {
      cache('owners/$id/balance/', {...zeroBalance, 'owner_id': id});
    } else if (resource == 'partners') {
      cache('partners/$id/balance/', {...zeroBalance, 'partner_id': id});
    } else if (resource == 'ships') {
      cache('ships/$id/financials/', {
        'ship_id': id,
        'total_revenue': '0.00',
        'total_expenses': '0.00',
        'profit': '0.00',
        'has_unpriced_purchases': false,
      });
    } else if (resource == 'trips') {
      cache('trips/$id/financials/', {
        'trip_id': id,
        'revenue': '0.00',
        'expenses': '0.00',
        'remaining': '0.00',
        'profit': '0.00',
        'has_unpriced_purchases': false,
      });
      cache('trips/$id/purchases/', <dynamic>[]);
    }
  }

  void _recalculateDerivedCaches() {
    final transactions = <String, Map<String, dynamic>>{};
    for (final row in _database.select(
      'SELECT cache_key, body FROM response_cache WHERE cache_key LIKE ?',
      ['$_scope::%transactions/%'],
    )) {
      final rawKey = (row['cache_key'] as String).split('::').last;
      final uri = Uri.parse(rawKey);
      if (!uri.path.endsWith('transactions/') ||
          uri.queryParameters.keys.any((key) => key != 'page')) {
        continue;
      }
      final decoded = jsonDecode(row['body'] as String);
      final items = decoded is Map ? decoded['results'] : decoded;
      if (items is! List) continue;
      for (final item in items.whereType<Map>()) {
        final value = Map<String, dynamic>.from(item);
        final id = value['id']?.toString();
        if (id != null) transactions[id] = value;
      }
    }

    double amount(Map<String, dynamic> row) =>
        double.tryParse('${row['amount'] ?? 0}') ?? 0;
    Iterable<Map<String, dynamic>> forField(String field, String id) =>
        transactions.values.where((row) => '${row[field]}' == id);
    void balance(String path, String entityKey, String id, double value) {
      cache(path, {
        entityKey: id,
        'they_owe_us': value > 0 ? value.toStringAsFixed(2) : '0.00',
        'we_owe_them': value < 0 ? (-value).toStringAsFixed(2) : '0.00',
        'balance': value.toStringAsFixed(2),
      });
    }

    for (final client in _cachedResourceItems('clients')) {
      final id = client['id']?.toString();
      if (id == null) continue;
      var value = 0.0;
      for (final row in forField('client', id)) {
        value += row['transaction_type'] == 'CLIENT_PURCHASE'
            ? amount(row)
            : row['transaction_type'] == 'CLIENT_PAYMENT'
            ? -amount(row)
            : 0;
      }
      balance('clients/$id/balance/', 'client_id', id, value);
    }
    for (final partner in _cachedResourceItems('partners')) {
      final id = partner['id']?.toString();
      if (id == null) continue;
      var value = 0.0;
      for (final row in forField('partner', id)) {
        value +=
            const {
              'PARTNER_LOAN_GIVEN',
              'PARTNER_REPAYMENT_PAID',
            }.contains(row['transaction_type'])
            ? amount(row)
            : const {
                'PARTNER_LOAN_RECEIVED',
                'PARTNER_REPAYMENT_RECEIVED',
              }.contains(row['transaction_type'])
            ? -amount(row)
            : 0;
      }
      balance('partners/$id/balance/', 'partner_id', id, value);
    }

    final ships = _cachedResourceItems('ships');
    final trips = _cachedResourceItems('trips');
    for (final ship in ships) {
      final id = ship['id']?.toString();
      if (id == null) continue;
      final rows = forField('ship', id);
      final revenue = rows
          .where((row) => row['transaction_type'] == 'CLIENT_PURCHASE')
          .fold<double>(0, (sum, row) => sum + amount(row));
      final expenses = rows
          .where((row) => row['transaction_type'] == 'SHIP_EXPENSE')
          .fold<double>(0, (sum, row) => sum + amount(row));
      final unpriced = rows.any(
        (row) =>
            row['transaction_type'] == 'CLIENT_PURCHASE' &&
            row['unit_price'] == null,
      );
      cache('ships/$id/financials/', {
        'ship_id': id,
        'total_revenue': revenue.toStringAsFixed(2),
        'total_expenses': expenses.toStringAsFixed(2),
        'profit': (revenue - expenses).toStringAsFixed(2),
        'has_unpriced_purchases': unpriced,
      });
    }
    for (final trip in trips) {
      final id = trip['id']?.toString();
      if (id == null) continue;
      final rows = forField('trip', id);
      final revenue = rows
          .where((row) => row['transaction_type'] == 'CLIENT_PURCHASE')
          .fold<double>(0, (sum, row) => sum + amount(row));
      final expenses = rows
          .where((row) => row['transaction_type'] == 'SHIP_EXPENSE')
          .fold<double>(0, (sum, row) => sum + amount(row));
      final remaining = revenue - expenses;
      cache('trips/$id/financials/', {
        'trip_id': id,
        'revenue': revenue.toStringAsFixed(2),
        'expenses': expenses.toStringAsFixed(2),
        'remaining': remaining.toStringAsFixed(2),
        'profit': remaining.toStringAsFixed(2),
        'has_unpriced_purchases': rows.any(
          (row) =>
              row['transaction_type'] == 'CLIENT_PURCHASE' &&
              row['unit_price'] == null,
        ),
      });
    }
    for (final owner in _cachedResourceItems('owners')) {
      final id = owner['id']?.toString();
      if (id == null) continue;
      final shipIds = ships
          .where((ship) => '${ship['owner']}' == id)
          .map((ship) => '${ship['id']}')
          .toSet();
      var value = 0.0;
      for (final row in transactions.values) {
        if ('${row['owner']}' == id) {
          value += row['transaction_type'] == 'OWNER_DEPOSIT'
              ? amount(row)
              : row['transaction_type'] == 'OWNER_WITHDRAWAL'
              ? -amount(row)
              : 0;
        } else if (shipIds.contains('${row['ship']}') &&
            row['transaction_type'] == 'CLIENT_PURCHASE') {
          value += amount(row);
        }
      }
      // Owner balances use the opposite direction from clients and partners.
      cache('owners/$id/balance/', {
        'owner_id': id,
        'they_owe_us': value < 0 ? (-value).toStringAsFixed(2) : '0.00',
        'we_owe_them': value > 0 ? value.toStringAsFixed(2) : '0.00',
        'balance': value.toStringAsFixed(2),
      });
    }
  }

  List<Map<String, dynamic>> _cachedResourceItems(String resource) {
    final result = <String, Map<String, dynamic>>{};
    final rows = _database.select(
      'SELECT cache_key, body FROM response_cache WHERE cache_key LIKE ?',
      ['$_scope::%$resource/%'],
    );
    for (final row in rows) {
      final rawKey = (row['cache_key'] as String).split('::').last;
      final uri = Uri.parse(rawKey);
      if (!uri.path.endsWith('$resource/') ||
          uri.queryParameters.keys.any((key) => key != 'page')) {
        continue;
      }
      final decoded = jsonDecode(row['body'] as String);
      final items = decoded is Map ? decoded['results'] : decoded;
      if (items is! List) continue;
      for (final item in items.whereType<Map>()) {
        final value = Map<String, dynamic>.from(item);
        final id = value['id']?.toString();
        if (id != null) result[id] = value;
      }
    }
    return result.values.toList();
  }

  bool _isResourceList(String key, String resource) {
    final path = key.split('::').last.split('?').first;
    return path == '$resource/' || path.endsWith('/$resource/');
  }

  bool _matchesTransactionFilter(
    String scopedKey,
    Map<String, dynamic> payload,
  ) {
    final raw = scopedKey.split('::').last;
    final uri = Uri.parse(raw);
    final query = uri.queryParameters;
    bool matches(String parameter, String payloadKey) =>
        query[parameter] == null ||
        query[parameter] == payload[payloadKey]?.toString();
    return matches('owner_account', 'owner') &&
        matches('owner', 'owner') &&
        matches('partner', 'partner') &&
        matches('client', 'client') &&
        matches('ship', 'ship') &&
        matches('trip', 'trip') &&
        matches('transaction_type', 'transaction_type');
  }

  bool _prepend(Object? value, Map<String, dynamic> item) {
    if (value is List) {
      value.insert(0, item);
      return true;
    }
    if (value is Map<String, dynamic> && value['results'] is List) {
      (value['results'] as List).insert(0, item);
      if (value['count'] is int) value['count'] = (value['count'] as int) + 1;
      return true;
    }
    return false;
  }

  bool _changeById(
    Object? value,
    String id,
    Map<String, dynamic> payload, {
    required bool delete,
  }) {
    var changed = false;
    void visit(Object? node) {
      if (node is List) {
        final before = node.length;
        if (delete) {
          node.removeWhere((item) => item is Map && '${item['id']}' == id);
        }
        changed = changed || before != node.length;
        for (final item in node) {
          visit(item);
        }
      } else if (node is Map<String, dynamic>) {
        if ('${node['id']}' == id && !delete) {
          for (final entry in payload.entries) {
            if (entry.key == 'client' && node[entry.key] is Map) {
              node[entry.key] = {
                'id': entry.value,
                'name': _cachedName('clients', '${entry.value}') ?? '—',
              };
              continue;
            }
            node[entry.key] = entry.value;
          }
          if (payload.containsKey('transaction_date') &&
              node.containsKey('date')) {
            node['date'] = payload['transaction_date'];
          }
          changed = true;
        }
        for (final child in node.values.toList()) {
          visit(child);
        }
      }
    }

    visit(value);
    return changed;
  }

  String? _cachedName(String resource, String? id) {
    if (id == null) return null;
    final rows = _database.select(
      'SELECT body FROM response_cache WHERE cache_key LIKE ?',
      ['$_scope::$resource/%'],
    );
    for (final row in rows) {
      final decoded = jsonDecode(row['body'] as String);
      final list = decoded is Map ? decoded['results'] : decoded;
      if (list is List) {
        for (final item in list.whereType<Map>()) {
          if ('${item['id']}' == id) return item['name']?.toString();
        }
      }
    }
    return null;
  }

  String? _cachedTripDate(String? id) {
    if (id == null) return null;
    final rows = _database.select(
      'SELECT body FROM response_cache WHERE cache_key LIKE ?',
      ['$_scope::trips/%'],
    );
    for (final row in rows) {
      final decoded = jsonDecode(row['body'] as String);
      final list = decoded is Map ? decoded['results'] : decoded;
      if (list is List) {
        for (final item in list.whereType<Map>()) {
          if ('${item['id']}' == id) return item['departure_date']?.toString();
        }
      }
    }
    return null;
  }
}
