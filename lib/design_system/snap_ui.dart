// This file serves as a single entry point for all design system components.
import 'package:flutter/material.dart';

// Foundations
export 'colors.dart';
export 'dimensions.dart';
export 'typography.dart';

// Widgets
export 'widgets/snap_button.dart';
export 'widgets/snap_textfield.dart';
export 'widgets/snap_avatar.dart';
export 'widgets/snap_chat_bubble.dart';
export 'widgets/snap_user_search.dart';

// Compatibility aliases for legacy code
import 'colors.dart';
import 'dimensions.dart';
import 'typography.dart';

// Legacy aliases for backward compatibility
class SnapUI {
  // Access the classes directly as they contain static members
  static const colors = SnapUIColors;
  static const dimensions = SnapUIDimensions;
  static const typography = SnapUITypography;

  // Color getters for backward compatibility
  static Color get backgroundColor => SnapUIColors.backgroundLight;
  static Color get primaryColor => SnapUIColors.primaryYellow;

  // Spacing getters
  static EdgeInsets get pagePadding =>
      const EdgeInsets.all(SnapUIDimensions.spacingM);
  static EdgeInsets get cardPadding =>
      const EdgeInsets.all(SnapUIDimensions.spacingM);
  static SizedBox get verticalSpaceXSmall =>
      const SizedBox(height: SnapUIDimensions.spacingXXS);
  static SizedBox get verticalSpaceSmall =>
      const SizedBox(height: SnapUIDimensions.spacingS);
  static SizedBox get verticalSpaceMedium =>
      const SizedBox(height: SnapUIDimensions.spacingM);
  static SizedBox get verticalSpaceLarge =>
      const SizedBox(height: SnapUIDimensions.spacingL);
  static SizedBox get horizontalSpaceSmall =>
      const SizedBox(width: SnapUIDimensions.spacingS);

  // Border radius getters
  static BorderRadius get borderRadius =>
      BorderRadius.circular(SnapUIDimensions.radiusM);

  // Text style getters
  static TextStyle get headingStyle =>
      SnapUITypography.lightTextTheme.headlineMedium!;
  static TextStyle get bodyStyle => SnapUITypography.lightTextTheme.bodyLarge!;
  static TextStyle get captionStyle =>
      SnapUITypography.lightTextTheme.bodyMedium!;

  // Decoration getters
  static BoxDecoration get cardDecorationWithBorder => BoxDecoration(
    color: SnapUIColors.white,
    borderRadius: BorderRadius.circular(SnapUIDimensions.radiusM),
    border: Border.all(color: SnapUIColors.border),
  );

  // Input decoration getter
  static InputDecoration get inputDecoration => InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(SnapUIDimensions.radiusM),
    ),
    contentPadding: const EdgeInsets.all(SnapUIDimensions.spacingM),
  );

  // AppBar method
  static AppBar appBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
  }) {
    return AppBar(
      title: Text(title),
      actions: actions,
      leading: leading,
      centerTitle: centerTitle,
      backgroundColor: SnapUIColors.primaryYellow,
      foregroundColor: SnapUIColors.secondaryDark,
    );
  }

  // Button methods
  static Widget primaryButton(
    String text,
    VoidCallback onPressed, {
    bool isLoading = false,
    IconData? icon,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: SnapUIColors.primaryYellow,
        foregroundColor: SnapUIColors.secondaryDark,
        padding: const EdgeInsets.symmetric(
          horizontal: SnapUIDimensions.spacingL,
          vertical: SnapUIDimensions.spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnapUIDimensions.radiusM),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(text),
              ],
            )
          : Text(text),
    );
  }

  static Widget secondaryButton(
    String text,
    VoidCallback onPressed, {
    bool isLoading = false,
    IconData? icon,
  }) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: SnapUIColors.primaryYellow,
        side: const BorderSide(color: SnapUIColors.primaryYellow),
        padding: const EdgeInsets.symmetric(
          horizontal: SnapUIDimensions.spacingL,
          vertical: SnapUIDimensions.spacingM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnapUIDimensions.radiusM),
        ),
      ),
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : icon != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(text),
              ],
            )
          : Text(text),
    );
  }

  // SnackBar methods
  static SnackBar successSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: SnapUIColors.accentGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapUIDimensions.radiusM),
      ),
    );
  }

  static SnackBar errorSnackBar(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: SnapUIColors.accentRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapUIDimensions.radiusM),
      ),
    );
  }
}

