import 'package:flutter/material.dart';

import '../formatters/money_formatter.dart';
import '../theme/app_theme.dart';

/// Renders a formatted MRU amount with tabular numerals so stacked figures
/// align, and optionally colors it by sign using [MoneyColors].
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.value, {
    required this.locale,
    this.style,
    this.colorBySign = false,
    this.textAlign,
    super.key,
  });

  final double value;
  final String locale;
  final TextStyle? style;
  final bool colorBySign;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    Color? color = base.color;
    if (colorBySign) {
      final money = context.moneyColors;
      color = value > 0
          ? money.positive
          : value < 0
          ? money.negative
          : money.neutral;
    }
    return Text(
      formatMru(value, locale),
      textAlign: textAlign,
      style: base.copyWith(
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
