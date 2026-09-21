import 'package:flutter/material.dart';

/// A colored circular avatar showing an entity's initials, replacing the
/// generic outline-icon `CircleAvatar` used across ships/clients/partners/
/// owners/users lists. The color is derived deterministically from the name
/// so the same entity always gets the same tint.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar(this.name, {this.size = 44, this.icon, super.key});

  final String name;
  final double size;
  final IconData? icon;

  static const _palette = [
    Color(0xFF0B4A75),
    Color(0xFF0E8C82),
    Color(0xFF9A6B1E),
    Color(0xFF6D4FA0),
    Color(0xFFB4433F),
    Color(0xFF2E7D4F),
    Color(0xFF3B6E9A),
    Color(0xFFA24A78),
  ];

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Color get _color => _palette[name.hashCode.abs() % _palette.length];

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: size / 2,
    backgroundColor: _color.withValues(alpha: 0.16),
    foregroundColor: _color,
    child: icon != null
        ? Icon(icon, size: size * 0.5)
        : Text(
            _initials,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: size * 0.36,
            ),
          ),
  );
}
