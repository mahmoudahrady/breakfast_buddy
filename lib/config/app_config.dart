/// Application-wide configuration constants
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  // Currency configuration
  static const String currency = 'SAR';
  static const String currencySymbol = 'ر.س';
  static const String locale = 'ar_SA';

  // Alternative locale for English
  static const String localeEn = 'en_US';

  /// Format amount as currency string
  /// Example: 25.50 -> "25.50 ر.س"
  static String formatCurrency(double amount, {bool showSymbol = true}) {
    final formattedAmount = amount.toStringAsFixed(2);
    return showSymbol ? '$formattedAmount $currencySymbol' : formattedAmount;
  }

  /// Format amount as currency with thousands separator
  /// Example: 1250.50 -> "1,250.50 ر.س"
  static String formatCurrencyWithSeparator(double amount, {bool showSymbol = true}) {
    final parts = amount.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : '00';

    // Add thousands separator
    final formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    final formattedAmount = '$formattedInteger.$decimalPart';
    return showSymbol ? '$formattedAmount $currencySymbol' : formattedAmount;
  }

  /// Parse currency string to double
  /// Example: "25.50 ر.س" -> 25.50
  static double parseCurrency(String currencyString) {
    final cleaned = currencyString
        .replaceAll(currencySymbol, '')
        .replaceAll(',', '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  // App metadata
  static const String appName = 'Breakfast Buddy';
  static const String version = '1.0.0';

  // Feature flags
  static const bool enableNotifications = true;
  static const bool enableAnalytics = false;
  static const bool enableCrashReporting = false;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxImageSizeMB = 5;

  // Cache settings
  static const Duration menuCacheDuration = Duration(hours: 24);
  static const Duration profileCacheDuration = Duration(hours: 12);
}
