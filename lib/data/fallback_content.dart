/// Fallback content for AI features when RAG service is unavailable
/// Provides safe, goal-appropriate content as backup
library;

/// Fallback content organized by user goals and content types
class FallbackContent {
  // Content version for updates and cache invalidation
  static const String contentVersion = '1.0.0';
  static final DateTime lastUpdated = DateTime(2024, 12, 19);

  // Daily insights organized by goals
  static const Map<String, List<String>> _dailyInsights = {
    'weight_loss': [
      'Small changes add up! Try replacing one sugary drink with water today. *This is general wellness information, not medical advice.*',
      'Mindful eating can help you enjoy your food more and feel satisfied with smaller portions. *This is general wellness information, not medical advice.*',
      'Walking for just 10 extra minutes today can boost your energy and mood. *This is general wellness information, not medical advice.*',
      'Focus on adding more vegetables to your meals rather than restricting foods. *This is general wellness information, not medical advice.*',
      'Getting adequate sleep (7-9 hours) supports healthy metabolism and energy levels. *This is general wellness information, not medical advice.*',
      'Staying hydrated throughout the day can help manage hunger and boost energy. *This is general wellness information, not medical advice.*',
      'Eating protein with each meal can help you feel satisfied longer. *This is general wellness information, not medical advice.*',
      'Taking the stairs instead of the elevator is a simple way to add movement. *This is general wellness information, not medical advice.*',
      'Planning your meals ahead can help you make healthier choices. *This is general wellness information, not medical advice.*',
      'Celebrating small victories keeps you motivated on your journey. *This is general wellness information, not medical advice.*',
    ],
    'muscle_gain': [
      'Consistency with your workout routine is more important than intensity. *This is general wellness information, not medical advice.*',
      'Protein-rich foods like eggs, chicken, and beans support muscle recovery after exercise. *This is general wellness information, not medical advice.*',
      'Stay hydrated during workouts - aim for water before, during, and after exercise. *This is general wellness information, not medical advice.*',
      'Rest days are just as important as workout days for muscle development. *This is general wellness information, not medical advice.*',
      'Focus on compound movements that work multiple muscle groups for efficient training. *This is general wellness information, not medical advice.*',
      'Progressive overload means gradually increasing challenge over time. *This is general wellness information, not medical advice.*',
      'Proper form prevents injury and maximizes workout effectiveness. *This is general wellness information, not medical advice.*',
      'Eating enough calories supports your muscle-building goals. *This is general wellness information, not medical advice.*',
      'Quality sleep is when your muscles recover and grow. *This is general wellness information, not medical advice.*',
      'Tracking your workouts helps you see progress over time. *This is general wellness information, not medical advice.*',
    ],
    'energy': [
      'Eating balanced meals with protein, healthy fats, and complex carbs helps maintain steady energy. *This is general wellness information, not medical advice.*',
      'Take short breaks throughout your day to stretch and move around. *This is general wellness information, not medical advice.*',
      'Natural sunlight exposure in the morning can help regulate your energy cycles. *This is general wellness information, not medical advice.*',
      'Stay hydrated throughout the day - even mild dehydration can affect energy levels. *This is general wellness information, not medical advice.*',
      'Consider a 10-15 minute walk after meals to help with digestion and energy. *This is general wellness information, not medical advice.*',
      'Limiting caffeine after 2 PM may help improve your sleep quality. *This is general wellness information, not medical advice.*',
      'Deep breathing exercises can help reduce stress and boost energy. *This is general wellness information, not medical advice.*',
      'Eating iron-rich foods like spinach and lean meats supports energy levels. *This is general wellness information, not medical advice.*',
      'Regular exercise, even light activity, can increase overall energy. *This is general wellness information, not medical advice.*',
      'Managing stress through relaxation techniques supports sustained energy. *This is general wellness information, not medical advice.*',
    ],
    'health': [
      'A colorful plate with various fruits and vegetables provides diverse nutrients. *This is general wellness information, not medical advice.*',
      'Regular physical activity, even light exercise, supports overall wellness. *This is general wellness information, not medical advice.*',
      'Stress management through deep breathing or meditation can benefit overall health. *This is general wellness information, not medical advice.*',
      'Building healthy habits gradually is more sustainable than making drastic changes. *This is general wellness information, not medical advice.*',
      'Social connections and community support are important for overall wellness. *This is general wellness information, not medical advice.*',
      'Drinking plenty of water supports nearly every function in your body. *This is general wellness information, not medical advice.*',
      'Regular health check-ups help you stay on top of your wellness. *This is general wellness information, not medical advice.*',
      'Limiting processed foods and choosing whole foods supports overall health. *This is general wellness information, not medical advice.*',
      'Finding activities you enjoy makes staying active more sustainable. *This is general wellness information, not medical advice.*',
      'Practicing gratitude can improve both mental and physical well-being. *This is general wellness information, not medical advice.*',
    ],
    'strength': [
      'Progressive overload - gradually increasing challenge - helps build strength over time. *This is general wellness information, not medical advice.*',
      'Proper form is more important than lifting heavy weights. *This is general wellness information, not medical advice.*',
      'Include both upper and lower body exercises for balanced strength development. *This is general wellness information, not medical advice.*',
      'Functional movements that mimic daily activities can improve practical strength. *This is general wellness information, not medical advice.*',
      'Allow adequate recovery time between strength training sessions. *This is general wellness information, not medical advice.*',
      'Warming up before strength training prepares your muscles and joints. *This is general wellness information, not medical advice.*',
      'Core strength supports all other movements and daily activities. *This is general wellness information, not medical advice.*',
      'Bodyweight exercises can be just as effective as weights for building strength. *This is general wellness information, not medical advice.*',
      'Consistency beats intensity when building long-term strength. *This is general wellness information, not medical advice.*',
      'Listen to your body and adjust intensity based on how you feel. *This is general wellness information, not medical advice.*',
    ],
  };

