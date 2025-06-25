/// Comprehensive Health Knowledge Data for SnapAMeal Phase II
/// Curated evidence-based health content for the RAG system
library health_knowledge_data;

import '../services/rag_service.dart';

class HealthKnowledgeData {
  static DateTime get _now => DateTime.now();

  /// Get all fitness knowledge documents
  static List<KnowledgeDocument> getFitnessKnowledge() {
    return [
      KnowledgeDocument(
        id: 'fitness_001',
        content: 'High-Intensity Interval Training (HIIT) burns more calories in less time and continues burning calories for hours after exercise (EPOC effect). Just 15-20 minutes, 3 times per week can significantly improve fitness and fat loss.',
        category: 'fitness',
        contentType: 'tip',
        source: 'curated',
        tags: ['HIIT', 'calorie_burn', 'EPOC', 'time_efficient'],
        confidenceScore: 0.93,
        lastUpdated: _now,
        userPreferenceMatch: ['weight_loss', 'time_efficient', 'fat_loss'],
      ),
      KnowledgeDocument(
        id: 'fitness_002',
        content: 'Strength training preserves muscle mass during weight loss, increases metabolism, and improves bone density. Aim for 2-3 sessions per week, focusing on compound movements like squats, deadlifts, and push-ups.',
        category: 'fitness',
        contentType: 'fact',
        source: 'curated',
        tags: ['strength_training', 'muscle_preservation', 'metabolism', 'compound_movements'],
        confidenceScore: 0.95,
        lastUpdated: _now,
        userPreferenceMatch: ['weight_loss', 'muscle_building', 'bone_health'],
      ),
      KnowledgeDocument(
        id: 'fitness_003',
        content: 'Walking is an underrated fat-burning exercise. A brisk 30-minute walk burns 150-200 calories and can be done anywhere. Aim for 8,000-10,000 steps daily for optimal health benefits.',
        category: 'fitness',
        contentType: 'tip',
        source: 'curated',
        tags: ['walking', 'steps', 'low_impact', 'accessible'],
        confidenceScore: 0.90,
        lastUpdated: _now,
        userPreferenceMatch: ['weight_loss', 'beginner_friendly', 'low_impact'],
      ),
    ];
  }

  /// Get all fasting knowledge documents
  static List<KnowledgeDocument> getFastingKnowledge() {
    return [
      KnowledgeDocument(
        id: 'fasting_001',
        content: 'The 16:8 intermittent fasting method involves eating within an 8-hour window and fasting for 16 hours. This pattern naturally reduces calorie intake and can improve insulin sensitivity and fat burning.',
        category: 'fasting',
        contentType: 'fact',
        source: 'curated',
        tags: ['16:8', 'eating_window', 'insulin_sensitivity', 'fat_burning'],
        confidenceScore: 0.95,
        lastUpdated: _now,
        userPreferenceMatch: ['intermittent_fasting', 'weight_loss', 'insulin_sensitivity'],
      ),
      KnowledgeDocument(
        id: 'fasting_002',
        content: 'During fasting periods, stay hydrated with water, herbal tea, or black coffee. These beverages won\'t break your fast and can help suppress appetite and maintain energy levels.',
        category: 'fasting',
        contentType: 'tip',
        source: 'curated',
        tags: ['hydration', 'appetite_suppression', 'coffee', 'herbal_tea'],
        confidenceScore: 0.90,
        lastUpdated: _now,
        userPreferenceMatch: ['intermittent_fasting', 'appetite_control'],
      ),
      KnowledgeDocument(
        id: 'fasting_003',
        content: 'Break your fast gently with nutrient-dense foods like vegetables, lean proteins, and healthy fats. Avoid processed foods or large meals immediately after fasting to prevent digestive discomfort.',
        category: 'fasting',
        contentType: 'tip',
        source: 'curated',
        tags: ['breaking_fast', 'nutrient_dense', 'gentle_refeeding', 'digestion'],
        confidenceScore: 0.88,
        lastUpdated: _now,
        userPreferenceMatch: ['intermittent_fasting', 'digestive_health'],
      ),
    ];
  }

