class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.username,
    required this.phone,
    required this.isActive,
    required this.isStaff,
    required this.role,
  });
  factory ManagedUser.fromJson(Map<String, dynamic> json) => ManagedUser(
    id: json['id'] as int,
    username: json['username'] as String,
    phone: json['phone'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? true,
    isStaff: json['is_staff'] as bool? ?? false,
    role: json['role'] as String? ?? 'USER',
  );
  final int id;
  final String username;
  final String phone;
  final bool isActive;
  final bool isStaff;
  final String role;
}

class AuditRecord {
  const AuditRecord({
    required this.id,
    required this.username,
    required this.userId,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.timestamp,
    required this.oldValues,
    required this.newValues,
  });
  factory AuditRecord.fromJson(Map<String, dynamic> json) => AuditRecord(
    id: json['id'] as int,
    username: json['username'] as String?,
    userId: json['user'] as int?,
    action: json['action'] as String,
    entity: json['entity_name'] as String,
    entityId: json['entity_id'].toString(),
    timestamp: DateTime.parse(json['timestamp'] as String),
    oldValues: (json['old_values'] as Map<String, dynamic>?) ?? const {},
    newValues: (json['new_values'] as Map<String, dynamic>?) ?? const {},
  );
  final int id;
  final String? username;
  final int? userId;
  final String action;
  final String entity;
  final String entityId;
  final DateTime timestamp;
  final Map<String, dynamic> oldValues;
  final Map<String, dynamic> newValues;
}

class AuditFilters {
  const AuditFilters({
    this.userId,
    this.action,
    this.entity,
    this.start,
    this.end,
  });
  final int? userId;
  final String? action;
  final String? entity;
  final DateTime? start;
  final DateTime? end;
  Map<String, dynamic> toQuery(int page) => {
    'page': page,
    if (userId != null) 'user': userId,
    if (action != null) 'action': action,
    if (entity != null && entity!.trim().isNotEmpty) 'entity': entity!.trim(),
    if (start != null) 'start_date': _date(start!),
    if (end != null) 'end_date': _date(end!),
  };
  static String _date(DateTime value) =>
      value.toIso8601String().split('T').first;
}

class AuditPage {
  const AuditPage({required this.rows, required this.hasMore});
  final List<AuditRecord> rows;
  final bool hasMore;
}

class CompanyConfig {
  const CompanyConfig({
    required this.name,
    required this.phone,
    required this.address,
  });
  factory CompanyConfig.fromJson(Map<String, dynamic> json) => CompanyConfig(
    name: json['company_name'] as String? ?? '',
    phone: json['company_phone'] as String? ?? '',
    address: json['company_address'] as String? ?? '',
  );
  final String name;
  final String phone;
  final String address;
}
