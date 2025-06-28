import 'package:flutter/material.dart';
import '../models/conversation_starter.dart';
import '../design_system/snap_ui.dart';

/// Widget to display conversation starters in health groups
class ConversationStarterCard extends StatelessWidget {
  final ConversationStarter conversationStarter;
  final VoidCallback? onTap;
  final VoidCallback? onReport;
  final VoidCallback? onReact;
  final bool showEngagement;

  const ConversationStarterCard({
    super.key,
    required this.conversationStarter,
    this.onTap,
    this.onReport,
    this.onReact,
    this.showEngagement = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: SnapDimensions.paddingMedium,
        vertical: SnapDimensions.paddingSmall,
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusMedium),
        child: Container(
          padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusMedium),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _getTypeColor().withValues(alpha: 0.1),
                _getTypeColor().withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type and actions
              Row(
                children: [
                  // Type indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SnapDimensions.paddingSmall,
                      vertical: SnapDimensions.paddingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: _getTypeColor(),
                      borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          conversationStarter.typeIcon,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          conversationStarter.typeDisplayName,
                          style: SnapTypography.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // AI Generated indicator
                  if (conversationStarter.isAIGenerated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SnapDimensions.paddingSmall,
                        vertical: SnapDimensions.paddingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: SnapColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            size: 12,
                            color: SnapColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI',
                            style: SnapTypography.bodySmall.copyWith(
                              color: SnapColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Menu button
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: SnapColors.textSecondary,
                      size: 20,
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case 'report':
                          onReport?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
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
              
              const SizedBox(height: SnapDimensions.paddingMedium),
              
              // Title
              Text(
                conversationStarter.title,
                style: SnapTypography.headingSmall.copyWith(
                  color: SnapColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              
              const SizedBox(height: SnapDimensions.paddingSmall),
              
              // Content
              Text(
                conversationStarter.content,
                style: SnapTypography.bodyMedium.copyWith(
                  color: SnapColors.textSecondary,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: SnapDimensions.paddingMedium),
              
              // Tags
              if (conversationStarter.tags.isNotEmpty)
                Wrap(
                  spacing: SnapDimensions.paddingSmall,
                  runSpacing: SnapDimensions.paddingXSmall,
                  children: conversationStarter.tags
                      .where((tag) => tag != 'ai-generated') // Hide AI tag since we show it separately
                      .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SnapDimensions.paddingSmall,
                          vertical: SnapDimensions.paddingXSmall,
                        ),
                        decoration: BoxDecoration(
                          color: SnapColors.surface,
                          borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusSmall),
                          border: Border.all(
                            color: SnapColors.border,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: SnapTypography.bodySmall.copyWith(
                            color: SnapColors.textSecondary,
                          ),
                        ),
                      ))
                      .toList(),
                ),
              
              const SizedBox(height: SnapDimensions.paddingMedium),
              
              // Footer with engagement and actions
              Row(
                children: [
                  // Engagement info
                  if (showEngagement && conversationStarter.engagementScore > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SnapDimensions.paddingSmall,
                        vertical: SnapDimensions.paddingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: SnapColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.trending_up,
                            size: 12,
                            color: SnapColors.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${conversationStarter.engagementScore} interactions',
                            style: SnapTypography.bodySmall.copyWith(
                              color: SnapColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const Spacer(),
                  
                  // React button
                  if (onReact != null)
                    TextButton.icon(
                      onPressed: onReact,
                      icon: Icon(
                        Icons.thumb_up_outlined,
                        size: 16,
                        color: SnapColors.primary,
                      ),
                      label: Text(
                        'React',
                        style: SnapTypography.bodySmall.copyWith(
                          color: SnapColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SnapDimensions.paddingSmall,
                          vertical: SnapDimensions.paddingXSmall,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  
                  const SizedBox(width: SnapDimensions.paddingSmall),
                  
                  // Reply button
                  TextButton.icon(
                    onPressed: onTap,
                    icon: Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: SnapColors.primary,
                    ),
                    label: Text(
                      'Discuss',
                      style: SnapTypography.bodySmall.copyWith(
                        color: SnapColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SnapDimensions.paddingSmall,
                        vertical: SnapDimensions.paddingXSmall,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              
              // Posted time
              if (conversationStarter.postedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: SnapDimensions.paddingSmall),
                  child: Text(
                    'Posted ${_getTimeAgo(conversationStarter.postedAt!)}',
                    style: SnapTypography.bodySmall.copyWith(
                      color: SnapColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get color based on conversation starter type
  Color _getTypeColor() {
    switch (conversationStarter.type) {
      case ConversationStarterType.question:
        return SnapColors.primary;
      case ConversationStarterType.poll:
        return SnapColors.secondary;
      case ConversationStarterType.challenge:
        return SnapColors.warning;
      case ConversationStarterType.discussion:
        return SnapColors.info;
      case ConversationStarterType.tip:
        return SnapColors.success;
    }
  }

  /// Get time ago string
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 