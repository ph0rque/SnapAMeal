import 'package:flutter/material.dart';
import 'package:snapameal/design_system/colors.dart';
import 'package:snapameal/design_system/typography.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    surface: SnapUIColors.backgroundLight,
    primary: SnapUIColors.accentGreen, // Health-focused green primary
    secondary: SnapUIColors.primaryYellow, // Energetic yellow secondary
    tertiary: SnapUIColors.accentBlue, // Calming blue tertiary
    error: SnapUIColors.accentRed,
    onPrimary: SnapUIColors.white,
    onSecondary: SnapUIColors.black,
    onSurface: SnapUIColors.textPrimaryLight,
  ),
  textTheme: SnapUITypography.lightTextTheme,
  scaffoldBackgroundColor: SnapUIColors.backgroundLight,
  appBarTheme: AppBarTheme(
    backgroundColor: SnapUIColors.accentGreen, // Health-focused app bar
    elevation: 0,
    iconTheme: const IconThemeData(color: SnapUIColors.white),
    titleTextStyle: SnapUITypography.lightTextTheme.titleLarge?.copyWith(
      color: SnapUIColors.white,
      fontWeight: FontWeight.w600,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: SnapUIColors.greyBackground,
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: SnapUIColors.border),
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
    color: SnapUIColors.white,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: SnapUIColors.accentGreen,
    foregroundColor: SnapUIColors.white,
  ),
); 