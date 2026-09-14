import 'package:flutter/foundation.dart';
import '../data/partners_repository.dart';
import '../domain/partner_models.dart';

enum PartnersStatus { idle, loading, loaded, error }

class PartnersController extends ChangeNotifier {
  PartnersController(this.repository);
  final PartnersRepository repository;
  PartnersStatus status = PartnersStatus.idle;
  List<PartnerRecord> partners = [];
  String query = '';
  List<PartnerRecord> get filtered => partners
      .where((item) => item.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
  Future<void> load() async {
    status = PartnersStatus.loading;
    notifyListeners();
    try {
      partners = await repository.partners();
      status = PartnersStatus.loaded;
    } catch (_) {
      status = PartnersStatus.error;
    }
    notifyListeners();
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  Future<void> save({
    PartnerRecord? partner,
    required String name,
    required String phone,
  }) async {
    await repository.savePartner(id: partner?.id, name: name, phone: phone);
    await load();
  }

  Future<void> delete(String id) async {
    await repository.deletePartner(id);
    await load();
  }
}
