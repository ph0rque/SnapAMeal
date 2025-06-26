import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../snap_ui.dart';
import '../../models/meal_log.dart';

/// Beautiful meal card widget for displaying meal logs
class MealCardWidget extends StatelessWidget {
  final MealLog mealLog;
  final VoidCallback? onTap;
  final VoidCallback? onShare;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;
  final bool isCompact;

  const MealCardWidget({
    super.key,
    required this.mealLog,
    this.onTap,
    this.onShare,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SnapDimensions.radiusM),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SnapDimensions.radiusM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(),
            _buildContentSection(),
            if (!isCompact) _buildNutritionSection(),
            if (showActions) _buildActionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader() {
    return Stack(
      children: [
        // Meal Image
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: AspectRatio(
            aspectRatio: isCompact ? 16 / 9 : 4 / 3,
            child: CachedNetworkImage(
              imageUrl: mealLog.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
        
        // Timestamp Overlay
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              timeago.format(mealLog.timestamp),
              style: SnapTypography.caption.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
        
        // Confidence Badge
        if (mealLog.recognitionResult.confidenceScore > 0.8)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified, color: Colors.white, size: 12),
                  const SizedBox(width: 2),
                  Text(
                    'AI Verified',
                    style: SnapTypography.caption.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detected Foods
          if (mealLog.recognitionResult.detectedFoods.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.local_dining,
                  size: 16,
                  color: SnapColors.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mealLog.recognitionResult.detectedFoods
                        .map((food) => food.name)
                        .join(', '),
                    style: SnapTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: SnapDimensions.spacingS),
          ],
          
          // AI Caption
          if (mealLog.aiCaption != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SnapColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SnapColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                mealLog.aiCaption!,
                style: SnapTypography.body.copyWith(
                  fontStyle: FontStyle.italic,
                  color: SnapColors.primary.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: SnapDimensions.spacingS),
          ],
          
          // User Caption
          if (mealLog.userCaption != null) ...[
            Text(
              mealLog.userCaption!,
              style: SnapTypography.body,
            ),
            const SizedBox(height: SnapDimensions.spacingS),
          ],
          
          // Tags
          if (mealLog.tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: mealLog.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SnapColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SnapColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '#$tag',
                  style: SnapTypography.caption.copyWith(
                    color: SnapColors.primary,
                    fontSize: 11,
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: SnapDimensions.spacingS),
          ],
          
          // Mood and Hunger (if not compact)
          if (!isCompact && (mealLog.moodRating != null || mealLog.hungerLevel != null)) ...[
            Row(
              children: [
                if (mealLog.moodRating != null) ...[
                  const Icon(
                    Icons.sentiment_satisfied,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mood: ${mealLog.moodRating!.rating}/5',
                    style: SnapTypography.caption,
                  ),
                ],
                if (mealLog.moodRating != null && mealLog.hungerLevel != null)
                  const SizedBox(width: 16),
                if (mealLog.hungerLevel != null) ...[
                  const Icon(
                    Icons.restaurant,
                    size: 16,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Hunger: ${mealLog.hungerLevel!.level}/5',
                    style: SnapTypography.caption,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionSection() {
    final nutrition = mealLog.recognitionResult.totalNutrition;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SnapColors.greyBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SnapColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                size: 16,
                color: SnapColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Nutrition Facts',
                style: SnapTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SnapDimensions.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutritionItem('Calories', '${nutrition.calories.round()}', 'kcal'),
              _buildNutritionItem('Protein', '${nutrition.protein.round()}', 'g'),
              _buildNutritionItem('Carbs', '${nutrition.carbs.round()}', 'g'),
              _buildNutritionItem('Fat', '${nutrition.fat.round()}', 'g'),
            ],
          ),
          
          // Allergen Warnings
          if (mealLog.recognitionResult.allergenWarnings.isNotEmpty) ...[
            const SizedBox(height: SnapDimensions.spacingS),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Contains: ${mealLog.recognitionResult.allergenWarnings.join(', ')}',
                      style: SnapTypography.caption.copyWith(
                        color: Colors.orange[800],
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: SnapTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: SnapColors.primary,
          ),
        ),
        Text(
          unit,
          style: SnapTypography.caption.copyWith(
            fontSize: 10,
            color: SnapColors.primary,
          ),
        ),
        Text(
          label,
          style: SnapTypography.caption.copyWith(
            fontSize: 10,
            color: SnapColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: SnapColors.greyBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (onShare != null)
            _buildActionButton(
              icon: Icons.share,
              label: 'Share',
              onTap: onShare!,
            ),
          if (onEdit != null)
            _buildActionButton(
              icon: Icons.edit,
              label: 'Edit',
              onTap: onEdit!,
            ),
          if (onDelete != null)
            _buildActionButton(
              icon: Icons.delete,
              label: 'Delete',
              onTap: onDelete!,
              color: SnapColors.error,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: color ?? SnapColors.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: SnapTypography.caption.copyWith(
                color: color ?? SnapColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact version of meal card for lists
class CompactMealCard extends StatelessWidget {
  final MealLog mealLog;
  final VoidCallback? onTap;

  const CompactMealCard({
    super.key,
    required this.mealLog,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MealCardWidget(
      mealLog: mealLog,
      onTap: onTap,
      showActions: false,
      isCompact: true,
    );
  }
}

/// Meal stats widget for displaying aggregated nutrition information
class MealStatsWidget extends StatelessWidget {
  final List<MealLog> mealLogs;
  final String period; // 'today', 'week', 'month'

  const MealStatsWidget({
    super.key,
    required this.mealLogs,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    final totalNutrition = _calculateTotalNutrition();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SnapColors.primary.withValues(alpha: 0.1),
            SnapColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
                  borderRadius: BorderRadius.circular(SnapDimensions.borderRadius),
        border: Border.all(
          color: SnapColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: SnapColors.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Nutrition Summary - ${period.toUpperCase()}',
                style: SnapTypography.heading.copyWith(
                  color: SnapColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: SnapDimensions.spacingS),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Meals', '${mealLogs.length}', Icons.restaurant),
              _buildStatItem('Calories', '${totalNutrition.calories.round()}', Icons.local_fire_department),
              _buildStatItem('Protein', '${totalNutrition.protein.round()}g', Icons.fitness_center),
              _buildStatItem('Avg Score', '${_calculateAvgConfidence().toStringAsFixed(1)}%', Icons.star),
            ],
          ),
        ],
      ),
    );
  }

  NutritionInfo _calculateTotalNutrition() {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;
    double totalSodium = 0;

    for (final meal in mealLogs) {
      final nutrition = meal.recognitionResult.totalNutrition;
      totalCalories += nutrition.calories;
      totalProtein += nutrition.protein;
      totalCarbs += nutrition.carbs;
      totalFat += nutrition.fat;
      totalFiber += nutrition.fiber;
      totalSugar += nutrition.sugar;
      totalSodium += nutrition.sodium;
    }

    return NutritionInfo(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      sugar: totalSugar,
      sodium: totalSodium,
      servingSize: mealLogs.fold(0.0, (sum, meal) => sum + meal.recognitionResult.totalNutrition.servingSize),
      vitamins: {},
      minerals: {},
    );
  }

  double _calculateAvgConfidence() {
    if (mealLogs.isEmpty) return 0.0;
    
    double totalConfidence = 0;
    for (final meal in mealLogs) {
      totalConfidence += meal.recognitionResult.confidenceScore;
    }
    
    return (totalConfidence / mealLogs.length) * 100;
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: SnapColors.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: SnapTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: SnapColors.primary,
          ),
        ),
        Text(
          label,
          style: SnapTypography.caption,
        ),
      ],
    );
  }
} 