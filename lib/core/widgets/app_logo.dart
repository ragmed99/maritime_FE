import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 96, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF0B4A75).withValues(alpha: 0.2),
          blurRadius: 18,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.16),
      child: Image.asset(
        'assets/branding/tar_fishing_icon.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Tar Fishing',
      ),
    ),
  );
}
