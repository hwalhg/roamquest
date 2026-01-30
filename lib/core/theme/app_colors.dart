import 'package:flutter/material.dart';

/// Application color scheme
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5B4BC4);
  static const Color primaryLight = Color(0xFFA29BFE);

  // Secondary Colors
  static const Color secondary = Color(0xFF00CEC9);
  static const Color secondaryDark = Color(0xFF00B5B0);
  static const Color secondaryLight = Color(0xFF81ECEC);

  // Accent Colors
  static const Color accent = Color(0xFFFD79A8);
  static const Color accentYellow = Color(0xFFFDCB6E);

  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
  static const Color textTertiary = Color(0xFFB2BEC3);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // Status Colors
  static const Color success = Color(0xFF00B894);
  static const Color successLight = Color(0xFF55EFC4);
  static const Color error = Color(0xFFD63031);
  static const Color errorLight = Color(0xFFFF7675);
  static const Color warning = Color(0xFFFDCB6E);
  static const Color info = Color(0xFF74B9FF);

  // Category Colors
  static const Color landmark = Color(0xFFFF6B6B);
  static const Color food = Color(0xFF4ECDC4);
  static const Color experience = Color(0xFF45B7D1);
  static const Color hidden = Color(0xFF96CEB4);

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'landmark':
        return landmark;
      case 'food':
        return food;
      case 'experience':
        return experience;
      case 'hidden':
        return hidden;
      default:
        return primary;
    }
  }

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF6C5CE7),
    Color(0xFFA29BFE),
  ];

  static const List<Color> sunsetGradient = [
    Color(0xFF6C5CE7),
    Color(0xFFFD79A8),
    Color(0xFFFDCB6E),
  ];

  static const List<Color> oceanGradient = [
    Color(0xFF00CEC9),
    Color(0xFF0984E3),
  ];

  // Overlay & Shadow Colors
  static const Color overlay = Color(0x80000000);
  static const Color shadow = Color(0x1A000000);
  static const Color border = Color(0xFFDFE6E9);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
}
