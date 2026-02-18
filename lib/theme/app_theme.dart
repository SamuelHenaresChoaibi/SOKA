import 'package:flutter/material.dart';
import 'package:soka/theme/app_colors.dart';

class AppTheme {
  static ThemeData darkTheme({bool highContrast = false}) {
    return _buildTheme(
      brightness: Brightness.dark,
      primary: highContrast ? const Color(0xFF000000) : AppColors.primary,
      background: highContrast ? const Color(0xFF000000) : AppColors.background,
      surface: highContrast ? const Color(0xFF101010) : AppColors.surface,
      secondary: highContrast ? const Color(0xFF141414) : AppColors.secondary,
      border: highContrast ? const Color(0xFF5E5E5E) : AppColors.border,
      accent: highContrast ? const Color(0xFFFFD84C) : AppColors.accent,
      accentSoft: highContrast ? const Color(0xFFCDA62A) : AppColors.accentSoft,
      textPrimary: highContrast
          ? const Color(0xFFFFFFFF)
          : AppColors.textPrimary,
      textSecondary: highContrast
          ? const Color(0xFFE2E2E2)
          : AppColors.textSecondary,
      textMuted: highContrast ? const Color(0xFFBFBFBF) : AppColors.textMuted,
    );
  }

  static ThemeData lightTheme({bool highContrast = false}) {
    return _buildTheme(
      brightness: Brightness.light,
      primary: highContrast ? const Color(0xFFFFFFFF) : const Color(0xFFF5F1E2),
      background: highContrast
          ? const Color(0xFFFFFFFF)
          : const Color(0xFFF8F5EA),
      surface: highContrast ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF),
      secondary: highContrast
          ? const Color(0xFFFFFFFF)
          : const Color(0xFFF2EAD0),
      border: highContrast ? const Color(0xFF525252) : const Color(0xFFD8CCAA),
      accent: highContrast ? const Color(0xFF8A6D1A) : const Color(0xFFB38A12),
      accentSoft: highContrast
          ? const Color(0xFF6C5414)
          : const Color(0xFF8A6D1A),
      textPrimary: highContrast
          ? const Color(0xFF000000)
          : const Color(0xFF171410),
      textSecondary: highContrast
          ? const Color(0xFF1A1A1A)
          : const Color(0xFF3F3728),
      textMuted: highContrast
          ? const Color(0xFF242424)
          : const Color(0xFF5C523F),
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color background,
    required Color surface,
    required Color secondary,
    required Color border,
    required Color accent,
    required Color accentSoft,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: accent,
        onPrimary: isDark ? primary : Colors.white,
        secondary: accentSoft,
        onSecondary: textPrimary,
        error: const Color(0xFFB3261E),
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: textMuted, fontWeight: FontWeight.w500),
        labelStyle: TextStyle(
          color: textSecondary,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: accent, width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEC5B5B), width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEC5B5B), width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: isDark ? primary : Colors.white,
          disabledBackgroundColor: border,
          disabledForegroundColor: textMuted,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: secondary,
        contentTextStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: primary.withValues(alpha: 0.96),
        indicatorColor: accent,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? (isDark ? primary : Colors.white) : textMuted,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? (isDark ? primary : Colors.white) : textMuted,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12,
          );
        }),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: textPrimary),
        headlineMedium: TextStyle(color: textPrimary),
        headlineSmall: TextStyle(color: textPrimary),
        titleLarge: TextStyle(color: textPrimary),
        titleMedium: TextStyle(color: textPrimary),
        titleSmall: TextStyle(color: textPrimary),
        bodyLarge: TextStyle(color: textPrimary),
        bodyMedium: TextStyle(color: textPrimary),
        bodySmall: TextStyle(color: textSecondary),
        labelLarge: TextStyle(color: textPrimary),
        labelMedium: TextStyle(color: textSecondary),
        labelSmall: TextStyle(color: textMuted),
      ),
    );
  }

  static ThemeData get ligthTheme => lightTheme();
}
