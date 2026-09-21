import '../../dashboard/domain/dashboard_models.dart';

class OwnerRecord {
  const OwnerRecord({
    required this.id,
    required this.name,
    required this.phone,
  });
  factory OwnerRecord.fromJson(Map<String, dynamic> json) => OwnerRecord(
    id: json['id'] as String,
    name: json['name'] as String,
    phone: json['phone'] as String? ?? '',
  );
  final String id;
  final String name;
  final String phone;
}

class OwnerTransaction {
  const OwnerTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.time,
    required this.description,
    this.shipId,
    this.recordedBy,
  });
  factory OwnerTransaction.fromJson(Map<String, dynamic> json) =>
      OwnerTransaction(
        id: json['id'] as String,
        type: json['transaction_type'] as String,
        amount: moneyFromJson(json['amount']),
        date: DateTime.parse(json['transaction_date'] as String),
        time: DateTime.parse(json['created_at'] as String),
        description: json['description'] as String? ?? '',
        shipId: json['ship'] as String?,
        recordedBy:
            (json['created_by'] as Map<String, dynamic>?)?['username']
                as String?,
      );
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final DateTime time;
  final String description;
  final String? shipId;
  final String? recordedBy;
}

class OwnerShip {
  const OwnerShip({
    required this.id,
    required this.name,
    required this.outcome,
  });

  factory OwnerShip.fromJson(Map<String, dynamic> json, {double outcome = 0}) =>
      OwnerShip(
        id: json['id'] as String,
        name: json['name'] as String,
        outcome: outcome,
      );

  final String id;
  final String name;
  final double outcome;
}
