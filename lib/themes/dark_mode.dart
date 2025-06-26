import 'package:flutter/material.dart';
import 'package:snapameal/design_system/colors.dart';
import 'package:snapameal/design_system/typography.dart';

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    surface: SnapUIColors.backgroundDark,
    primary: SnapUIColors.accentGreen, // Health-focused green primary
    secondary: SnapUIColors.primaryYellow, // Energetic yellow secondary
    tertiary: SnapUIColors.accentBlue, // Calming blue tertiary
    error: SnapUIColors.accentRed,
    onPrimary: SnapUIColors.white,
    onSecondary: SnapUIColors.black,
    onSurface: SnapUIColors.textPrimaryDark,
  ),
  textTheme: SnapUITypography.darkTextTheme,
  scaffoldBackgroundColor: SnapUIColors.backgroundDark,
  appBarTheme: AppBarTheme(
    backgroundColor: SnapUIColors.backgroundDark, // Keep dark for dark mode
    elevation: 0,
    iconTheme: const IconThemeData(color: SnapUIColors.accentGreen),
    titleTextStyle: SnapUITypography.darkTextTheme.titleLarge?.copyWith(
      color: SnapUIColors.accentGreen,
      fontWeight: FontWeight.w600,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: SnapUIColors.secondaryDark,
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: SnapUIColors.greyDark),
      borderRadius: BorderRadius.circular(12), // More rounded for modern health app feel
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: SnapUIColors.accentGreen, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: SnapUIColors.accentGreen,
      foregroundColor: SnapUIColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  cardTheme: const CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    color: SnapUIColors.greyDark,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: SnapUIColors.accentGreen,
    foregroundColor: SnapUIColors.white,
  ),
); 