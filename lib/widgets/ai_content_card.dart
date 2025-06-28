import 'package:flutter/material.dart';
import 'package:snapameal/design_system/snap_ui.dart';
import 'package:snapameal/models/ai_content.dart';
import 'package:snapameal/services/content_reporting_service.dart';
import 'package:snapameal/utils/logger.dart';

class AIContentCard extends StatefulWidget {
  final AIContent content;
  final VoidCallback? onDismissed;

  const AIContentCard({
    super.key,
    required this.content,
    this.onDismissed,
  });

  @override
  State<AIContentCard> createState() => _AIContentCardState();
}

class _AIContentCardState extends State<AIContentCard> {
  bool _isDismissed = false;
  bool _isExpanded = false;

  Future<void> _dismissContent() async {
    try {
      setState(() {
        _isDismissed = true;
      });
      widget.onDismissed?.call();
    } catch (e) {
      Logger.d('Failed to dismiss AI content: $e');
    }
  }

  Future<void> _reportContent() async {
    try {
      await ContentReportingService().reportContent(
        contentId: widget.content.id,
        contentType: 'ai_content',
        reason: 'inappropriate_content',
        additionalInfo: 'Reported from AI content feed',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapUI.successSnackBar('Content reported successfully'),
        );
        _dismissContent();
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
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: SnapDimensions.paddingMedium,
        vertical: SnapDimensions.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: SnapColors.white,
        borderRadius: BorderRadius.circular(SnapDimensions.radiusM),
        border: Border.all(color: SnapColors.border),
        boxShadow: [
          BoxShadow(
            color: SnapColors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(SnapDimensions.paddingMedium),
            child: Row(
              children: [
                // AI Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SnapDimensions.paddingSmall,
                    vertical: SnapDimensions.paddingSmall / 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.content.typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(SnapDimensions.radiusS),
                    border: Border.all(
                      color: widget.content.typeColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 12,
                        color: widget.content.typeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI ${widget.content.displayType}',
                        style: SnapTypography.bodyMedium.copyWith(
                          color: widget.content.typeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // More options
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert,
                    color: SnapColors.textSecondary,
                    size: 18,
                  ),
                  onSelected: (value) {
                    switch (value) {
                      case 'dismiss':
                        _dismissContent();
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
                          Icon(Icons.visibility_off, size: 16),
                          SizedBox(width: 8),
                          Text('Hide'),
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
          ),

          // Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: SnapDimensions.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Icon(
                      widget.content.typeIcon,
                      color: widget.content.typeColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.content.title,
                        style: SnapTypography.titleLarge.copyWith(
                          color: SnapColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Summary or content preview
                Text(
                  _isExpanded 
                      ? widget.content.content
                      : widget.content.summary ?? _getContentPreview(),
                  style: SnapTypography.bodyMedium.copyWith(
                    color: SnapColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: _isExpanded ? null : 3,
                  overflow: _isExpanded ? null : TextOverflow.ellipsis,
                ),

                // Expand/Collapse button
                if (_shouldShowExpandButton()) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Text(
                      _isExpanded ? 'Show less' : 'Read more',
                      style: SnapTypography.bodyMedium.copyWith(
                        color: widget.content.typeColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Tags
          if (widget.content.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SnapDimensions.paddingMedium),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.content.tags.take(4).map((tag) => Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SnapDimensions.paddingSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SnapColors.greyBackground,
                    borderRadius: BorderRadius.circular(SnapDimensions.radiusS),
                  ),
                  child: Text(
                    '#$tag',
                    style: SnapTypography.bodyMedium.copyWith(
                      color: SnapColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],

          // Footer
          Padding(
            padding: EdgeInsets.all(SnapDimensions.paddingMedium),
            child: Row(
              children: [
                // Personalized indicator
                if (widget.content.isPersonalized) ...[
                  Icon(
                    Icons.person,
                    size: 14,
                    color: SnapColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Personalized for you',
                    style: SnapTypography.bodyMedium.copyWith(
                      color: SnapColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.public,
                    size: 14,
                    color: SnapColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'General health tip',
                    style: SnapTypography.bodyMedium.copyWith(
                      color: SnapColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
                const Spacer(),
                // Time
                Text(
                  _formatTime(widget.content.createdAt),
                  style: SnapTypography.bodyMedium.copyWith(
                    color: SnapColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getContentPreview() {
    final content = widget.content.content;
    if (content.length <= 150) return content;
    
    // Find a good breaking point near 150 characters
    int breakPoint = content.indexOf(' ', 140);
    if (breakPoint == -1 || breakPoint > 160) {
      breakPoint = 150;
    }
    
    return '${content.substring(0, breakPoint)}...';
  }

  bool _shouldShowExpandButton() {
    if (widget.content.summary != null) {
      return widget.content.content.length > 200;
    }
    return widget.content.content.length > 150;
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
} 