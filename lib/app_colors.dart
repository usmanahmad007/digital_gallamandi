import 'package:flutter/material.dart';

class AppColors {
  // Main Theme Colors
  static const Color primaryGreen = Color(0xFF2E7D32);  // Harvest Green
  static const Color secondaryBrown = Color(0xFF8D6E63); // Soil Brown
  static const Color accentYellow = Color(0xFFFBC02D);  // Sunshine Mustard

  // Neutral Colors
  static const Color background = Color(0xFFF8F9FA);    // Clean off-white
  static const Color cardWhite = Colors.white;
  static const Color textDark = Color(0xFF212121);
  static const Color textGrey = Color(0xFF757575);

  // Feedback Colors
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color successGreen = Color(0xFF388E3C);

  // Field Colors
  static Color fieldFill = Colors.grey.withOpacity(0.05);
  static Color fieldFocus = primaryGreen.withOpacity(0.1);
}