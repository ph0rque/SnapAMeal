import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// A subtle indicator widget that shows when the app is in demo mode
class DemoModeIndicator extends StatelessWidget {
  final bool showLabel;
  final double size;
  final Color? color;

  const DemoModeIndicator({
    super.key,
    this.showLabel = true,
    this.size = 16.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isCurrentUserDemo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final indicatorColor = color ?? theme.colorScheme.secondary;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: indicatorColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: indicatorColor.withOpacity(0.3),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.science_outlined,
                size: size,
                color: indicatorColor,
              ),
              if (showLabel) ...[
                const SizedBox(width: 4.0),
                Text(
                  'DEMO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: indicatorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.0,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// A compact demo mode indicator for use in app bars and navigation
class CompactDemoIndicator extends StatelessWidget {
  const CompactDemoIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const DemoModeIndicator(
      showLabel: false,
      size: 14.0,
    );
  }
}

/// A banner-style demo indicator for prominent display
class DemoBannerIndicator extends StatelessWidget {
  final String? message;
  final VoidCallback? onTap;

  const DemoBannerIndicator({
    super.key,
    this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isCurrentUserDemo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final bannerColor = theme.colorScheme.tertiary;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  bannerColor.withOpacity(0.1),
                  bannerColor.withOpacity(0.05),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: bannerColor.withOpacity(0.2),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 16.0,
                  color: bannerColor,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    message ?? 'Demo Mode - Showcasing SnapAMeal features',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: bannerColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8.0),
                  Icon(
                    Icons.info_outline,
                    size: 16.0,
                    color: bannerColor.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Extension to easily add demo indicators to existing widgets
extension DemoModeExtension on Widget {
  /// Wraps the widget with a demo mode indicator if in demo mode
  Widget withDemoIndicator({
    bool showBanner = false,
    String? bannerMessage,
    VoidCallback? onBannerTap,
  }) {
    return Column(
      children: [
        if (showBanner)
          DemoBannerIndicator(
            message: bannerMessage,
            onTap: onBannerTap,
          ),
        Expanded(child: this),
      ],
    );
  }
} 