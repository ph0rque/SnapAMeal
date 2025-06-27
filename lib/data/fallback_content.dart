/// Fallback content for AI features when RAG service is unavailable
/// Provides safe, goal-appropriate content as backup
library;

/// Fallback content organized by user goals and content types
class FallbackContent {
  // Daily insights organized by goals
  static const Map<String, List<String>> _dailyInsights = {
    'weight_loss': [
      'Small changes add up! Try replacing one sugary drink with water today. *This is general wellness information, not medical advice.*',
      'Mindful eating can help you enjoy your food more and feel satisfied with smaller portions. *This is general wellness information, not medical advice.*',
      'Walking for just 10 extra minutes today can boost your energy and mood. *This is general wellness information, not medical advice.*',
      'Focus on adding more vegetables to your meals rather than restricting foods. *This is general wellness information, not medical advice.*',
      'Getting adequate sleep (7-9 hours) supports healthy metabolism and energy levels. *This is general wellness information, not medical advice.*',
    ],
    'muscle_gain': [
      'Consistency with your workout routine is more important than intensity. *This is general wellness information, not medical advice.*',
      'Protein-rich foods like eggs, chicken, and beans support muscle recovery after exercise. *This is general wellness information, not medical advice.*',
      'Stay hydrated during workouts - aim for water before, during, and after exercise. *This is general wellness information, not medical advice.*',
      'Rest days are just as important as workout days for muscle development. *This is general wellness information, not medical advice.*',
      'Focus on compound movements that work multiple muscle groups for efficient training. *This is general wellness information, not medical advice.*',
    ],
    'energy': [
      'Eating balanced meals with protein, healthy fats, and complex carbs helps maintain steady energy. *This is general wellness information, not medical advice.*',
      'Take short breaks throughout your day to stretch and move around. *This is general wellness information, not medical advice.*',
      'Natural sunlight exposure in the morning can help regulate your energy cycles. *This is general wellness information, not medical advice.*',
      'Stay hydrated throughout the day - even mild dehydration can affect energy levels. *This is general wellness information, not medical advice.*',
      'Consider a 10-15 minute walk after meals to help with digestion and energy. *This is general wellness information, not medical advice.*',
    ],
    'health': [
      'A colorful plate with various fruits and vegetables provides diverse nutrients. *This is general wellness information, not medical advice.*',
      'Regular physical activity, even light exercise, supports overall wellness. *This is general wellness information, not medical advice.*',
      'Stress management through deep breathing or meditation can benefit overall health. *This is general wellness information, not medical advice.*',
      'Building healthy habits gradually is more sustainable than making drastic changes. *This is general wellness information, not medical advice.*',
      'Social connections and community support are important for overall wellness. *This is general wellness information, not medical advice.*',
    ],
    'strength': [
      'Progressive overload - gradually increasing challenge - helps build strength over time. *This is general wellness information, not medical advice.*',
      'Proper form is more important than lifting heavy weights. *This is general wellness information, not medical advice.*',
      'Include both upper and lower body exercises for balanced strength development. *This is general wellness information, not medical advice.*',
      'Functional movements that mimic daily activities can improve practical strength. *This is general wellness information, not medical advice.*',
      'Allow adequate recovery time between strength training sessions. *This is general wellness information, not medical advice.*',
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
  };

  // Recipe suggestions organized by dietary restrictions
  static const Map<String, List<String>> _recipeIdeas = {
    'vegetarian': [
      'Try a colorful vegetable stir-fry with tofu and brown rice for a balanced meal. *This is general wellness information, not medical advice.*',
      'Bean and vegetable soup with whole grain bread makes a hearty, protein-rich meal. *This is general wellness information, not medical advice.*',
      'Greek yogurt parfait with berries and nuts provides protein and healthy fats. *This is general wellness information, not medical advice.*',
    ],
    'vegan': [
      'Quinoa bowl with roasted vegetables and tahini dressing offers complete protein. *This is general wellness information, not medical advice.*',
      'Lentil curry with vegetables provides plant-based protein and fiber. *This is general wellness information, not medical advice.*',
      'Smoothie bowl with plant-based protein powder, fruits, and nuts for breakfast. *This is general wellness information, not medical advice.*',
    ],
    'general': [
      'Grilled chicken with roasted vegetables and sweet potato for a balanced meal. *This is general wellness information, not medical advice.*',
      'Salmon with quinoa and steamed broccoli provides protein and omega-3s. *This is general wellness information, not medical advice.*',
      'Turkey and vegetable lettuce wraps for a light, protein-rich lunch. *This is general wellness information, not medical advice.*',
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
        if (lowerFood.contains(category)) {
          return _nutritionInsights[category]!;
        }
      }
    }

    // Generic insight if no specific match
    return 'The foods you logged contain various nutrients that can support your wellness goals. *This is general wellness information, not medical advice.*';
  }

  /// Get recipe suggestions based on dietary restrictions
  static List<String> getRecipeSuggestions(List<String> dietaryRestrictions) {
    if (dietaryRestrictions.contains('vegetarian')) {
      return _recipeIdeas['vegetarian']!;
    } else if (dietaryRestrictions.contains('vegan')) {
      return _recipeIdeas['vegan']!;
    } else {
      return _recipeIdeas['general']!;
    }
  }

  /// Get mission for user's primary goal
  static Map<String, dynamic> getMission(List<String> userGoals) {
    final primaryGoal = userGoals.isNotEmpty ? userGoals.first.toLowerCase() : 'health';
    return _missions[primaryGoal] ?? _missions['weight_loss']!;
  }

  /// Get generic safe response when all else fails
  static String getSafeGenericResponse() {
    return '''
I'm here to support your wellness journey! While I don't have specific information for your question right now, I'd be happy to help with general nutrition education, lifestyle tips, and wellness information.

For personalized advice or specific health concerns, I recommend consulting with a healthcare professional who can provide guidance based on your individual needs.

*This information is for general wellness purposes only and is not a substitute for professional medical advice, diagnosis, or treatment.*
''';
  }

  /// Check if content exists for given parameters
  static bool hasContentFor({
    String? contentType,
    List<String>? userGoals,
    List<String>? dietaryRestrictions,
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
      default:
        return true; // Always have generic safe response
    }
  }
} 