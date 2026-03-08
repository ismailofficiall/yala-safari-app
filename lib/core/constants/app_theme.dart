import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFF2E7D32);
  static const Color accentGold = Color(0xFFB8954F);
  static const Color lightGreen = Color(0xFF66BB6A);
  static const Color background = Color(0xFFE8EDE6);
  static const Color surface = Color(0xFFFBFDF9);
  static const Color darkText = Color(0xFF141814);
  static const Color greyText = Color(0xFF5F6560);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFC8E6C9),
      onPrimaryContainer: const Color(0xFF0D2812),
      secondary: accentGold,
      onSecondary: const Color(0xFF1F1C14),
      tertiary: lightGreen,
      surface: surface,
      onSurface: darkText,
      onSurfaceVariant: greyText,
      surfaceContainerHighest: const Color(0xFFDEE5DF),
      outline: const Color(0xFFC5CDC7),
      outlineVariant: const Color(0xFFE2E8E3),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      splashColor: primaryGreen.withValues(alpha: 0.08),
      highlightColor: primaryGreen.withValues(alpha: 0.05),
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(
      bodyColor: darkText,
      displayColor: darkText,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: darkText,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: darkText, size: 22),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.07),
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: primaryGreen.withValues(alpha: 0.35),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        labelStyle: TextStyle(color: greyText, fontSize: 15, fontFamily: GoogleFonts.plusJakartaSans().fontFamily),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          color: primaryGreen,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        backgroundColor: surface,
        indicatorColor: primaryGreen.withValues(alpha: 0.14),
        surfaceTintColor: Colors.transparent,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.2,
            color: selected ? primaryGreen : greyText,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? primaryGreen : greyText,
            size: 24,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2D3330),
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 20, color: darkText),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primaryGreen,
        unselectedLabelColor: greyText,
        indicatorColor: primaryGreen,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
      ),
    );
  }
}
