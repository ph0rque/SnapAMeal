/// Comprehensive Health Knowledge Data for SnapAMeal Phase II
/// Curated evidence-based health content for the RAG system

import '../services/rag_service.dart';

class HealthKnowledgeData {
  static DateTime get _now => DateTime.now();

  /// Get all fitness knowledge documents
  static List<KnowledgeDocument> getFitnessKnowledge() {
    return [
      KnowledgeDocument(
        id: 'fitness_001',
        title: 'HIIT Training Benefits',
        content: 'High-Intensity Interval Training (HIIT) burns more calories in less time and continues burning calories for hours after exercise (EPOC effect). Just 15-20 minutes, 3 times per week can significantly improve fitness and fat loss.',
        category: 'fitness',
        source: 'curated',
        tags: ['HIIT', 'calorie_burn', 'EPOC', 'time_efficient'],
        confidenceScore: 0.93,
        createdAt: _now,
        metadata: {
          'contentType': 'tip',
          'userPreferenceMatch': ['weight_loss', 'time_efficient', 'fat_loss'],
        },
      ),
      KnowledgeDocument(
        id: 'fitness_002',
        title: 'Strength Training Benefits',
        content: 'Strength training preserves muscle mass during weight loss, increases metabolism, and improves bone density. Aim for 2-3 sessions per week, focusing on compound movements like squats, deadlifts, and push-ups.',
        category: 'fitness',
        source: 'curated',
        tags: ['strength_training', 'muscle_preservation', 'metabolism', 'compound_movements'],
        confidenceScore: 0.95,
        createdAt: _now,
        metadata: {
          'contentType': 'fact',
          'userPreferenceMatch': ['weight_loss', 'muscle_building', 'bone_health'],
        },
      ),
      KnowledgeDocument(
        id: 'fitness_003',
        title: 'Walking Exercise Benefits',
        content: 'Walking is an underrated fat-burning exercise. A brisk 30-minute walk burns 150-200 calories and can be done anywhere. Aim for 8,000-10,000 steps daily for optimal health benefits.',
        category: 'fitness',
        source: 'curated',
        tags: ['walking', 'steps', 'low_impact', 'accessible'],
        confidenceScore: 0.90,
        createdAt: _now,
        metadata: {
          'contentType': 'tip',
          'userPreferenceMatch': ['weight_loss', 'beginner_friendly', 'low_impact'],
        },
      ),
    ];
  }

  /// Get all fasting knowledge documents
  static List<KnowledgeDocument> getFastingKnowledge() {
    return [
      KnowledgeDocument(
        id: 'fasting_001',
        title: '16:8 Intermittent Fasting Method',
        content: 'The 16:8 intermittent fasting method involves eating within an 8-hour window and fasting for 16 hours. This pattern naturally reduces calorie intake and can improve insulin sensitivity and fat burning.',
        category: 'fasting',
        source: 'curated',
        tags: ['16:8', 'eating_window', 'insulin_sensitivity', 'fat_burning'],
        confidenceScore: 0.95,
        createdAt: _now,
        metadata: {
          'contentType': 'fact',
          'userPreferenceMatch': ['intermittent_fasting', 'weight_loss', 'insulin_sensitivity'],
        },
      ),
      KnowledgeDocument(
        id: 'fasting_002',
        title: 'Fasting Period Hydration',
        content: 'During fasting periods, stay hydrated with water, herbal tea, or black coffee. These beverages won\'t break your fast and can help suppress appetite and maintain energy levels.',
        category: 'fasting',
        source: 'curated',
        tags: ['hydration', 'appetite_suppression', 'coffee', 'herbal_tea'],
        confidenceScore: 0.90,
        createdAt: _now,
        metadata: {
          'contentType': 'tip',
          'userPreferenceMatch': ['intermittent_fasting', 'appetite_control'],
        },
      ),
      KnowledgeDocument(
        id: 'fasting_003',
        title: 'Breaking Your Fast Properly',
        content: 'Break your fast gently with nutrient-dense foods like vegetables, lean proteins, and healthy fats. Avoid processed foods or large meals immediately after fasting to prevent digestive discomfort.',
        category: 'fasting',
        source: 'curated',
        tags: ['breaking_fast', 'nutrient_dense', 'gentle_refeeding', 'digestion'],
        confidenceScore: 0.88,
        createdAt: _now,
        metadata: {
          'contentType': 'tip',
          'userPreferenceMatch': ['intermittent_fasting', 'digestive_health'],
        },
      ),
    ];
  }

