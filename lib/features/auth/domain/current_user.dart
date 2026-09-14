class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.username,
    required this.isStaff,
    required this.isActive,
    this.email = '',
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
    id: json['id'] as int,
    username: json['username'] as String,
    email: json['email'] as String? ?? '',
    isStaff: json['is_staff'] as bool? ?? false,
    isActive: json['is_active'] as bool? ?? true,
  );

  final int id;
  final String username;
  final String email;
  final bool isStaff;
  final bool isActive;
}
