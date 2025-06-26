import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapameal/design_system/colors.dart';

class SnapUITypography {
  const SnapUITypography._();

  static final TextTheme lightTextTheme = TextTheme(
    displayLarge: GoogleFonts.nunitoSans(fontSize: 32, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryLight),
    displayMedium: GoogleFonts.nunitoSans(fontSize: 28, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryLight),
    headlineMedium: GoogleFonts.nunitoSans(fontSize: 24, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryLight),
    titleLarge: GoogleFonts.nunitoSans(fontSize: 20, fontWeight: FontWeight.w600, color: SnapUIColors.textPrimaryLight),
    bodyLarge: GoogleFonts.nunitoSans(fontSize: 16, fontWeight: FontWeight.normal, color: SnapUIColors.textPrimaryLight),
    bodyMedium: GoogleFonts.nunitoSans(fontSize: 14, fontWeight: FontWeight.normal, color: SnapUIColors.textSecondaryLight),
    labelLarge: GoogleFonts.nunitoSans(fontSize: 16, fontWeight: FontWeight.bold, color: SnapUIColors.white), // For buttons
  );

  static final TextTheme darkTextTheme = TextTheme(
    displayLarge: GoogleFonts.nunitoSans(fontSize: 32, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryDark),
    displayMedium: GoogleFonts.nunitoSans(fontSize: 28, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryDark),
    headlineMedium: GoogleFonts.nunitoSans(fontSize: 24, fontWeight: FontWeight.bold, color: SnapUIColors.textPrimaryDark),
    titleLarge: GoogleFonts.nunitoSans(fontSize: 20, fontWeight: FontWeight.w600, color: SnapUIColors.textPrimaryDark),
    bodyLarge: GoogleFonts.nunitoSans(fontSize: 16, fontWeight: FontWeight.normal, color: SnapUIColors.textPrimaryDark),
    bodyMedium: GoogleFonts.nunitoSans(fontSize: 14, fontWeight: FontWeight.normal, color: SnapUIColors.textSecondaryDark),
    labelLarge: GoogleFonts.nunitoSans(fontSize: 16, fontWeight: FontWeight.bold, color: SnapUIColors.white), // For buttons
  );
} 