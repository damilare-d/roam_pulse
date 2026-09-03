import 'package:flutter/material.dart';

/// RoamPulse's palette: calm, trustworthy, travel + technology — not a
/// dashboard of alarming reds. Status colors are reserved for genuine
/// state changes (see docs/PRODUCT_DISCOVERY.md principle 2: "reassure by
/// default, alarm only when true").
abstract final class AppColors {
  static const Color primary = Color(0xFF1D4E89);
  static const Color primaryLight = Color(0xFF5B85B8);

  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF1A1D24);
  static const Color textSecondary = Color(0xFF5C6370);
  static const Color divider = Color(0xFFE3E6EA);

  /// Connected / healthy.
  static const Color positive = Color(0xFF2E9E5B);

  /// Degraded / needs attention soon.
  static const Color warning = Color(0xFFC98A1B);

  /// Offline / error.
  static const Color negative = Color(0xFFC94B3D);

  /// Unknown / synchronizing — deliberately neutral, not alarming.
  static const Color neutral = Color(0xFF8A93A2);
}
