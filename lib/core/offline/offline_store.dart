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
      if (method == 'POST' && _isResourceList(key, resource)) {
        changed = _prepend(decoded, result);
      } else if (id != null && (method == 'PATCH' || method == 'DELETE')) {
        changed = _changeById(decoded, id, payload, delete: method == 'DELETE');
      }
      if (resource == 'transactions' && method == 'POST') {
        final tripId = payload['trip']?.toString();
        if (tripId != null && key.contains('trips/$tripId/purchases/')) {
          final clientId = payload['client']?.toString();
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
  }

  bool _isResourceList(String key, String resource) {
    final path = key.split('::').last.split('?').first;
    return path == '$resource/' || path.endsWith('/$resource/');
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
}
