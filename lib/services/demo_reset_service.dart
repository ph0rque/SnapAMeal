import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';
import 'demo_data_service.dart';

/// Service for managing demo data reset functionality
class DemoResetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _demoPrefix = 'demo_';

  /// Reset all demo data for the current demo user
  static Future<bool> resetCurrentUserDemoData() async {
    try {
      final authService = AuthService();
      final isDemo = await authService.isCurrentUserDemo();
      
      if (!isDemo) {
        debugPrint('❌ Reset failed: Current user is not a demo user');
        return false;
      }

      final currentUser = authService.getCurrentUser();
      if (currentUser == null) {
        debugPrint('❌ Reset failed: No current user');
        return false;
      }

      final personaId = await authService.getCurrentDemoPersonaId();
      if (personaId == null) {
        debugPrint('❌ Reset failed: Could not determine demo persona');
        return false;
      }

      debugPrint('🔄 Starting demo reset for user: ${currentUser.uid} (persona: $personaId)');

      // Reset user-specific demo data
      await _resetUserGeneratedData(currentUser.uid);
      
      // Re-seed the persona's base data
      await _reseedPersonaData(currentUser.uid, personaId);

      debugPrint('✅ Demo reset completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Demo reset failed: $e');
      return false;
    }
  }

  /// Reset demo data for all demo users (admin function)
  static Future<bool> resetAllDemoData() async {
    try {
      debugPrint('🔄 Starting full demo reset...');

      // Get all demo collections
      final demoCollections = [
        '${_demoPrefix}health_profiles',
        '${_demoPrefix}fasting_sessions',
        '${_demoPrefix}meal_logs',
        '${_demoPrefix}progress_stories',
        '${_demoPrefix}friendships',
        '${_demoPrefix}health_groups',
        '${_demoPrefix}group_chat_messages',
        '${_demoPrefix}ai_advice_history',
        '${_demoPrefix}health_challenges',
        '${_demoPrefix}user_streaks',
      ];

      // Clear all demo collections
      for (final collection in demoCollections) {
        await _clearCollection(collection);
      }

      // Re-seed all demo data
      await DemoDataService.seedAllDemoData();

      debugPrint('✅ Full demo reset completed successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Full demo reset failed: $e');
      return false;
    }
  }

  /// Reset only user-generated content (preserves seeded data structure)
  static Future<void> _resetUserGeneratedData(String userId) async {
    final batch = _firestore.batch();

    // Collections that contain user-generated content to reset
    final userDataQueries = [
      // Reset user's meal logs (keep structure, reset to seeded state)
      _firestore.collection('${_demoPrefix}meal_logs')
          .where('userId', isEqualTo: userId)
          .where('isUserGenerated', isEqualTo: true),
      
      // Reset user's progress stories (keep seeded ones)
      _firestore.collection('${_demoPrefix}progress_stories')
          .where('userId', isEqualTo: userId)
          .where('isUserGenerated', isEqualTo: true),
      
      // Reset user's group messages (keep seeded conversation)
      _firestore.collection('${_demoPrefix}group_chat_messages')
          .where('senderId', isEqualTo: userId)
          .where('isUserGenerated', isEqualTo: true),
      
      // Reset user's AI advice interactions (keep seeded history)
      _firestore.collection('${_demoPrefix}ai_advice_history')
          .where('userId', isEqualTo: userId)
          .where('isUserGenerated', isEqualTo: true),
    ];

    // Execute deletions
    for (final query in userDataQueries) {
      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
    debugPrint('🗑️ User-generated content cleared for user: $userId');
  }

  /// Re-seed persona-specific data after reset
  static Future<void> _reseedPersonaData(String userId, String personaId) async {
    debugPrint('🌱 Re-seeding data for persona: $personaId');
    
    // Re-seed this specific persona's data
    await DemoDataService.seedPersonaData(personaId, userId);
  }

  /// Clear an entire Firestore collection
  static Future<void> _clearCollection(String collectionName) async {
    debugPrint('🗑️ Clearing collection: $collectionName');
    
    final collection = _firestore.collection(collectionName);
    final snapshot = await collection.get();
    
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    debugPrint('✅ Collection cleared: $collectionName (${snapshot.docs.length} documents)');
  }

  /// Get reset statistics for the current demo user
  static Future<Map<String, int>> getDemoDataStats() async {
    try {
      final authService = AuthService();
      final currentUser = authService.getCurrentUser();
      
      if (currentUser == null) {
        return {};
      }

      final userId = currentUser.uid;
      final stats = <String, int>{};

      // Count documents in each demo collection for this user
      final collections = {
        'Fasting Sessions': '${_demoPrefix}fasting_sessions',
        'Meal Logs': '${_demoPrefix}meal_logs',
        'Progress Stories': '${_demoPrefix}progress_stories',
        'AI Advice': '${_demoPrefix}ai_advice_history',
        'Health Challenges': '${_demoPrefix}health_challenges',
        'Streaks': '${_demoPrefix}user_streaks',
      };

      for (final entry in collections.entries) {
        final snapshot = await _firestore
            .collection(entry.value)
            .where('userId', isEqualTo: userId)
            .get();
        stats[entry.key] = snapshot.docs.length;
      }

      // Count group messages sent by this user
      final messagesSnapshot = await _firestore
          .collection('${_demoPrefix}group_chat_messages')
          .where('senderId', isEqualTo: userId)
          .get();
      stats['Group Messages'] = messagesSnapshot.docs.length;

      return stats;
    } catch (e) {
      debugPrint('❌ Failed to get demo data stats: $e');
      return {};
    }
  }

  /// Check if demo reset is available for current user
  static Future<bool> isResetAvailable() async {
    final authService = AuthService();
    return await authService.isCurrentUserDemo();
  }

  /// Get the last reset timestamp for current user
  static Future<DateTime?> getLastResetTime() async {
    try {
      final authService = AuthService();
      final currentUser = authService.getCurrentUser();
      
      if (currentUser == null) return null;

      final doc = await _firestore
          .collection('${_demoPrefix}reset_history')
          .doc(currentUser.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final timestamp = data?['lastReset'] as Timestamp?;
        return timestamp?.toDate();
      }

      return null;
    } catch (e) {
      debugPrint('❌ Failed to get last reset time: $e');
      return null;
    }
  }



  /// Validate demo data integrity after reset
  static Future<bool> validateDemoDataIntegrity() async {
    try {
      final authService = AuthService();
      final currentUser = authService.getCurrentUser();
      
      if (currentUser == null) return false;

      final userId = currentUser.uid;
      
      // Check that essential collections have data
      final essentialChecks = [
        _firestore.collection('${_demoPrefix}health_profiles').doc(userId),
        _firestore.collection('${_demoPrefix}fasting_sessions')
            .where('userId', isEqualTo: userId)
            .limit(1),
        _firestore.collection('${_demoPrefix}meal_logs')
            .where('userId', isEqualTo: userId)
            .limit(1),
      ];

      for (final check in essentialChecks) {
        if (check is DocumentReference) {
          final doc = await check.get();
          if (!doc.exists) return false;
        } else if (check is Query) {
          final snapshot = await check.get();
          if (snapshot.docs.isEmpty) return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('❌ Demo data integrity validation failed: $e');
      return false;
    }
  }
} 