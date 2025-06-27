/// Meal Insight Card Widget
/// Displays AI-generated nutrition insights after meal logging
library;

import 'package:flutter/material.dart';
import '../design_system/snap_ui.dart';
import '../services/content_reporting_service.dart';
import '../utils/logger.dart';

/// Card widget that displays nutrition insights for logged meals
class MealInsightCard extends StatefulWidget {
  final String userId;
  final String content;
  final String mealId;
  final VoidCallback? onDismissed;

  const MealInsightCard({
    super.key,
    required this.userId,
    required this.content,
    required this.mealId,
    this.onDismissed,
  });

  @override
  State<MealInsightCard> createState() => _MealInsightCardState();
}

class _MealInsightCardState extends State<MealInsightCard> {
  bool _isDismissed = false;
  bool _isReporting = false;

  Future<void> _dismissInsight() async {
    setState(() {
      _isDismissed = true;
    });
    widget.onDismissed?.call();
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Insight dismissed'),
          backgroundColor: SnapUI.primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _reportContent(String reason, {String? additionalDetails}) async {
    setState(() {
      _isReporting = true;
    });

    try {
      final success = await ContentReportingService.reportContent(
        userId: widget.userId,
        content: widget.content,
        contentType: 'nutrition',
        reason: reason,
        additionalDetails: additionalDetails,
      );

      if (mounted) {
        setState(() {
          _isReporting = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Thank you for your feedback. Content reported.'),
              backgroundColor: SnapUI.primaryColor,
            ),
          );
          // Auto-dismiss after reporting
          await _dismissInsight();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit report'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Logger.d('Error reporting content: $e');
      if (mounted) {
        setState(() {
          _isReporting = false;
        });
      }
    }
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => _ReportDialog(
        onReport: _reportContent,
        isLoading: _isReporting,
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
      margin: const EdgeInsets.symmetric(
        horizontal: SnapUI.paddingMedium,
        vertical: SnapUI.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: SnapUI.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(SnapUI.borderRadiusMedium),
        border: Border.all(
          color: SnapUI.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(SnapUI.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: SnapUI.primaryColor,
                  size: 18,
                ),
                const SizedBox(width: SnapUI.paddingSmall),
                Text(
                  'Nutrition Insight',
                  style: SnapUI.textTheme.titleSmall?.copyWith(
                    color: SnapUI.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // More options menu
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: SnapUI.textSecondary,
                    size: 16,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'dismiss':
                        _dismissInsight();
                        break;
                      case 'report':
                        _showReportDialog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'dismiss',
                      child: Row(
                        children: [
                          Icon(Icons.close, size: 14),
                          SizedBox(width: 6),
                          Text('Dismiss'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 14),
                          SizedBox(width: 6),
                          Text('Report'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: SnapUI.paddingSmall),
            
            // Content
            Text(
              widget.content,
              style: SnapUI.textTheme.bodySmall?.copyWith(
                height: 1.3,
                color: SnapUI.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for reporting inappropriate content
class _ReportDialog extends StatefulWidget {
  final Function(String reason, {String? additionalDetails}) onReport;
  final bool isLoading;

  const _ReportDialog({
    required this.onReport,
    required this.isLoading,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  String? _selectedReason;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report Content'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you reporting this content?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            
            // Report reasons
            ...ContentReportingService.getReportReasons().map((reason) => 
              RadioListTile<String>(
                title: Text(reason),
                value: reason,
                groupValue: _selectedReason,
                onChanged: (value) {
                  setState(() {
                    _selectedReason = value;
                  });
                },
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Additional details
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Additional details (optional)',
                hintText: 'Please provide more context...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 300,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: widget.isLoading || _selectedReason == null
              ? null
              : () {
                  widget.onReport(
                    _selectedReason!,
                    additionalDetails: _detailsController.text.trim().isEmpty
                        ? null
                        : _detailsController.text.trim(),
                  );
                  Navigator.of(context).pop();
                },
          child: widget.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Report'),
        ),
      ],
    );
  }
} 