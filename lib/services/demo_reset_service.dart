import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'auth_service.dart';
import 'demo_data_service.dart';

/// Service for managing demo data reset functionality
class DemoResetService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _demoPrefix = 'demo_';
  static const List<String> _demoCollections = [
    'demo_health_profiles',
    'demo_fasting_sessions',
    // 'demo_meal_logs', // Migrated to production meal_logs
    'demo_progress_stories',
    'demo_friendships',
    // 'demo_health_groups', // Migrated to production health_groups
    'demo_group_chat_messages',
    'demo_ai_advice_history',
    'demo_health_challenges',
    'demo_user_streaks',
  ];

  /// Reset all demo data for the current demo user
  static Future<bool> resetCurrentUserDemoData() async {
    try {
      final authService = AuthService();
      final isDemo = await authService.isCurrentUserDemo();

      if (!isDemo) {
        Logger.d('❌ Reset failed: Current user is not a demo user');
        return false;
      }

      final currentUser = authService.getCurrentUser();
      if (currentUser == null) {
        Logger.d('❌ Reset failed: No current user');
        return false;
      }

      final personaId = await authService.getCurrentDemoPersonaId();
      if (personaId == null) {
        Logger.d('❌ Reset failed: Could not determine demo persona');
        return false;
      }

      Logger.d(
        '🔄 Starting demo reset for user: ${currentUser.uid} (persona: $personaId)',
      );

      final baseline = await _captureBaselineHashes();

      // Reset user-specific demo data
      await _resetUserGeneratedData(currentUser.uid);

      // Re-seed the persona's base data
      await _reseedPersonaData(currentUser.uid, personaId);

      final ok = await _compareHashes(baseline);
      if (!ok) {
        Logger.d(
          '⚠️ Hash mismatch after reset – seeded data may be inconsistent',
        );
      }

      Logger.d('✅ Demo reset completed successfully');
      return true;
    } catch (e) {
      Logger.d('❌ Demo reset failed: $e');
      return false;
    }
  }

  /// Reset demo data for all demo users (admin function)
  static Future<bool> resetAllDemoData() async {
    try {
      Logger.d('🔄 Starting full demo reset...');

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

      Logger.d('✅ Full demo reset completed successfully');
      return true;
    } catch (e) {
      Logger.d('❌ Full demo reset failed: $e');
      return false;
    }
  }

  /// Reset only user-generated content (preserves seeded data structure)
  static Future<void> _resetUserGeneratedData(String userId) async {
    final batch = _firestore.batch();

    // Collections that contain user-generated content to reset
    final userDataQueries = [
      // Reset user's meal logs (keep structure, reset to seeded state)
      _firestore
          .collection('${_demoPrefix}meal_logs')
          .where('userId', isEqualTo: userId)
          .where('isUserGenerated', isEqualTo: true),

      // Reset user's progress stories (keep seeded ones)
      _firestore
          .collection('${_demoPrefix}progress_stories')
          .where('userId', isEqualTo: userId)
          .where('isUserGenerated', isEqualTo: true),

      // Reset user's group messages (keep seeded conversation)
      _firestore
          .collection('${_demoPrefix}group_chat_messages')
          .where('senderId', isEqualTo: userId)
          .where('isUserGenerated', isEqualTo: true),

      // Reset user's AI advice interactions (keep seeded history)
      _firestore
          .collection('${_demoPrefix}ai_advice_history')
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
    Logger.d('🗑️ User-generated content cleared for user: $userId');
  }

  /// Re-seed persona-specific data after reset
  static Future<void> _reseedPersonaData(
    String userId,
    String personaId,
  ) async {
    Logger.d('🌱 Re-seeding data for persona: $personaId');

    // Re-seed this specific persona's data
    await DemoDataService.seedPersonaData(personaId, userId);
  }

  /// Clear an entire Firestore collection
  static Future<void> _clearCollection(String collectionName) async {
    Logger.d('🗑️ Clearing collection: $collectionName');

    final collection = _firestore.collection(collectionName);
    final snapshot = await collection.get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    Logger.d(
      '✅ Collection cleared: $collectionName (${snapshot.docs.length} documents)',
    );
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
        try {
          final snapshot = await _firestore
              .collection(entry.value)
              .where('userId', isEqualTo: userId)
              .get();
          stats[entry.key] = snapshot.docs.length;
        } catch (collectionError) {
          // Handle permission errors gracefully
          if (collectionError.toString().contains('permission-denied')) {
            // For permission errors, set count to 0 and continue
            stats[entry.key] = 0;
            Logger.d('Demo stats: Permission denied for ${entry.key}, using fallback');
          } else {
            // For other errors, rethrow
            rethrow;
          }
        }
      }

      // Count group messages sent by this user
      try {
        final messagesSnapshot = await _firestore
            .collection('${_demoPrefix}group_chat_messages')
            .where('senderId', isEqualTo: userId)
            .get();
        stats['Group Messages'] = messagesSnapshot.docs.length;
      } catch (messagesError) {
        if (messagesError.toString().contains('permission-denied')) {
          stats['Group Messages'] = 0;
          Logger.d('Demo stats: Permission denied for Group Messages, using fallback');
        } else {
          // For non-permission errors, still provide fallback but log the error
          stats['Group Messages'] = 0;
          Logger.d('Demo stats: Error getting group messages: $messagesError');
        }
      }

      return stats;
    } catch (e) {
      // Handle general permission errors gracefully
      if (e.toString().contains('permission-denied')) {
        Logger.d('Demo stats: Permission denied, using empty stats');
        return <String, int>{
          'Fasting Sessions': 0,
          'Meal Logs': 0,
          'Progress Stories': 0,
          'AI Advice': 0,
          'Health Challenges': 0,
          'Streaks': 0,
          'Group Messages': 0,
        };
      } else {
        Logger.d('❌ Failed to get demo data stats: $e');
        return {};
      }
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
      // Handle permission errors gracefully
      if (e.toString().contains('permission-denied')) {
        Logger.d('Demo reset time: Permission denied, returning null');
        return null;
      } else {
        Logger.d('❌ Failed to get last reset time: $e');
        return null;
      }
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
        _firestore
            .collection('${_demoPrefix}fasting_sessions')
            .where('userId', isEqualTo: userId)
            .limit(1),
        _firestore
            .collection('${_demoPrefix}meal_logs')
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
      Logger.d('❌ Demo data integrity validation failed: $e');
      return false;
    }
  }

  /// Generate a lightweight deterministic hash for a collection based on
  /// document count and the most recent updatedAt/createdAt timestamp.
  static Future<String> _getCollectionHash(String collection) async {
    // Use aggregation queries when available; fallback to client-side.
    final snapshot = await _firestore.collection(collection).get();
    int count = snapshot.docs.length;
    int latest = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      Timestamp? ts;
      if (data.containsKey('updatedAt')) ts = data['updatedAt'] as Timestamp?;
      ts ??= data['createdAt'] as Timestamp?;
      if (ts != null && ts.millisecondsSinceEpoch > latest) {
        latest = ts.millisecondsSinceEpoch;
      }
    }
    return '$count:$latest';
  }

  /// Capture baseline hashes for all demo collections.
  static Future<Map<String, String>> _captureBaselineHashes() async {
    final map = <String, String>{};
    for (final col in _demoCollections) {
      map[col] = await _getCollectionHash(col);
    }
    return map;
  }

  /// Compare current hashes with baseline; return true if identical.
  static Future<bool> _compareHashes(Map<String, String> baseline) async {
    for (final col in _demoCollections) {
      final current = await _getCollectionHash(col);
      if (baseline[col] != current) return false;
    }
    return true;
  }
}
