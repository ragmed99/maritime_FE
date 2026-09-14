import '../../../core/network/api_client.dart';
import '../domain/transaction_models.dart';

class TransactionsRepository {
  TransactionsRepository(this._api);
  final ApiClient _api;

  Future<TransactionPage> page(TransactionFilters filters, int page) async {
    final data = (await _api.get<Map<String, dynamic>>(
      'transactions/',
      query: filters.toQuery(page),
    )).data!;
    return TransactionPage(
      rows: (data['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(LedgerTransaction.fromJson)
          .toList(),
      hasMore: data['next'] != null,
    );
  }

  Future<List<Map<String, dynamic>>> _all(String path) async {
    final rows = <Map<String, dynamic>>[];
    String? next = path;
    while (next != null) {
      final data = (await _api.get<Map<String, dynamic>>(next)).data!;
      rows.addAll((data['results'] as List).cast<Map<String, dynamic>>());
      next = data['next'] as String?;
    }
    return rows;
  }

  Future<TransactionLookups> lookups() async {
    final values = await Future.wait([
      _all('ships/'),
      _all('trips/'),
      _all('clients/'),
      _all('partners/'),
      _all('owners/'),
    ]);
    List<LookupOption> named(List<Map<String, dynamic>> rows) => rows
        .map((row) => LookupOption(row['id'] as String, row['name'] as String))
        .toList();
    return TransactionLookups(
      ships: named(values[0]),
      trips: values[1]
          .map(
            (row) => LookupOption(
              row['id'] as String,
              row['departure_date'] as String,
              parentId: row['ship'] as String,
            ),
          )
          .toList(),
      clients: named(values[2]),
      partners: named(values[3]),
      owners: named(values[4]),
    );
  }

  Future<void> update(
    LedgerTransaction row, {
    required double amount,
    required DateTime date,
    required String description,
    required String reference,
  }) => _api.patch(
    'transactions/${row.id}/',
    data: {
      'amount': amount.toStringAsFixed(2),
      'transaction_date': date.toIso8601String().split('T').first,
      'description': description,
      'reference': reference,
    },
  );

  Future<void> delete(String id) => _api.delete('transactions/$id/');
}