  // Nutrition insights for different food types
  static const Map<String, String> _nutritionInsights = {
    'vegetables': 'Vegetables provide essential vitamins, minerals, and fiber that support overall health and digestion. *This is general wellness information, not medical advice.*',
    'fruits': 'Fruits offer natural sugars for energy along with vitamins and antioxidants. *This is general wellness information, not medical advice.*',
    'proteins': 'Protein foods help with muscle maintenance and can help you feel satisfied after meals. *This is general wellness information, not medical advice.*',
    'grains': 'Whole grains provide sustained energy and important B vitamins for daily activities. *This is general wellness information, not medical advice.*',
    'dairy': 'Dairy products can provide calcium and protein, though many alternatives exist for those who prefer them. *This is general wellness information, not medical advice.*',
    'nuts': 'Nuts and seeds provide healthy fats and protein, making them a satisfying snack option. *This is general wellness information, not medical advice.*',
    'fish': 'Fish provides lean protein and healthy omega-3 fatty acids that support overall wellness. *This is general wellness information, not medical advice.*',
    'chicken': 'Chicken is a versatile lean protein that can be prepared in many healthy ways. *This is general wellness information, not medical advice.*',
    'eggs': 'Eggs are a complete protein source and can be part of a balanced breakfast. *This is general wellness information, not medical advice.*',
    'legumes': 'Beans and lentils provide plant-based protein and fiber for sustained energy. *This is general wellness information, not medical advice.*',
    'avocado': 'Avocados contain healthy monounsaturated fats and fiber. *This is general wellness information, not medical advice.*',
    'berries': 'Berries are rich in antioxidants and add natural sweetness to meals. *This is general wellness information, not medical advice.*',
    'leafy_greens': 'Leafy greens like spinach and kale are nutrient-dense and versatile. *This is general wellness information, not medical advice.*',
    'sweet_potato': 'Sweet potatoes provide complex carbohydrates and beta-carotene. *This is general wellness information, not medical advice.*',
    'quinoa': 'Quinoa is a complete protein grain that provides all essential amino acids. *This is general wellness information, not medical advice.*',
  };

