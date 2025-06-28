import 'package:flutter/material.dart';
import 'package:snapameal/design_system/colors.dart';
import 'package:snapameal/design_system/dimensions.dart';

enum SnapButtonType { primary, secondary }

class SnapButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String text;
  final SnapButtonType type;

  const SnapButton({
    super.key,
    required this.onTap,
    required this.text,
    this.type = SnapButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = type == SnapButtonType.primary
        ? SnapUIColors.primaryYellow
        : SnapUIColors.secondaryDark;

    final foregroundColor = type == SnapButtonType.primary
        ? SnapUIColors.black
        : SnapUIColors.white;

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(
          horizontal: SnapUIDimensions.spacingXL,
          vertical: SnapUIDimensions.spacingL,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SnapUIDimensions.radiusM),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
      child: Center(child: Text(text)),
    );
  }
}
