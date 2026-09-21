import 'package:flutter/material.dart';

class HomeButton extends StatelessWidget {
  const HomeButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: Localizations.localeOf(context).languageCode == 'ar'
        ? 'الرئيسية'
        : 'Accueil',
    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
    icon: const Icon(Icons.home_outlined),
  );
}