  // Recipe suggestions organized by dietary restrictions
  static const Map<String, List<String>> _recipeIdeas = {
    'vegetarian': [
      'Try a colorful vegetable stir-fry with tofu and brown rice for a balanced meal. *This is general wellness information, not medical advice.*',
      'Bean and vegetable soup with whole grain bread makes a hearty, protein-rich meal. *This is general wellness information, not medical advice.*',
      'Greek yogurt parfait with berries and nuts provides protein and healthy fats. *This is general wellness information, not medical advice.*',
      'Caprese salad with fresh mozzarella, tomatoes, and basil is light and satisfying. *This is general wellness information, not medical advice.*',
      'Vegetable curry with chickpeas and brown rice offers plant-based protein. *This is general wellness information, not medical advice.*',
      'Quinoa stuffed bell peppers make a colorful, nutrient-dense meal. *This is general wellness information, not medical advice.*',
    ],
    'vegan': [
      'Quinoa bowl with roasted vegetables and tahini dressing offers complete protein. *This is general wellness information, not medical advice.*',
      'Lentil curry with vegetables provides plant-based protein and fiber. *This is general wellness information, not medical advice.*',
      'Smoothie bowl with plant-based protein powder, fruits, and nuts for breakfast. *This is general wellness information, not medical advice.*',
      'Buddha bowl with hummus, vegetables, and seeds for a nutrient-packed meal. *This is general wellness information, not medical advice.*',
      'Black bean and sweet potato tacos with avocado are filling and flavorful. *This is general wellness information, not medical advice.*',
      'Overnight oats with almond milk, chia seeds, and fruit for easy breakfast. *This is general wellness information, not medical advice.*',
    ],
    'general': [
      'Grilled chicken with roasted vegetables and sweet potato for a balanced meal. *This is general wellness information, not medical advice.*',
      'Salmon with quinoa and steamed broccoli provides protein and omega-3s. *This is general wellness information, not medical advice.*',
      'Turkey and vegetable lettuce wraps for a light, protein-rich lunch. *This is general wellness information, not medical advice.*',
      'Lean beef stir-fry with mixed vegetables and brown rice. *This is general wellness information, not medical advice.*',
      'Baked cod with herbs and roasted root vegetables. *This is general wellness information, not medical advice.*',
      'Chicken and vegetable soup with whole grain crackers. *This is general wellness information, not medical advice.*',
    ],
    'low_carb': [
      'Zucchini noodles with grilled chicken and pesto sauce. *This is general wellness information, not medical advice.*',
      'Cauliflower rice stir-fry with shrimp and vegetables. *This is general wellness information, not medical advice.*',
      'Lettuce wrap tacos with ground turkey and avocado. *This is general wellness information, not medical advice.*',
      'Egg salad with mixed greens and cucumber. *This is general wellness information, not medical advice.*',
    ],
    'high_protein': [
      'Greek yogurt bowl with protein powder, berries, and nuts. *This is general wellness information, not medical advice.*',
      'Protein smoothie with spinach, banana, and almond butter. *This is general wellness information, not medical advice.*',
      'Cottage cheese with sliced tomatoes and herbs. *This is general wellness information, not medical advice.*',
      'Hard-boiled eggs with hummus and vegetables. *This is general wellness information, not medical advice.*',
    ],
  };

  // Mission ideas for different goals
  static const Map<String, Map<String, dynamic>> _missions = {
    'weight_loss': {
      'title': 'Your First 7 Days: Healthy Habits',
      'description': 'Start building sustainable habits that support your wellness journey.',
      'steps': [
        'Day 1: Track your meals to understand your eating patterns',
        'Day 2: Add one extra serving of vegetables to your dinner',
        'Day 3: Take a 15-minute walk after lunch',
        'Day 4: Replace one sugary drink with water',
        'Day 5: Try a new healthy recipe',
        'Day 6: Get 7-8 hours of sleep',
        'Day 7: Reflect on what felt good this week',
      ],
    },
    'muscle_gain': {
      'title': 'Your First 7 Days: Building Strength',
      'description': 'Establish a foundation for strength and muscle development.',
      'steps': [
        'Day 1: Do 10 bodyweight squats and 5 push-ups',
        'Day 2: Include protein with every meal',
        'Day 3: Try a 20-minute strength workout',
        'Day 4: Focus on proper form over intensity',
        'Day 5: Add an extra protein snack',
        'Day 6: Rest day - focus on recovery',
        'Day 7: Plan your workouts for next week',
      ],
    },
    'energy': {
      'title': 'Your First 7 Days: Natural Energy',
      'description': 'Build habits that naturally boost your energy levels.',
      'steps': [
        'Day 1: Eat a balanced breakfast with protein',
        'Day 2: Take a 5-minute walk every 2 hours',
        'Day 3: Drink water first thing in the morning',
        'Day 4: Get sunlight exposure in the morning',
        'Day 5: Try a 10-minute meditation',
        'Day 6: Go to bed 30 minutes earlier',
        'Day 7: Notice which habits boosted your energy',
      ],
    },
    'strength': {
      'title': 'Your First 7 Days: Building Foundation',
      'description': 'Create a strong foundation for your strength journey.',
      'steps': [
        'Day 1: Learn proper squat form with bodyweight',
        'Day 2: Practice push-ups (modified if needed)',
        'Day 3: Hold a plank for 30 seconds',
        'Day 4: Try lunges with proper form',
        'Day 5: Do a full-body stretching routine',
        'Day 6: Active recovery with a gentle walk',
        'Day 7: Set strength goals for next week',
      ],
    },
    'health': {
      'title': 'Your First 7 Days: Wellness Foundation',
      'description': 'Build a foundation of healthy habits for overall wellness.',
      'steps': [
        'Day 1: Eat 5 servings of fruits and vegetables',
        'Day 2: Drink 8 glasses of water',
        'Day 3: Get 30 minutes of movement',
        'Day 4: Practice 5 minutes of deep breathing',
        'Day 5: Connect with a friend or family member',
        'Day 6: Spend time in nature',
        'Day 7: Reflect on your wellness priorities',
      ],
    },
  };

