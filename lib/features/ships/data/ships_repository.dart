import '../../../core/network/api_client.dart';
import '../domain/ship_models.dart';

class ShipsRepository {
  ShipsRepository(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> _rows(String path) async {
    final rows = <Map<String, dynamic>>[];
    String? next = path;
    while (next != null) {
      final page = (await _api.get<Map<String, dynamic>>(next)).data!;
      rows.addAll(apiResults(page));
      next = page['next'] as String?;
    }
    return rows;
  }

  Future<List<OwnerOption>> owners() async =>
      (await _rows('owners/')).map(OwnerOption.fromJson).toList();

  Future<List<ClientOption>> clients() async =>
      (await _rows('clients/')).map(ClientOption.fromJson).toList();

  Future<List<ShipRecord>> ships() async {
    final results = await Future.wait([_rows('ships/'), _rows('owners/')]);
    final ownerNames = {
      for (final row in results[1]) row['id'] as String: row['name'] as String,
    };
    return results[0]
        .map((row) => ShipRecord.fromJson(row, ownerNames[row['owner']] ?? ''))
        .toList();
  }

  Future<Financials> shipFinancials(String shipId) async => Financials.ship(
    (await _api.get<Map<String, dynamic>>('ships/$shipId/financials/')).data!,
  );

  Future<Financials> tripFinancials(String tripId) async => Financials.trip(
    (await _api.get<Map<String, dynamic>>('trips/$tripId/financials/')).data!,
  );

  Future<void> saveShip({
    String? id,
    required String name,
    required String registrationNumber,
    required String ownerId,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'registration_number': registrationNumber,
      'owner': ownerId,
    };
    if (id == null) {
      await _api.post('ships/', data: data);
    } else {
      await _api.patch('ships/$id/', data: data);
    }
  }

  Future<void> deleteShip(String id) => _api.delete('ships/$id/');

  Future<List<TripRecord>> trips(String shipId) async {
    final rows = (await _rows(
      'trips/',
    )).where((row) => row['ship'] == shipId).toList();
    return Future.wait(
      rows.map((row) async {
        final id = row['id'] as String;
        final financials = await tripFinancials(id);
        return TripRecord.fromJson(row, financials: financials);
      }),
    );
  }

  Future<void> saveTrip({
    String? id,
    required String shipId,
    required DateTime departureDate,
    List<TripFinancialEntry> expenses = const [],
    List<TripFinancialEntry> revenues = const [],
  }) async {
    final data = <String, dynamic>{
      'ship': shipId,
      'departure_date': _date(departureDate),
    };
    if (id == null) {
      data['expenses'] = expenses.map((entry) => entry.toJson()).toList();
      data['revenues'] = revenues.map((entry) => entry.toJson()).toList();
      await _api.post('trips/', data: data);
    } else {
      await _api.patch('trips/$id/', data: data);
    }
  }

  Future<void> deleteTrip(String id) => _api.delete('trips/$id/');

  Future<List<TripTransaction>> transactions(String tripId) async {
    final results = await Future.wait([
      _rows('transactions/'),
      _rows('clients/'),
    ]);
    final names = {
      for (final row in results[1]) row['id'] as String: row['name'] as String,
    };
    return results[0]
        .where((row) => row['trip'] == tripId)
        .map((row) => TripTransaction.fromJson(row, names[row['client']]))
        .toList();
  }

  Future<void> addTransaction({
    required String type,
    required String shipId,
    required String tripId,
    required double amount,
    required DateTime date,
    required String description,
    String? clientId,
  }) async {
    await _api.post(
      'transactions/',
      data: {
        'transaction_type': type,
        'ship': shipId,
        'trip': tripId,
        'client': clientId,
        'amount': amount.toStringAsFixed(2),
        'transaction_date': _date(date),
        'description': description,
      },
    );
  }

  String _date(DateTime value) => value.toIso8601String().split('T').first;
}