  /// Get all weight loss knowledge documents
  static List<KnowledgeDocument> getWeightLossKnowledge() {
    return [
      KnowledgeDocument(
        id: 'weightloss_001',
        title: 'Sustainable Weight Loss Rate',
        content: 'A sustainable weight loss rate is 1-2 pounds per week, achieved through a calorie deficit of 500-1000 calories daily. This preserves muscle mass and prevents metabolic slowdown.',
        category: 'weight_loss',
        source: 'curated',
        tags: ['sustainable_rate', 'calorie_deficit', 'muscle_preservation', 'metabolism'],
        confidenceScore: 0.95,
        createdAt: _now,
        metadata: {
          'contentType': 'fact',
          'userPreferenceMatch': ['weight_loss', 'sustainable', 'healthy_rate'],
        },
      ),
      KnowledgeDocument(
        id: 'weightloss_002',
        title: 'Overcoming Weight Loss Plateaus',
        content: 'Weight loss plateaus are normal and occur as your body adapts to lower calorie intake. Combat plateaus by varying your exercise routine, adjusting calorie intake, or taking a brief diet break.',
        category: 'weight_loss',
        source: 'curated',
        tags: ['plateaus', 'adaptation', 'diet_break', 'exercise_variation'],
        confidenceScore: 0.88,
        createdAt: _now,
        metadata: {
          'contentType': 'tip',
          'userPreferenceMatch': ['weight_loss', 'plateau_breaking'],
        },
      ),
    ];
  }

  /// Get all meal planning knowledge documents
  static List<KnowledgeDocument> getMealPlanningKnowledge() {
    return [
      KnowledgeDocument(
        id: 'meal_planning_001',
        title: 'Sunday Meal Prep Strategy',
        content: 'Meal prep on Sundays can save 3-4 hours during the week and ensures healthy options are always available. Focus on batch-cooking proteins, grains, and chopped vegetables.',
        category: 'meal_planning',
        source: 'curated',
        tags: ['meal_prep', 'batch_cooking', 'time_saving', 'healthy_options'],
        confidenceScore: 0.92,
        createdAt: _now,
        metadata: {
          'contentType': 'tip',
          'userPreferenceMatch': ['time_efficient', 'meal_prep', 'healthy_eating'],
        },
      ),
      KnowledgeDocument(
        id: 'meal_planning_002',
        title: 'The Plate Method for Balanced Meals',
        content: 'The plate method for balanced meals: fill half your plate with vegetables, one quarter with lean protein, and one quarter with complex carbohydrates. Add a thumb-sized portion of healthy fats.',
        category: 'meal_planning',
        source: 'curated',
        tags: ['plate_method', 'balanced_meals', 'portion_control', 'visual_guide'],
        confidenceScore: 0.95,
        createdAt: _now,
        metadata: {
          'contentType': 'tip',
          'userPreferenceMatch': ['portion_control', 'balanced_nutrition', 'visual_learning'],
        },
      ),
    ];
  }

