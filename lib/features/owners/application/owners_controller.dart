import 'package:flutter/foundation.dart';
import '../data/owners_repository.dart';
import '../domain/owner_models.dart';

enum OwnersStatus { idle, loading, loaded, error }

class OwnersController extends ChangeNotifier {
  OwnersController(this.repository);
  final OwnersRepository repository;
  OwnersStatus status = OwnersStatus.idle;
  List<OwnerRecord> owners = [];
  String query = '';
  List<OwnerRecord> get filtered => owners
      .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
  Future<void> load() async {
    status = OwnersStatus.loading;
    notifyListeners();
    try {
      owners = await repository.owners();
      status = OwnersStatus.loaded;
    } catch (_) {
      status = OwnersStatus.error;
    }
    notifyListeners();
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  Future<void> save({
    OwnerRecord? owner,
    required String name,
    required String phone,
  }) async {
    await repository.saveOwner(id: owner?.id, name: name, phone: phone);
    await load();
  }

  Future<void> delete(String id) async {
    await repository.deleteOwner(id);
    await load();
  }
}