  // AI content for feed integration
  static const Map<String, List<Map<String, dynamic>>> _aiContentArticles = {
    'weight_loss': [
      {
        'title': 'The Power of Small Changes',
        'content': 'Small, consistent changes often lead to lasting results. Focus on one habit at a time for sustainable progress.',
        'type': 'article',
        'category': 'motivation',
      },
      {
        'title': 'Mindful Eating Tips',
        'content': 'Eating slowly and paying attention to hunger cues can help you enjoy food more and feel satisfied with appropriate portions.',
        'type': 'tip',
        'category': 'nutrition',
      },
    ],
    'muscle_gain': [
      {
        'title': 'Recovery is Growth',
        'content': 'Your muscles grow during rest periods, not just during workouts. Prioritize sleep and rest days for optimal results.',
        'type': 'article',
        'category': 'fitness',
      },
      {
        'title': 'Protein Timing',
        'content': 'Including protein with each meal helps support muscle recovery and keeps you feeling satisfied throughout the day.',
        'type': 'tip',
        'category': 'nutrition',
      },
    ],
    'energy': [
      {
        'title': 'Natural Energy Boosters',
        'content': 'Regular movement, adequate hydration, and balanced meals are natural ways to maintain steady energy levels.',
        'type': 'article',
        'category': 'wellness',
      },
      {
        'title': 'Morning Sunlight',
        'content': 'Getting natural light in the morning helps regulate your circadian rhythm and can improve energy throughout the day.',
        'type': 'tip',
        'category': 'wellness',
      },
    ],
  };

  // Friend matching explanations
  static const List<String> _friendMatchingExplanations = [
    'You both have similar health goals and could motivate each other!',
    'Your activity levels and interests seem well-matched for mutual support.',
    'You share common dietary preferences and could exchange recipe ideas.',
    'Your wellness journeys are at similar stages - perfect for encouragement!',
    'You both value consistency in your health routines.',
    'Your complementary strengths could help you both grow.',
    'You share similar challenges and could support each other through them.',
    'Your positive attitudes toward health would be mutually inspiring.',
  ];

  // Weekly review fallback content
  static const Map<String, List<String>> _weeklyReviewHighlights = {
    'active': [
      'You stayed active this week - every bit of movement counts!',
      'Your consistency with activities is building healthy habits.',
      'You made time for your health despite a busy schedule.',
    ],
    'nutrition': [
      'You logged meals consistently, which helps with awareness.',
      'You tried new foods this week - variety is important for nutrition.',
      'Your focus on balanced meals is supporting your goals.',
    ],
    'social': [
      'You engaged with the community and shared your journey.',
      'Your stories inspired others on their wellness paths.',
      'You built connections that support your health goals.',
    ],
  };

  /// Get random daily insight for user's primary goal
  static String getDailyInsight(List<String> userGoals) {
    final primaryGoal = userGoals.isNotEmpty ? userGoals.first.toLowerCase() : 'health';
    final insights = _dailyInsights[primaryGoal] ?? _dailyInsights['health']!;
    
    // Use current day to ensure consistent insight per day
    final dayIndex = DateTime.now().day % insights.length;
    return insights[dayIndex];
  }