  /// Get all weight loss knowledge documents
  static List<KnowledgeDocument> getWeightLossKnowledge() {
    return [
      KnowledgeDocument(
        id: 'weightloss_001',
        content: 'A sustainable weight loss rate is 1-2 pounds per week, achieved through a calorie deficit of 500-1000 calories daily. This preserves muscle mass and prevents metabolic slowdown.',
        category: 'weight_loss',
        contentType: 'fact',
        source: 'curated',
        tags: ['sustainable_rate', 'calorie_deficit', 'muscle_preservation', 'metabolism'],
        confidenceScore: 0.95,
        lastUpdated: _now,
        userPreferenceMatch: ['weight_loss', 'sustainable', 'healthy_rate'],
      ),
      KnowledgeDocument(
        id: 'weightloss_002',
        content: 'Weight loss plateaus are normal and occur as your body adapts to lower calorie intake. Combat plateaus by varying your exercise routine, adjusting calorie intake, or taking a brief diet break.',
        category: 'weight_loss',
        contentType: 'tip',
        source: 'curated',
        tags: ['plateaus', 'adaptation', 'diet_break', 'exercise_variation'],
        confidenceScore: 0.88,
        lastUpdated: _now,
        userPreferenceMatch: ['weight_loss', 'plateau_breaking'],
      ),
    ];
  }

  /// Get all meal planning knowledge documents
  static List<KnowledgeDocument> getMealPlanningKnowledge() {
    return [
      KnowledgeDocument(
        id: 'meal_planning_001',
        content: 'Meal prep on Sundays can save 3-4 hours during the week and ensures healthy options are always available. Focus on batch-cooking proteins, grains, and chopped vegetables.',
        category: 'meal_planning',
        contentType: 'tip',
        source: 'curated',
        tags: ['meal_prep', 'batch_cooking', 'time_saving', 'healthy_options'],
        confidenceScore: 0.92,
        lastUpdated: _now,
        userPreferenceMatch: ['time_efficient', 'meal_prep', 'healthy_eating'],
      ),
      KnowledgeDocument(
        id: 'meal_planning_002',
        content: 'The plate method for balanced meals: fill half your plate with vegetables, one quarter with lean protein, and one quarter with complex carbohydrates. Add a thumb-sized portion of healthy fats.',
        category: 'meal_planning',
        contentType: 'tip',
        source: 'curated',
        tags: ['plate_method', 'balanced_meals', 'portion_control', 'visual_guide'],
        confidenceScore: 0.95,
        lastUpdated: _now,
        userPreferenceMatch: ['portion_control', 'balanced_nutrition', 'visual_learning'],
      ),
    ];
  }

  /// Get all wellness knowledge documents
  static List<KnowledgeDocument> getWellnessKnowledge() {
    return [
      KnowledgeDocument(
        id: 'wellness_001',
        content: 'Quality sleep is crucial for weight management, hormone regulation, and recovery. Poor sleep disrupts hunger hormones (ghrelin and leptin), leading to increased appetite and cravings.',
        category: 'wellness',
        contentType: 'fact',
        source: 'curated',
        tags: ['sleep', 'hormones', 'ghrelin', 'leptin', 'appetite'],
        confidenceScore: 0.95,
        lastUpdated: _now,
        userPreferenceMatch: ['sleep_optimization', 'weight_loss', 'hormone_balance'],
      ),
      KnowledgeDocument(
        id: 'wellness_002',
        content: 'Chronic stress elevates cortisol levels, which can promote fat storage, especially around the midsection. Manage stress through meditation, deep breathing, regular exercise, or hobbies.',
        category: 'wellness',
        contentType: 'fact',
        source: 'curated',
        tags: ['stress_management', 'cortisol', 'fat_storage', 'meditation', 'breathing'],
        confidenceScore: 0.90,
        lastUpdated: _now,
        userPreferenceMatch: ['stress_management', 'weight_loss', 'meditation'],
      ),
    ];
  }

