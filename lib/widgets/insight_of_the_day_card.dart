/// Insight of the Day Card Widget
/// Displays personalized daily health insights on the dashboard
library;

import 'package:flutter/material.dart';
import '../design_system/snap_ui.dart';
import '../services/daily_insights_service.dart';
import '../services/content_reporting_service.dart';
import '../utils/logger.dart';

/// Card widget that displays the daily insight with dismissal and reporting options
class InsightOfTheDayCard extends StatefulWidget {
  final String userId;
  final VoidCallback? onDismissed;

  const InsightOfTheDayCard({
    super.key,
    required this.userId,
    this.onDismissed,
  });

  @override
  State<InsightOfTheDayCard> createState() => _InsightOfTheDayCardState();
}

class _InsightOfTheDayCardState extends State<InsightOfTheDayCard> {
  Map<String, dynamic>? _insight;
  bool _isLoading = true;
  bool _isDismissed = false;
  bool _isReporting = false;

  @override
  void initState() {
    super.initState();
    _loadInsight();
  }

  Future<void> _loadInsight() async {
    try {
      final insight = await DailyInsightsService.getOrGenerateInsight(widget.userId);
      if (mounted) {
        setState(() {
          _insight = insight;
          _isDismissed = insight?['isDismissed'] == true;
          _isLoading = false;
        });
      }
    } catch (e) {
      Logger.d('Error loading insight: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _dismissInsight() async {
    if (_insight == null) return;

    try {
      final success = await DailyInsightsService.dismissInsight(
        widget.userId,
        _insight!['id'],
      );

      if (success && mounted) {
        setState(() {
          _isDismissed = true;
        });
        widget.onDismissed?.call();
        
        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Insight dismissed'),
            backgroundColor: SnapUI.primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Logger.d('Error dismissing insight: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to dismiss insight'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reportContent(String reason, {String? additionalDetails}) async {
    if (_insight == null) return;

    setState(() {
      _isReporting = true;
    });

    try {
      final success = await ContentReportingService.reportContent(
        userId: widget.userId,
        content: _insight!['content'],
        contentType: 'insight',
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

    return Card(
      margin: const EdgeInsets.all(SnapUI.paddingMedium),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapUI.borderRadiusMedium),
      ),
      child: Container(
        padding: const EdgeInsets.all(SnapUI.paddingMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SnapUI.borderRadiusMedium),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SnapUI.primaryColor.withOpacity(0.1),
              SnapUI.secondaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: SnapUI.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: SnapUI.paddingSmall),
                Text(
                  'Insight of the Day',
                  style: SnapUI.textTheme.titleMedium?.copyWith(
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
                    size: 18,
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
                          Icon(Icons.close, size: 16),
                          SizedBox(width: 8),
                          Text('Dismiss'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 16),
                          SizedBox(width: 8),
                          Text('Report'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: SnapUI.paddingMedium),
            
            // Content
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(SnapUI.paddingLarge),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_insight != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _insight!['content'] ?? '',
                    style: SnapUI.textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: SnapUI.paddingMedium),
                  
                  // Source indicator
                  Row(
                    children: [
                      Icon(
                        _insight!['source'] == 'rag' 
                            ? Icons.psychology_outlined 
                            : Icons.book_outlined,
                        size: 14,
                        color: SnapUI.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _insight!['source'] == 'rag' 
                            ? 'AI-Generated' 
                            : 'Curated Content',
                        style: SnapUI.textTheme.bodySmall?.copyWith(
                          color: SnapUI.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(SnapUI.paddingMedium),
                decoration: BoxDecoration(
                  color: SnapUI.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(SnapUI.borderRadiusSmall),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: SnapUI.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: SnapUI.paddingSmall),
                    Expanded(
                      child: Text(
                        'Unable to load today\'s insight. Please try again later.',
                        style: SnapUI.textTheme.bodySmall?.copyWith(
                          color: SnapUI.errorColor,
                        ),
                      ),
                    ),
                  ],
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
              maxLength: 500,
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