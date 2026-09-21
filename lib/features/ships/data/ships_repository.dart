import 'dart:typed_data';

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

  Future<OwnerOption> createOwner({
    required String name,
    required String phone,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      'owners/',
      data: {'name': name, 'phone': phone},
    );
    return OwnerOption.fromJson(response.data!);
  }

  Future<List<ClientOption>> clients() async =>
      (await _rows('clients/')).map(ClientOption.fromJson).toList();

  Future<ClientOption> createClient(String name) async {
    final response = await _api.post<Map<String, dynamic>>(
      'clients/',
      data: {'name': name, 'phone': ''},
    );
    return ClientOption.fromJson(response.data!);
  }

  Future<List<ShipRecord>> ships() async {
    final results = await Future.wait([_rows('ships/'), _rows('owners/')]);
    final ownerNames = {
      for (final row in results[1]) row['id'] as String: row['name'] as String,
    };
    final records = results[0]
        .map((row) => ShipRecord.fromJson(row, ownerNames[row['owner']] ?? ''))
        .toList();
    return Future.wait(
      records.map((ship) async {
        final financials = await shipFinancials(ship.id);
        return ShipRecord(
          id: ship.id,
          name: ship.name,
          ownerId: ship.ownerId,
          ownerName: ship.ownerName,
          financials: financials,
        );
      }),
    );
  }

  Future<List<ShipRecord>> pointeurShips() async => (await _rows('ships/'))
      .map(
        (row) => ShipRecord.fromJson(row, row['owner_name'] as String? ?? ''),
      )
      .toList();

  Future<List<TripRecord>> pointeurTrips(String shipId) async =>
      (await _rows('trips/'))
          .where((row) => row['ship'] == shipId)
          .map((row) => TripRecord.fromJson(row))
          .toList();

  Future<List<PointeurPurchase>> pointeurPurchases(String tripId) async {
    final response = await _api.get<List<dynamic>>('trips/$tripId/purchases/');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(PointeurPurchase.fromJson)
        .toList();
  }

  Future<Financials> shipFinancials(String shipId) async => Financials.ship(
    (await _api.get<Map<String, dynamic>>('ships/$shipId/financials/')).data!,
  );

  Future<Financials> tripFinancials(String tripId) async => Financials.trip(
    (await _api.get<Map<String, dynamic>>('trips/$tripId/financials/')).data!,
  );

  Future<Uint8List> tripDetailsPdf(String tripId, String language) async =>
      Uint8List.fromList(
        await _api.download(
          'trips/$tripId/details/pdf/',
          query: {'lang': language},
        ),
      );

  Future<void> saveShip({
    String? id,
    required String name,
    required String ownerId,
  }) async {
    final data = <String, dynamic>{'name': name, 'owner': ownerId};
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
  }) async {
    final data = <String, dynamic>{
      'ship': shipId,
      'departure_date': _date(departureDate),
    };
    if (id == null) {
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
    double? quantity,
    double? unitPrice,
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
        if (quantity != null) 'quantity': quantity.toStringAsFixed(2),
        if (unitPrice != null) 'unit_price': unitPrice.toStringAsFixed(2),
      },
    );
  }

  Future<void> addPendingPurchase({
    required String shipId,
    required String tripId,
    required String clientId,
    required String description,
    required double quantity,
    required DateTime date,
  }) => addTransaction(
    type: 'CLIENT_PURCHASE',
    shipId: shipId,
    tripId: tripId,
    clientId: clientId,
    description: description,
    quantity: quantity,
    amount: 0,
    date: date,
  );

  Future<void> updatePendingPurchase({
    required String transactionId,
    required String clientId,
    required String description,
    required double quantity,
  }) => _api.patch(
    'transactions/$transactionId/',
    data: {
      'client': clientId,
      'description': description,
      'quantity': quantity.toStringAsFixed(2),
    },
  );

  Future<void> setPurchaseUnitPrice(String transactionId, double unitPrice) =>
      _api.patch(
        'transactions/$transactionId/',
        data: {'unit_price': unitPrice.toStringAsFixed(2)},
      );

  Future<void> updatePurchase(
    String id, {
    required double quantity,
    required double unitPrice,
    required String description,
  }) => _api.patch(
    'transactions/$id/',
    data: {
      'description': description,
      'quantity': quantity.toStringAsFixed(2),
      'unit_price': unitPrice.toStringAsFixed(2),
    },
  );

  Future<void> deleteTransaction(String id) => _api.delete('transactions/$id/');

  String _date(DateTime value) => value.toIso8601String().split('T').first;
}
