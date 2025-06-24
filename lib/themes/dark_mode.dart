import 'package:flutter/material.dart';
import 'package:snapameal/design_system/colors.dart';
import 'package:snapameal/design_system/typography.dart';

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    surface: SnapUIColors.backgroundDark,
    primary: SnapUIColors.primaryYellow,
    secondary: SnapUIColors.accentBlue,
    tertiary: SnapUIColors.accentPurple,
    error: SnapUIColors.accentRed,
    onPrimary: SnapUIColors.black,
    onSecondary: SnapUIColors.white,
    onSurface: SnapUIColors.textPrimaryDark,
  ),
  textTheme: SnapUITypography.darkTextTheme,
  scaffoldBackgroundColor: SnapUIColors.backgroundDark,
  appBarTheme: AppBarTheme(
    backgroundColor: SnapUIColors.backgroundDark,
    elevation: 0,
    iconTheme: const IconThemeData(color: SnapUIColors.textPrimaryDark),
    titleTextStyle: SnapUITypography.darkTextTheme.titleLarge,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: SnapUIColors.secondaryDark,
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: SnapUIColors.greyDark),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: SnapUIColors.primaryYellow),
      borderRadius: BorderRadius.circular(8),
    ),
  ),
); 