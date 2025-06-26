import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_advice.dart';
import '../models/health_profile.dart';
import '../models/meal_log.dart';
import '../models/fasting_session.dart';
import '../services/rag_service.dart';
import '../services/openai_service.dart';

class AIAdviceService {
  static final AIAdviceService _instance = AIAdviceService._internal();
  factory AIAdviceService() => _instance;
  AIAdviceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RAGService _ragService = RAGService();
  final OpenAIService _openAIService = OpenAIService();

  // Collections
  CollectionReference get _adviceCollection => _firestore.collection('ai_advice');
  CollectionReference get _healthProfilesCollection => _firestore.collection('health_profiles');
  CollectionReference get _behaviorPatternsCollection => _firestore.collection('behavior_patterns');
  CollectionReference get _adviceFeedbackCollection => _firestore.collection('advice_feedback');

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
      debugPrint('Error getting health profile: $e');
      return null;
    }
  }

  Future<void> updateHealthProfile(HealthProfile profile) async {
    try {
      await _healthProfilesCollection.doc(profile.userId).set(
        profile.toFirestore(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error updating health profile: $e');
      rethrow;
    }
  }

  Future<HealthProfile> createInitialHealthProfile(String userId, {
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
      await _behaviorPatternsCollection.doc(userId).set(
        behaviorAnalysis,
        SetOptions(merge: true),
      );

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
      debugPrint('Error analyzing behavior patterns: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _analyzeMealPatterns(String userId) async {
    try {
      final mealLogsQuery = await _firestore
          .collection('meal_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      if (mealLogsQuery.docs.isEmpty) return {};

      final mealLogs = mealLogsQuery.docs.map((doc) => MealLog.fromFirestore(doc)).toList();

      // Analyze timing patterns
      final mealTimes = mealLogs.map((log) => log.timestamp.hour + (log.timestamp.minute / 60.0)).toList();
      final avgMealTime = mealTimes.reduce((a, b) => a + b) / mealTimes.length;

      // Analyze frequency
      final daysWithMeals = mealLogs.map((log) => DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day)).toSet().length;
      final avgMealsPerDay = mealLogs.length / max(daysWithMeals, 1);

      // Analyze portion sizes and calories
      final caloriesData = mealLogs.where((log) => log.estimatedCalories != null).map((log) => log.estimatedCalories!).toList();
      final avgCalories = caloriesData.isEmpty ? 0.0 : caloriesData.reduce((a, b) => a + b) / caloriesData.length;

      // Analyze meal types and nutrition
      final mealTypes = <String, int>{};
      final nutritionTrends = <String, List<double>>{
        'calories': [],
        'protein': [],
        'carbs': [],
        'fat': [],
      };

      for (final log in mealLogs) {
        // Count meal types
        if (log.mealType != null) {
          mealTypes[log.mealType!] = (mealTypes[log.mealType!] ?? 0) + 1;
        }

        // Track nutrition trends
        if (log.estimatedCalories != null) nutritionTrends['calories']!.add(log.estimatedCalories!);
        if (log.nutritionAnalysis != null) {
          final nutrition = log.nutritionAnalysis!;
          if (nutrition['protein'] != null) nutritionTrends['protein']!.add(nutrition['protein'].toDouble());
          if (nutrition['carbs'] != null) nutritionTrends['carbs']!.add(nutrition['carbs'].toDouble());
          if (nutrition['fat'] != null) nutritionTrends['fat']!.add(nutrition['fat'].toDouble());
        }
      }

      return {
        'averageMealTime': avgMealTime,
        'averageMealsPerDay': avgMealsPerDay,
        'averageCaloriesPerMeal': avgCalories,
        'mealTypeDistribution': mealTypes,
        'nutritionTrends': nutritionTrends,
        'totalMealsLogged': mealLogs.length,
        'daysActive': daysWithMeals,
        'consistency': _calculateConsistencyScore(mealTimes),
        'lastAnalyzed': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error analyzing meal patterns: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> _analyzeFastingPatterns(String userId) async {
    try {
      final fastingQuery = await _firestore
          .collection('fasting_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(50)
          .get();

      if (fastingQuery.docs.isEmpty) return {};

      final fastingSessions = fastingQuery.docs.map((doc) => FastingSession.fromFirestore(doc)).toList();

      // Analyze fasting duration patterns
      final durations = fastingSessions.where((session) => session.duration != null).map((session) => session.duration!.inHours).toList();
      final avgDuration = durations.isEmpty ? 0.0 : durations.reduce((a, b) => a + b) / durations.length;

      // Analyze success rate
      final completedSessions = fastingSessions.where((session) => session.isCompleted).length;
      final successRate = fastingSessions.isEmpty ? 0.0 : completedSessions / fastingSessions.length;

      // Analyze frequency
      final daysWithFasting = fastingSessions.map((session) => DateTime(session.startTime.year, session.startTime.month, session.startTime.day)).toSet().length;
      final avgSessionsPerWeek = (fastingSessions.length / max(daysWithFasting, 1)) * 7;

      // Analyze timing patterns
      final startTimes = fastingSessions.map((session) => session.startTime.hour + (session.startTime.minute / 60.0)).toList();
      final avgStartTime = startTimes.isEmpty ? 0.0 : startTimes.reduce((a, b) => a + b) / startTimes.length;

      return {
        'averageDurationHours': avgDuration,
        'successRate': successRate,
        'averageSessionsPerWeek': avgSessionsPerWeek,
        'averageStartTime': avgStartTime,
        'totalSessions': fastingSessions.length,
        'completedSessions': completedSessions,
        'daysActive': daysWithFasting,
        'consistency': _calculateConsistencyScore(startTimes),
        'lastAnalyzed': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('Error analyzing fasting patterns: $e');
      return {};
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

  double _calculateConsistencyScore(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / values.length;
    final standardDeviation = sqrt(variance);
    
    // Convert to 0-1 score (lower deviation = higher consistency)
    return max(0.0, 1.0 - (standardDeviation / mean));
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
    if (fastingPatterns['successRate'] != null) {
      score += fastingPatterns['successRate'] * 0.25;
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
      final ragContext = _buildRAGContext(healthProfile, behaviorAnalysis, context);

      // Generate advice using RAG
      final adviceContent = await _generateAdviceWithRAG(
        userQuery ?? _generateDefaultQuery(type, healthProfile),
        ragContext,
        type ?? AdviceType.custom,
      );

      // Create advice object
      final advice = AIAdvice(
        id: '', // Will be set by Firestore
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
        personalizationFactors: _extractPersonalizationFactors(healthProfile, behaviorAnalysis),
        trigger: userQuery != null ? AdviceTrigger.userRequested : AdviceTrigger.behavioral,
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

      // Save advice to Firestore
      final docRef = await _adviceCollection.add(advice.toFirestore());
      final savedAdvice = advice.copyWith();

      return savedAdvice;
    } catch (e) {
      debugPrint('Error generating personalized advice: $e');
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
      debugPrint('Error getting behavior analysis: $e');
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
        'bmi': profile.calculateBMI(),
        'activityLevel': profile.activityLevel.name,
        'primaryGoals': profile.primaryGoals.map((g) => g.name).toList(),
        'dietaryPreferences': profile.dietaryPreferences.map((d) => d.name).toList(),
        'healthConditions': profile.healthConditions.map((h) => h.name).toList(),
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
      final ragResults = await _ragService.queryHealthKnowledge(query, context: context);

      // Build prompt for OpenAI
      final prompt = _buildAdvicePrompt(query, context, ragResults, type);

      // Generate advice using OpenAI
      final response = await _openAIService.generateText(prompt);

      // Parse response (assuming structured JSON response)
      return _parseAdviceResponse(response, ragResults);
    } catch (e) {
      debugPrint('Error generating advice with RAG: $e');
      return {
        'title': 'Health Tip',
        'content': 'Stay hydrated and maintain a balanced diet for optimal health.',
        'summary': 'Basic health advice',
        'actions': ['Drink 8 glasses of water daily'],
        'confidence': 0.5,
      };
    }
  }

  String _buildAdvicePrompt(
    String query,
    Map<String, dynamic> context,
    Map<String, dynamic> ragResults,
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

  String _formatRAGResultsForPrompt(Map<String, dynamic> ragResults) {
    if (ragResults.isEmpty) return 'No specific knowledge retrieved.';
    
    final buffer = StringBuffer();
    if (ragResults['results'] != null) {
      for (final result in ragResults['results']) {
        buffer.writeln('- ${result['content']}');
      }
    }
    return buffer.toString();
  }

  Map<String, dynamic> _parseAdviceResponse(String response, Map<String, dynamic> ragResults) {
    try {
      // This would parse the JSON response from OpenAI
      // For now, return a structured response
      return {
        'title': 'Personalized Health Advice',
        'content': response,
        'summary': 'AI-generated health advice based on your profile',
        'actions': ['Follow the advice provided'],
        'sources': ragResults['sources'] ?? [],
        'confidence': 0.8,
      };
    } catch (e) {
      debugPrint('Error parsing advice response: $e');
      return {
        'title': 'Health Advice',
        'content': response,
        'confidence': 0.5,
      };
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

  AdvicePriority _determinePriority(Map<String, dynamic> adviceContent, HealthProfile? profile) {
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
      factors['hasFastingPatterns'] = behaviorAnalysis['fastingPatterns'] != null;
    }
    
    return factors;
  }

  // Task 6.4: Feedback Mechanism
  Future<void> recordAdviceFeedback(String adviceId, int rating, {String? comment}) async {
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
      debugPrint('Error recording advice feedback: $e');
      rethrow;
    }
  }

  Future<void> _updateUserFeedbackProfile(String userId, String adviceId, int rating) async {
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
      debugPrint('Error updating user feedback profile: $e');
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
      debugPrint('Error improving recommendations: $e');
    }
  }

  Future<Map<String, dynamic>> _analyzeFeedbackPatterns(String userId) async {
    try {
      final feedbackQuery = await _adviceFeedbackCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();

      final feedbacks = feedbackQuery.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Analyze rating patterns
      final ratings = feedbacks.map((f) => f['rating'] as int).toList();
      final avgRating = ratings.isEmpty ? 0.0 : ratings.reduce((a, b) => a + b) / ratings.length;
      
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
      debugPrint('Error analyzing feedback patterns: $e');
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

  Future<void> _updatePersonalizationInsights(String userId, Map<String, dynamic> feedbackAnalysis) async {
    try {
      final profile = await getHealthProfile(userId);
      if (profile != null) {
        final insights = Map<String, dynamic>.from(profile.personalizedInsights);
        insights['feedbackAnalysis'] = feedbackAnalysis;
        insights['lastUpdated'] = DateTime.now().toIso8601String();
        
        final updatedProfile = profile.copyWith(
          personalizedInsights: insights,
        );
        
        await updateHealthProfile(updatedProfile);
      }
    } catch (e) {
      debugPrint('Error updating personalization insights: $e');
    }
  }

  Future<void> _adjustAdviceParameters(String userId, Map<String, dynamic> feedbackAnalysis) async {
    // This would adjust the AI advice generation parameters based on feedback
    // For example, prefer certain advice types, adjust tone, etc.
  }

  // Task 6.6: Conversational AI Advice Interface
  Future<AIAdvice> handleConversationalQuery(String userId, String query) async {
    try {
      return await generatePersonalizedAdvice(
        userId,
        userQuery: query,
        type: _inferAdviceTypeFromQuery(query),
        category: AdviceCategory.recommendation,
      );
    } catch (e) {
      debugPrint('Error handling conversational query: $e');
      rethrow;
    }
  }

  AdviceType _inferAdviceTypeFromQuery(String query) {
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('food') || lowerQuery.contains('eat') || lowerQuery.contains('nutrition')) {
      return AdviceType.nutrition;
    } else if (lowerQuery.contains('exercise') || lowerQuery.contains('workout') || lowerQuery.contains('fitness')) {
      return AdviceType.exercise;
    } else if (lowerQuery.contains('fast') || lowerQuery.contains('fasting')) {
      return AdviceType.fasting;
    } else if (lowerQuery.contains('sleep') || lowerQuery.contains('rest')) {
      return AdviceType.sleep;
    } else if (lowerQuery.contains('motivation') || lowerQuery.contains('motivated')) {
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
      final triggers = await _identifyAdviceTriggers(userId, profile, behaviorAnalysis);

      for (final trigger in triggers) {
        await _generateProactiveAdvice(userId, trigger);
      }
    } catch (e) {
      debugPrint('Error checking proactive advice triggers: $e');
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
      final daysSinceLastMeal = DateTime.now().difference(
        DateTime.parse(behaviorAnalysis['mealPatterns']['lastAnalyzed'])
      ).inDays;
      
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

  Future<void> _generateProactiveAdvice(String userId, Map<String, dynamic> trigger) async {
    try {
      final adviceType = _mapTriggerToAdviceType(trigger['category']);
      final category = _mapTriggerToAdviceCategory(trigger['type']);
      
      await generatePersonalizedAdvice(
        userId,
        type: adviceType,
        category: category,
        context: {
          'trigger': trigger,
          'proactive': true,
        },
      );
    } catch (e) {
      debugPrint('Error generating proactive advice: $e');
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
        .map((snapshot) => snapshot.docs
            .map((doc) => AIAdvice.fromFirestore(doc))
            .toList());
  }

  Future<void> markAdviceAsRead(String adviceId) async {
    try {
      await _adviceCollection.doc(adviceId).update({
        'isRead': true,
        'interactedAt': Timestamp.now(),
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error marking advice as read: $e');
    }
  }

  Future<void> bookmarkAdvice(String adviceId, bool bookmarked) async {
    try {
      await _adviceCollection.doc(adviceId).update({
        'isBookmarked': bookmarked,
        'interactedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error bookmarking advice: $e');
    }
  }

  Future<void> dismissAdvice(String adviceId) async {
    try {
      await _adviceCollection.doc(adviceId).update({
        'isDismissed': true,
        'interactedAt': Timestamp.now(),
      });
    } catch (e) {
      debugPrint('Error dismissing advice: $e');
    }
  }
} 