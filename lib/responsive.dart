import 'package:flutter/material.dart';

extension ResponsiveExt on BuildContext {
  bool get isDesktop => MediaQuery.of(this).size.width >= 1100;
  bool get isTablet => MediaQuery.of(this).size.width >= 600 && MediaQuery.of(this).size.width < 1100;
  bool get isMobile => MediaQuery.of(this).size.width < 600;

  double wp(double percent) => MediaQuery.of(this).size.width * percent;
  double hp(double percent) => MediaQuery.of(this).size.height * percent;
}

extension ColorWithValues on Color {
  /// Lightweight compatibility shim for `withValues(alpha: x)` used in the codebase.
  /// Maps `alpha` (0.0-1.0) to `withOpacity`.
  Color withValues({double? alpha}) {
    if (alpha == null) return this;
    final normalizedAlpha = alpha.clamp(0.0, 1.0);
    return withAlpha((normalizedAlpha * 255).round());
  }
}
