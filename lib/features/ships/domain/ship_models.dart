import '../../dashboard/domain/dashboard_models.dart';

List<Map<String, dynamic>> apiResults(Map<String, dynamic> json) =>
    (json['results'] as List<dynamic>).cast<Map<String, dynamic>>();

class OwnerOption {
  const OwnerOption({required this.id, required this.name});
  factory OwnerOption.fromJson(Map<String, dynamic> json) =>
      OwnerOption(id: json['id'] as String, name: json['name'] as String);
  final String id;
  final String name;
}

class ShipRecord {
  const ShipRecord({
    required this.id,
    required this.name,
    required this.registrationNumber,
    required this.ownerId,
    required this.ownerName,
  });
  factory ShipRecord.fromJson(Map<String, dynamic> json, String ownerName) =>
      ShipRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        registrationNumber: json['registration_number'] as String,
        ownerId: json['owner'] as String,
        ownerName: ownerName,
      );
  final String id;
  final String name;
  final String registrationNumber;
  final String ownerId;
  final String ownerName;
}

class Financials {
  const Financials({
    required this.revenue,
    required this.expenses,
    required this.profit,
  });
  factory Financials.ship(Map<String, dynamic> json) => Financials(
    revenue: moneyFromJson(json['total_revenue']),
    expenses: moneyFromJson(json['total_expenses']),
    profit: moneyFromJson(json['profit']),
  );
  factory Financials.trip(Map<String, dynamic> json) => Financials(
    revenue: moneyFromJson(json['revenue']),
    expenses: moneyFromJson(json['expenses']),
    profit: moneyFromJson(json['profit'] ?? json['remaining']),
  );
  final double revenue;
  final double expenses;
  final double profit;
}

class TripRecord {
  const TripRecord({
    required this.id,
    required this.shipId,
    required this.departureDate,
    this.departureTime,
    this.returnDate,
    this.arrivalTime,
    required this.origin,
    required this.destination,
    required this.notes,
    this.financials,
  });
  factory TripRecord.fromJson(
    Map<String, dynamic> json, {
    Financials? financials,
  }) => TripRecord(
    id: json['id'] as String,
    shipId: json['ship'] as String,
    departureDate: DateTime.parse(json['departure_date'] as String),
    departureTime: json['departure_time'] as String?,
    returnDate: json['return_date'] == null
        ? null
        : DateTime.parse(json['return_date'] as String),
    arrivalTime: json['arrival_time'] as String?,
    origin: json['origin'] as String? ?? '',
    destination: json['destination'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    financials: financials,
  );
  final String id;
  final String shipId;
  final DateTime departureDate;
  final String? departureTime;
  final DateTime? returnDate;
  final String? arrivalTime;
  final String origin;
  final String destination;
  final String notes;
  final Financials? financials;
}

class TripFinancialEntry {
  const TripFinancialEntry({required this.amount, required this.description});
  final double amount;
  final String description;

  Map<String, dynamic> toJson() => {
    'amount': amount.toStringAsFixed(2),
    'description': description,
  };
}

class TripTransaction {
  const TripTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    this.clientName,
  });
  factory TripTransaction.fromJson(
    Map<String, dynamic> json,
    String? clientName,
  ) => TripTransaction(
    id: json['id'] as String,
    type: json['transaction_type'] as String,
    amount: moneyFromJson(json['amount']),
    date: DateTime.parse(json['transaction_date'] as String),
    description: json['description'] as String? ?? '',
    clientName: clientName,
  );
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String description;
  final String? clientName;
}

class ClientOption {
  const ClientOption({required this.id, required this.name});
  factory ClientOption.fromJson(Map<String, dynamic> json) =>
      ClientOption(id: json['id'] as String, name: json['name'] as String);
  final String id;
  final String name;
}
