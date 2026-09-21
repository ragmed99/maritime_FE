import '../../../core/network/api_client.dart';
import '../domain/administration_models.dart';

class AdministrationRepository {
  AdministrationRepository(this._api);
  final ApiClient _api;

  Future<List<ManagedUser>> users() async {
    final rows = <ManagedUser>[];
    String? next = 'users/';
    while (next != null) {
      final page = (await _api.get<Map<String, dynamic>>(next)).data!;
      rows.addAll(
        (page['results'] as List).cast<Map<String, dynamic>>().map(
          ManagedUser.fromJson,
        ),
      );
      next = page['next'] as String?;
    }
    return rows;
  }

  Future<void> createUser({
    required String username,
    required String password,
    required String phone,
    required String role,
  }) => _api.post(
    'users/',
    data: {
      'username': username,
      'password': password,
      'phone': phone,
      'role': role,
    },
  );

  Future<void> setActive(int id, bool active) =>
      _api.patch('users/$id/status/', data: {'is_active': active});
  Future<void> resetPassword(int id, String password) =>
      _api.post('users/$id/reset-password/', data: {'new_password': password});
  Future<void> changePassword(String current, String password) => _api.post(
    'auth/change-password/',
    data: {'current_password': current, 'new_password': password},
  );

  Future<AuditPage> audit(AuditFilters filters, int pageNumber) async {
    final page = (await _api.get<Map<String, dynamic>>(
      'audit-logs/',
      query: filters.toQuery(pageNumber),
    )).data!;
    return AuditPage(
      rows: (page['results'] as List)
          .cast<Map<String, dynamic>>()
          .map(AuditRecord.fromJson)
          .toList(),
      hasMore: page['next'] != null,
    );
  }

  Future<CompanyConfig> companyConfig() async => CompanyConfig.fromJson(
    (await _api.get<Map<String, dynamic>>('app-config/')).data!,
  );
}
