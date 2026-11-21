import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scamshield/core/theme/app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.neel,
      primary: AppColors.neel,
      onPrimary: Colors.white,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
      error: AppColors.danger,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.chalk,
    );

    TextStyle hind(
      double size,
      FontWeight weight, {
      double height = 1.3,
      Color color = AppColors.ink,
    }) => GoogleFonts.hindSiliguri(
      fontSize: size,
      fontWeight: weight,
      height: height,
      color: color,
    );

    final text = base.textTheme
        .apply(
          fontFamily: GoogleFonts.hindSiliguri().fontFamily,
          bodyColor: AppColors.ink,
          displayColor: AppColors.ink,
        )
        .copyWith(
          displaySmall: hind(34, FontWeight.w700, height: 1.2),
          headlineMedium: hind(28, FontWeight.w700, height: 1.25),
          titleLarge: hind(24, FontWeight.w700),
          titleMedium: hind(20, FontWeight.w600),
          bodyLarge: hind(20, FontWeight.w500, height: 1.45),
          bodyMedium: hind(18, FontWeight.w400, height: 1.45),
          bodySmall: hind(
            16,
            FontWeight.w400,
            height: 1.4,
            color: AppColors.muted,
          ),
          labelLarge: hind(20, FontWeight.w700),
        );

    final rounded20 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );
    OutlineInputBorder field(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: color, width: width),
    );

    return base.copyWith(
      textTheme: text,
      iconTheme: const IconThemeData(size: 30, color: AppColors.ink),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.chalk,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 76,
        titleTextStyle: text.titleLarge,
        iconTheme: const IconThemeData(size: 32, color: AppColors.ink),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(68),
          textStyle: text.labelLarge,
          shape: rounded20,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(68),
          textStyle: text.labelLarge,
          shape: rounded20,
          side: const BorderSide(color: AppColors.neel, width: 2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.all(20),
        hintStyle: text.bodyLarge?.copyWith(color: AppColors.muted),
        border: field(AppColors.line, 2),
        enabledBorder: field(AppColors.line, 2),
        focusedBorder: field(AppColors.neel, 3),
        errorBorder: field(AppColors.danger, 2),
        focusedErrorBorder: field(AppColors.danger, 3),
        errorStyle: text.bodySmall?.copyWith(color: AppColors.danger),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.neelDeep,
        contentTextStyle: text.bodyLarge?.copyWith(color: Colors.white),
      ),
    );
  }
}
