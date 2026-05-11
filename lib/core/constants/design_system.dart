/// Design System untuk HIMAKOM Attendance App
/// Mengikuti Material Design 3 dengan referensi dari UI mockup yang diberikan
import 'package:flutter/material.dart';

/// Palet warna utama untuk aplikasi
class AppColors {
  AppColors._(); // prevent instantiation

  /// ─── Primary Colors ──────────────────────────────
  /// Warna biru terang sebagai primary color (mengikuti referensi UI)
  static const Color primary = Color(0xFF0056CC); // Bright Blue
  static const Color primaryDark = Color(0xFF0043A3); // Darker Blue
  static const Color primaryLight = Color(0xFF4D94FF); // Lighter Blue
  static const Color primarySurface = Color(0xFFE8F0FF); // Very Light Blue bg

  /// ─── Neutral Colors ──────────────────────────────
  static const Color background = Color(0xFFFAFAFA); // Off-white background
  static const Color surface = Color(0xFFFFFFFF); // Pure white for cards/surfaces
  static const Color error = Color(0xFFDC3545); // Bootstrap red
  static const Color errorLight = Color(0xFFF8D7DA); // Light error background
  static const Color success = Color(0xFF28A745); // Bootstrap green
  static const Color successLight = Color(0xFFD4EDDA); // Light success background
  static const Color warning = Color(0xFFFFC107); // Bootstrap warning/yellow
  static const Color warningLight = Color(0xFFFFF3CD); // Light warning background
  static const Color info = Color(0xFF17A2B8); // Bootstrap info/cyan
  static const Color infoLight = Color(0xFFD1ECF1); // Light info background

  /// ─── Text Colors ────────────────────────────────
  static const Color textPrimary = Color(0xFF1F2937); // Dark gray/black text
  static const Color textSecondary = Color(0xFF6B7280); // Medium gray text
  static const Color textTertiary = Color(0xFF9CA3AF); // Light gray text
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on primary

  /// ─── Border & Divider Colors ────────────────────
  static const Color border = Color(0xFFE5E7EB); // Light gray border
  static const Color divider = Color(0xFFF3F4F6); // Very light divider

  /// ─── Status Colors ───────────────────────────────
  static const Color hadir = success; // Green for present/valid
  static const Color izin = info; // Cyan for excused
  static const Color alpha = error; // Red for absent/invalid
  static const Color terlambat = warning; // Yellow for late
}

/// Ukuran dan spacing konsisten
class AppSpacing {
  AppSpacing._(); // prevent instantiation

  /// Padding & Margin standar (menggunakan 8pt grid system)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  /// Border radius untuk berbagai elemen
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;

  /// Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 48.0;

  /// Button heights
  static const double buttonHeightSm = 36.0;
  static const double buttonHeightMd = 44.0;
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightXl = 56.0;

  /// App Bar height
  static const double appBarHeight = 56.0;
  static const double appBarHeightLarge = 104.0;

  /// Bottom navigation bar height
  static const double bottomNavHeight = 80.0;
}

/// Typography styles sesuai Material Design 3
class AppTypography {
  AppTypography._(); // prevent instantiation

  /// Display styles (untuk judul besar/headline)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w700, // bold
    height: 1.25,
    letterSpacing: 0.0,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28.0,
    fontWeight: FontWeight.w700,
    height: 1.29,
    letterSpacing: 0.0,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    height: 1.33,
    letterSpacing: 0.0,
  );

  /// Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0.0,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600, // semibold
    height: 1.44,
    letterSpacing: 0.0,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.0,
  );

  /// Title styles
  static const TextStyle titleLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.1,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 1.57,
    letterSpacing: 0.1,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    height: 1.67,
    letterSpacing: 0.1,
  );

  /// Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400, // regular
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 1.43,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 1.33,
    letterSpacing: 0.4,
  );

  /// Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.5,
  );
}

/// Shadow definitions untuk elevation
class AppShadows {
  AppShadows._(); // prevent instantiation

  /// Elevation 0 (no shadow)
  static const List<BoxShadow> elevation0 = [];

  /// Elevation 1 (subtle shadow)
  static const List<BoxShadow> elevation1 = [
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  /// Elevation 2 (small card shadow)
  static const List<BoxShadow> elevation2 = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 2),
      blurRadius: 6,
      spreadRadius: 0,
    ),
  ];

  /// Elevation 3 (medium card shadow)
  static const List<BoxShadow> elevation3 = [
    BoxShadow(
      color: Color(0x12000000),
      offset: Offset(0, 3),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];

  /// Elevation 4 (prominent shadow)
  static const List<BoxShadow> elevation4 = [
    BoxShadow(
      color: Color(0x17000000),
      offset: Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];
}

/// Extension untuk menambahkan shadow ke Container dengan mudah
extension ShadowExtension on BoxDecoration {
  BoxDecoration withShadow(List<BoxShadow> shadows) {
    return BoxDecoration(
      color: color,
      border: border,
      borderRadius: borderRadius,
      boxShadow: shadows,
    );
  }
}

/// Transition durations
class AppDurations {
  AppDurations._(); // prevent instantiation

  static const Duration instant = Duration(milliseconds: 0);
  static const Duration short = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration long = Duration(milliseconds: 500);
  static const Duration extraLong = Duration(milliseconds: 1000);
}
