import 'dart:typed_data';

import '../../../core/network/api_client.dart';
import '../../dashboard/domain/dashboard_models.dart';
import '../../transactions/domain/transaction_models.dart';
import '../domain/report_models.dart';

class ReportsRepository {
  ReportsRepository(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> _all(String path) async {
    final result = <Map<String, dynamic>>[];
    String? next = path;
    while (next != null) {
      final page = (await _api.get<Map<String, dynamic>>(next)).data!;
      result.addAll((page['results'] as List).cast<Map<String, dynamic>>());
      next = page['next'] as String?;
    }
    return result;
  }

  Future<ReportLookups> lookups() async {
    final values = await Future.wait([
      _all('clients/'),
      _all('ships/'),
      _all('trips/'),
      _all('partners/'),
      _all('owners/'),
    ]);
    List<LookupOption> named(List<Map<String, dynamic>> rows) => rows
        .map((row) => LookupOption(row['id'] as String, row['name'] as String))
        .toList();
    return ReportLookups(
      clients: named(values[0]),
      ships: named(values[1]),
      trips: values[2]
          .map(
            (row) => LookupOption(
              row['id'] as String,
              row['departure_date'].toString(),
              parentId: row['ship'] as String,
            ),
          )
          .toList(),
      partners: named(values[3]),
      owners: named(values[4]),
    );
  }

  Future<StatementData> statement(StatementRequest request) async =>
      StatementData.fromJson(
        (await _api.get<Map<String, dynamic>>(
          '${request.resource}/${request.entityId}/statement/',
          query: request.query,
        )).data!,
      );

  Future<Uint8List> pdf(StatementRequest request) async => Uint8List.fromList(
    await _api.download(
      '${request.resource}/${request.entityId}/statement/pdf/',
      query: request.query,
    ),
  );

  Future<DashboardMetrics> summary(DateTime start, DateTime end) async =>
      DashboardMetrics.fromJson(
        (await _api.get<Map<String, dynamic>>(
          'dashboard/',
          query: {'start_date': _date(start), 'end_date': _date(end)},
        )).data!,
      );

  String _date(DateTime value) => value.toIso8601String().split('T').first;
}
