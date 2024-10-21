// lib/components/responsive.dart

import 'package:flutter/material.dart';

class Responsive {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;

  // Helper methods untuk mengecek device type
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // Method untuk mendapatkan width berdasarkan persentase dari screen width
  static double getWidth(BuildContext context, {double percentage = 100}) =>
      MediaQuery.of(context).size.width * (percentage / 100);

  // Method untuk mendapatkan height berdasarkan persentase dari screen height
  static double getHeight(BuildContext context, {double percentage = 100}) =>
      MediaQuery.of(context).size.height * (percentage / 100);

  // Helper methods untuk font sizes
  static double getFontSize(
    BuildContext context, {
    double mobile = 14,
    double tablet = 16,
    double desktop = 18,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Helper methods untuk padding
  static EdgeInsets getPadding(
    BuildContext context, {
    EdgeInsets mobile = const EdgeInsets.all(8),
    EdgeInsets tablet = const EdgeInsets.all(16),
    EdgeInsets desktop = const EdgeInsets.all(24),
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  // Helper method untuk card height
  static double getCardHeight(BuildContext context) {
    if (isMobile(context)) return 120;
    if (isTablet(context)) return 150;
    return 180;
  }

  // Helper method untuk chart size
  static double getChartSize(BuildContext context) {
    if (isMobile(context)) return 200;
    if (isTablet(context)) return 300;
    return 400;
  }

  // Helper method untuk grid columns
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 2;
    if (isTablet(context)) return 3;
    return 4;
  }

  static double getAspectRatio(BuildContext context) {
    if (isMobile(context)) return 1.5; // Increased from 1.2
    if (isTablet(context)) return 1.8; // Increased from 1.5
    return 2.0; // Keep desktop the same
  }
}
