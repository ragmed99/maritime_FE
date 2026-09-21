import '../../../core/network/api_client.dart';
import '../domain/dashboard_models.dart';

abstract interface class DashboardDataSource {
  Future<DashboardData> fetchDashboard();
}

class DashboardRepository implements DashboardDataSource {
  DashboardRepository(this._api);
  final ApiClient _api;

  @override
  Future<DashboardData> fetchDashboard() async {
    final responses = await Future.wait([
      _api.get<Map<String, dynamic>>('dashboard/'),
      _api.get<Map<String, dynamic>>('reports/ships/'),
      _api.get<Map<String, dynamic>>('reports/clients/'),
      _api.get<Map<String, dynamic>>('reports/partners/'),
      _api.get<Map<String, dynamic>>('financial-summary/'),
    ]);
    List<Map<String, dynamic>> rows(int index) =>
        (responses[index].data!['results'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
    return DashboardData(
      metrics: DashboardMetrics.fromJson(responses[0].data!),
      ships: rows(1).map(ShipSummary.fromJson).toList(),
      clients: rows(2).map(ClientSummary.fromJson).toList(),
      partners: rows(3).map(PartnerSummary.fromJson).toList(),
      positions: (responses[4].data!['positions'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(FinancialPosition.fromJson)
          .toList(),
    );
  }
}
