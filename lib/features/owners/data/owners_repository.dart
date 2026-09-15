import '../../../core/network/api_client.dart';
import '../../../core/models/account_position.dart';
import '../domain/owner_models.dart';

class OwnersRepository {
  OwnersRepository(this._api);
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

  Future<List<OwnerRecord>> owners() async =>
      (await _rows('owners/')).map(OwnerRecord.fromJson).toList();
  Future<void> saveOwner({
    String? id,
    required String name,
    required String phone,
  }) async {
    final data = {'name': name, 'phone': phone};
    if (id == null) {
      await _api.post('owners/', data: data);
    } else {
      await _api.patch('owners/$id/', data: data);
    }
  }

  Future<void> deleteOwner(String id) => _api.delete('owners/$id/');
  Future<AccountPosition> balance(String id) async => AccountPosition.fromJson(
    (await _api.get<Map<String, dynamic>>('owners/$id/balance/')).data!,
  );
  Future<List<OwnerTransaction>> transactions(String id) async => (await _rows(
    'transactions/?owner_account=$id',
  )).map(OwnerTransaction.fromJson).toList();
  Future<List<OwnerShip>> ships(String id) async => (await _rows(
    'ships/',
  )).where((row) => row['owner'] == id).map(OwnerShip.fromJson).toList();
  Future<void> addTransaction({
    required String ownerId,
    required String type,
    required double amount,
    required DateTime date,
    required String description,
  }) => _api.post(
    'transactions/',
    data: {
      'owner': ownerId,
      'transaction_type': type,
      'amount': amount.toStringAsFixed(2),
      'transaction_date': date.toIso8601String().split('T').first,
      'description': description,
    },
  );
}
