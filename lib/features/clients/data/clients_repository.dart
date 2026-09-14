import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../domain/client_models.dart';

class ClientsRepository {
  ClientsRepository(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> _rows(String path) async {
    final rows = <Map<String, dynamic>>[];
    String? next = path;
    while (next != null) {
      final page = (await _api.get<Map<String, dynamic>>(next)).data!;
      rows.addAll(
        (page['results'] as List<dynamic>).cast<Map<String, dynamic>>(),
      );
      next = page['next'] as String?;
    }
    return rows;
  }

  Future<List<ClientRecord>> clients() async =>
      (await _rows('clients/')).map(ClientRecord.fromJson).toList();

  Future<void> saveClient({
    String? id,
    required String name,
    required String phone,
  }) async {
    final data = {'name': name, 'phone': phone};
    if (id == null) {
      await _api.post('clients/', data: data);
    } else {
      await _api.patch('clients/$id/', data: data);
    }
  }

  Future<void> deleteClient(String id) => _api.delete('clients/$id/');

  Future<ClientStatementData> statement(
    String clientId,
    ClientFilters filters,
  ) async {
    final balance = await _api.get<Map<String, dynamic>>(
      'clients/$clientId/balance/',
    );
    final transactions = <ClientTransactionRow>[];
    String? next = 'clients/$clientId/statement/';
    var firstPage = true;
    while (next != null) {
      final statement = (await _api.get<Map<String, dynamic>>(
        next,
        query: firstPage ? filters.toQuery() : null,
      )).data!;
      final page = statement['transactions'] as Map<String, dynamic>;
      transactions.addAll(
        (page['results'] as List<dynamic>).cast<Map<String, dynamic>>().map(
          ClientTransactionRow.fromJson,
        ),
      );
      next = page['next'] as String?;
      firstPage = false;
    }
    return ClientStatementData(
      currentBalance: double.parse(balance.data!['balance'].toString()),
      transactions: transactions,
    );
  }

  Future<List<RelationOption>> ships() async => (await _rows('ships/'))
      .map(
        (row) => RelationOption(
          id: row['id'] as String,
          name: row['name'] as String,
        ),
      )
      .toList();

  Future<Map<String, List<RelationOption>>> tripsByShip() async {
    final result = <String, List<RelationOption>>{};
    for (final row in await _rows('trips/')) {
      result
          .putIfAbsent(row['ship'] as String, () => [])
          .add(
            RelationOption(
              id: row['id'] as String,
              name: row['departure_date'] as String,
            ),
          );
    }
    return result;
  }

  Future<void> addTransaction({
    required String clientId,
    required String type,
    required double amount,
    required DateTime date,
    required String description,
    String? shipId,
    String? tripId,
  }) => _api.post(
    'transactions/',
    data: {
      'client': clientId,
      'transaction_type': type,
      'amount': amount.toStringAsFixed(2),
      'transaction_date': formatApiDate(date),
      'description': description,
      if (type == 'CLIENT_PURCHASE') 'ship': shipId,
      if (type == 'CLIENT_PURCHASE') 'trip': tripId,
    },
  );

  Future<Uint8List> statementPdf(
    String clientId,
    ClientFilters filters,
  ) async => Uint8List.fromList(
    await _api.download(
      'clients/$clientId/statement/pdf/',
      query: filters.toQuery(),
    ),
  );
}
