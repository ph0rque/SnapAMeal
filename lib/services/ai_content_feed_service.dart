import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snapameal/models/ai_content.dart';
import 'package:snapameal/models/health_profile.dart';
import 'package:snapameal/utils/logger.dart';

class AIContentFeedService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final AIContentFeedService _instance = AIContentFeedService._internal();
  factory AIContentFeedService() => _instance;
  AIContentFeedService._internal();

  /// Generate personalized content for user's feed
  Future<List<AIContent>> generatePersonalizedContent({
    required String userId,
    required HealthProfile healthProfile,
    int limit = 5,
  }) async {
    try {
      Logger.d('Generating personalized content for user $userId');

      final content = <AIContent>[];

      // Try to generate content using RAG service
      try {
        final ragContent = await _generateContentWithRAG(userId, healthProfile, limit);
        content.addAll(ragContent);
      } catch (e) {
        Logger.d('RAG content generation failed, using fallback: $e');
        final fallbackContent = _generateFallbackContent(userId, healthProfile, limit);
        content.addAll(fallbackContent);
      }

      // Save generated content to Firestore
      for (final contentItem in content) {
        await _firestore
            .collection('ai_content_feed')
            .doc(contentItem.id)
            .set(contentItem.toFirestore());
      }

      Logger.d('Generated ${content.length} content items for user $userId');
      return content;
    } catch (e) {
      Logger.d('Error generating personalized content: $e');
      return [];
    }
  }

  /// Generate content using RAG service
  Future<List<AIContent>> _generateContentWithRAG(
    String userId,
    HealthProfile healthProfile,
    int limit,
  ) async {
    // For now, use fallback content since RAG integration is complex
    // In a full implementation, this would call RAGService with content generation prompts
    return _generateFallbackContent(userId, healthProfile, limit);
  }

  /// Generate fallback content when RAG service is unavailable
  List<AIContent> _generateFallbackContent(
    String userId,
    HealthProfile healthProfile,
    int limit,
  ) {
    final content = <AIContent>[];
    final goals = healthProfile.primaryGoals.map((g) => g.name).toList();
    final restrictions = <String>[]; // TODO: Add dietary restrictions to HealthProfile model
    final now = DateTime.now();

    // Generate content based on user's goals
    if (goals.contains('weight_loss')) {
      content.add(_createWeightLossContent(userId, now));
    }
    
    if (goals.contains('muscle_gain')) {
      content.add(_createMuscleGainContent(userId, now));
    }

    if (goals.contains('intermittent_fasting')) {
      content.add(_createFastingContent(userId, now));
    }

    // Add general health content
    content.add(_createGeneralHealthContent(userId, now));

    // Add motivational content
    content.add(_createMotivationalContent(userId, now));

    // Filter based on dietary restrictions
    final filteredContent = content.where((item) {
      return restrictions.isEmpty || 
             item.dietaryRestrictions.isEmpty ||
             restrictions.any((restriction) => item.dietaryRestrictions.contains(restriction));
    }).toList();

    // Return limited number of items
    return filteredContent.take(limit).toList();
  }

  AIContent _createWeightLossContent(String userId, DateTime now) {
    return AIContent(
      id: 'ai_content_${userId}_weight_loss_${now.millisecondsSinceEpoch}',
      title: 'Smart Portion Control Tips',
      content: '''Did you know that using smaller plates can help with portion control? Studies show that people eat 20-25% less when using 9-inch plates instead of 12-inch plates.

Here are some simple portion control strategies:
• Use your hand as a guide: palm-sized protein, fist-sized vegetables
• Eat slowly and mindfully - it takes 20 minutes for your brain to register fullness
• Start meals with a glass of water to help with satiety
• Fill half your plate with vegetables before adding other foods

Remember: sustainable weight loss is about creating healthy habits, not restricting yourself!

*This information is for general wellness purposes only and is not a substitute for professional medical advice.*''',
      summary: 'Simple portion control strategies that can help with sustainable weight loss.',
      type: AIContentType.tip,
      priority: AIContentPriority.high,
      tags: ['weight_loss', 'portion_control', 'mindful_eating'],
      targetGoals: ['weight_loss'],
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
      isPersonalized: true,
      targetUserId: userId,
    );
  }

  AIContent _createMuscleGainContent(String userId, DateTime now) {
    return AIContent(
      id: 'ai_content_${userId}_muscle_gain_${now.millisecondsSinceEpoch}',
      title: 'Post-Workout Nutrition Timing',
      content: '''The "anabolic window" - that magical time after your workout when your muscles are primed for growth! Here's what you need to know:

🕐 Timing: Aim to eat within 2 hours post-workout (the 30-minute window is less critical than once thought)

🥩 Protein: 20-40g of high-quality protein to stimulate muscle protein synthesis
• Chicken, fish, eggs, Greek yogurt, protein powder
• Leucine-rich foods are especially effective

🍌 Carbs: 30-60g to replenish glycogen stores
• Fruits, rice, oats, sweet potatoes work great
• Higher intensity workouts need more carbs

💧 Hydration: Don't forget to rehydrate! You lose electrolytes during exercise.

Pro tip: A protein shake with a banana is a convenient post-workout option!

*This information is for general wellness purposes only and is not a substitute for professional medical advice.*''',
      summary: 'Optimize your post-workout nutrition for better muscle building results.',
      type: AIContentType.article,
      priority: AIContentPriority.high,
      tags: ['muscle_gain', 'post_workout', 'protein', 'nutrition_timing'],
      targetGoals: ['muscle_gain'],
      createdAt: now,
      expiresAt: now.add(const Duration(days: 10)),
      isPersonalized: true,
      targetUserId: userId,
    );
  }

  AIContent _createFastingContent(String userId, DateTime now) {
    return AIContent(
      id: 'ai_content_${userId}_fasting_${now.millisecondsSinceEpoch}',
      title: 'Breaking Your Fast: What to Eat First',
      content: '''Breaking your fast properly is just as important as the fast itself! Here's how to transition back to eating:

🥗 Start Small: Begin with easily digestible foods
• Bone broth, herbal tea, or water with lemon
• Small portion of vegetables or fruit
• Avoid large, heavy meals immediately

🍳 First Meal Ideas:
• Scrambled eggs with spinach
• Greek yogurt with berries
• Avocado with a small salad
• Bone broth with vegetables

⚠️ Foods to Avoid Initially:
• Large amounts of refined carbs
• Very fatty or fried foods
• Excessive caffeine
• Large portions of anything

🕐 Timing: Take 30-60 minutes to ease back into eating. Listen to your body!

The goal is to maintain the metabolic benefits of fasting while nourishing your body properly.

*This information is for general wellness purposes only and is not a substitute for professional medical advice.*''',
      summary: 'Learn the best practices for breaking your intermittent fast safely and effectively.',
      type: AIContentType.tip,
      priority: AIContentPriority.medium,
      tags: ['intermittent_fasting', 'breaking_fast', 'meal_timing'],
      targetGoals: ['intermittent_fasting'],
      createdAt: now,
      expiresAt: now.add(const Duration(days: 14)),
      isPersonalized: true,
      targetUserId: userId,
    );
  }

  AIContent _createGeneralHealthContent(String userId, DateTime now) {
    return AIContent(
      id: 'ai_content_${userId}_general_${now.millisecondsSinceEpoch}',
      title: 'The Power of Sleep for Health',
      content: '''Quality sleep is one of the most underrated aspects of health! Here's why it matters and how to improve it:

😴 Why Sleep Matters:
• Muscle recovery and growth hormone release
• Appetite regulation (leptin and ghrelin balance)
• Immune system strengthening
• Mental clarity and mood regulation

🌙 Sleep Optimization Tips:
• Aim for 7-9 hours per night
• Keep a consistent sleep schedule
• Create a cool, dark sleeping environment
• Avoid screens 1 hour before bed
• Try magnesium or chamomile tea for relaxation

📱 Track Your Sleep:
• Notice patterns between sleep and energy levels
• Pay attention to how different foods affect your sleep
• Consider a sleep tracking app or device

Poor sleep can sabotage even the best diet and exercise efforts. Prioritize your rest!

*This information is for general wellness purposes only and is not a substitute for professional medical advice.*''',
      summary: 'Discover how quality sleep impacts your health goals and learn practical tips for better rest.',
      type: AIContentType.article,
      priority: AIContentPriority.medium,
      tags: ['sleep', 'recovery', 'general_health', 'wellness'],
      targetGoals: ['health', 'weight_loss', 'muscle_gain'],
      createdAt: now,
      expiresAt: now.add(const Duration(days: 21)),
      isPersonalized: true,
      targetUserId: userId,
    );
  }

  AIContent _createMotivationalContent(String userId, DateTime now) {
    return AIContent(
      id: 'ai_content_${userId}_motivation_${now.millisecondsSinceEpoch}',
      title: 'Progress Over Perfection',
      content: '''🌟 Remember: Every small step counts!

Your health journey isn't about being perfect - it's about being consistent. Here's what really matters:

✅ Celebrating Small Wins:
• Logged your meals for 3 days in a row? That's progress!
• Chose water over soda? Victory!
• Took the stairs instead of the elevator? You're building habits!

🎯 Focus on Systems, Not Just Goals:
• Instead of "lose 20 pounds," focus on "log meals daily"
• Instead of "never eat sugar," focus on "eat vegetables with every meal"
• Small, sustainable changes compound over time

💪 Be Kind to Yourself:
• Bad days don't erase good days
• Setbacks are part of the process
• Tomorrow is always a fresh start

You're not trying to be perfect - you're trying to be better than yesterday. And that's exactly what you're doing! 🚀

Keep going, you've got this! 💙''',
      summary: 'A gentle reminder that progress matters more than perfection on your health journey.',
      type: AIContentType.motivation,
      priority: AIContentPriority.low,
      tags: ['motivation', 'mindset', 'progress', 'self_compassion'],
      targetGoals: ['health', 'weight_loss', 'muscle_gain'],
      createdAt: now,
      expiresAt: now.add(const Duration(days: 30)),
      isPersonalized: true,
      targetUserId: userId,
    );
  }

  /// Get existing content for user's feed
  Future<List<AIContent>> getContentForUser({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('ai_content_feed')
          .where('targetUserId', isEqualTo: userId)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('expiresAt')
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AIContent.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.d('Error getting content for user: $e');
      return [];
    }
  }

  /// Get general (non-personalized) content
  Future<List<AIContent>> getGeneralContent({
    List<String>? targetGoals,
    int limit = 5,
  }) async {
    try {
      Query query = _firestore
          .collection('ai_content_feed')
          .where('isPersonalized', isEqualTo: false)
          .where('expiresAt', isGreaterThan: Timestamp.fromDate(DateTime.now()));

      if (targetGoals != null && targetGoals.isNotEmpty) {
        query = query.where('targetGoals', arrayContainsAny: targetGoals);
      }

      final snapshot = await query
          .orderBy('expiresAt')
          .orderBy('priority', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => AIContent.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.d('Error getting general content: $e');
      return [];
    }
  }

  /// Clean up expired content
  Future<int> cleanupExpiredContent() async {
    try {
      final cutoffDate = DateTime.now();
      
      final snapshot = await _firestore
          .collection('ai_content_feed')
          .where('expiresAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      Logger.d('Cleaned up ${snapshot.docs.length} expired content items');
      return snapshot.docs.length;
    } catch (e) {
      Logger.d('Error cleaning up expired content: $e');
      return 0;
    }
  }

  /// Check if user should receive new content
  Future<bool> shouldGenerateNewContent(String userId) async {
    try {
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      
      final snapshot = await _firestore
          .collection('ai_content_feed')
          .where('targetUserId', isEqualTo: userId)
          .where('createdAt', isGreaterThan: Timestamp.fromDate(oneDayAgo))
          .limit(1)
          .get();

      // Generate new content if no content was created in the last 24 hours
      return snapshot.docs.isEmpty;
    } catch (e) {
      Logger.d('Error checking if should generate new content: $e');
      return true; // Default to generating content if check fails
    }
  }
} 