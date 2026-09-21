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
    required this.ownerId,
    required this.ownerName,
    this.financials = const Financials(revenue: 0, expenses: 0, profit: 0),
  });
  factory ShipRecord.fromJson(Map<String, dynamic> json, String ownerName) =>
      ShipRecord(
        id: json['id'] as String,
        name: json['name'] as String,
        ownerId: json['owner'] as String,
        ownerName: ownerName,
      );
  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final Financials financials;
}

class Financials {
  const Financials({
    required this.revenue,
    required this.expenses,
    required this.profit,
    this.hasUnpricedPurchases = false,
  });
  factory Financials.ship(Map<String, dynamic> json) => Financials(
    revenue: moneyFromJson(json['total_revenue']),
    expenses: moneyFromJson(json['total_expenses']),
    profit: moneyFromJson(json['profit']),
    hasUnpricedPurchases: json['has_unpriced_purchases'] as bool? ?? false,
  );
  factory Financials.trip(Map<String, dynamic> json) => Financials(
    revenue: moneyFromJson(json['revenue']),
    expenses: moneyFromJson(json['expenses']),
    profit: moneyFromJson(json['profit'] ?? json['remaining']),
    hasUnpricedPurchases: json['has_unpriced_purchases'] as bool? ?? false,
  );
  final double revenue;
  final double expenses;
  final double profit;
  final bool hasUnpricedPurchases;
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

class TripTransaction {
  const TripTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.description,
    this.quantity,
    this.unitPrice,
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
    quantity: json['quantity'] == null ? null : moneyFromJson(json['quantity']),
    unitPrice: json['unit_price'] == null
        ? null
        : moneyFromJson(json['unit_price']),
    clientName: clientName,
  );
  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final String description;
  final double? quantity;
  final double? unitPrice;
  final String? clientName;
}

class ClientOption {
  const ClientOption({required this.id, required this.name});
  factory ClientOption.fromJson(Map<String, dynamic> json) =>
      ClientOption(id: json['id'] as String, name: json['name'] as String);
  final String id;
  final String name;
}

class PointeurPurchase {
  const PointeurPurchase({
    required this.id,
    required this.description,
    required this.quantity,
    required this.date,
    required this.clientName,
    required this.clientId,
  });

  factory PointeurPurchase.fromJson(Map<String, dynamic> json) {
    final client = json['client'] as Map<String, dynamic>?;
    return PointeurPurchase(
      id: json['id'] as String,
      description: json['description'] as String? ?? '',
      quantity: moneyFromJson(json['quantity']),
      date: DateTime.parse(json['date'] as String),
      clientName: client?['name'] as String? ?? '—',
      clientId: client?['id'] as String?,
    );
  }

  final String id;
  final String description;
  final double quantity;
  final DateTime date;
  final String clientName;
  final String? clientId;
}