  /// Get all wellness knowledge documents
  static List<KnowledgeDocument> getWellnessKnowledge() {
    return [
      KnowledgeDocument(
        id: 'wellness_001',
        title: 'Sleep and Weight Management',
        content: 'Quality sleep is crucial for weight management, hormone regulation, and recovery. Poor sleep disrupts hunger hormones (ghrelin and leptin), leading to increased appetite and cravings.',
        category: 'wellness',
        source: 'curated',
        tags: ['sleep', 'hormones', 'ghrelin', 'leptin', 'appetite'],
        confidenceScore: 0.95,
        createdAt: _now,
        metadata: {
          'contentType': 'fact',
          'userPreferenceMatch': ['sleep_optimization', 'weight_loss', 'hormone_balance'],
        },
      ),
      KnowledgeDocument(
        id: 'wellness_002',
        title: 'Stress Management and Weight',
        content: 'Chronic stress elevates cortisol levels, which can promote fat storage, especially around the midsection. Manage stress through meditation, deep breathing, regular exercise, or hobbies.',
        category: 'wellness',
        source: 'curated',
        tags: ['stress_management', 'cortisol', 'fat_storage', 'meditation', 'breathing'],
        confidenceScore: 0.90,
        createdAt: _now,
        metadata: {
          'contentType': 'fact',
          'userPreferenceMatch': ['stress_management', 'weight_loss', 'meditation'],
        },
      ),
    ];
  }

  /// Get all behavioral health knowledge documents
  static List<KnowledgeDocument> getBehavioralHealthKnowledge() {
    return [
      KnowledgeDocument(
        id: 'behavioral_001',
        title: 'Habit Stacking for Success',
        content: 'Habit stacking - linking a new healthy habit to an existing routine - increases success rates by 65%. For example: "After I brush my teeth, I will do 10 push-ups."',
        category: 'behavioral_health',
        source: 'curated',
        tags: ['habit_stacking', 'routine', 'behavior_change', 'success_rates'],
        confidenceScore: 0.90,
        createdAt: _now,
        metadata: {
          'contentType': 'tip',
          'userPreferenceMatch': ['habit_building', 'behavior_change', 'routine'],
        },
      ),
      KnowledgeDocument(
        id: 'behavioral_002',
        title: 'Self-Compassion in Health Journey',
        content: 'Self-compassion during setbacks leads to better long-term outcomes than self-criticism. Treat yourself with the same kindness you would show a good friend facing similar challenges.',
        category: 'behavioral_health',
        source: 'curated',
        tags: ['self_compassion', 'setbacks', 'long_term_success', 'kindness'],
        confidenceScore: 0.85,
        createdAt: _now,
        metadata: {
          'contentType': 'tip',
          'userPreferenceMatch': ['self_compassion', 'resilience', 'mental_health'],
        },
      ),
    ];
  }

  /// Get all recipe knowledge documents
  static List<KnowledgeDocument> getRecipeKnowledge() {
    return [
      KnowledgeDocument(
        id: 'recipe_001',
        title: 'Quick Protein-Packed Breakfast',
        content: 'Quick protein-packed breakfast: Greek yogurt with berries and nuts. High in protein (20g), fiber, probiotics, and antioxidants. Takes 2 minutes to prepare and keeps you full for hours.',
        category: 'recipes',
        source: 'curated',
        tags: ['breakfast', 'protein', 'quick', 'greek_yogurt', 'berries'],
        confidenceScore: 0.88,
        createdAt: _now,
        metadata: {
          'contentType': 'recipe',
          'userPreferenceMatch': ['quick_meals', 'high_protein', 'breakfast'],
        },
      ),
      KnowledgeDocument(
        id: 'recipe_002',
        title: 'Balanced Post-Workout Meal',
        content: 'Post-workout meal: Grilled chicken with quinoa and roasted vegetables. Provides complete protein for muscle recovery, complex carbs for energy replenishment, and vitamins from colorful vegetables.',
        category: 'recipes',
        source: 'curated',
        tags: ['post_workout', 'protein', 'quinoa', 'muscle_recovery'],
        confidenceScore: 0.92,
        createdAt: _now,
        metadata: {
          'contentType': 'recipe',
          'userPreferenceMatch': ['post_workout', 'muscle_building', 'balanced_nutrition'],
        },
      ),
    ];
  }

