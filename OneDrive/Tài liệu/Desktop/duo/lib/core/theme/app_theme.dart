import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final bg = isDark ? AppColors.gray950 : AppColors.gray50;
    final surface = isDark ? AppColors.gray900 : AppColors.white;
    final inputFill = isDark ? AppColors.gray800 : AppColors.gray100;

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      primaryColor: AppColors.rose500,
      colorScheme: isDark
          ? const ColorScheme.dark(
              primary: AppColors.rose500,
              secondary: AppColors.plum500,
              surface: AppColors.gray900,
              onSurface: AppColors.white,
              error: AppColors.red500,
            )
          : const ColorScheme.light(
              primary: AppColors.rose500,
              secondary: AppColors.plum700,
              surface: AppColors.white,
              onSurface: AppColors.black,
              error: AppColors.red500,
            ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.display1,
        headlineLarge: AppTextStyles.h1,
        headlineMedium: AppTextStyles.h2,
        titleMedium: AppTextStyles.h3,
        bodyLarge: AppTextStyles.bodyLg,
        bodyMedium: AppTextStyles.bodyMd,
        bodySmall: AppTextStyles.bodySm,
        labelLarge: AppTextStyles.labelLg,
        labelMedium: AppTextStyles.labelMd,
        labelSmall: AppTextStyles.labelSm,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: isDark ? AppColors.white : AppColors.black,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.h2.copyWith(
          color: isDark ? AppColors.white : AppColors.black,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: AppColors.rose500,
        unselectedItemColor: AppColors.gray400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTextStyles.labelSm,
        unselectedLabelStyle: AppTextStyles.labelSm,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: AppTextStyles.bodyMd.copyWith(color: AppColors.gray400),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.rose500, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rose500,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          elevation: 0,
          textStyle: AppTextStyles.labelLg,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.rose500,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AppColors.rose500, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppTextStyles.labelLg,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gray400,
          textStyle: AppTextStyles.labelLg,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.gray700 : AppColors.gray200,
        thickness: 1,
      ),
      fontFamily: GoogleFonts.dmSans().fontFamily,
    );
  }
}
