import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../design_system/snap_ui.dart';
import '../utils/logger.dart';

class ReviewCard extends StatelessWidget {
  final Map<String, dynamic> review;
  final String reviewType;

  const ReviewCard({
    super.key,
    required this.review,
    required this.reviewType,
  });

  @override
  Widget build(BuildContext context) {
    final reviewContent = review['review_content'] as Map<String, dynamic>? ?? {};
    final activityData = review['activity_data'] as Map<String, dynamic>? ?? {};
    final isAiGenerated = review['is_ai_generated'] as bool? ?? false;
    
    // Extract date information with robust handling for both Timestamp and String
    final dateField = reviewType == 'weekly' ? 'week_of' : 'month_of';
    DateTime reviewDate = DateTime.now();
    
    final dateValue = review[dateField];
    if (dateValue is Timestamp) {
      reviewDate = dateValue.toDate();
    } else if (dateValue is String) {
      try {
        reviewDate = DateTime.parse(dateValue);
      } catch (e) {
        Logger.d('Failed to parse date string: $dateValue, using current date');
      }
    }
    
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapDimensions.radiusLarge),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SnapDimensions.radiusLarge),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: reviewType == 'weekly' 
                ? [SnapColors.primary.withValues(alpha: 0.1), SnapColors.primary.withValues(alpha: 0.05)]
                : [SnapColors.secondary.withValues(alpha: 0.1), SnapColors.secondary.withValues(alpha: 0.05)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(SnapDimensions.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(reviewDate, isAiGenerated),
              const SizedBox(height: SnapDimensions.spacingMedium),
              _buildSummary(reviewContent),
              const SizedBox(height: SnapDimensions.spacingMedium),
              _buildHighlights(reviewContent),
              const SizedBox(height: SnapDimensions.spacingMedium),
              _buildMetrics(activityData),
              if (reviewType == 'monthly') ...[
                const SizedBox(height: SnapDimensions.spacingMedium),
                _buildAchievementBadges(reviewContent),
              ],
              const SizedBox(height: SnapDimensions.spacingMedium),
              _buildInsights(reviewContent),
              if (reviewType == 'weekly') ...[
                const SizedBox(height: SnapDimensions.spacingMedium),
                _buildNextWeekGoals(reviewContent),
              ],
              const SizedBox(height: SnapDimensions.spacingMedium),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build card header with date and AI indicator
  Widget _buildHeader(DateTime reviewDate, bool isAiGenerated) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: reviewType == 'weekly' ? SnapColors.primary : SnapColors.secondary,
            borderRadius: BorderRadius.circular(SnapDimensions.radiusSmall),
          ),
          child: Icon(
            reviewType == 'weekly' ? Icons.calendar_view_week : Icons.calendar_month,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: SnapDimensions.spacingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reviewType == 'weekly' 
                    ? 'Week of ${_formatDate(reviewDate)}'
                    : '${_getMonthName(reviewDate.month)} ${reviewDate.year}',
                style: SnapTextStyles.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAiGenerated)
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 14,
                      color: SnapColors.accent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI Generated',
                      style: SnapTextStyles.bodySmall.copyWith(
                        color: SnapColors.accent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build summary section
  Widget _buildSummary(Map<String, dynamic> reviewContent) {
    final summary = reviewContent['summary'] as String? ?? 'No summary available';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SnapDimensions.radiusMedium),
        border: Border.all(color: SnapColors.border),
      ),
      child: Text(
        summary,
        style: SnapTextStyles.bodyMedium.copyWith(
          height: 1.5,
        ),
      ),
    );
  }

  /// Build highlights section
  Widget _buildHighlights(Map<String, dynamic> reviewContent) {
    final highlights = reviewContent['highlights'] as List<dynamic>? ?? [];
    
    if (highlights.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.star,
              color: SnapColors.warning,
              size: 20,
            ),
            const SizedBox(width: SnapDimensions.spacingSmall),
            Text(
              'Highlights',
              style: SnapTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: SnapDimensions.spacingSmall),
        ...highlights.take(3).map((highlight) => Padding(
          padding: const EdgeInsets.only(bottom: SnapDimensions.spacingXSmall),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 8, right: 8),
                decoration: BoxDecoration(
                  color: SnapColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  highlight.toString(),
                  style: SnapTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// Build activity metrics section
  Widget _buildMetrics(Map<String, dynamic> activityData) {
    final metrics = activityData['metrics'] as Map<String, dynamic>? ?? {};
    final overallMetrics = metrics['overall'] as Map<String, dynamic>? ?? {};
    final storyMetrics = metrics['stories'] as Map<String, dynamic>? ?? {};
    final mealMetrics = metrics['meals'] as Map<String, dynamic>? ?? {};
    
    final totalActivities = overallMetrics['total_activities'] as int? ?? 0;
    final activeDays = overallMetrics['active_days'] as int? ?? 0;
    final storyCount = storyMetrics['total_count'] as int? ?? 0;
    final mealCount = mealMetrics['total_count'] as int? ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: SnapColors.surface,
        borderRadius: BorderRadius.circular(SnapDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Summary',
            style: SnapTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: SnapDimensions.spacingSmall),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.timeline,
                  label: 'Total Activities',
                  value: totalActivities.toString(),
                  color: SnapColors.primary,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.calendar_today,
                  label: 'Active Days',
                  value: activeDays.toString(),
                  color: SnapColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: SnapDimensions.spacingSmall),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.camera_alt,
                  label: 'Stories',
                  value: storyCount.toString(),
                  color: SnapColors.secondary,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  icon: Icons.restaurant,
                  label: 'Meals Logged',
                  value: mealCount.toString(),
                  color: SnapColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual metric item
  Widget _buildMetricItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(SnapDimensions.paddingSmall),
      margin: const EdgeInsets.only(right: SnapDimensions.spacingSmall),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(SnapDimensions.radiusSmall),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: SnapTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build achievement badges (monthly only)
  Widget _buildAchievementBadges(Map<String, dynamic> reviewContent) {
    final badges = reviewContent['achievement_badges'] as List<dynamic>? ?? [];
    
    if (badges.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: SnapColors.warning,
              size: 20,
            ),
            const SizedBox(width: SnapDimensions.spacingSmall),
            Text(
              'Achievements',
              style: SnapTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: SnapDimensions.spacingSmall),
        Wrap(
          spacing: SnapDimensions.spacingSmall,
          runSpacing: SnapDimensions.spacingSmall,
          children: badges.map((badge) => _buildBadgeChip(badge)).toList(),
        ),
      ],
    );
  }

  /// Build individual badge chip
  Widget _buildBadgeChip(dynamic badge) {
    final badgeMap = badge as Map<String, dynamic>? ?? {};
    final name = badgeMap['name'] as String? ?? 'Achievement';
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SnapDimensions.paddingSmall,
        vertical: SnapDimensions.paddingXSmall,
      ),
      decoration: BoxDecoration(
        color: SnapColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(SnapDimensions.radiusLarge),
        border: Border.all(color: SnapColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.emoji_events,
            color: SnapColors.warning,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            name,
            style: SnapTextStyles.bodySmall.copyWith(
              color: SnapColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build insights section
  Widget _buildInsights(Map<String, dynamic> reviewContent) {
    final insights = reviewContent['insights'] as List<dynamic>? ?? [];
    final weeklyInsights = reviewContent['weekly_insights'] as List<dynamic>? ?? [];
    
    final allInsights = [...insights, ...weeklyInsights];
    
    if (allInsights.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.lightbulb,
              color: SnapColors.accent,
              size: 20,
            ),
            const SizedBox(width: SnapDimensions.spacingSmall),
            Text(
              'Insights',
              style: SnapTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: SnapDimensions.spacingSmall),
        ...allInsights.take(2).map((insight) => Padding(
          padding: const EdgeInsets.only(bottom: SnapDimensions.spacingXSmall),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(SnapDimensions.paddingSmall),
            decoration: BoxDecoration(
              color: SnapColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(SnapDimensions.radiusSmall),
              border: Border.all(color: SnapColors.accent.withValues(alpha: 0.2)),
            ),
            child: Text(
              insight.toString(),
              style: SnapTextStyles.bodyMedium.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        )),
      ],
    );
  }

  /// Build next week goals (weekly only)
  Widget _buildNextWeekGoals(Map<String, dynamic> reviewContent) {
    final goals = reviewContent['next_week_goals'] as List<dynamic>? ?? [];
    
    if (goals.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flag,
              color: SnapColors.success,
              size: 20,
            ),
            const SizedBox(width: SnapDimensions.spacingSmall),
            Text(
              'Next Week Goals',
              style: SnapTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: SnapDimensions.spacingSmall),
        ...goals.take(3).map((goal) => Padding(
          padding: const EdgeInsets.only(bottom: SnapDimensions.spacingXSmall),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 8, right: 8),
                decoration: BoxDecoration(
                  color: SnapColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  goal.toString(),
                  style: SnapTextStyles.bodyMedium,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _shareReview(context),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              foregroundColor: SnapColors.primary,
              side: BorderSide(color: SnapColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SnapDimensions.radiusMedium),
              ),
            ),
          ),
        ),
        const SizedBox(width: SnapDimensions.spacingMedium),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _viewDetails(context),
            icon: const Icon(Icons.visibility),
            label: const Text('View Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: reviewType == 'weekly' ? SnapColors.primary : SnapColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SnapDimensions.radiusMedium),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Share review
  void _shareReview(BuildContext context) {
    try {
      final reviewContent = review['review_content'] as Map<String, dynamic>? ?? {};
      final summary = reviewContent['summary'] as String? ?? 'Check out my health journey review!';
      final highlights = reviewContent['highlights'] as List<dynamic>? ?? [];
      
      String shareText = 'My ${reviewType.capitalize()} Health Review\n\n$summary';
      
      if (highlights.isNotEmpty) {
        shareText += '\n\nHighlights:\n';
        shareText += highlights.take(3).map((h) => '• $h').join('\n');
      }
      
      shareText += '\n\n#SnapAMeal #HealthJourney';
      
      Share.share(shareText);
    } catch (e) {
      Logger.d('Error sharing review: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to share review'),
          backgroundColor: SnapColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// View detailed review
  void _viewDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${reviewType.capitalize()} Review Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Full review data and analytics coming soon!'),
              const SizedBox(height: SnapDimensions.spacingMedium),
              Text(
                'This feature will show detailed breakdowns of your activity patterns, trends, and personalized recommendations.',
                style: SnapTextStyles.bodyMedium.copyWith(
                  color: SnapColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get month name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
} 