import 'package:flutter/material.dart';

/// Food App Color Palette
/// Warm, appetizing colors inspired by popular food delivery apps
class TropicalColors {
  // Primary Food App Colors - Warm and appetizing
  static const Color orange = Color(0xFFFF6B35);      // Vibrant orange - appetite stimulating
  static const Color warmOrange = Color(0xFFFF8C42);  // Warm orange - friendly and inviting
  static const Color coral = Color(0xFFFF9A76);       // Soft coral - warm accent
  static const Color cream = Color(0xFFFFF8F0);       // Cream - soft background

  // Supporting Colors
  static const Color darkGreen = Color(0xFF2D5016);   // Deep green - fresh & natural
  static const Color sage = Color(0xFF52734D);        // Sage green - healthy
  static const Color mint = Color(0xFF91C788);        // Fresh mint - success

  // Text Colors
  static const Color darkText = Color(0xFF2C3333);    // Almost black - high contrast
  static const Color mediumText = Color(0xFF5C5C5C);  // Medium gray - secondary text
  static const Color lightText = Color(0xFF8B8B8B);   // Light gray - tertiary text

  // Background Colors
  static const Color background = Color(0xFFFFFCF9);  // Warm white background
  static const Color surface = Colors.white;          // Pure white for cards
  static const Color surfaceAlt = Color(0xFFFFF5EB);  // Light cream for subtle backgrounds

  // Semantic Colors
  static const Color success = mint;
  static const Color warning = warmOrange;
  static const Color error = Color(0xFFE63946);       // Food-safe red
  static const Color info = Color(0xFF457B9D);        // Muted blue

  // Status Colors (for orders)
  static const Color pending = warmOrange;
  static const Color confirmed = mint;
  static const Color preparing = coral;
  static const Color ready = darkGreen;
  static const Color delivered = mint;
  static const Color cancelled = Color(0xFF9E9E9E);   // Neutral gray

  // Helper method to create gradient
  static LinearGradient createGradient({
    List<Color>? colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: colors ?? [orange, coral],
      begin: begin,
      end: end,
    );
  }

  // Helper method to create subtle gradient
  static LinearGradient createSubtleGradient(Color baseColor) {
    return LinearGradient(
      colors: [
        baseColor.withValues(alpha: 0.08),
        baseColor.withValues(alpha: 0.03),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

/// App Theme Data Builder
class TropicalTheme {
  static ThemeData buildLightTheme() {
    final colorScheme = ColorScheme.light(
      primary: TropicalColors.orange,
      secondary: TropicalColors.coral,
      tertiary: TropicalColors.mint,
      surface: TropicalColors.surface,
      error: TropicalColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: TropicalColors.darkText,
      onError: Colors.white,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: TropicalColors.background,
      brightness: Brightness.light,

      // App Bar Theme - Minimal & Clean
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: TropicalColors.darkText,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: TropicalColors.darkText,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(
          color: TropicalColors.orange,
          size: 24,
        ),
      ),

      // Card Theme - Minimal with subtle borders
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shadowColor: Colors.black.withValues(alpha: 0.02),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Input Decoration Theme - Clean & Simple
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TropicalColors.orange, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TropicalColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: TropicalColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(
          color: TropicalColors.mediumText.withValues(alpha: 0.7),
          fontSize: 15,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: TropicalColors.orange,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          shadowColor: TropicalColors.orange.withValues(alpha: 0.3),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.2)),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: TropicalColors.orange, width: 1.5),
          foregroundColor: TropicalColors.orange,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: TropicalColors.orange,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Chip Theme - Subtle & Clean
      chipTheme: ChipThemeData(
        backgroundColor: TropicalColors.orange.withValues(alpha: 0.08),
        selectedColor: TropicalColors.orange.withValues(alpha: 0.15),
        deleteIconColor: TropicalColors.orange,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          color: TropicalColors.orange,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      // Floating Action Button Theme - Flat & Modern
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: TropicalColors.orange,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: TropicalColors.orange,
        unselectedItemColor: TropicalColors.mediumText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        elevation: 0,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        titleTextStyle: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: TropicalColors.darkText,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: TropicalColors.orange,
        circularTrackColor: TropicalColors.orange.withValues(alpha: 0.15),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: Colors.black.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),

      // Text Theme - Clean Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: TropicalColors.darkText,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          color: TropicalColors.darkText,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: TropicalColors.darkText,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: TropicalColors.darkText,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: TropicalColors.darkText,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.1,
          color: TropicalColors.darkText,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.normal,
          letterSpacing: 0.1,
          color: TropicalColors.mediumText,
        ),
      ),
    );
  }
}
