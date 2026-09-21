import 'package:flutter/foundation.dart';

import '../data/ships_repository.dart';
import '../domain/ship_models.dart';

enum LoadStatus { idle, loading, loaded, error }

class ShipsController extends ChangeNotifier {
  ShipsController(this.repository);
  final ShipsRepository repository;
  LoadStatus status = LoadStatus.idle;
  List<ShipRecord> ships = [];
  List<OwnerOption> owners = [];
  String query = '';

  List<ShipRecord> get filteredShips => ships
      .where((ship) => ship.name.toLowerCase().contains(query.toLowerCase()))
      .toList();

  Financials get overallFinancials => Financials(
    revenue: ships.fold(0, (sum, ship) => sum + ship.financials.revenue),
    expenses: ships.fold(0, (sum, ship) => sum + ship.financials.expenses),
    profit: ships.fold(0, (sum, ship) => sum + ship.financials.profit),
  );

  Future<void> load() async {
    status = LoadStatus.loading;
    notifyListeners();
    try {
      final data = await Future.wait([repository.ships(), repository.owners()]);
      ships = data[0] as List<ShipRecord>;
      owners = data[1] as List<OwnerOption>;
      status = LoadStatus.loaded;
    } catch (_) {
      status = LoadStatus.error;
    }
    notifyListeners();
  }

  void search(String value) {
    query = value;
    notifyListeners();
  }

  Future<void> refreshOwners() async {
    owners = await repository.owners();
    notifyListeners();
  }

  Future<bool> saveShip({
    String? id,
    required String name,
    required String ownerId,
  }) =>
      _mutate(() => repository.saveShip(id: id, name: name, ownerId: ownerId));
  Future<bool> deleteShip(String id) =>
      _mutate(() => repository.deleteShip(id));

  Future<bool> _mutate(Future<void> Function() action) async {
    try {
      await action();
      await load();
      return true;
    } catch (_) {
      status = LoadStatus.error;
      notifyListeners();
      return false;
    }
  }
}
