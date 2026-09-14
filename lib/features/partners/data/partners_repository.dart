import '../../../core/network/api_client.dart';
import '../domain/partner_models.dart';

class PartnersRepository {
  PartnersRepository(this._api);
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

  Future<List<PartnerRecord>> partners() async =>
      (await _rows('partners/')).map(PartnerRecord.fromJson).toList();
  Future<void> savePartner({
    String? id,
    required String name,
    required String phone,
  }) async {
    final data = {'name': name, 'phone': phone};
    if (id == null) {
      await _api.post('partners/', data: data);
    } else {
      await _api.patch('partners/$id/', data: data);
    }
  }

  Future<void> deletePartner(String id) => _api.delete('partners/$id/');
  Future<double> balance(String id) async => double.parse(
    (await _api.get<Map<String, dynamic>>(
      'partners/$id/balance/',
    )).data!['balance'].toString(),
  );
  Future<List<PartnerTransaction>> transactions(String id) async =>
      (await _rows('transactions/'))
          .where((row) => row['partner'] == id)
          .map(PartnerTransaction.fromJson)
          .toList();
  Future<void> addTransaction({
    required String partnerId,
    required String type,
    required double amount,
    required DateTime date,
    required String description,
  }) => _api.post(
    'transactions/',
    data: {
      'partner': partnerId,
      'transaction_type': type,
      'amount': amount.toStringAsFixed(2),
      'transaction_date': date.toIso8601String().split('T').first,
      'description': description,
    },
  );
}
