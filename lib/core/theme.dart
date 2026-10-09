import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const cream = Color(0xFFF9F6F0);
  static const terracotta = Color(0xFFE05A47);
  static const sage = Color(0xFF4A7C59);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0x0D000000);
  static const ink = Color(0xFF2B2623);
  static const muted = Color(0xFF7A716B);
  static const amber = Color(0xFFFFF3D6);
  static const amberInk = Color(0xFF8A5A00);
}

const cardShadow = [
  BoxShadow(color: AppColors.border, blurRadius: 16, offset: Offset(0, 6)),
];

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.terracotta,
    primary: AppColors.terracotta,
    secondary: AppColors.sage,
    surface: AppColors.surface,
  );
  final text = GoogleFonts.nunitoTextTheme().apply(
    bodyColor: AppColors.ink,
    displayColor: AppColors.ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
    textTheme: text,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    ),
  );
}
