import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';

class SnapChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;

  const SnapChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isCurrentUser
        ? SnapUIColors.primaryYellow
        : SnapUIColors.greyLight;
    
    final textColor = isCurrentUser
        ? SnapUIColors.black
        : SnapUIColors.textPrimaryLight;

    return Container(
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(SnapUIDimensions.radiusL),
          topRight: const Radius.circular(SnapUIDimensions.radiusL),
          bottomLeft: isCurrentUser
              ? const Radius.circular(SnapUIDimensions.radiusL)
              : const Radius.circular(0),
          bottomRight: isCurrentUser
              ? const Radius.circular(0)
              : const Radius.circular(SnapUIDimensions.radiusL),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SnapUIDimensions.spacingL,
        vertical: SnapUIDimensions.spacingM,
      ),
      margin: const EdgeInsets.symmetric(
        vertical: SnapUIDimensions.spacingXS,
        horizontal: SnapUIDimensions.spacingS,
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: textColor),
      ),
    );
  }
} 