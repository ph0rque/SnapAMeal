import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapameal/design_system/colors.dart';

class SnapUITypography {
  const SnapUITypography._();

  // Fallback font family for when Google Fonts fails to load
  static const String _fallbackFontFamily = 'SF Pro Display'; // macOS system font
  
  // Helper method to create text style with fallback
  static TextStyle _createTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
  }) {
    try {
      return GoogleFonts.nunitoSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fallbackFontFamily: _fallbackFontFamily,
      );
    } catch (e) {
      // Fallback to system font if Google Fonts fails
      return TextStyle(
        fontFamily: _fallbackFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
  }

  static final TextTheme lightTextTheme = TextTheme(
    displayLarge: _createTextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryLight),
    displayMedium: _createTextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryLight),
    headlineMedium: _createTextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryLight),
    titleLarge: _createTextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: SnapUIColors.textPrimaryLight),
    bodyLarge: _createTextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: SnapUIColors.textPrimaryLight),
    bodyMedium: _createTextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: SnapUIColors.textSecondaryLight),
    labelLarge: _createTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SnapUIColors.white), // For buttons
  );

  static final TextTheme darkTextTheme = TextTheme(
    displayLarge: _createTextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryDark),
    displayMedium: _createTextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryDark),
    headlineMedium: _createTextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryDark),
    titleLarge: _createTextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: SnapUIColors.textPrimaryDark),
    bodyLarge: _createTextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: SnapUIColors.textPrimaryDark),
    bodyMedium: _createTextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: SnapUIColors.textSecondaryDark),
    labelLarge: _createTextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: SnapUIColors.white), // For buttons
  );
} 