import 'package:flutter/material.dart';

class AppColors {
  
  static const Color primary = Color(0xFF1E0A07);
  static const Color primaryContainer = Color(0xFF361F1A);
  static const Color secondary = Color(0xFF9D4406);
  static const Color onSecondary = Color(0xFFFFFFFF);

  
  static const Color surface = Color(0xFFFFF8F6);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFEF1EC);
  static const Color surfaceContainer = Color(0xFFF8EBE6);
  static const Color surfaceContainerHigh = Color(0xFFF2E6E1);
  static const Color surfaceContainerHighest = Color(0xFFECE0DB);
  static const Color surfaceDim = Color(0xFFE3D8D3);


  static const Color onSurface = Color(0xFF201A18);
  static const Color onSurfaceVariant = Color(0xFF504442);
  static const Color outline = Color(0xFF827471);
  static const Color outlineVariant = Color(0xFFD4C3BF);

  
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}

class AppTextStyles {
  static const String headlineFont = 'Manrope';
  static const String bodyFont = 'WorkSans';

  static TextStyle displayLg = const TextStyle(
    fontFamily: headlineFont,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryContainer,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static TextStyle headlineMd = const TextStyle(
    fontFamily: headlineFont,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.primaryContainer,
  );

  static TextStyle headlineSm = const TextStyle(
    fontFamily: headlineFont,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryContainer,
  );

  static TextStyle titleLg = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle titleMd = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static TextStyle bodyLg = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static TextStyle bodyMd = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static TextStyle labelLg = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelMd = const TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.onSurfaceVariant,
  );
}

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: Colors.white,
          secondary: AppColors.secondary,
          onSecondary: Colors.white,
          error: AppColors.error,
          onError: Colors.white,
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
        ),
        fontFamily: 'WorkSans',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.primaryContainer,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.outline,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
      );
}