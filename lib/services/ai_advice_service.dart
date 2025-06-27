import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_advice.dart';
import '../models/health_profile.dart';
import '../models/meal_log.dart';
import '../models/fasting_session.dart';
import '../services/rag_service.dart';
import '../services/openai_service.dart';
import '../utils/logger.dart';

class AIAdviceService {
  static final AIAdviceService _instance = AIAdviceService._internal();
  factory AIAdviceService() => _instance;
  AIAdviceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RAGService _ragService = RAGService(OpenAIService());

  // Collections
  CollectionReference get _adviceCollection =>
      _firestore.collection('ai_advice');
  CollectionReference get _healthProfilesCollection =>
      _firestore.collection('health_profiles');
  CollectionReference get _behaviorPatternsCollection =>
      _firestore.collection('behavior_patterns');
  CollectionReference get _adviceFeedbackCollection =>
      _firestore.collection('advice_feedback');

  String? get currentUserId => _auth.currentUser?.uid;

  // Task 6.1: Comprehensive User Health Profile Tracking System
  Future<HealthProfile?> getHealthProfile(String userId) async {
    try {
      final doc = await _healthProfilesCollection.doc(userId).get();
      if (doc.exists) {
        return HealthProfile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.d('Error getting health profile: $e');
      return null;
    }
  }

  Future<void> updateHealthProfile(HealthProfile profile) async {
    try {
      await _healthProfilesCollection
          .doc(profile.userId)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      Logger.d('Error updating health profile: $e');
      rethrow;
    }
  }

  Future<HealthProfile> createInitialHealthProfile(
    String userId, {
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    List<HealthGoalType>? primaryGoals,
    ActivityLevel? activityLevel,
  }) async {
    final profile = HealthProfile(
      userId: userId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      primaryGoals: primaryGoals ?? [],
      activityLevel: activityLevel ?? ActivityLevel.moderatelyActive,
    );

    await updateHealthProfile(profile);
    return profile;
  }

  // Task 6.2: Behavior Pattern Analysis
  Future<Map<String, dynamic>> analyzeBehaviorPatterns(String userId) async {
    try {
      // Analyze meal patterns
      final mealPatterns = await _analyzeMealPatterns(userId);

      // Analyze fasting patterns
      final fastingPatterns = await _analyzeFastingPatterns(userId);

      // Analyze app usage patterns
      final appUsagePatterns = await _analyzeAppUsagePatterns(userId);

      // Analyze exercise patterns (from health profile updates)
      final exercisePatterns = await _analyzeExercisePatterns(userId);

      // Analyze sleep patterns (if available)
      final sleepPatterns = await _analyzeSleepPatterns(userId);

      final behaviorAnalysis = {
        'userId': userId,
        'analyzedAt': DateTime.now().toIso8601String(),
        'mealPatterns': mealPatterns,
        'fastingPatterns': fastingPatterns,
        'appUsagePatterns': appUsagePatterns,
        'exercisePatterns': exercisePatterns,
        'sleepPatterns': sleepPatterns,
        'overallHealthScore': _calculateOverallHealthScore(
          mealPatterns,
          fastingPatterns,
          exercisePatterns,
          sleepPatterns,
        ),
      };

      // Store behavior analysis
      await _behaviorPatternsCollection
          .doc(userId)
          .set(behaviorAnalysis, SetOptions(merge: true));

      // Update health profile with behavior patterns
      final profile = await getHealthProfile(userId);
      if (profile != null) {
        final updatedProfile = profile.copyWith(
          mealPatterns: mealPatterns,
          fastingPatterns: fastingPatterns,
          exercisePatterns: exercisePatterns,
          sleepPatterns: sleepPatterns,
          appUsagePatterns: appUsagePatterns,
        );
        await updateHealthProfile(updatedProfile);
      }

      return behaviorAnalysis;
    } catch (e) {
      Logger.d('Error analyzing behavior patterns: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _analyzeMealPatterns(String userId) async {
    try {
      final mealLogs = await _firestore
          .collection('meal_logs')
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(30)
          .get();

      if (mealLogs.docs.isEmpty) {
        return {
          'average_calories': 0.0,
          'meal_frequency': 0.0,
          'most_common_meal_types': <String>[],
          'nutrition_balance': <String, double>{},
          'eating_schedule': <String, double>{},
        };
      }

      double totalCalories = 0;
      Map<String, int> mealTypeCount = {};
      Map<String, double> nutritionTotals = {
        'protein': 0,
        'carbs': 0,
        'fat': 0,
      };
      Map<int, int> hourlyMeals = {};

      for (var doc in mealLogs.docs) {
        final mealLog = MealLog.fromFirestore(doc);
        final calories = mealLog.recognitionResult.totalNutrition.calories;
        totalCalories += calories;

        // Analyze meal timing
        final hour = mealLog.timestamp.hour;
        hourlyMeals[hour] = (hourlyMeals[hour] ?? 0) + 1;

        // Analyze nutrition
        final nutrition = mealLog.recognitionResult.totalNutrition;
        nutritionTotals['protein'] =
            (nutritionTotals['protein'] ?? 0) + nutrition.protein;
        nutritionTotals['carbs'] =
            (nutritionTotals['carbs'] ?? 0) + nutrition.carbs;
        nutritionTotals['fat'] = (nutritionTotals['fat'] ?? 0) + nutrition.fat;

        // Categorize meal by time
        String mealType;
        if (hour >= 5 && hour < 11) {
          mealType = 'breakfast';
        } else if (hour >= 11 && hour < 16) {
          mealType = 'lunch';
        } else if (hour >= 16 && hour < 22) {
          mealType = 'dinner';
        } else {
          mealType = 'snack';
        }
        mealTypeCount[mealType] = (mealTypeCount[mealType] ?? 0) + 1;
      }

      final avgCalories = totalCalories / mealLogs.docs.length;
      final mealFrequency = mealLogs.docs.length / 7.0; // Per week

      // Get most common meal types
      final sortedMealTypes = mealTypeCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final mostCommonMealTypes = sortedMealTypes
          .take(3)
          .map((e) => e.key)
          .toList();

      return {
        'average_calories': avgCalories,
        'meal_frequency': mealFrequency,
        'most_common_meal_types': mostCommonMealTypes,
        'nutrition_balance': nutritionTotals,
        'eating_schedule': hourlyMeals.map(
          (k, v) => MapEntry(k.toString(), v.toDouble()),
        ),
      };
    } catch (e) {
      Logger.d('Error analyzing meal patterns: $e');
      return {
        'average_calories': 0.0,
        'meal_frequency': 0.0,
        'most_common_meal_types': <String>[],
        'nutrition_balance': <String, double>{},
        'eating_schedule': <String, double>{},
      };
    }
  }

  Future<Map<String, dynamic>> _analyzeFastingPatterns(String userId) async {
    try {
      final fastingSessions = await _firestore
          .collection('fasting_sessions')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(30)
          .get();

      if (fastingSessions.docs.isEmpty) {
        return {
          'average_duration': 0.0,
          'completion_rate': 0.0,
          'preferred_times': <String>[],
          'success_factors': <String>[],
        };
      }

      double totalDuration = 0;
      int completedSessions = 0;
      Map<int, int> startTimeCount = {};

      for (var doc in fastingSessions.docs) {
        final session = FastingSession.fromJson(doc.data());

        totalDuration +=
            (session.actualDuration?.inHours ??
            session.plannedDuration.inHours);

        if (session.state == FastingState.completed) {
          completedSessions++;
        }

        // Analyze start times
        DateTime? startTime =
            session.actualStartTime ?? session.plannedStartTime;
        if (startTime != null) {
          final hour = startTime.hour;
          startTimeCount[hour] = (startTimeCount[hour] ?? 0) + 1;
        }
      }

      final avgDuration = totalDuration / fastingSessions.docs.length;
      final completionRate = completedSessions / fastingSessions.docs.length;

      // Get preferred start times
      final sortedStartTimes = startTimeCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final preferredTimes = sortedStartTimes
          .take(3)
          .map((e) => '${e.key}:00')
          .toList();

      return {
        'average_duration': avgDuration,
        'completion_rate': completionRate,
        'preferred_times': preferredTimes,
        'success_factors': <String>['consistency', 'preparation', 'motivation'],
      };
    } catch (e) {
      Logger.d('Error analyzing fasting patterns: $e');
      return {
        'average_duration': 0.0,
        'completion_rate': 0.0,
        'preferred_times': <String>[],
        'success_factors': <String>[],
      };
    }
  }

  Future<Map<String, dynamic>> _analyzeAppUsagePatterns(String userId) async {
    // This would integrate with app analytics or user activity tracking
    // For now, we'll return basic patterns
    return {
      'dailyActiveHours': [],
      'featureUsage': {},
      'sessionDuration': 0.0,
      'engagementScore': 0.0,
      'lastAnalyzed': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _analyzeExercisePatterns(String userId) async {
    // This would integrate with health profile exercise tracking
    return {
      'weeklyFrequency': 0.0,
      'preferredTypes': [],
      'averageDuration': 0.0,
      'intensityLevels': {},
      'lastAnalyzed': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _analyzeSleepPatterns(String userId) async {
    // This would integrate with sleep tracking data
    return {
      'averageSleepDuration': 0.0,
      'bedtime': 0.0,
      'wakeTime': 0.0,
      'sleepQuality': 0.0,
      'lastAnalyzed': DateTime.now().toIso8601String(),
    };
  }

  double _calculateOverallHealthScore(
    Map<String, dynamic> mealPatterns,
    Map<String, dynamic> fastingPatterns,
    Map<String, dynamic> exercisePatterns,
    Map<String, dynamic> sleepPatterns,
  ) {
    double score = 0.0;
    int factors = 0;

    // Meal consistency
    if (mealPatterns['consistency'] != null) {
      score += mealPatterns['consistency'] * 0.25;
      factors++;
    }

    // Fasting success rate
    if (fastingPatterns['completion_rate'] != null) {
      score += fastingPatterns['completion_rate'] * 0.25;
      factors++;
    }

    // Exercise frequency (placeholder)
    if (exercisePatterns['weeklyFrequency'] != null) {
      score += min(1.0, exercisePatterns['weeklyFrequency'] / 5.0) * 0.25;
      factors++;
    }

    // Sleep quality (placeholder)
    if (sleepPatterns['sleepQuality'] != null) {
      score += sleepPatterns['sleepQuality'] * 0.25;
      factors++;
    }

    return factors > 0 ? score / factors : 0.0;
  }

  // Task 6.3: RAG-Powered Advice Generation
  Future<AIAdvice> generatePersonalizedAdvice(
    String userId, {
    AdviceType? type,
    AdviceCategory? category,
    String? userQuery,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Get user health profile and behavior patterns
      final healthProfile = await getHealthProfile(userId);
      final behaviorAnalysis = await _getBehaviorAnalysis(userId);

      // Build context for RAG query
      final ragContext = _buildRAGContext(
        healthProfile,
        behaviorAnalysis,
        context,
      );

      // Generate advice using RAG
      final adviceContent = await _generateAdviceWithRAG(
        userQuery ?? _generateDefaultQuery(type, healthProfile),
        ragContext,
        type ?? AdviceType.custom,
      );

      // Save advice to Firestore first to get the document ID
      final docRef = await _adviceCollection.add({
        'userId': userId,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'title': adviceContent['title'] ?? 'Health Advice',
        'content': adviceContent['content'] ?? 'No advice generated',
        'summary': adviceContent['summary'],
        'type': (type ?? AdviceType.custom).name,
        'category': (category ?? AdviceCategory.tip).name,
        'priority': _determinePriority(adviceContent, healthProfile).name,
        'context': ragContext,
        'tags': adviceContent['tags'] ?? [],
        'personalizationFactors': _extractPersonalizationFactors(
          healthProfile,
          behaviorAnalysis,
        ),
        'trigger':
            (userQuery != null
                    ? AdviceTrigger.userRequested
                    : AdviceTrigger.behavioral)
                .name,
        'sourceQuery': userQuery,
        'ragSources': adviceContent['sources'] ?? [],
        'confidenceScore': adviceContent['confidence']?.toDouble(),
        'generationMetadata': {
          'model': 'gpt-4',
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0',
        },
        'suggestedActions': adviceContent['actions'] ?? [],
        'deliveredAt': Timestamp.fromDate(DateTime.now()),
        'isRead': false,
        'isDismissed': false,
        'isBookmarked': false,
        'isProactive': userQuery == null,
        'interactionData': {},
        'actionTracking': {},
        'viewCount': 0,
        'shareCount': 0,
        'outcomeData': {},
      });

      // Create advice object with the correct ID
      final savedAdvice = AIAdvice(
        id: docRef.id,
        userId: userId,
        createdAt: DateTime.now(),
        title: adviceContent['title'] ?? 'Health Advice',
        content: adviceContent['content'] ?? 'No advice generated',
        summary: adviceContent['summary'],
        type: type ?? AdviceType.custom,
        category: category ?? AdviceCategory.tip,
        priority: _determinePriority(adviceContent, healthProfile),
        context: ragContext,
        tags: adviceContent['tags'] ?? [],
        personalizationFactors: _extractPersonalizationFactors(
          healthProfile,
          behaviorAnalysis,
        ),
        trigger: userQuery != null
            ? AdviceTrigger.userRequested
            : AdviceTrigger.behavioral,
        sourceQuery: userQuery,
        ragSources: adviceContent['sources'] ?? [],
        confidenceScore: adviceContent['confidence']?.toDouble(),
        generationMetadata: {
          'model': 'gpt-4',
          'timestamp': DateTime.now().toIso8601String(),
          'version': '1.0',
        },
        suggestedActions: adviceContent['actions'] ?? [],
        deliveredAt: DateTime.now(),
      );

      return savedAdvice;
    } catch (e) {
      Logger.d('Error generating personalized advice: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _getBehaviorAnalysis(String userId) async {
    try {
      final doc = await _behaviorPatternsCollection.doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      Logger.d('Error getting behavior analysis: $e');
      return {};
    }
  }

  Map<String, dynamic> _buildRAGContext(
    HealthProfile? profile,
    Map<String, dynamic> behaviorAnalysis,
    Map<String, dynamic>? additionalContext,
  ) {
    final context = <String, dynamic>{};

    if (profile != null) {
      context['healthProfile'] = {
        'age': profile.age,
        'gender': profile.gender,
        'activityLevel': profile.activityLevel.name,
        'primaryGoals': profile.primaryGoals.map((g) => g.name).toList(),
        'dietaryPreferences': profile.dietaryPreferences
            .map((d) => d.name)
            .toList(),
        'healthConditions': profile.healthConditions
            .map((h) => h.name)
            .toList(),
      };
    }

    context['behaviorPatterns'] = behaviorAnalysis;

    if (additionalContext != null) {
      context.addAll(additionalContext);
    }

    return context;
  }

  Future<Map<String, dynamic>> _generateAdviceWithRAG(
    String query,
    Map<String, dynamic> context,
    AdviceType type,
  ) async {
    try {
      // Use RAG service to get relevant health knowledge
      final ragResults = await _ragService.performSemanticSearch(
        query: query,
        maxResults: 5,
      );

      // Build prompt for OpenAI
      final prompt = _buildAdvicePrompt(
        query,
        context,
        ragResults.map((r) => r.document.content).toList(),
        type,
      );

      // Generate advice using OpenAI
      final response = await OpenAIService().getChatCompletion(prompt);

      // Parse response (assuming structured JSON response)
      if (response != null && response.isNotEmpty) {
        return _parseAdviceResponse(response, type, query, context);
      } else {
        throw Exception('Empty response from OpenAI');
      }
    } catch (e) {
      Logger.d('Error generating advice with RAG: $e');
      return {
        'title': 'Health Tip',
        'content':
            'Stay hydrated and maintain a balanced diet for optimal health.',
        'summary': 'Basic health advice',
        'actions': ['Drink 8 glasses of water daily'],
        'confidence': 0.5,
      };
    }
  }

  String _buildAdvicePrompt(
    String query,
    Map<String, dynamic> context,
    List<String> ragResults,
    AdviceType type,
  ) {
    return '''
Generate personalized health advice based on the following:

User Query: $query
Advice Type: ${type.name}

User Context:
${_formatContextForPrompt(context)}

Relevant Health Knowledge:
${_formatRAGResultsForPrompt(ragResults)}

Please provide advice in the following JSON format:
{
  "title": "Brief, engaging title",
  "content": "Detailed, personalized advice (2-3 paragraphs)",
  "summary": "One sentence summary for notifications",
  "actions": ["Specific actionable step 1", "Specific actionable step 2"],
  "tags": ["relevant", "tags"],
  "confidence": 0.8
}

Make the advice:
1. Personalized to the user's profile and patterns
2. Actionable with specific steps
3. Evidence-based using the provided knowledge
4. Motivating and supportive in tone
5. Appropriate for their health goals and conditions
''';
  }

  String _formatContextForPrompt(Map<String, dynamic> context) {
    final buffer = StringBuffer();
    context.forEach((key, value) {
      buffer.writeln('$key: $value');
    });
    return buffer.toString();
  }

  String _formatRAGResultsForPrompt(List<String> ragResults) {
    if (ragResults.isEmpty) return 'No specific knowledge retrieved.';

    final buffer = StringBuffer();
    for (final result in ragResults) {
      buffer.writeln('- $result');
    }
    return buffer.toString();
  }

  Map<String, dynamic> _parseAdviceResponse(
    String response,
    AdviceType type,
    String query,
    Map<String, dynamic> context,
  ) {
    try {
      // This would parse the JSON response from OpenAI
      // For now, return a structured response
      return {
        'title': 'Personalized Health Advice',
        'content': response,
        'summary': 'AI-generated health advice based on your profile',
        'actions': ['Follow the advice provided'],
        'sources': context['sources'] ?? [],
        'confidence': 0.8,
      };
    } catch (e) {
      Logger.d('Error parsing advice response: $e');
      return {'title': 'Health Advice', 'content': response, 'confidence': 0.5};
    }
  }

  String _generateDefaultQuery(AdviceType? type, HealthProfile? profile) {
    switch (type) {
      case AdviceType.nutrition:
        return 'What nutrition advice do you have for my current diet and goals?';
      case AdviceType.exercise:
        return 'What exercise recommendations do you have based on my activity level?';
      case AdviceType.fasting:
        return 'How can I improve my fasting routine and success rate?';
      case AdviceType.sleep:
        return 'What sleep optimization advice do you have for me?';
      case AdviceType.motivation:
        return 'How can I stay motivated to achieve my health goals?';
      default:
        return 'What general health advice do you have for me today?';
    }
  }

  AdvicePriority _determinePriority(
    Map<String, dynamic> adviceContent,
    HealthProfile? profile,
  ) {
    // Logic to determine priority based on content and user profile
    if (adviceContent['urgent'] == true) return AdvicePriority.urgent;
    if (adviceContent['important'] == true) return AdvicePriority.high;
    return AdvicePriority.medium;
  }

  Map<String, dynamic> _extractPersonalizationFactors(
    HealthProfile? profile,
    Map<String, dynamic> behaviorAnalysis,
  ) {
    final factors = <String, dynamic>{};

    if (profile != null) {
      factors['hasHealthGoals'] = profile.primaryGoals.isNotEmpty;
      factors['hasHealthConditions'] = profile.healthConditions.isNotEmpty;
      factors['activityLevel'] = profile.activityLevel.name;
    }

    if (behaviorAnalysis.isNotEmpty) {
      factors['hasMealPatterns'] = behaviorAnalysis['mealPatterns'] != null;
      factors['hasFastingPatterns'] =
          behaviorAnalysis['fastingPatterns'] != null;
    }

    return factors;
  }

  // Task 6.4: Feedback Mechanism
  Future<void> recordAdviceFeedback(
    String adviceId,
    int rating, {
    String? comment,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) return;

      // Update advice document
      await _adviceCollection.doc(adviceId).update({
        'userRating': rating,
        'ratedAt': Timestamp.now(),
        'interactedAt': Timestamp.now(),
      });

      // Store detailed feedback
      await _adviceFeedbackCollection.add({
        'userId': userId,
        'adviceId': adviceId,
        'rating': rating,
        'comment': comment,
        'timestamp': Timestamp.now(),
      });

      // Update user health profile with feedback
      await _updateUserFeedbackProfile(userId, adviceId, rating);
    } catch (e) {
      Logger.d('Error recording advice feedback: $e');
      rethrow;
    }
  }

  Future<void> _updateUserFeedbackProfile(
    String userId,
    String adviceId,
    int rating,
  ) async {
    try {
      final profile = await getHealthProfile(userId);
      if (profile != null) {
        final updatedFeedback = Map<String, int>.from(profile.adviceFeedback);
        updatedFeedback[adviceId] = rating;

        final updatedProfile = profile.copyWith(
          adviceFeedback: updatedFeedback,
        );

        await updateHealthProfile(updatedProfile);
      }
    } catch (e) {
      Logger.d('Error updating user feedback profile: $e');
    }
  }

  // Task 6.5: Adaptive Learning System
  Future<void> improveRecommendations(String userId) async {
    try {
      // Analyze user feedback patterns
      final feedbackAnalysis = await _analyzeFeedbackPatterns(userId);

      // Update personalization insights
      await _updatePersonalizationInsights(userId, feedbackAnalysis);

      // Adjust advice generation parameters
      await _adjustAdviceParameters(userId, feedbackAnalysis);
    } catch (e) {
      Logger.d('Error improving recommendations: $e');
    }
  }

  Future<Map<String, dynamic>> _analyzeFeedbackPatterns(String userId) async {
    try {
      final feedbackQuery = await _adviceFeedbackCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final feedbacks = feedbackQuery.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      // Analyze rating patterns
      final ratings = feedbacks.map((f) => f['rating'] as int).toList();
      final avgRating = ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length;

      // Analyze advice type preferences
      final typePreferences = <String, double>{};
      final categoryPreferences = <String, double>{};

      // This would analyze which types/categories get better ratings

      return {
        'averageRating': avgRating,
        'totalFeedbacks': feedbacks.length,
        'typePreferences': typePreferences,
        'categoryPreferences': categoryPreferences,
        'improvementTrend': _calculateImprovementTrend(ratings),
      };
    } catch (e) {
      Logger.d('Error analyzing feedback patterns: $e');
      return {};
    }
  }

  double _calculateImprovementTrend(List<int> ratings) {
    if (ratings.length < 10) return 0.0;

    final recent = ratings.take(20).toList();
    final older = ratings.skip(20).take(20).toList();

    if (older.isEmpty) return 0.0;

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;

    return recentAvg - olderAvg;
  }

  Future<void> _updatePersonalizationInsights(
    String userId,
    Map<String, dynamic> feedbackAnalysis,
  ) async {
    try {
      final profile = await getHealthProfile(userId);
      if (profile != null) {
        final insights = Map<String, dynamic>.from(
          profile.personalizedInsights,
        );
        insights['feedbackAnalysis'] = feedbackAnalysis;
        insights['lastUpdated'] = DateTime.now().toIso8601String();

        final updatedProfile = profile.copyWith(personalizedInsights: insights);

        await updateHealthProfile(updatedProfile);
      }
    } catch (e) {
      Logger.d('Error updating personalization insights: $e');
    }
  }

  Future<void> _adjustAdviceParameters(
    String userId,
    Map<String, dynamic> feedbackAnalysis,
  ) async {
    // This would adjust the AI advice generation parameters based on feedback
    // For example, prefer certain advice types, adjust tone, etc.
  }

  // Task 6.6: Conversational AI Advice Interface
  Future<AIAdvice> handleConversationalQuery(
    String userId,
    String query,
  ) async {
    try {
      return await generatePersonalizedAdvice(
        userId,
        userQuery: query,
        type: _inferAdviceTypeFromQuery(query),
        category: AdviceCategory.recommendation,
      );
    } catch (e) {
      Logger.d('Error handling conversational query: $e');
      rethrow;
    }
  }

  AdviceType _inferAdviceTypeFromQuery(String query) {
    final lowerQuery = query.toLowerCase();

    if (lowerQuery.contains('food') ||
        lowerQuery.contains('eat') ||
        lowerQuery.contains('nutrition')) {
      return AdviceType.nutrition;
    } else if (lowerQuery.contains('exercise') ||
        lowerQuery.contains('workout') ||
        lowerQuery.contains('fitness')) {
      return AdviceType.exercise;
    } else if (lowerQuery.contains('fast') || lowerQuery.contains('fasting')) {
      return AdviceType.fasting;
    } else if (lowerQuery.contains('sleep') || lowerQuery.contains('rest')) {
      return AdviceType.sleep;
    } else if (lowerQuery.contains('motivation') ||
        lowerQuery.contains('motivated')) {
      return AdviceType.motivation;
    }

    return AdviceType.custom;
  }

  // Task 6.7: Proactive Advice Triggers
  Future<void> checkProactiveAdviceTriggers(String userId) async {
    try {
      final profile = await getHealthProfile(userId);
      if (profile == null || !profile.receiveAdvice) return;

      final behaviorAnalysis = await _getBehaviorAnalysis(userId);
      final triggers = await _identifyAdviceTriggers(
        userId,
        profile,
        behaviorAnalysis,
      );

      for (final trigger in triggers) {
        await _generateProactiveAdvice(userId, trigger);
      }
    } catch (e) {
      Logger.d('Error checking proactive advice triggers: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _identifyAdviceTriggers(
    String userId,
    HealthProfile profile,
    Map<String, dynamic> behaviorAnalysis,
  ) async {
    final triggers = <Map<String, dynamic>>[];

    // Check for inactivity triggers
    if (behaviorAnalysis['mealPatterns']?['daysActive'] != null) {
      final daysSinceLastMeal = DateTime.now()
          .difference(
            DateTime.parse(behaviorAnalysis['mealPatterns']['lastAnalyzed']),
          )
          .inDays;

      if (daysSinceLastMeal > 3) {
        triggers.add({
          'type': 'inactivity',
          'category': 'nutrition',
          'priority': 'medium',
          'context': 'No meal logging for $daysSinceLastMeal days',
        });
      }
    }

    // Check for goal-related triggers
    if (profile.primaryGoals.contains(HealthGoalType.weightLoss)) {
      // Check if user needs encouragement or tips
      triggers.add({
        'type': 'goal_support',
        'category': 'motivation',
        'priority': 'low',
        'context': 'Weight loss goal support',
      });
    }

    // Check for health condition triggers
    if (profile.healthConditions.isNotEmpty) {
      triggers.add({
        'type': 'health_condition',
        'category': 'medical_reminder',
        'priority': 'high',
        'context': 'Health condition management',
      });
    }

    return triggers;
  }

  Future<void> _generateProactiveAdvice(
    String userId,
    Map<String, dynamic> trigger,
  ) async {
    try {
      final adviceType = _mapTriggerToAdviceType(trigger['category']);
      final category = _mapTriggerToAdviceCategory(trigger['type']);

      await generatePersonalizedAdvice(
        userId,
        type: adviceType,
        category: category,
        context: {'trigger': trigger, 'proactive': true},
      );
    } catch (e) {
      Logger.d('Error generating proactive advice: $e');
    }
  }

  AdviceType _mapTriggerToAdviceType(String category) {
    switch (category) {
      case 'nutrition':
        return AdviceType.nutrition;
      case 'exercise':
        return AdviceType.exercise;
      case 'motivation':
        return AdviceType.motivation;
      case 'medical_reminder':
        return AdviceType.medicalReminder;
      default:
        return AdviceType.custom;
    }
  }

  AdviceCategory _mapTriggerToAdviceCategory(String type) {
    switch (type) {
      case 'inactivity':
        return AdviceCategory.reminder;
      case 'goal_support':
        return AdviceCategory.encouragement;
      case 'health_condition':
        return AdviceCategory.warning;
      default:
        return AdviceCategory.tip;
    }
  }

  // Utility methods
  Stream<List<AIAdvice>> getAdviceStream(String userId) {
    return _adviceCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AIAdvice.fromFirestore(doc)).toList(),
        );
  }

  Future<void> markAdviceAsRead(String adviceId) async {
    try {
      await _adviceCollection.doc(adviceId).update({
        'isRead': true,
        'interactedAt': Timestamp.now(),
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      Logger.d('Error marking advice as read: $e');
    }
  }

  Future<void> bookmarkAdvice(String adviceId, bool bookmarked) async {
    try {
      await _adviceCollection.doc(adviceId).update({
        'isBookmarked': bookmarked,
        'interactedAt': Timestamp.now(),
      });
    } catch (e) {
      Logger.d('Error bookmarking advice: $e');
    }
  }

  Future<void> dismissAdvice(String adviceId) async {
    try {
      await _adviceCollection.doc(adviceId).update({
        'isDismissed': true,
        'interactedAt': Timestamp.now(),
      });
    } catch (e) {
      Logger.d('Error dismissing advice: $e');
    }
  }
}
