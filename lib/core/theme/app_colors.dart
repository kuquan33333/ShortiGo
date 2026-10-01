import 'package:flutter/material.dart';

/// Short-drama palette. Keep this centralized so player, shelves and cards
/// share the same visual language.
class AppColors {
  const AppColors._();

  // Backgrounds
  static const Color bg = Color(0xFF050505);
  static const Color surface = Color(0xFF121212);
  static const Color surfaceElevated = Color(0xFF202020);
  static const Color divider = Color(0xFF2E2E2E);

  // Brand
  static const Color primary = Color(0xFFFF2D68);
  static const Color primaryLight = Color(0xFFFF6C91);
  static const Color accent = Color(0xFFFF9F43);

  // Text
  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textSecondary = Color(0xFFB9B9B9);
  static const Color textMuted = Color(0xFF777777);

  // Status
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // VIP gold
  static const Color vipGold = Color(0xFFFFD166);
}