  /// Get nutrition insight for detected foods
  static String getNutritionInsight(List<String> detectedFoods) {
    if (detectedFoods.isEmpty) {
      return 'Eating a variety of foods helps ensure you get diverse nutrients. *This is general wellness information, not medical advice.*';
    }

    // Try to match detected foods with insights
    for (final food in detectedFoods) {
      final lowerFood = food.toLowerCase();
      for (final category in _nutritionInsights.keys) {
        if (lowerFood.contains(category) || 
            _isRelatedFood(lowerFood, category)) {
          return _nutritionInsights[category]!;
        }
      }
    }

    // Generic insight if no specific match
    return 'The foods you logged contain various nutrients that can support your wellness goals. *This is general wellness information, not medical advice.*';
  }

  /// Check if a food is related to a category
  static bool _isRelatedFood(String food, String category) {
    const foodMappings = {
      'vegetables': ['broccoli', 'carrot', 'spinach', 'kale', 'tomato', 'pepper', 'onion', 'celery', 'cucumber'],
      'fruits': ['apple', 'banana', 'orange', 'grape', 'strawberry', 'blueberry', 'mango', 'pineapple'],
      'proteins': ['beef', 'pork', 'turkey', 'tuna', 'salmon', 'shrimp', 'tofu', 'tempeh'],
      'grains': ['rice', 'bread', 'pasta', 'oats', 'barley', 'wheat', 'quinoa'],
      'legumes': ['bean', 'lentil', 'pea', 'chickpea', 'soy'],
    };

    final relatedFoods = foodMappings[category] ?? [];
    return relatedFoods.any((relatedFood) => food.contains(relatedFood));
  }

  /// Get recipe suggestions based on dietary restrictions
  static List<String> getRecipeSuggestions(List<String> dietaryRestrictions, {List<String>? userGoals}) {
    // Check for specific dietary restrictions first
    if (dietaryRestrictions.contains('vegan')) {
      return _recipeIdeas['vegan']!;
    } else if (dietaryRestrictions.contains('vegetarian')) {
      return _recipeIdeas['vegetarian']!;
    } else if (dietaryRestrictions.contains('low_carb') || dietaryRestrictions.contains('keto')) {
      return _recipeIdeas['low_carb']!;
    }

    // Check user goals for recipe suggestions
    if (userGoals != null) {
      if (userGoals.contains('muscle_gain') || userGoals.contains('strength')) {
        return _recipeIdeas['high_protein']!;
      }
    }

    return _recipeIdeas['general']!;
  }

  /// Get mission for user's primary goal
  static Map<String, dynamic> getMission(List<String> userGoals) {
    final primaryGoal = userGoals.isNotEmpty ? userGoals.first.toLowerCase() : 'health';
    return Map<String, dynamic>.from(_missions[primaryGoal] ?? _missions['health']!);
  }

  /// Get AI content for feed based on user goals
  static List<Map<String, dynamic>> getAIContentForFeed(List<String> userGoals, {int count = 3}) {
    final primaryGoal = userGoals.isNotEmpty ? userGoals.first.toLowerCase() : 'health';
    final content = _aiContentArticles[primaryGoal] ?? _aiContentArticles['weight_loss']!;
    
    return content.take(count).map((item) => Map<String, dynamic>.from(item)).toList();
  }

  /// Get friend matching explanation
  static String getFriendMatchingExplanation() {
    final random = DateTime.now().millisecond % _friendMatchingExplanations.length;
    return _friendMatchingExplanations[random];
  }

  /// Get weekly review highlights
  static List<String> getWeeklyReviewHighlights(Map<String, dynamic> activityData) {
    final highlights = <String>[];
    final metrics = activityData['metrics'] as Map<String, dynamic>? ?? {};
    
    // Add highlights based on activity
    final storyMetrics = metrics['stories'] as Map<String, dynamic>? ?? {};
    final storyCount = storyMetrics['total_count'] as int? ?? 0;
    if (storyCount > 0) {
      highlights.addAll(_weeklyReviewHighlights['social']!);
    }
    
    final mealMetrics = metrics['meals'] as Map<String, dynamic>? ?? {};
    final mealCount = mealMetrics['total_count'] as int? ?? 0;
    if (mealCount > 0) {
      highlights.addAll(_weeklyReviewHighlights['nutrition']!);
    }
    
    final overallMetrics = metrics['overall'] as Map<String, dynamic>? ?? {};
    final totalActivities = overallMetrics['total_activities'] as int? ?? 0;
    if (totalActivities > 0) {
      highlights.addAll(_weeklyReviewHighlights['active']!);
    }
    
    // Return up to 3 highlights
    return highlights.take(3).toList();
  }