  /// Get all behavioral health knowledge documents
  static List<KnowledgeDocument> getBehavioralHealthKnowledge() {
    return [
      KnowledgeDocument(
        id: 'behavioral_001',
        content: 'Habit stacking - linking a new healthy habit to an existing routine - increases success rates by 65%. For example: "After I brush my teeth, I will do 10 push-ups."',
        category: 'behavioral_health',
        contentType: 'tip',
        source: 'curated',
        tags: ['habit_stacking', 'routine', 'behavior_change', 'success_rates'],
        confidenceScore: 0.90,
        lastUpdated: _now,
        userPreferenceMatch: ['habit_building', 'behavior_change', 'routine'],
      ),
      KnowledgeDocument(
        id: 'behavioral_002',
        content: 'Self-compassion during setbacks leads to better long-term outcomes than self-criticism. Treat yourself with the same kindness you would show a good friend facing similar challenges.',
        category: 'behavioral_health',
        contentType: 'tip',
        source: 'curated',
        tags: ['self_compassion', 'setbacks', 'long_term_success', 'kindness'],
        confidenceScore: 0.85,
        lastUpdated: _now,
        userPreferenceMatch: ['self_compassion', 'resilience', 'mental_health'],
      ),
    ];
  }

  /// Get all recipe knowledge documents
  static List<KnowledgeDocument> getRecipeKnowledge() {
    return [
      KnowledgeDocument(
        id: 'recipe_001',
        content: 'Quick protein-packed breakfast: Greek yogurt with berries and nuts. High in protein (20g), fiber, probiotics, and antioxidants. Takes 2 minutes to prepare and keeps you full for hours.',
        category: 'recipes',
        contentType: 'recipe',
        source: 'curated',
        tags: ['breakfast', 'protein', 'quick', 'greek_yogurt', 'berries'],
        confidenceScore: 0.90,
        lastUpdated: _now,
        userPreferenceMatch: ['quick_meals', 'high_protein', 'breakfast'],
      ),
      KnowledgeDocument(
        id: 'recipe_002',
        content: 'Simple fat-burning salad: Mixed greens, grilled chicken, avocado, and olive oil vinaigrette. Provides complete protein, healthy fats, and fiber for sustained energy and satiety.',
        category: 'recipes',
        contentType: 'recipe',
        source: 'curated',
        tags: ['salad', 'fat_burning', 'chicken', 'avocado', 'complete_protein'],
        confidenceScore: 0.88,
        lastUpdated: _now,
        userPreferenceMatch: ['fat_loss', 'balanced_meals', 'salads'],
      ),
    ];
  }

  /// Get all supplement knowledge documents
  static List<KnowledgeDocument> getSupplementKnowledge() {
    return [
      KnowledgeDocument(
        id: 'supplement_001',
        content: 'Vitamin D deficiency affects 40% of adults and can impact mood, bone health, and immune function. Consider supplementation if you have limited sun exposure, especially in winter months.',
        category: 'supplements',
        contentType: 'fact',
        source: 'curated',
        tags: ['vitamin_d', 'deficiency', 'mood', 'bone_health', 'immune'],
        confidenceScore: 0.92,
        lastUpdated: _now,
        userPreferenceMatch: ['vitamin_d', 'bone_health', 'immune_support'],
      ),
    ];
  }

  /// Get all hydration knowledge documents
  static List<KnowledgeDocument> getHydrationKnowledge() {
    return [
      KnowledgeDocument(
        id: 'hydration_001',
        content: 'Proper hydration supports metabolism, appetite control, and exercise performance. Aim for half your body weight in ounces daily, plus extra during exercise or hot weather.',
        category: 'hydration',
        contentType: 'tip',
        source: 'curated',
        tags: ['hydration', 'metabolism', 'appetite_control', 'exercise_performance'],
        confidenceScore: 0.95,
        lastUpdated: _now,
        userPreferenceMatch: ['hydration', 'metabolism', 'exercise_performance'],
      ),
      KnowledgeDocument(
        id: 'hydration_002',
        content: 'Drinking water before meals can reduce calorie intake by 13% and support weight loss. Try having a large glass of water 30 minutes before eating to improve satiety.',
        category: 'hydration',
        contentType: 'tip',
        source: 'curated',
        tags: ['pre_meal_water', 'calorie_reduction', 'satiety', 'weight_loss'],
        confidenceScore: 0.88,
        lastUpdated: _now,
        userPreferenceMatch: ['weight_loss', 'appetite_control', 'hydration'],
      ),
    ];
  }
} 