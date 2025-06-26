import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Contextual tooltip widget for demo mode features
class DemoTooltip extends StatelessWidget {
  final Widget child;
  final String message;
  final String? title;
  final IconData? icon;
  final Color? backgroundColor;
  final Duration showDuration;
  final bool showOnlyInDemo;

  const DemoTooltip({
    super.key,
    required this.child,
    required this.message,
    this.title,
    this.icon,
    this.backgroundColor,
    this.showDuration = const Duration(seconds: 3),
    this.showOnlyInDemo = true,
  });

  @override
  Widget build(BuildContext context) {
    if (showOnlyInDemo) {
      return FutureBuilder<bool>(
        future: AuthService().isCurrentUserDemo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!) {
            return child;
          }
          return _buildTooltip(context);
        },
      );
    }
    
    return _buildTooltip(context);
  }

  Widget _buildTooltip(BuildContext context) {
    return Tooltip(
      message: message,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: TextStyle(
        color: Theme.of(context).colorScheme.onInverseSurface,
        fontSize: 14,
      ),
      preferBelow: false,
      child: child,
    );
  }
}

/// Rich tooltip with title, icon, and detailed content for complex features
class RichDemoTooltip extends StatelessWidget {
  final Widget child;
  final String title;
  final String description;
  final IconData icon;
  final List<String>? bulletPoints;
  final VoidCallback? onLearnMore;
  final bool showOnlyInDemo;

  const RichDemoTooltip({
    super.key,
    required this.child,
    required this.title,
    required this.description,
    required this.icon,
    this.bulletPoints,
    this.onLearnMore,
    this.showOnlyInDemo = true,
  });