  /// Get generic safe response when all else fails
  static String getSafeGenericResponse() {
    return '''
I'm here to support your wellness journey! While I don't have specific information for your question right now, I'd be happy to help with general nutrition education, lifestyle tips, and wellness information.

For personalized advice or specific health concerns, I recommend consulting with a healthcare professional who can provide guidance based on your individual needs.

*This information is for general wellness purposes only and is not a substitute for professional medical advice, diagnosis, or treatment.*
''';
  }

  // Conversation starters organized by group type
  static const Map<String, List<Map<String, dynamic>>> _conversationStarters = {
    'fasting': [
      {
        'title': 'Fasting Motivation Monday',
        'content': 'What keeps you motivated during your fasting windows? Share your tips and strategies!',
        'type': 'question',
        'tags': ['motivation', 'tips'],
      },
      {
        'title': 'Hydration Check',
        'content': 'How do you stay hydrated during fasting? What are your favorite non-caloric beverages?',
        'type': 'discussion',
        'tags': ['hydration', 'beverages'],
      },
      {
        'title': 'Breaking Fast Favorites',
        'content': 'What\'s your go-to meal for breaking your fast? Share your favorite recipes!',
        'type': 'discussion',
        'tags': ['meals', 'recipes'],
      },
    ],
    'calorieGoals': [
      {
        'title': 'Calorie Tracking Tips',
        'content': 'What tools or methods help you track calories effectively? Share your favorites!',
        'type': 'question',
        'tags': ['tracking', 'tools'],
      },
      {
        'title': 'Satisfying Low-Calorie Meals',
        'content': 'What are your favorite filling meals that fit your calorie goals?',
        'type': 'discussion',
        'tags': ['meals', 'satisfaction'],
      },
      {
        'title': 'Portion Size Wisdom',
        'content': 'What tricks help you manage portion sizes without feeling deprived?',
        'type': 'question',
        'tags': ['portions', 'tips'],
      },
    ],
    'workoutBuddies': [
      {
        'title': 'Workout Wednesday',
        'content': 'What\'s your favorite type of exercise and why? Let\'s inspire each other!',
        'type': 'discussion',
        'tags': ['exercise', 'motivation'],
      },
      {
        'title': 'Form Check Friday',
        'content': 'Share a tip about proper form for your favorite exercise!',
        'type': 'tip',
        'tags': ['form', 'technique'],
      },
      {
        'title': 'Accountability Partners',
        'content': 'Who wants to be workout buddies this week? Let\'s motivate each other!',
        'type': 'challenge',
        'tags': ['accountability', 'partners'],
      },
    ],
    'nutrition': [
      {
        'title': 'Meal Prep Sunday',
        'content': 'What are you prepping for the week? Share your meal prep ideas and photos!',
        'type': 'discussion',
        'tags': ['meal-prep', 'planning'],
      },
      {
        'title': 'Veggie Victory',
        'content': 'How do you sneak more vegetables into your meals? Share your creative ideas!',
        'type': 'question',
        'tags': ['vegetables', 'creativity'],
      },
      {
        'title': 'Healthy Swaps',
        'content': 'What\'s your favorite healthy ingredient swap that doesn\'t sacrifice taste?',
        'type': 'tip',
        'tags': ['swaps', 'healthy'],
      },
    ],
    'wellness': [
      {
        'title': 'Mindful Monday',
        'content': 'How do you practice mindfulness in your daily routine? Share your techniques!',
        'type': 'discussion',
        'tags': ['mindfulness', 'routine'],
      },
      {
        'title': 'Stress-Busting Strategies',
        'content': 'What healthy ways do you manage stress? Let\'s build a toolkit together!',
        'type': 'question',
        'tags': ['stress', 'management'],
      },
      {
        'title': 'Gratitude Practice',
        'content': 'Share three things you\'re grateful for today. Let\'s spread positivity!',
        'type': 'challenge',
        'tags': ['gratitude', 'positivity'],
      },
    ],
    'support': [
      {
        'title': 'Check-In Circle',
        'content': 'How are you feeling about your health journey this week? Share your wins and challenges!',
        'type': 'discussion',
        'tags': ['check-in', 'support'],
      },
      {
        'title': 'Motivation Monday',
        'content': 'What quote, song, or thought motivates you when things get tough?',
        'type': 'question',
        'tags': ['motivation', 'inspiration'],
      },
      {
        'title': 'Small Wins Celebration',
        'content': 'Share a small victory from your health journey - no win is too small to celebrate!',
        'type': 'challenge',
        'tags': ['wins', 'celebration'],
      },
    ],
    'recipes': [
      {
        'title': 'Recipe Remix',
        'content': 'Take a classic recipe and make it healthier! Share your creative modifications.',
        'type': 'challenge',
        'tags': ['recipes', 'healthy'],
      },
      {
        'title': 'Quick & Easy Favorites',
        'content': 'What\'s your go-to healthy recipe when you\'re short on time?',
        'type': 'question',
        'tags': ['quick', 'easy'],
      },
      {
        'title': 'Ingredient Spotlight',
        'content': 'Pick one healthy ingredient and share your favorite way to use it!',
        'type': 'discussion',
        'tags': ['ingredients', 'cooking'],
      },
    ],
  };

