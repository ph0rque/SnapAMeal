import 'package:flutter/material.dart';
import 'package:snapameal/design_system/colors.dart';
import 'package:snapameal/design_system/typography.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    surface: SnapUIColors.backgroundLight,
    primary: SnapUIColors.primaryYellow,
    secondary: SnapUIColors.accentBlue,
    tertiary: SnapUIColors.accentPurple,
    error: SnapUIColors.accentRed,
    onPrimary: SnapUIColors.black,
    onSecondary: SnapUIColors.white,
    onSurface: SnapUIColors.textPrimaryLight,
  ),
  textTheme: SnapUITypography.lightTextTheme,
  scaffoldBackgroundColor: SnapUIColors.backgroundLight,
  appBarTheme: AppBarTheme(
    backgroundColor: SnapUIColors.backgroundLight,
    elevation: 0,
    iconTheme: const IconThemeData(color: SnapUIColors.textPrimaryLight),
    titleTextStyle: SnapUITypography.lightTextTheme.titleLarge,
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: SnapUIColors.greyBackground,
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: SnapUIColors.border),
      borderRadius: BorderRadius.circular(8),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: SnapUIColors.primaryYellow),
      borderRadius: BorderRadius.circular(8),
    ),
  ),
); 