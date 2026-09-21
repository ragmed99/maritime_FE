double moneyFromJson(Object? value) => switch (value) {
  num number => number.toDouble(),
  String text => double.parse(text),
  _ => 0,
};

class DashboardMetrics {
  const DashboardMetrics({
    required this.expectedCash,
    required this.peopleOweUs,
    required this.weOwePeople,
    required this.netPosition,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.profitLoss,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) =>
      DashboardMetrics(
        expectedCash: moneyFromJson(json['expected_cash']),
        peopleOweUs: moneyFromJson(json['total_people_owe_us']),
        weOwePeople: moneyFromJson(json['total_we_owe_people']),
        netPosition: moneyFromJson(json['net_financial_position']),
        totalRevenue: moneyFromJson(json['total_revenue']),
        totalExpenses: moneyFromJson(json['total_expenses']),
        profitLoss: moneyFromJson(json['total_profit_loss']),
      );

  final double expectedCash;
  final double peopleOweUs;
  final double weOwePeople;
  final double netPosition;
  final double totalRevenue;
  final double totalExpenses;
  final double profitLoss;
}

class ShipSummary {
  const ShipSummary({
    required this.name,
    required this.revenue,
    required this.expenses,
    required this.profitLoss,
  });
  factory ShipSummary.fromJson(Map<String, dynamic> json) => ShipSummary(
    name: json['ship_name'] as String,
    revenue: moneyFromJson(json['revenue']),
    expenses: moneyFromJson(json['expenses']),
    profitLoss: moneyFromJson(json['profit_loss']),
  );
  final String name;
  final double revenue;
  final double expenses;
  final double profitLoss;
}

class ClientSummary {
  const ClientSummary({required this.name, required this.balance});
  factory ClientSummary.fromJson(Map<String, dynamic> json) => ClientSummary(
    name: json['client_name'] as String,
    balance: moneyFromJson(json['current_balance']),
  );
  final String name;
  final double balance;
}

class PartnerSummary {
  const PartnerSummary({required this.name, required this.balance});
  factory PartnerSummary.fromJson(Map<String, dynamic> json) => PartnerSummary(
    name: json['partner_name'] as String,
    balance: moneyFromJson(json['current_balance']),
  );
  final String name;
  final double balance;
}

class DashboardData {
  const DashboardData({
    required this.metrics,
    required this.ships,
    required this.clients,
    required this.partners,
    required this.positions,
  });
  final DashboardMetrics metrics;
  final List<ShipSummary> ships;
  final List<ClientSummary> clients;
  final List<PartnerSummary> partners;
  final List<FinancialPosition> positions;
}

class FinancialPosition {
  const FinancialPosition({
    required this.kind,
    required this.name,
    required this.theyOweUs,
    required this.weOweThem,
    required this.createdAt,
  });

  factory FinancialPosition.fromJson(Map<String, dynamic> json) =>
      FinancialPosition(
        kind: json['kind'] as String,
        name: json['name'] as String,
        theyOweUs: moneyFromJson(json['they_owe_us']),
        weOweThem: moneyFromJson(json['we_owe_them']),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  final String kind;
  final String name;
  final double theyOweUs;
  final double weOweThem;
  final DateTime createdAt;
}
