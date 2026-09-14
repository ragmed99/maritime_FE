import 'package:intl/intl.dart';

String formatMru(double value, String localeName) => NumberFormat.currency(
  locale: localeName,
  name: 'MRU',
  symbol: 'MRU ',
  decimalDigits: 2,
).format(value);
