/// Meal Insight Card Widget
/// Displays AI-generated nutrition insights after meal logging
library;

import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/services/daily_insights_service.dart';
import 'package:snapameal/services/content_reporting_service.dart';
import 'package:snapameal/models/ai_advice.dart';
import 'package:snapameal/models/meal_log.dart';
import 'package:snapameal/utils/logger.dart';

/// Card widget that displays nutrition insights for logged meals
class MealInsightCard extends StatefulWidget {
  final MealLog mealLog;
  
  const MealInsightCard({
    super.key,
    required this.mealLog,
  });

  @override
  State<MealInsightCard> createState() => _MealInsightCardState();
}

class _MealInsightCardState extends State<MealInsightCard> {
  bool _isDismissed = false;
  bool _isLoading = true;
  AIAdvice? _insight;

  @override
  void initState() {
    super.initState();
    _loadMealInsight();
  }

  Future<void> _loadMealInsight() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final insight = await DailyInsightsService().getMealInsight(widget.mealLog);
      
      if (mounted) {
        setState(() {
          _insight = insight;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.d('Failed to load meal insight: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _dismissInsight() async {
    try {
      if (_insight != null) {
        await DailyInsightsService().dismissInsight(_insight!.id);
      }
      
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    } catch (e) {
      Logger.d('Failed to dismiss meal insight: $e');
      // Show error but don't prevent dismissal in UI
      if (mounted) {
        setState(() {
          _isDismissed = true;
        });
      }
    }
  }

  Future<void> _reportContent() async {
    if (_insight == null) return;

    try {
      await ContentReportingService().reportContent(
        contentId: _insight!.id,
        contentType: 'meal_insight',
        reason: 'inappropriate_content',
        additionalInfo: 'Reported from meal insight card for meal: ${widget.mealLog.id}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapUI.successSnackBar('Content reported successfully'),
        );
        // Also dismiss the card after reporting
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
      margin: EdgeInsets.symmetric(
        horizontal: SnapDimensions.paddingMedium,
        vertical: SnapDimensions.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: SnapColors.primaryYellow.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(SnapDimensions.radiusMedium),
        border: Border.all(
          color: SnapColors.primaryYellow.withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(SnapDimensions.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights,
                      color: SnapColors.primaryYellow,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Meal Insight',
                      style: SnapTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: SnapColors.textSecondary,
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
                        size: 14,
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
                        size: 14,
                        color: SnapColors.textSecondary,
                      ),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.all(SnapDimensions.paddingSmall),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
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
      padding: EdgeInsets.all(SnapDimensions.paddingSmall),
      child: const Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
          SizedBox(width: 8),
          Text('Analyzing your meal...', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }



  Widget _buildInsightContent() {
    return Text(
      _insight!.content,
      style: SnapTypography.bodyMedium.copyWith(
        color: SnapColors.textPrimary,
        fontSize: 13,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Text(
      'No insights available for this meal',
      style: SnapTypography.bodyMedium.copyWith(
        color: SnapColors.textSecondary,
        fontSize: 12,
      ),
    );
  }
} 