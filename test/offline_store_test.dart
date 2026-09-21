import 'package:flutter_test/flutter_test.dart';
import 'package:maritime_frontend/core/offline/offline_store.dart';

void main() {
  test('offline store persists cached responses and queued writes', () {
    final store = OfflineStore.memory();
    store.cache('clients/', {
      'count': 1,
      'results': [
        {'id': 'one', 'name': 'Existing'},
      ],
    });

    store.enqueue('POST', 'clients/', {'id': 'two', 'name': 'Offline'});
    store.applyMutation(
      'POST',
      'clients/',
      {'id': 'two', 'name': 'Offline'},
      {'id': 'two', 'name': 'Offline'},
    );

    final cached = store.read('clients/')! as Map<String, dynamic>;
    expect(store.pendingCount, 1);
    expect((cached['results'] as List).first['name'], 'Offline');
    expect(store.queued().single.path, 'clients/');

    store.completed(store.queued().single.id);
    expect(store.pendingCount, 0);
  });

  test('offline UUIDs are valid and unique', () {
    final first = OfflineStore.newUuid();
    final second = OfflineStore.newUuid();
    expect(first, isNot(second));
    expect(
      first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test('cached data and queued writes are isolated per account', () {
    final store = OfflineStore.memory();
    store.setScope(1);
    store.cache('clients/', {'results': <dynamic>[]});
    store.enqueue('POST', 'clients/', {'name': 'First account'});

    store.setScope(2);
    expect(store.read('clients/'), isNull);
    expect(store.pendingCount, 0);
    store.cache('clients/', {
      'results': [
        {'name': 'Second account'},
      ],
    });

    store.setScope(1);
    expect(store.pendingCount, 1);
    final cached = store.read('clients/')! as Map<String, dynamic>;
    expect(cached['results'], isEmpty);
  });
}
