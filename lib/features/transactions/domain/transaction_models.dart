import '../../dashboard/domain/dashboard_models.dart';

class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.createdAt,
    required this.description,
    required this.reference,
    this.shipId,
    this.tripId,
    this.clientId,
    this.partnerId,
    this.ownerId,
    this.recordedBy,
  });

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) =>
      LedgerTransaction(
        id: json['id'] as String,
        type: json['transaction_type'] as String,
        amount: moneyFromJson(json['amount']),
        date: DateTime.parse(json['transaction_date'] as String),
        createdAt: DateTime.parse(json['created_at'] as String),
        description: json['description'] as String? ?? '',
        reference: json['reference'] as String? ?? '',
        shipId: json['ship'] as String?,
        tripId: json['trip'] as String?,
        clientId: json['client'] as String?,
        partnerId: json['partner'] as String?,
        ownerId: json['owner'] as String?,
        recordedBy:
            (json['created_by'] as Map<String, dynamic>?)?['username']
                as String?,
      );

  final String id;
  final String type;
  final double amount;
  final DateTime date;
  final DateTime createdAt;
  final String description;
  final String reference;
  final String? shipId;
  final String? tripId;
  final String? clientId;
  final String? partnerId;
  final String? ownerId;
  final String? recordedBy;
}

class LookupOption {
  const LookupOption(this.id, this.name, {this.parentId});
  final String id;
  final String name;
  final String? parentId;
}

class TransactionLookups {
  const TransactionLookups({
    required this.ships,
    required this.trips,
    required this.clients,
    required this.partners,
    required this.owners,
  });
  final List<LookupOption> ships;
  final List<LookupOption> trips;
  final List<LookupOption> clients;
  final List<LookupOption> partners;
  final List<LookupOption> owners;

  String? name(List<LookupOption> options, String? id) => id == null
      ? null
      : options.where((item) => item.id == id).firstOrNull?.name;
}

class TransactionFilters {
  const TransactionFilters({
    this.startDate,
    this.endDate,
    this.type,
    this.shipId,
    this.tripId,
    this.clientId,
    this.partnerId,
    this.ownerId,
    this.search,
  });
  final DateTime? startDate;
  final DateTime? endDate;
  final String? type;
  final String? shipId;
  final String? tripId;
  final String? clientId;
  final String? partnerId;
  final String? ownerId;
  final String? search;

  Map<String, dynamic> toQuery(int page) => {
    'page': page,
    if (startDate != null) 'start_date': _date(startDate!),
    if (endDate != null) 'end_date': _date(endDate!),
    if (type != null) 'transaction_type': type,
    if (shipId != null) 'ship': shipId,
    if (tripId != null) 'trip': tripId,
    if (clientId != null) 'client': clientId,
    if (partnerId != null) 'partner': partnerId,
    if (ownerId != null) 'owner': ownerId,
    if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
  };

  static String _date(DateTime value) =>
      value.toIso8601String().split('T').first;
}

class TransactionPage {
  const TransactionPage({required this.rows, required this.hasMore});
  final List<LedgerTransaction> rows;
  final bool hasMore;
}
