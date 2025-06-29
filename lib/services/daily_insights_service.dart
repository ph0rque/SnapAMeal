/// Daily Insights Service for generating personalized daily health tips
/// Handles scheduled generation and caching of insights for users
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:snapameal/utils/logger.dart';
import 'package:snapameal/data/fallback_content.dart';
import 'package:snapameal/services/rag_service.dart';
import 'package:snapameal/services/ai_preference_service.dart';
import 'package:snapameal/models/ai_advice.dart';
import 'package:snapameal/models/meal_log.dart';

/// Service for managing daily insight generation and retrieval
class DailyInsightsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final RAGService? _ragService = null; // Will be injected when available
  static final AIPreferenceService _preferenceService = AIPreferenceService();

  // Singleton instance
  static final DailyInsightsService _instance = DailyInsightsService._internal();
  factory DailyInsightsService() => _instance;
  DailyInsightsService._internal();

  /// Generate daily insights for all users (called by scheduled task)
  static Future<Map<String, dynamic>> generateDailyInsightsForAllUsers() async {
    try {
      final today = _getTodayString();
      Logger.d('Starting daily insight generation for $today');

      // Get all users with health profiles
      final usersSnapshot = await _firestore
          .collection('users')
          .where('healthProfile', isNotEqualTo: null)
          .get();

      int successCount = 0;
      int errorCount = 0;
      final errors = <String>[];

      // Process users in batches to avoid overwhelming the system
      const batchSize = 10;
      final users = usersSnapshot.docs;

      for (int i = 0; i < users.length; i += batchSize) {
        final batch = users.skip(i).take(batchSize).toList();
        
        final results = await Future.wait(
          batch.map((userDoc) => _generateInsightForUser(userDoc.id, userDoc.data(), today)),
          eagerError: false,
        );

        for (int j = 0; j < results.length; j++) {
          if (results[j]) {
            successCount++;
          } else {
            errorCount++;
            errors.add('Failed to generate insight for user ${batch[j].id}');
          }
        }

        // Small delay between batches
        if (i + batchSize < users.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      Logger.d('Daily insight generation completed. Success: $successCount, Errors: $errorCount');

      return {
        'success': true,
        'date': today,
        'processed': users.length,
        'successful': successCount,
        'errors': errorCount,
        'errorDetails': errors,
      };
    } catch (e) {
      Logger.d('Error in daily insight generation: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Generate insight for a single user
  static Future<bool> _generateInsightForUser(
    String userId,
    Map<String, dynamic> userData,
    String date,
  ) async {
    try {
      // Check if user has daily insights enabled
      final shouldShow = await _preferenceService.shouldShowDailyInsight();
      if (!shouldShow) {
        Logger.d('Daily insights disabled for user $userId');
        return true; // Return true to indicate "success" (user preference honored)
      }

      // Check if insight already exists for today
      final existingInsight = await _firestore
          .collection('daily_insights')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: date)
          .limit(1)
          .get();

      if (existingInsight.docs.isNotEmpty) {
        Logger.d('Insight already exists for user $userId on $date');
        return true;
      }

      // Extract user health profile
      final healthProfile = userData['healthProfile'] as Map<String, dynamic>?;
      if (healthProfile == null) {
        Logger.d('No health profile found for user $userId');
        return false;
      }

      final goals = List<String>.from(healthProfile['goals'] ?? ['health']);
      final dietaryRestrictions = List<String>.from(healthProfile['dietaryRestrictions'] ?? []);

      // Generate insight content
      final insightResult = await _generateInsightContent(goals, dietaryRestrictions);

      // Store in Firestore
      await _firestore.collection('daily_insights').add({
        'userId': userId,
        'date': date,
        'content': insightResult['content'],
        'isGenerated': insightResult['isGenerated'],
        'createdAt': FieldValue.serverTimestamp(),
        'goalType': goals.isNotEmpty ? goals.first : 'health',
        'source': insightResult['source'],
        'expiresAt': _getExpirationTimestamp(),
      });

      Logger.d('Generated insight for user $userId');
      return true;
    } catch (e) {
      Logger.d('Error generating insight for user $userId: $e');
      return false;
    }
  }

  /// Generate insight content using RAG service or fallback
  static Future<Map<String, dynamic>> _generateInsightContent(
    List<String> goals,
    List<String> dietaryRestrictions,
  ) async {
    try {
      // Try RAG service first (when available)
      if (_ragService != null) {
        // TODO: Implement RAG service call
        // For now, use fallback content
      }
    } catch (e) {
      Logger.d('RAG service failed, using fallback: $e');
    }

    // Use fallback content
    final content = FallbackContent.getDailyInsight(goals);
    
    return {
      'content': content,
      'isGenerated': false,
      'source': 'fallback',
    };
  }

  /// Get today's insight for a specific user
  static Future<Map<String, dynamic>?> _getTodaysInsightStatic(String userId) async {
    try {
      final today = _getTodayString();
      
      final snapshot = await _firestore
          .collection('daily_insights')
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return data;
      }

      return null;
    } catch (e) {
      Logger.d('Error fetching today\'s insight for user $userId: $e');
      return null;
    }
  }

  /// Generate insight for user if not exists (on-demand generation)
  static Future<Map<String, dynamic>?> getOrGenerateInsight(String userId) async {
    try {
      // Try to get existing insight first
      final existingInsight = await _getTodaysInsightStatic(userId);
      if (existingInsight != null) {
        return existingInsight;
      }

      // Get user data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        Logger.d('User $userId not found');
        return null;
      }

      final userData = userDoc.data()!;
      final today = _getTodayString();

      // Generate new insight
      final success = await _generateInsightForUser(userId, userData, today);
      if (success) {
        return await _getTodaysInsightStatic(userId);
      }

      return null;
    } catch (e) {
      Logger.d('Error in getOrGenerateInsight for user $userId: $e');
      return null;
    }
  }

  /// Mark insight as dismissed by user
  static Future<bool> _dismissInsightStatic(String userId, String insightId) async {
    try {
      await _firestore
          .collection('daily_insights')
          .doc(insightId)
          .update({
        'dismissedAt': FieldValue.serverTimestamp(),
        'isDismissed': true,
      });

      // Also track dismissal in user preferences
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
        'aiPreferences.dismissedInsights': FieldValue.arrayUnion([insightId]),
      });

      Logger.d('Insight $insightId dismissed by user $userId');
      return true;
    } catch (e) {
      Logger.d('Error dismissing insight: $e');
      return false;
    }
  }

  /// Get insight history for user
  static Future<List<Map<String, dynamic>>> getInsightHistory(
    String userId, {
    int limit = 30,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('daily_insights')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      Logger.d('Error fetching insight history for user $userId: $e');
      return [];
    }
  }

  /// Clean up expired insights (call periodically)
  static Future<int> cleanupExpiredInsights() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      
      final snapshot = await _firestore
          .collection('daily_insights')
          .where('expiresAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      
      Logger.d('Cleaned up ${snapshot.docs.length} expired insights');
      return snapshot.docs.length;
    } catch (e) {
      Logger.d('Error cleaning up expired insights: $e');
      return 0;
    }
  }

  /// Get today's date as string (YYYY-MM-DD)
  static String _getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Get expiration timestamp (24 hours from now)
  static Timestamp _getExpirationTimestamp() {
    return Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24)));
  }

  /// Get insights statistics
  static Future<Map<String, dynamic>> getInsightsStats() async {
    try {
      final today = _getTodayString();
      
      // Get today's insights
      final todaySnapshot = await _firestore
          .collection('daily_insights')
          .where('date', isEqualTo: today)
          .get();

      final totalToday = todaySnapshot.docs.length;
      final generatedToday = todaySnapshot.docs
          .where((doc) {
          final data = doc.data();
          return data['isGenerated'] == true;
        })
          .length;
      final fallbackToday = totalToday - generatedToday;
      final dismissedToday = todaySnapshot.docs
          .where((doc) {
          final data = doc.data();
          return data['isDismissed'] == true;
        })
          .length;

      return {
        'date': today,
        'total': totalToday,
        'generated': generatedToday,
        'fallback': fallbackToday,
        'dismissed': dismissedToday,
        'dismissalRate': totalToday > 0 ? (dismissedToday / totalToday * 100).round() : 0,
      };
    } catch (e) {
      Logger.d('Error fetching insights stats: $e');
      return {
        'date': _getTodayString(),
        'total': 0,
        'generated': 0,
        'fallback': 0,
        'dismissed': 0,
        'dismissalRate': 0,
      };
    }
  }

  // Instance methods that wrap static methods
  Future<AIAdvice?> getTodaysInsight() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    // Check user preferences
    final shouldShow = await _preferenceService.shouldShowDailyInsight();
    if (!shouldShow) return null;
    
    final insightData = await DailyInsightsService._getTodaysInsightStatic(user.uid);
    if (insightData == null) return null;
    
    return AIAdvice(
      id: insightData['id'],
      userId: user.uid,
      title: 'Daily Insight',
      content: insightData['content'],
      type: AdviceType.nutrition,
      category: AdviceCategory.insight,
      trigger: AdviceTrigger.scheduled,
      createdAt: DateTime.now(),
    );
  }

  Future<AIAdvice?> getMealInsight(MealLog mealLog) async {
    try {
      // Check user preferences
      final shouldShow = await _preferenceService.shouldShowMealInsight();
      if (!shouldShow) return null;
      
      // Check if content type is enabled
      final nutritionEnabled = await _preferenceService.isContentTypeEnabled('nutrition');
      if (!nutritionEnabled) return null;
      
      // For now, generate a simple insight based on the meal
      // In the future, this could use RAG service with meal context
      final content = _generateSimpleMealInsight(mealLog);
      
      return AIAdvice(
        id: 'meal_insight_${mealLog.id}_${DateTime.now().millisecondsSinceEpoch}',
        userId: mealLog.userId,
        title: 'Meal Insight',
        content: content,
        type: AdviceType.nutrition,
        category: AdviceCategory.insight,
        trigger: AdviceTrigger.contextual,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      Logger.d('Failed to generate meal insight: $e');
      return null;
    }
  }

  Future<void> dismissInsight(String insightId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    await DailyInsightsService._dismissInsightStatic(user.uid, insightId);
  }

  String _generateSimpleMealInsight(MealLog mealLog) {
    // Simple meal insights based on primary food category and time
    final primaryCategory = mealLog.recognitionResult.primaryFoodCategory.toLowerCase();
    final hour = mealLog.timestamp.hour;
    
    // Time-based insights
    if (hour >= 6 && hour <= 10) {
      return 'Great start to your day! A nutritious breakfast helps maintain steady energy levels throughout the morning.';
    } else if (hour >= 11 && hour <= 14) {
      return 'Mid-day fuel! Remember to include a balance of protein, healthy fats, and complex carbs for sustained afternoon energy.';
    } else if (hour >= 17 && hour <= 21) {
      return 'Perfect dinner timing! This gives your body time to digest before rest.';
    } else if (hour > 21) {
      return 'Late meal noted. Try to eat your last meal 2-3 hours before bedtime for better sleep quality.';
    }
    
    // Category-based insights
    if (primaryCategory.contains('fruit')) {
      return 'Excellent choice! Fruits provide natural sugars, fiber, and essential vitamins for sustained energy.';
    } else if (primaryCategory.contains('vegetable')) {
      return 'Great nutrition! Vegetables are packed with vitamins, minerals, and fiber that support overall health.';
    } else if (primaryCategory.contains('protein')) {
      return 'Smart protein choice! This will help maintain muscle mass and keep you feeling satisfied.';
    }
    
    return 'Every meal is an opportunity to nourish your body. Keep making mindful food choices!';
  }
} 