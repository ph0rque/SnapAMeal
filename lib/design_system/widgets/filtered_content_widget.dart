import 'package:flutter/material.dart';
import '../../services/content_filter_service.dart';
import '../../models/fasting_session.dart';

/// Widget displayed when content is filtered during fasting
class FilteredContentWidget extends StatelessWidget {
  final ContentFilterResult filterResult;
  final FastingSession fastingSession;
  final VoidCallback? onViewProgress;
  final VoidCallback? onViewAlternatives;

  const FilteredContentWidget({
    Key? key,
    required this.filterResult,
    required this.fastingSession,
    this.onViewProgress,
    this.onViewAlternatives,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.green.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Filter icon and title
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.visibility_off,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content Filtered',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    Text(
                      'Supporting your fasting journey',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // Motivational content
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  filterResult.replacementContent ?? 
                  'Content hidden to support your fasting goals 🎯',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 16),
                
                // Progress indicator
                _buildProgressIndicator(),
              ],
            ),
          ),
          
          SizedBox(height: 16),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onViewProgress,
                  icon: Icon(Icons.timeline, size: 18),
                  label: Text('View Progress'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    side: BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 12),
              
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onViewAlternatives,
                  icon: Icon(Icons.fitness_center, size: 18),
                  label: Text('Motivation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Filter details (for transparency)
          Text(
            'Filtered: ${_getCategoryDisplayName(filterResult.category)} content',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Build progress indicator showing fasting progress
  Widget _buildProgressIndicator() {
    final progressPercentage = fastingSession.progressPercentage;
    final hoursElapsed = fastingSession.elapsedTime.inHours;
    final minutesElapsed = fastingSession.elapsedTime.inMinutes.remainder(60);
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fasting Progress',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            Text(
              '${hoursElapsed}h ${minutesElapsed}m',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 8),
        
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              progressPercentage > 0.75 ? Colors.green :
              progressPercentage > 0.5 ? Colors.orange :
              Colors.blue,
            ),
            minHeight: 8,
          ),
        ),
        
        SizedBox(height: 4),
        
        Text(
          '${(progressPercentage * 100).toInt()}% Complete',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  /// Get display name for filter category
  String _getCategoryDisplayName(FilterCategory? category) {
    switch (category) {
      case FilterCategory.food:
        return 'Food';
      case FilterCategory.restaurant:
        return 'Restaurant';
      case FilterCategory.cooking:
        return 'Cooking';
      case FilterCategory.drinks:
        return 'Beverage';
      case FilterCategory.snacks:
        return 'Snack';
      case FilterCategory.diet:
        return 'Diet';
      case FilterCategory.fitness:
        return 'Fitness';
      case FilterCategory.health:
        return 'Health';
      default:
        return 'Unknown';
    }
  }
}

/// Compact version for list items
class FilteredContentListItem extends StatelessWidget {
  final ContentFilterResult filterResult;
  final VoidCallback? onTap;

  const FilteredContentListItem({
    Key? key,
    required this.filterResult,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.visibility_off,
              color: Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Content filtered',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  if (filterResult.replacementContent != null)
                    Text(
                      filterResult.replacementContent!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Alternative content suggestions widget
class AlternativeContentWidget extends StatelessWidget {
  final AlternativeContent content;

  const AlternativeContentWidget({
    Key? key,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.withValues(alpha: 0.1),
            Colors.blue.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lightbulb,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  content.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Text(
            content.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
          
          if (content.actionText != null && content.onAction != null) ...[
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: content.onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(content.actionText!),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 