  /// Get all supplement knowledge documents
  static List<KnowledgeDocument> getSupplementKnowledge() {
    return [
      KnowledgeDocument(
        id: 'supplement_001',
        title: 'Vitamin D for Health',
        content: 'Vitamin D supports immune function, bone health, and mood regulation. Most people need 1000-2000 IU daily, especially those with limited sun exposure. Best taken with fat for absorption.',
        category: 'supplements',
        source: 'curated',
        tags: ['vitamin_d', 'immune_function', 'bone_health', 'mood'],
        confidenceScore: 0.90,
        createdAt: _now,
        metadata: {
          'contentType': 'fact',
          'userPreferenceMatch': ['immune_health', 'bone_health', 'mood_support'],
        },
      ),
      KnowledgeDocument(
        id: 'supplement_002',
        title: 'Omega-3 Fatty Acids Benefits',
        content: 'Omega-3 fatty acids support heart health, brain function, and reduce inflammation. Aim for 1-2g daily from fish oil or algae-based supplements if you don\'t eat fatty fish regularly.',
        category: 'supplements',
        source: 'curated',
        tags: ['omega_3', 'heart_health', 'brain_function', 'inflammation'],
        confidenceScore: 0.92,
        createdAt: _now,
        metadata: {
          'contentType': 'fact',
          'userPreferenceMatch': ['heart_health', 'brain_health', 'anti_inflammatory'],
        },
      ),
    ];
  }

  /// Get all hydration knowledge documents
  static List<KnowledgeDocument> getHydrationKnowledge() {
    return [
      KnowledgeDocument(
        id: 'hydration_001',
        title: 'Daily Water Intake Guidelines',
        content: 'Aim for 8-10 glasses (64-80 oz) of water daily, more if you exercise or live in hot climates. Proper hydration supports metabolism, appetite control, and energy levels.',
        category: 'hydration',
        source: 'curated',
        tags: ['water_intake', 'metabolism', 'appetite_control', 'energy'],
        confidenceScore: 0.95,
        createdAt: _now,
        metadata: {
          'contentType': 'tip',
          'userPreferenceMatch': ['hydration', 'metabolism', 'energy'],
        },
      ),
      KnowledgeDocument(
        id: 'hydration_002',
        title: 'Hydration During Exercise',
        content: 'Drink 16-20 oz of water 2-3 hours before exercise, 8 oz every 15-20 minutes during exercise, and 16-24 oz for every pound lost through sweat after exercise.',
        category: 'hydration',
        source: 'curated',
        tags: ['exercise_hydration', 'pre_workout', 'post_workout', 'sweat_replacement'],
        confidenceScore: 0.90,
        createdAt: _now,
        metadata: {
          'contentType': 'tip',
          'userPreferenceMatch': ['exercise', 'hydration', 'performance'],
        },
      ),
    ];
  }

  /// Get all documents combined
  static List<KnowledgeDocument> getAllKnowledge() {
    return [
      ...getFitnessKnowledge(),
      ...getFastingKnowledge(),
      ...getWeightLossKnowledge(),
      ...getMealPlanningKnowledge(),
      ...getWellnessKnowledge(),
      ...getBehavioralHealthKnowledge(),
      ...getRecipeKnowledge(),
      ...getSupplementKnowledge(),
      ...getHydrationKnowledge(),
    ];
  }

  /// Get knowledge by category
  static List<KnowledgeDocument> getKnowledgeByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'fitness':
        return getFitnessKnowledge();
      case 'fasting':
        return getFastingKnowledge();
      case 'weight_loss':
        return getWeightLossKnowledge();
      case 'meal_planning':
        return getMealPlanningKnowledge();
      case 'wellness':
        return getWellnessKnowledge();
      case 'behavioral_health':
        return getBehavioralHealthKnowledge();
      case 'recipes':
        return getRecipeKnowledge();
      case 'supplements':
        return getSupplementKnowledge();
      case 'hydration':
        return getHydrationKnowledge();
      default:
        return [];
    }
  }

  /// Search knowledge by tags
  static List<KnowledgeDocument> getKnowledgeByTags(List<String> searchTags) {
    final allKnowledge = getAllKnowledge();
    return allKnowledge.where((doc) {
      return searchTags.any((tag) => doc.tags.contains(tag));
    }).toList();
  }
} 