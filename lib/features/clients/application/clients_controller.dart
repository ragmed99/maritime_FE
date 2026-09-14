import 'package:flutter/foundation.dart';

import '../data/clients_repository.dart';
import '../domain/client_models.dart';

enum ClientsStatus { idle, loading, loaded, error }

class ClientsController extends ChangeNotifier {
  ClientsController(this.repository);
  final ClientsRepository repository;
  ClientsStatus status = ClientsStatus.idle;
  List<ClientRecord> clients = [];
  String query = '';
  List<ClientRecord> get filtered => clients
      .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
      .toList();

  Future<void> load() async {
    status = ClientsStatus.loading;
    notifyListeners();
    try {
      clients = await repository.clients();
      status = ClientsStatus.loaded;
    } catch (_) {
      status = ClientsStatus.error;
    }
    notifyListeners();
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  Future<void> save({
    ClientRecord? client,
    required String name,
    required String phone,
  }) async {
    await repository.saveClient(id: client?.id, name: name, phone: phone);
    await load();
  }

  Future<void> delete(String id) async {
    await repository.deleteClient(id);
    await load();
  }
}
