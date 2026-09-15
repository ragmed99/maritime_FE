import '../../dashboard/domain/dashboard_models.dart';
import '../../../core/models/account_position.dart';

class ClientRecord {
  const ClientRecord({
    required this.id,
    required this.name,
    required this.phone,
  });
  factory ClientRecord.fromJson(Map<String, dynamic> json) => ClientRecord(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String? ?? '',
  );
  final String id;
  final String name;
  final String phone;
}

class RelationOption {
  const RelationOption({required this.id, required this.name});
  final String id;
  final String name;
}

class ClientTransactionRow {
  const ClientTransactionRow({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.time,
    required this.description,
    this.ship,
    this.trip,
    this.recordedBy,
  });
  factory ClientTransactionRow.fromJson(
    Map<String, dynamic> json,
  ) => ClientTransactionRow(
    id: json['id'] as String,
    type: json['transaction_type'] as String,
    amount: moneyFromJson(json['amount']),
    date: DateTime.parse(json['date'] as String),
    time: json['time'] as String,
    description: json['description'] as String? ?? '',
    ship: (json['ship'] as Map<String, dynamic>?)?['name'] as String?,
    trip: (json['trip'] as Map<String, dynamic>?)?['departure_date'] as String?,
    recordedBy:
        (json['created_by'] as Map<String, dynamic>?)?['username'] as String?,
  );
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String time;
  final String description;
  final String? ship;
  final String? trip;
  final String? recordedBy;
}

class ClientStatementData {
  const ClientStatementData({
    required this.position,
    required this.transactions,
  });
  final AccountPosition position;
  final List<ClientTransactionRow> transactions;
}

class ClientFilters {
  const ClientFilters({
    this.startDate,
    this.endDate,
    this.shipId,
    this.tripId,
    this.type,
  });
  final DateTime? startDate;
  final DateTime? endDate;
  final String? shipId;
  final String? tripId;
  final String? type;

  Map<String, dynamic> toQuery() => {
    if (startDate != null) 'start_date': formatApiDate(startDate!),
    if (endDate != null) 'end_date': formatApiDate(endDate!),
    if (shipId != null) 'ship': shipId,
    if (tripId != null) 'trip': tripId,
    if (type != null) 'transaction_type': type,
  };
}

String formatApiDate(DateTime value) =>
    value.toIso8601String().split('T').first;