  @override
  Widget build(BuildContext context) {
    if (showOnlyInDemo) {
      return FutureBuilder<bool>(
        future: AuthService().isCurrentUserDemo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!) {
            return child;
          }
          return _buildRichTooltip(context);
        },
      );
    }
    
    return _buildRichTooltip(context);
  }

  Widget _buildRichTooltip(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRichTooltipDialog(context),
      child: Stack(
        children: [
          child,
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.help_outline,
                size: 12,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRichTooltipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            if (bulletPoints != null && bulletPoints!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...bulletPoints!.map((point) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(point)),
                  ],
                ),
              )),
            ],
          ],
        ),
        actions: [
          if (onLearnMore != null)
            TextButton(
              onPressed: onLearnMore,
              child: const Text('Learn More'),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

/// Predefined tooltips for common SnapAMeal features
class SnapAMealTooltips {
  /// RAG-powered AI insights tooltip
  static Widget ragInsights({required Widget child}) {
    return RichDemoTooltip(
      title: 'RAG-Powered AI Insights',
      description: 'Our AI uses Retrieval-Augmented Generation to provide personalized health advice based on your unique profile and the latest research.',
      icon: Icons.psychology_outlined,
      bulletPoints: [
        'Combines your personal data with scientific research',
        'Provides context-aware recommendations',
        'Learns and adapts to your preferences over time',
        'Backed by peer-reviewed health studies',
      ],
      child: child,
    );
  }

  /// Story permanence explanation tooltip
  static Widget storyPermanence({required Widget child}) {
    return RichDemoTooltip(
      title: 'Logarithmic Story Permanence',
      description: 'Stories become more permanent based on engagement. Popular content stays visible longer, creating a natural curation system.',
      icon: Icons.auto_stories_outlined,
      bulletPoints: [
        'High engagement = longer visibility',
        'Milestone achievements become permanent',
        'Creates meaningful content curation',
        'Encourages quality over quantity',
      ],
      child: child,
    );
  }

  /// AR content filtering tooltip
  static Widget arFiltering({required Widget child}) {
    return RichDemoTooltip(
      title: 'AR Content Filtering',
      description: 'Advanced AR filters help you stay focused during fasting by filtering out food-related content in your camera view.',
      icon: Icons.filter_alt_outlined,
      bulletPoints: [
        'Real-time food detection and blurring',
        'Customizable filter intensity',
        'Helps maintain fasting discipline',
        'Works with camera and social feeds',
      ],
      child: child,
    );
  }

  /// AI meal recognition tooltip
  static Widget mealRecognition({required Widget child}) {
    return RichDemoTooltip(
      title: 'AI Meal Recognition',
      description: 'Advanced computer vision instantly identifies your food, calculates nutrition, and logs your meals automatically.',
      icon: Icons.camera_alt_outlined,
      bulletPoints: [
        'Identifies 1000+ food items instantly',
        'Calculates accurate nutrition data',
        'Learns your eating patterns',
        'Suggests portion improvements',
      ],
      child: child,
    );
  }

  /// Social matching tooltip
  static Widget socialMatching({required Widget child}) {
    return RichDemoTooltip(
      title: 'AI-Powered Friend Matching',
      description: 'Our AI suggests friends with complementary health goals and similar journeys to enhance your social experience.',
      icon: Icons.people_outline,
      bulletPoints: [
        'Matches based on health goals and preferences',
        'Considers personality compatibility',
        'Suggests accountability partners',
        'Builds supportive communities',
      ],
      child: child,
    );
  }

  /// Fasting timer intelligence tooltip
  static Widget fastingIntelligence({required Widget child}) {
    return RichDemoTooltip(
      title: 'Intelligent Fasting Timer',
      description: 'Smart fasting timer that adapts to your schedule, predicts optimal windows, and provides personalized insights.',
      icon: Icons.timer_outlined,
      bulletPoints: [
        'Learns your optimal fasting patterns',
        'Predicts hunger waves and energy levels',
        'Suggests ideal eating windows',
        'Tracks mood and energy correlation',
      ],
      child: child,
    );
  }

  /// Health dashboard insights tooltip
  static Widget dashboardInsights({required Widget child}) {
    return RichDemoTooltip(
      title: 'Comprehensive Health Dashboard',
      description: 'Your personalized health command center with AI-driven insights, trend analysis, and predictive recommendations.',
      icon: Icons.dashboard_outlined,
      bulletPoints: [
        'Real-time health metric tracking',
        'Predictive trend analysis',
        'Personalized goal recommendations',
        'Integration with wearable devices',
      ],
      child: child,
    );
  }

  /// Simple tooltip for quick explanations
  static Widget simple({
    required Widget child,
    required String message,
    IconData? icon,
  }) {
    return DemoTooltip(
      message: message,
      icon: icon,
      child: child,
    );
  }
}

/// Helper widget to add demo tooltips to existing widgets
extension DemoTooltipExtension on Widget {
  /// Wraps widget with a simple demo tooltip
  Widget withDemoTooltip(String message, {IconData? icon}) {
    return SnapAMealTooltips.simple(
      message: message,
      icon: icon,
      child: this,
    );
  }

  /// Wraps widget with RAG insights tooltip
  Widget withRAGTooltip() {
    return SnapAMealTooltips.ragInsights(child: this);
  }

  /// Wraps widget with story permanence tooltip
  Widget withStoryTooltip() {
    return SnapAMealTooltips.storyPermanence(child: this);
  }

  /// Wraps widget with AR filtering tooltip
  Widget withARTooltip() {
    return SnapAMealTooltips.arFiltering(child: this);
  }

  /// Wraps widget with meal recognition tooltip
  Widget withMealRecognitionTooltip() {
    return SnapAMealTooltips.mealRecognition(child: this);
  }

  /// Wraps widget with social matching tooltip
  Widget withSocialMatchingTooltip() {
    return SnapAMealTooltips.socialMatching(child: this);
  }

  /// Wraps widget with fasting intelligence tooltip
  Widget withFastingTooltip() {
    return SnapAMealTooltips.fastingIntelligence(child: this);
  }

  /// Wraps widget with dashboard insights tooltip
  Widget withDashboardTooltip() {
    return SnapAMealTooltips.dashboardInsights(child: this);
  }
} 