import 'package:flutter/material.dart';

class SnapUIColors {
  // Prevent instantiation
  const SnapUIColors._();

  // Primary Palette
  static const Color primaryYellow = Color(0xFFFFC107); // A vibrant, golden yellow
  static const Color secondaryDark = Color(0xFF212121); // A very dark grey

  // Accent Palette
  static const Color accentBlue = Color(0xFF2196F3);  // For chat, links, and info
  static const Color accentRed = Color(0xFFE53935);   // For recording, errors, and alerts
  static const Color accentPurple = Color(0xFF9C27B0); // For stories and special events
  static const Color accentGreen = Color(0xFF4CAF50);  // For success states

  // Greyscale Palette
  static const Color black = Color(0xFF000000);
  static const Color greyDark = Color(0xFF424242);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color greyBackground = Color(0xFFF5F5F5); // For light theme backgrounds
  static const Color white = Color(0xFFFFFFFF);

  // Semantic Colors (for theming)
  static const Color backgroundLight = white;
  static const Color backgroundDark = black;
  static const Color textPrimaryLight = black;
  static const Color textPrimaryDark = white;
  static const Color textSecondaryLight = greyDark;
  static const Color textSecondaryDark = grey;
  static const Color border = greyLight;
} 