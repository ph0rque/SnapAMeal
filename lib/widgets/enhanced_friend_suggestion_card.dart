import 'package:flutter/material.dart';
import '../design_system/snap_ui.dart';

/// Widget to display enhanced friend suggestions with AI justifications
class EnhancedFriendSuggestionCard extends StatelessWidget {
  final Map<String, dynamic> suggestion;
  final VoidCallback? onSendRequest;
  final VoidCallback? onDismiss;
  final VoidCallback? onViewProfile;

  const EnhancedFriendSuggestionCard({
    super.key,
    required this.suggestion,
    this.onSendRequest,
    this.onDismiss,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = suggestion['display_name'] ?? 'Unknown User';
    final profilePicUrl = suggestion['profile_pic_url'] as String?;
    final justification = suggestion['match_justification'] as String? ?? '';
    final hasAIJustification = suggestion['has_ai_justification'] as bool? ?? false;
    final compatibilityScore = suggestion['compatibility_score'] as double? ?? 0.0;
    final healthProfile = suggestion['health_profile'] as Map<String, dynamic>? ?? {};
    final healthGoals = List<String>.from(healthProfile['health_goals'] ?? []);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: SnapDimensions.paddingMedium,
        vertical: SnapDimensions.paddingSmall,
      ),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusMedium),
      ),
      child: Container(
        padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusMedium),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              SnapColors.primary.withOpacity(0.02),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile info and compatibility
            Row(
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 24,
                  backgroundColor: SnapColors.primary.withOpacity(0.1),
                  backgroundImage: profilePicUrl != null && profilePicUrl.isNotEmpty
                      ? NetworkImage(profilePicUrl)
                      : null,
                  child: profilePicUrl == null || profilePicUrl.isEmpty
                      ? Icon(
                          Icons.person,
                          color: SnapColors.primary,
                          size: 24,
                        )
                      : null,
                ),
                
                const SizedBox(width: SnapDimensions.paddingMedium),
                
                // Name and compatibility
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: SnapTypography.headingSmall.copyWith(
                          color: SnapColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Compatibility score
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: _getCompatibilityColor(compatibilityScore),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(compatibilityScore * 100).toInt()}% compatible',
                            style: SnapTypography.bodySmall.copyWith(
                              color: _getCompatibilityColor(compatibilityScore),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // AI indicator
                if (hasAIJustification)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SnapDimensions.paddingSmall,
                      vertical: SnapDimensions.paddingXSmall,
                    ),
                    decoration: BoxDecoration(
                      color: SnapColors.primary.withOpacity(0.1),
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
                          'AI Match',
                          style: SnapTypography.bodySmall.copyWith(
                            color: SnapColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: SnapDimensions.paddingMedium),
            
            // Health goals
            if (healthGoals.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Goals',
                    style: SnapTypography.bodySmall.copyWith(
                      color: SnapColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: SnapDimensions.paddingSmall),
                  
                  Wrap(
                    spacing: SnapDimensions.paddingSmall,
                    runSpacing: SnapDimensions.paddingXSmall,
                    children: healthGoals.take(3).map((goal) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: SnapDimensions.paddingSmall,
                        vertical: SnapDimensions.paddingXSmall,
                      ),
                      decoration: BoxDecoration(
                        color: SnapColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusSmall),
                        border: Border.all(
                          color: SnapColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        goal.toLowerCase(),
                        style: SnapTypography.bodySmall.copyWith(
                          color: SnapColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )).toList(),
                  ),
                  
                  const SizedBox(height: SnapDimensions.paddingMedium),
                ],
              ),
            
            // AI Justification
            if (justification.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
                decoration: BoxDecoration(
                  color: hasAIJustification 
                      ? SnapColors.primary.withOpacity(0.05)
                      : SnapColors.surface,
                  borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusSmall),
                  border: Border.all(
                    color: hasAIJustification 
                        ? SnapColors.primary.withOpacity(0.1)
                        : SnapColors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasAIJustification ? Icons.psychology : Icons.lightbulb_outline,
                          size: 16,
                          color: hasAIJustification ? SnapColors.primary : SnapColors.info,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasAIJustification ? 'AI Insight' : 'Why this match?',
                          style: SnapTypography.bodySmall.copyWith(
                            color: hasAIJustification ? SnapColors.primary : SnapColors.info,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: SnapDimensions.paddingSmall),
                    
                    Text(
                      justification,
                      style: SnapTypography.bodyMedium.copyWith(
                        color: SnapColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: SnapDimensions.paddingMedium),
            
            // Action buttons
            Row(
              children: [
                // View Profile button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewProfile,
                    icon: Icon(
                      Icons.person_outline,
                      size: 16,
                      color: SnapColors.primary,
                    ),
                    label: Text(
                      'View Profile',
                      style: SnapTypography.bodySmall.copyWith(
                        color: SnapColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: SnapColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusSmall),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: SnapDimensions.paddingSmall,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: SnapDimensions.paddingSmall),
                
                // Add Friend button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onSendRequest,
                    icon: const Icon(
                      Icons.person_add,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Add Friend',
                      style: SnapTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SnapColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusSmall),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: SnapDimensions.paddingSmall,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: SnapDimensions.paddingSmall),
                
                // Dismiss button
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    color: SnapColors.textSecondary,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: SnapColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(SnapDimensions.borderRadiusSmall),
                    ),
                    padding: const EdgeInsets.all(SnapDimensions.paddingSmall),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get color based on compatibility score
  Color _getCompatibilityColor(double score) {
    if (score >= 0.8) return SnapColors.success;
    if (score >= 0.6) return SnapColors.warning;
    if (score >= 0.4) return SnapColors.info;
    return SnapColors.textSecondary;
  }
} 