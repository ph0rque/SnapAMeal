import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/privacy_settings.dart';
import '../utils/logger.dart';

/// Service for managing AI content preferences
class AIPreferenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user's AI preferences
  Future<AIContentPreferences> getUserAIPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AIContentPreferences(); // Return defaults for anonymous users
      }

      final doc = await _firestore
          .collection('privacy_settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final privacySettings = PrivacySettings.fromFirestore(doc);
        return privacySettings.aiPreferences;
      } else {
        // Create default preferences for new users
        final defaultPreferences = AIContentPreferences();
        await _updateUserAIPreferences(defaultPreferences);
        return defaultPreferences;
      }
    } catch (e) {
      Logger.e('Error getting AI preferences: $e');
      return AIContentPreferences(); // Return defaults on error
    }
  }

  /// Update user's AI preferences
  Future<void> _updateUserAIPreferences(AIContentPreferences preferences) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get existing privacy settings or create new ones
      final doc = await _firestore
          .collection('privacy_settings')
          .doc(user.uid)
          .get();

      late PrivacySettings privacySettings;
      if (doc.exists) {
        privacySettings = PrivacySettings.fromFirestore(doc);
        privacySettings = privacySettings.copyWith(
          aiPreferences: preferences,
          updatedAt: DateTime.now(),
        );
      } else {
        privacySettings = PrivacySettings.defaultSettings(user.uid).copyWith(
          aiPreferences: preferences,
        );
      }

      await _firestore
          .collection('privacy_settings')
          .doc(user.uid)
          .set(privacySettings.toFirestore());

      Logger.i('AI preferences updated successfully');
    } catch (e) {
      Logger.e('Error updating AI preferences: $e');
      rethrow;
    }
  }

  /// Update specific AI preference
  Future<void> updateAIPreference({
    bool? enableAIContent,
    AIContentFrequency? dailyInsightFrequency,
    AIContentFrequency? mealInsightFrequency,
    AIContentFrequency? feedContentFrequency,
    Map<String, bool>? contentTypePreferences,
    bool? usePersonalizedContent,
    bool? allowGoalBasedContent,
    bool? allowDietaryContent,
    bool? allowFitnessContent,
    bool? enableConversationStarters,
    bool? enableFriendMatchingAI,
    bool? allowAIInGroups,
    bool? enableWeeklyReviews,
    bool? enableMonthlyReviews,
    bool? enableGoalTracking,
    bool? reportInappropriateContent,
    List<String>? blockedKeywords,
  }) async {
    try {
      final currentPreferences = await getUserAIPreferences();
      final updatedPreferences = currentPreferences.copyWith(
        enableAIContent: enableAIContent,
        dailyInsightFrequency: dailyInsightFrequency,
        mealInsightFrequency: mealInsightFrequency,
        feedContentFrequency: feedContentFrequency,
        contentTypePreferences: contentTypePreferences,
        usePersonalizedContent: usePersonalizedContent,
        allowGoalBasedContent: allowGoalBasedContent,
        allowDietaryContent: allowDietaryContent,
        allowFitnessContent: allowFitnessContent,
        enableConversationStarters: enableConversationStarters,
        enableFriendMatchingAI: enableFriendMatchingAI,
        allowAIInGroups: allowAIInGroups,
        enableWeeklyReviews: enableWeeklyReviews,
        enableMonthlyReviews: enableMonthlyReviews,
        enableGoalTracking: enableGoalTracking,
        reportInappropriateContent: reportInappropriateContent,
        blockedKeywords: blockedKeywords,
        updatedAt: DateTime.now(),
      );

      await _updateUserAIPreferences(updatedPreferences);
    } catch (e) {
      Logger.e('Error updating specific AI preference: $e');
      rethrow;
    }
  }

  /// Check if user should see daily insight based on preferences
  Future<bool> shouldShowDailyInsight() async {
    try {
      final preferences = await getUserAIPreferences();
      return preferences.shouldShowDailyInsight();
    } catch (e) {
      Logger.e('Error checking daily insight preference: $e');
      return true; // Default to showing content on error
    }
  }

  /// Check if user should see meal insight based on preferences
  Future<bool> shouldShowMealInsight() async {
    try {
      final preferences = await getUserAIPreferences();
      return preferences.shouldShowMealInsight();
    } catch (e) {
      Logger.e('Error checking meal insight preference: $e');
      return true; // Default to showing content on error
    }
  }

  /// Check if user should see feed content based on preferences
  Future<bool> shouldShowFeedContent() async {
    try {
      final preferences = await getUserAIPreferences();
      return preferences.shouldShowFeedContent();
    } catch (e) {
      Logger.e('Error checking feed content preference: $e');
      return true; // Default to showing content on error
    }
  }

  /// Check if specific content type is enabled
  Future<bool> isContentTypeEnabled(String contentType) async {
    try {
      final preferences = await getUserAIPreferences();
      return preferences.isContentTypeEnabled(contentType);
    } catch (e) {
      Logger.e('Error checking content type preference: $e');
      return true; // Default to enabled on error
    }
  }

  /// Check if content type has been dismissed
  Future<bool> isContentTypeDismissed(String contentType) async {
    try {
      final preferences = await getUserAIPreferences();
      return preferences.isContentTypeDismissed(contentType);
    } catch (e) {
      Logger.e('Error checking content type dismissal: $e');
      return false; // Default to not dismissed on error
    }
  }

  /// Dismiss a content type
  Future<void> dismissContentType(String contentType) async {
    try {
      final preferences = await getUserAIPreferences();
      final dismissedTypes = Map<String, bool>.from(preferences.dismissedContentTypes);
      dismissedTypes[contentType] = true;

      final currentPreferences = await getUserAIPreferences();
      final updatedPreferences = currentPreferences.copyWith(
        dismissedContentTypes: dismissedTypes,
        updatedAt: DateTime.now(),
      );
      await _updateUserAIPreferences(updatedPreferences);

      Logger.i('Content type dismissed: $contentType');
    } catch (e) {
      Logger.e('Error dismissing content type: $e');
      rethrow;
    }
  }

  /// Reset dismissed content types
  Future<void> resetDismissedContentTypes() async {
    try {
      final currentPreferences = await getUserAIPreferences();
      final updatedPreferences = currentPreferences.copyWith(
        dismissedContentTypes: {},
        updatedAt: DateTime.now(),
      );
      await _updateUserAIPreferences(updatedPreferences);

      Logger.i('Dismissed content types reset');
    } catch (e) {
      Logger.e('Error resetting dismissed content types: $e');
      rethrow;
    }
  }

  /// Toggle content type preference
  Future<void> toggleContentType(String contentType, bool enabled) async {
    try {
      final preferences = await getUserAIPreferences();
      final contentTypes = Map<String, bool>.from(preferences.contentTypePreferences);
      contentTypes[contentType] = enabled;

      await updateAIPreference(
        contentTypePreferences: contentTypes,
      );

      Logger.i('Content type toggled: $contentType = $enabled');
    } catch (e) {
      Logger.e('Error toggling content type: $e');
      rethrow;
    }
  }

  /// Add blocked keyword
  Future<void> addBlockedKeyword(String keyword) async {
    try {
      final preferences = await getUserAIPreferences();
      final blockedKeywords = List<String>.from(preferences.blockedKeywords);
      
      if (!blockedKeywords.contains(keyword.toLowerCase())) {
        blockedKeywords.add(keyword.toLowerCase());
        
        await updateAIPreference(
          blockedKeywords: blockedKeywords,
        );

        Logger.i('Blocked keyword added: $keyword');
      }
    } catch (e) {
      Logger.e('Error adding blocked keyword: $e');
      rethrow;
    }
  }

  /// Remove blocked keyword
  Future<void> removeBlockedKeyword(String keyword) async {
    try {
      final preferences = await getUserAIPreferences();
      final blockedKeywords = List<String>.from(preferences.blockedKeywords);
      blockedKeywords.remove(keyword.toLowerCase());

      await updateAIPreference(
        blockedKeywords: blockedKeywords,
      );

      Logger.i('Blocked keyword removed: $keyword');
    } catch (e) {
      Logger.e('Error removing blocked keyword: $e');
      rethrow;
    }
  }

  /// Check if content contains blocked keywords
  Future<bool> containsBlockedKeywords(String content) async {
    try {
      final preferences = await getUserAIPreferences();
      final lowerContent = content.toLowerCase();
      
      for (final keyword in preferences.blockedKeywords) {
        if (lowerContent.contains(keyword.toLowerCase())) {
          return true;
        }
      }
      
      return false;
    } catch (e) {
      Logger.e('Error checking blocked keywords: $e');
      return false; // Default to not blocked on error
    }
  }

  /// Get user preferences summary for analytics
  Future<Map<String, dynamic>> getPreferencesSummary() async {
    try {
      final preferences = await getUserAIPreferences();
      return preferences.getPreferencesSummary();
    } catch (e) {
      Logger.e('Error getting preferences summary: $e');
      return {};
    }
  }

  /// Reset all preferences to defaults
  Future<void> resetToDefaults() async {
    try {
      await _updateUserAIPreferences(AIContentPreferences());
      Logger.i('AI preferences reset to defaults');
    } catch (e) {
      Logger.e('Error resetting preferences to defaults: $e');
      rethrow;
    }
  }

  /// Check if AI features are globally enabled
  Future<bool> areAIFeaturesEnabled() async {
    try {
      final preferences = await getUserAIPreferences();
      return preferences.enableAIContent;
    } catch (e) {
      Logger.e('Error checking AI features enabled: $e');
      return true; // Default to enabled on error
    }
  }

  /// Check if personalization is enabled
  Future<bool> isPersonalizationEnabled() async {
    try {
      final preferences = await getUserAIPreferences();
      return preferences.enableAIContent && preferences.usePersonalizedContent;
    } catch (e) {
      Logger.e('Error checking personalization enabled: $e');
      return true; // Default to enabled on error
    }
  }

  /// Check if social AI features are enabled
  Future<bool> areSocialAIFeaturesEnabled() async {
    try {
      final preferences = await getUserAIPreferences();
      return preferences.enableAIContent && 
             (preferences.enableConversationStarters || 
              preferences.enableFriendMatchingAI || 
              preferences.allowAIInGroups);
    } catch (e) {
      Logger.e('Error checking social AI features: $e');
      return true; // Default to enabled on error
    }
  }

  /// Check if review features are enabled
  Future<bool> areReviewFeaturesEnabled() async {
    try {
      final preferences = await getUserAIPreferences();
      return preferences.enableAIContent && 
             (preferences.enableWeeklyReviews || 
              preferences.enableMonthlyReviews || 
              preferences.enableGoalTracking);
    } catch (e) {
      Logger.e('Error checking review features: $e');
      return true; // Default to enabled on error
    }
  }

  /// Stream user's AI preferences for real-time updates
  Stream<AIContentPreferences> watchUserAIPreferences() {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return Stream.value(AIContentPreferences());
      }

      return _firestore
          .collection('privacy_settings')
          .doc(user.uid)
          .snapshots()
          .map((doc) {
            if (doc.exists) {
              final privacySettings = PrivacySettings.fromFirestore(doc);
              return privacySettings.aiPreferences;
            } else {
              return AIContentPreferences();
            }
          });
    } catch (e) {
      Logger.e('Error watching AI preferences: $e');
      return Stream.value(AIContentPreferences());
    }
  }

  /// Validate preferences before saving
  bool _validatePreferences(AIContentPreferences preferences) {
    // Basic validation
    if (preferences.blockedKeywords.length > 100) {
      Logger.e('Too many blocked keywords');
      return false;
    }

    // Check for valid frequency settings
    if (!AIContentFrequency.values.contains(preferences.dailyInsightFrequency) ||
        !AIContentFrequency.values.contains(preferences.mealInsightFrequency) ||
        !AIContentFrequency.values.contains(preferences.feedContentFrequency)) {
      Logger.e('Invalid frequency settings');
      return false;
    }

    return true;
  }

  /// Export user preferences for data portability
  Future<Map<String, dynamic>> exportUserPreferences() async {
    try {
      final preferences = await getUserAIPreferences();
      return {
        'ai_preferences': preferences.toMap(),
        'exported_at': DateTime.now().toIso8601String(),
        'version': '1.0.0',
      };
    } catch (e) {
      Logger.e('Error exporting user preferences: $e');
      rethrow;
    }
  }

  /// Import user preferences from exported data
  Future<void> importUserPreferences(Map<String, dynamic> data) async {
    try {
      if (data['ai_preferences'] != null) {
        final preferences = AIContentPreferences.fromMap(data['ai_preferences']);
        
        if (_validatePreferences(preferences)) {
          await _updateUserAIPreferences(preferences);
          Logger.i('User preferences imported successfully');
        } else {
          throw Exception('Invalid preferences data');
        }
      }
    } catch (e) {
      Logger.e('Error importing user preferences: $e');
      rethrow;
    }
  }
} 