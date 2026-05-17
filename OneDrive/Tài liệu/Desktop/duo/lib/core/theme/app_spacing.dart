import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  /// Minimum touch target per accessibility spec.
  static const double minTouchTarget = 48.0;
}

class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 18.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

class AppShadows {
  AppShadows._();

  static const cardShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      offset: Offset(0, 4),
    ),
  ];

  static const popoverShadow = [
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 40,
      offset: Offset(0, 8),
    ),
  ];
}