  /// Get conversation starter for group type
  static Map<String, dynamic> getConversationStarter(String groupType) {
    final starters = _conversationStarters[groupType] ?? _conversationStarters['support']!;
    
    // Use current day to ensure variety but consistency
    final dayIndex = DateTime.now().day % starters.length;
    return Map<String, dynamic>.from(starters[dayIndex]);
  }

  /// Get multiple conversation starters for scheduling
  static List<Map<String, dynamic>> getConversationStarters(String groupType, int count) {
    final starters = _conversationStarters[groupType] ?? _conversationStarters['support']!;
    final result = <Map<String, dynamic>>[];
    
    for (int i = 0; i < count && i < starters.length; i++) {
      result.add(Map<String, dynamic>.from(starters[i]));
    }
    
    return result;
  }

  /// Check if content exists for given parameters
  static bool hasContentFor({
    String? contentType,
    List<String>? userGoals,
    List<String>? dietaryRestrictions,
    String? groupType,
  }) {
    switch (contentType) {
      case 'daily_insight':
        return userGoals != null && userGoals.isNotEmpty;
      case 'nutrition_insight':
        return true; // Always have generic nutrition insights
      case 'recipe_suggestions':
        return true; // Always have recipe suggestions
      case 'mission':
        return userGoals != null && userGoals.isNotEmpty;
      case 'conversation_starter':
        return groupType != null && _conversationStarters.containsKey(groupType);
      case 'ai_content':
        return true; // Always have AI content for feed
      case 'friend_matching':
        return true; // Always have friend matching explanations
      case 'weekly_review':
        return true; // Always have weekly review content
      default:
        return true; // Always have generic safe response
    }
  }

  /// Get content version for cache invalidation
  static String getContentVersion() => contentVersion;

  /// Get last updated date
  static DateTime getLastUpdated() => lastUpdated;

  /// Validate content integrity
  static bool validateContent() {
    // Check that all required content categories exist
    final requiredCategories = [
      'weight_loss', 'muscle_gain', 'energy', 'health', 'strength'
    ];
    
    for (final category in requiredCategories) {
      if (!_dailyInsights.containsKey(category) || 
          _dailyInsights[category]!.isEmpty) {
        return false;
      }
    }
    
    return true;
  }

  /// Get content statistics for monitoring
  static Map<String, dynamic> getContentStats() {
    return {
      'version': contentVersion,
      'last_updated': lastUpdated.toIso8601String(),
      'daily_insights_count': _dailyInsights.values.fold<int>(0, (sum, list) => sum + list.length),
      'nutrition_insights_count': _nutritionInsights.length,
      'recipe_categories': _recipeIdeas.length,
      'mission_types': _missions.length,
      'conversation_starter_groups': _conversationStarters.length,
      'total_conversation_starters': _conversationStarters.values.fold<int>(0, (sum, list) => sum + list.length),
      'content_valid': validateContent(),
    };
  }
} 