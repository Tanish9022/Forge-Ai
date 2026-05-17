import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle display1 = GoogleFonts.syne(
    fontSize: 32,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    color: AppColors.white,
  );

  static TextStyle display2 = GoogleFonts.syne(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.white,
  );

  static TextStyle h1 = GoogleFonts.syne(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static TextStyle h2 = GoogleFonts.syne(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static TextStyle h3 = GoogleFonts.syne(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  static TextStyle bodyLg = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.white,
  );

  static TextStyle bodyMd = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.white,
  );

  static TextStyle bodySm = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.gray400,
  );

  static TextStyle labelLg = GoogleFonts.dmSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static TextStyle labelMd = GoogleFonts.dmSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.gray400,
  );

  static TextStyle labelSm = GoogleFonts.dmSans(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.gray400,
  );

  static TextStyle mono = GoogleFonts.dmMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.gray400,
  );
}
