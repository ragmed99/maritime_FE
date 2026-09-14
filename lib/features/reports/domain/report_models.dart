import '../../dashboard/domain/dashboard_models.dart';
import '../../transactions/domain/transaction_models.dart';

enum ReportKind { client, ship, partner, owner }

class ReportTransaction {
  const ReportTransaction({
    required this.date,
    required this.time,
    required this.type,
    required this.amount,
    required this.description,
    this.ship,
    this.trip,
    this.client,
    this.createdBy,
  });
  factory ReportTransaction.fromJson(Map<String, dynamic> json) =>
      ReportTransaction(
        date: DateTime.parse(json['date'].toString()),
        time: json['time'].toString(),
        type: json['transaction_type'] as String,
        amount: moneyFromJson(json['amount']),
        description: json['description'] as String? ?? '',
        ship: (json['ship'] as Map<String, dynamic>?)?['name'] as String?,
        trip: (json['trip'] as Map<String, dynamic>?)?['departure_date']
            ?.toString(),
        client: (json['client'] as Map<String, dynamic>?)?['name'] as String?,
        createdBy:
            (json['created_by'] as Map<String, dynamic>?)?['username']
                as String?,
      );
  final DateTime date;
  final String time;
  final String type;
  final double amount;
  final String description;
  final String? ship;
  final String? trip;
  final String? client;
  final String? createdBy;
}

class TripReportSummary {
  const TripReportSummary({
    required this.tripId,
    required this.date,
    required this.revenue,
    required this.expenses,
    required this.purchases,
    required this.remaining,
  });
  factory TripReportSummary.fromJson(Map<String, dynamic> json) =>
      TripReportSummary(
        tripId: json['trip_id'].toString(),
        date: DateTime.parse(json['departure_date'].toString()),
        revenue: moneyFromJson(json['revenue']),
        expenses: moneyFromJson(json['expenses']),
        purchases: moneyFromJson(json['client_purchases']),
        remaining: moneyFromJson(json['remaining_result']),
      );
  final String tripId;
  final DateTime date;
  final double revenue;
  final double expenses;
  final double purchases;
  final double remaining;
}

class StatementData {
  const StatementData({
    required this.subjectName,
    required this.summary,
    required this.transactions,
    required this.tripSummaries,
  });
  factory StatementData.fromJson(Map<String, dynamic> json) {
    final page = json['transactions'] as Map<String, dynamic>;
    return StatementData(
      subjectName: (json['subject'] as Map<String, dynamic>)['name'] as String,
      summary: (json['summary'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, moneyFromJson(value)),
      ),
      transactions: (page['results'] as List)
          .cast<Map<String, dynamic>>()
          .map(ReportTransaction.fromJson)
          .toList(),
      tripSummaries: ((json['trip_summaries'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(TripReportSummary.fromJson)
          .toList(),
    );
  }
  final String subjectName;
  final Map<String, double> summary;
  final List<ReportTransaction> transactions;
  final List<TripReportSummary> tripSummaries;
}

class StatementRequest {
  const StatementRequest({
    required this.kind,
    required this.entityId,
    this.startDate,
    this.endDate,
    this.shipId,
    this.tripIds = const [],
  });
  final ReportKind kind;
  final String entityId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? shipId;
  final List<String> tripIds;

  String get resource => switch (kind) {
    ReportKind.client => 'clients',
    ReportKind.ship => 'ships',
    ReportKind.partner => 'partners',
    ReportKind.owner => 'owners',
  };
  Map<String, dynamic> get query => {
    if (startDate != null) 'start_date': _date(startDate!),
    if (endDate != null) 'end_date': _date(endDate!),
    if (kind == ReportKind.client && shipId != null) 'ship': shipId,
    if (tripIds.length == 1) 'trip': tripIds.single,
    if (tripIds.length > 1) 'trips': tripIds.join(','),
  };
  static String _date(DateTime value) =>
      value.toIso8601String().split('T').first;
}

class ReportLookups {
  const ReportLookups({
    required this.clients,
    required this.ships,
    required this.trips,
    required this.partners,
    required this.owners,
  });
  final List<LookupOption> clients;
  final List<LookupOption> ships;
  final List<LookupOption> trips;
  final List<LookupOption> partners;
  final List<LookupOption> owners;
}
