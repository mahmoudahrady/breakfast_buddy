import 'package:intl/intl.dart';

/// Currency utilities for formatting prices with Saudi Riyal
class CurrencyUtils {
  // Saudi Riyal symbol
  static const String saudiRiyalSymbol = 'ر.س';

  /// Format a number as currency with Saudi Riyal symbol
  /// Example: formatCurrency(12.50) returns "12.50 ر.س"
  static String formatCurrency(double amount, {int decimalDigits = 2}) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimalDigits,
    );
    final formattedAmount = formatter.format(amount).trim();
    return '$formattedAmount $saudiRiyalSymbol';
  }

  /// Get just the currency symbol
  static String get currencySymbol => saudiRiyalSymbol;
}