class SnapColors {
  static const primaryYellow = SnapUIColors.primaryYellow;
  static const secondaryDark = SnapUIColors.secondaryDark;
  static const accentBlue = SnapUIColors.accentBlue;
  static const accentRed = SnapUIColors.accentRed;
  static const accentPurple = SnapUIColors.accentPurple;
  static const accentGreen = SnapUIColors.accentGreen;
  static const black = SnapUIColors.black;
  static const greyDark = SnapUIColors.greyDark;
  static const grey = SnapUIColors.grey;
  static const greyLight = SnapUIColors.greyLight;
  static const greyBackground = SnapUIColors.greyBackground;
  static const white = SnapUIColors.white;
  static const backgroundLight = SnapUIColors.backgroundLight;
  static const backgroundDark = SnapUIColors.backgroundDark;
  static const textPrimaryLight = SnapUIColors.textPrimaryLight;
  static const textPrimaryDark = SnapUIColors.textPrimaryDark;
  static const textSecondaryLight = SnapUIColors.textSecondaryLight;
  static const textSecondaryDark = SnapUIColors.textSecondaryDark;
  static const border = SnapUIColors.border;

  // Additional semantic aliases
  static const primary = primaryYellow;
  static const secondary = secondaryDark;
  static const accent = accentBlue;
  static const error = accentRed;
  static const success = accentGreen;
  static const textPrimary = textPrimaryLight;
  static const textSecondary = textSecondaryLight;
  static const divider = greyLight;

  // Additional missing aliases for compatibility
  static const surface = white;
  static const shadow = black;
  static const warning = primaryYellow;
  static const cardBackground = greyBackground;

  // Missing properties referenced in data_conflicts_page.dart
  static const backgroundPrimary = backgroundLight;
  static const backgroundSecondary = greyBackground;
}

class SnapTypography {
  static final displayLarge = SnapUITypography.lightTextTheme.displayLarge!;
  static final displayMedium = SnapUITypography.lightTextTheme.displayMedium!;
  static final headlineMedium = SnapUITypography.lightTextTheme.headlineMedium!;
  static final titleLarge = SnapUITypography.lightTextTheme.titleLarge!;
  static final bodyLarge = SnapUITypography.lightTextTheme.bodyLarge!;
  static final bodyMedium = SnapUITypography.lightTextTheme.bodyMedium!;
  static final labelLarge = SnapUITypography.lightTextTheme.labelLarge!;

  // Additional aliases
  static final heading1 = displayLarge;
  static final heading2 = displayMedium;
  static final heading3 = headlineMedium;
  static final heading = headlineMedium; // Generic heading alias
  static final body = bodyLarge;
  static final caption = bodyMedium;

  // Missing properties referenced in data_conflicts_page.dart
  static final heading4 = titleLarge;
}

class SnapDimensions {
  static const spacingXXS = SnapUIDimensions.spacingXXS;
  static const spacingXS = SnapUIDimensions.spacingXS;
  static const spacingS = SnapUIDimensions.spacingS;
  static const spacingM = SnapUIDimensions.spacingM;
  static const spacingL = SnapUIDimensions.spacingL;
  static const spacingXL = SnapUIDimensions.spacingXL;
  static const spacingXXL = SnapUIDimensions.spacingXXL;

  static const radiusS = SnapUIDimensions.radiusS;
  static const radiusM = SnapUIDimensions.radiusM;
  static const radiusL = SnapUIDimensions.radiusL;
  static const radiusCircle = SnapUIDimensions.radiusCircle;

  static const iconSizeS = SnapUIDimensions.iconSizeS;
  static const iconSizeM = SnapUIDimensions.iconSizeM;
  static const iconSizeL = SnapUIDimensions.iconSizeL;

  static const borderWidthS = SnapUIDimensions.borderWidthS;
  static const borderWidthM = SnapUIDimensions.borderWidthM;

  // Additional common aliases
  static const paddingSmall = spacingS;
  static const paddingMedium = spacingM;
  static const paddingLarge = spacingL;
  static const borderRadius = radiusM;
  static const radiusMedium = radiusM;
}
