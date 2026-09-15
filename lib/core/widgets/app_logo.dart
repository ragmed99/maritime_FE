import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({this.size = 96, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.12),
    child: Image.asset(
      'assets/branding/tar_fishing_logo.jpeg',
      width: size,
      height: size,
      fit: BoxFit.cover,
      semanticLabel: 'TAR FISHING',
    ),
  );
}
