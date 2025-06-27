import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/services/daily_insights_service.dart';
import 'package:snapameal/services/content_reporting_service.dart';
import 'package:snapameal/utils/logger.dart';

class InsightOfTheDayCard extends StatefulWidget {
  const InsightOfTheDayCard({super.key});

  @override
  State<InsightOfTheDayCard> createState() => _InsightOfTheDayCardState();
}

class _InsightOfTheDayCardState extends State<InsightOfTheDayCard> {
  bool _isDismissed = false;
  bool _isLoading = true;
  String? _insight;

  @override
  void initState() {
    super.initState();
    _loadTodaysInsight();
  }

  Future<void> _loadTodaysInsight() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final insight = await DailyInsightsService().getTodaysInsight();
      
      if (mounted) {
        setState(() {
          _insight = insight?.content;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.d('Failed to load daily insight: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _dismissInsight() async {
    try {
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    } catch (e) {
      Logger.d('Failed to dismiss insight: $e');
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    }
  }

  Future<void> _reportContent() async {
    try {
      await ContentReportingService().reportContent(
        contentId: 'daily_insight_${DateTime.now().millisecondsSinceEpoch}',
        contentType: 'daily_insight',
        reason: 'inappropriate_content',
        additionalInfo: 'Reported from daily insight card',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapUI.successSnackBar('Content reported successfully'),
        );
        _dismissInsight();
      }
    } catch (e) {
      Logger.d('Failed to report content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapUI.errorSnackBar('Failed to report content'),
        );
      }
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Content'),
        content: const Text('Are you sure you want to report this content as inappropriate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _reportContent();
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if dismissed
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(SnapDimensions.paddingMedium),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SnapDimensions.radiusM),
        gradient: LinearGradient(
          colors: [
            SnapColors.primaryYellow.withValues(alpha: 0.1),
            SnapColors.accentBlue.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(SnapDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and dismiss button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: SnapColors.primaryYellow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Insight of the Day',
                      style: SnapTypography.titleLarge.copyWith(
                        color: SnapColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Report button
                    IconButton(
                      onPressed: _insight != null ? _showReportDialog : null,
                      icon: Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: SnapColors.textSecondary,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(SnapDimensions.paddingSmall),
                    ),
                    // Dismiss button
                    IconButton(
                      onPressed: _dismissInsight,
                      icon: Icon(
                        Icons.close,
                        size: 16,
                        color: SnapColors.textSecondary,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(SnapDimensions.paddingSmall),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Content
            if (_isLoading)
              _buildLoadingState()
            else if (_insight != null)
              _buildInsightContent()
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(SnapDimensions.paddingMedium),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading your personalized insight...'),
        ],
      ),
    );
  }

  Widget _buildInsightContent() {
    return Text(
      _insight!,
      style: SnapTypography.bodyLarge.copyWith(
        color: SnapColors.textSecondary,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(SnapDimensions.paddingMedium),
      child: Text(
        'No insights available today. Check back tomorrow!',
        style: SnapTypography.bodyMedium.copyWith(
          color: SnapColors.textSecondary,
        ),
      ),
    );
  }
}

