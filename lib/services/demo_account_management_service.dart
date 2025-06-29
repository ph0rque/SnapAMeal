import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';
import 'demo_data_service.dart';
import 'demo_reset_service.dart';

/// Service for managing demo accounts with automated cleanup and maintenance
class DemoAccountManagementService {
  static final DemoAccountManagementService _instance =
      DemoAccountManagementService._internal();
  factory DemoAccountManagementService() => _instance;
  DemoAccountManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Demo account configurations - must match DemoPersonas emails
  static const Map<String, Map<String, dynamic>> demoAccounts = {
    'alice.demo@example.com': {
      'uid': 'demo_alice_uid',
      'displayName': 'Alice',
      'role': 'fitness_enthusiast',
      'maxSessionDuration': Duration(hours: 4),
      'autoResetInterval': Duration(days: 7),
    },
    'bob.demo@example.com': {
      'uid': 'demo_bob_uid',
      'displayName': 'Bob',
      'role': 'health_coach',
      'maxSessionDuration': Duration(hours: 6),
      'autoResetInterval': Duration(days: 7),
    },
    'charlie.demo@example.com': {
      'uid': 'demo_charlie_uid',
      'displayName': 'Chuck',
      'role': 'nutrition_student',
      'maxSessionDuration': Duration(hours: 2),
      'autoResetInterval': Duration(days: 7),
    },
  };

  /// Check if the current user is a demo account
  Future<bool> isCurrentUserDemo() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    return demoAccounts.containsKey(user.email);
  }

  /// Get demo account configuration for current user
  Future<Map<String, dynamic>?> getCurrentDemoAccountConfig() async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return null;

    return demoAccounts[user.email!];
  }

  /// Validate demo account status and perform maintenance
  Future<DemoAccountStatus> validateDemoAccount(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return DemoAccountStatus(
          isValid: false,
          status: 'not_authenticated',
          message: 'User not authenticated',
        );
      }

      final email = user.email;
      if (email == null || !demoAccounts.containsKey(email)) {
        return DemoAccountStatus(
          isValid: false,
          status: 'not_demo_account',
          message: 'Not a valid demo account',
        );
      }

      // Check session duration
      final config = demoAccounts[email]!;
      final sessionDoc = await _firestore
          .collection('demo_session_data')
          .doc(userId)
          .get();

      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data()!;
        final sessionStart = (sessionData['sessionStart'] as Timestamp)
            .toDate();
        final maxDuration = config['maxSessionDuration'] as Duration;

        if (DateTime.now().difference(sessionStart) > maxDuration) {
          // Session expired, trigger cleanup
          await _performSessionCleanup(userId);
          return DemoAccountStatus(
            isValid: true,
            status: 'session_expired',
            message: 'Demo session expired and reset',
            needsReset: true,
          );
        }
      }

      // Check auto-reset interval
      final lastResetDoc = await _firestore
          .collection('demo_reset_history')
          .where('userId', isEqualTo: userId)
          .orderBy('resetTime', descending: true)
          .limit(1)
          .get();

      if (lastResetDoc.docs.isNotEmpty) {
        final resetData = lastResetDoc.docs.first.data();
        final lastReset = (resetData['resetTime'] as Timestamp).toDate();
        final autoResetInterval = config['autoResetInterval'] as Duration;

        if (DateTime.now().difference(lastReset) > autoResetInterval) {
          return DemoAccountStatus(
            isValid: true,
            status: 'auto_reset_due',
            message: 'Auto-reset interval reached',
            needsReset: true,
          );
        }
      }

      return DemoAccountStatus(
        isValid: true,
        status: 'active',
        message: 'Demo account active and valid',
      );
    } catch (e) {
      return DemoAccountStatus(
        isValid: false,
        status: 'validation_error',
        message: 'Error validating demo account: $e',
      );
    }
  }

  /// Perform automated session cleanup
  Future<void> _performSessionCleanup(String userId) async {
    try {
      // Reset demo data
      await DemoResetService.resetCurrentUserDemoData();

      // Clear session data
      await _firestore.collection('demo_session_data').doc(userId).delete();

      // Log cleanup operation
      await _firestore.collection('demo_reset_history').add({
        'userId': userId,
        'resetType': 'automated_cleanup',
        'resetTime': FieldValue.serverTimestamp(),
        'reason': 'session_expired',
      });
    } catch (e) {
      Logger.d('Error performing session cleanup: $e');
    }
  }

  /// Initialize demo account session
  Future<void> initializeDemoSession(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return;

      final config = demoAccounts[user.email!];
      if (config == null) return;

      // Create session data
      await _firestore.collection('demo_session_data').doc(userId).set({
        'userId': userId,
        'email': user.email,
        'displayName': config['displayName'],
        'role': config['role'],
        'sessionStart': FieldValue.serverTimestamp(),
        'lastActivity': FieldValue.serverTimestamp(),
        'sessionId': _generateSessionId(),
        'isActive': true,
      });

      // Ensure demo data exists
      final hasData = await DemoDataService.hasDemoData(userId);

      if (!hasData) {
        await DemoDataService.seedPersonaData(userId, user.email!);
      }
    } catch (e) {
      Logger.d('Error initializing demo session: $e');
    }
  }

  /// Update session activity timestamp
  Future<void> updateSessionActivity(String userId) async {
    try {
      await _firestore.collection('demo_session_data').doc(userId).update({
        'lastActivity': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.d('Error updating session activity: $e');
    }
  }

  /// Get session statistics for all demo accounts
  Future<List<DemoSessionStats>> getAllSessionStats() async {
    try {
      final sessions = await _firestore.collection('demo_session_data').get();

      List<DemoSessionStats> stats = [];

      for (final doc in sessions.docs) {
        final data = doc.data();
        final sessionStart = (data['sessionStart'] as Timestamp).toDate();
        final lastActivity = (data['lastActivity'] as Timestamp).toDate();

        stats.add(
          DemoSessionStats(
            userId: data['userId'],
            email: data['email'],
            displayName: data['displayName'],
            role: data['role'],
            sessionStart: sessionStart,
            lastActivity: lastActivity,
            sessionDuration: DateTime.now().difference(sessionStart),
            isActive: data['isActive'] ?? false,
          ),
        );
      }

      return stats;
    } catch (e) {
      Logger.d('Error getting session stats: $e');
      return [];
    }
  }

  /// Cleanup inactive demo sessions
  Future<void> cleanupInactiveSessions() async {
    try {
      final inactiveThreshold = DateTime.now().subtract(
        const Duration(hours: 24),
      );

      final inactiveSessions = await _firestore
          .collection('demo_session_data')
          .where(
            'lastActivity',
            isLessThan: Timestamp.fromDate(inactiveThreshold),
          )
          .get();

      for (final doc in inactiveSessions.docs) {
        final data = doc.data();
        final userId = data['userId'];
        await _performSessionCleanup(userId);
      }
    } catch (e) {
      Logger.d('Error cleaning up inactive sessions: $e');
    }
  }

  /// Force reset all demo accounts (admin function)
  Future<void> resetAllDemoAccounts() async {
    try {
      for (final email in demoAccounts.keys) {
        final uid = demoAccounts[email]!['uid'];

        // Reset demo data for each account
        await DemoResetService.resetAllDemoData();

        // Clear session data
        await _firestore.collection('demo_session_data').doc(uid).delete();

        // Log reset operation
        await _firestore.collection('demo_reset_history').add({
          'userId': uid,
          'resetType': 'admin_reset_all',
          'resetTime': FieldValue.serverTimestamp(),
          'reason': 'admin_initiated',
        });
      }
    } catch (e) {
      Logger.d('Error resetting all demo accounts: $e');
    }
  }

  /// Get demo account usage analytics
  Future<DemoUsageAnalytics> getUsageAnalytics() async {
    try {
      // Get session stats
      final sessions = await getAllSessionStats();

      // Get reset history
      final resetHistory = await _firestore
          .collection('demo_reset_history')
          .orderBy('resetTime', descending: true)
          .limit(100)
          .get();

      // Calculate metrics
      final totalSessions = sessions.length;
      final activeSessions = sessions.where((s) => s.isActive).length;
      final avgSessionDuration = sessions.isEmpty
          ? Duration.zero
          : Duration(
              milliseconds:
                  sessions
                      .map((s) => s.sessionDuration.inMilliseconds)
                      .reduce((a, b) => a + b) ~/
                  sessions.length,
            );

      final totalResets = resetHistory.docs.length;
      final recentResets = resetHistory.docs.where((doc) {
        final data = doc.data();
        final resetTime = (data['resetTime'] as Timestamp).toDate();
        return DateTime.now().difference(resetTime).inDays <= 7;
      }).length;

      return DemoUsageAnalytics(
        totalSessions: totalSessions,
        activeSessions: activeSessions,
        averageSessionDuration: avgSessionDuration,
        totalResets: totalResets,
        recentResets: recentResets,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      Logger.d('Error getting usage analytics: $e');
      return DemoUsageAnalytics(
        totalSessions: 0,
        activeSessions: 0,
        averageSessionDuration: Duration.zero,
        totalResets: 0,
        recentResets: 0,
        lastUpdated: DateTime.now(),
      );
    }
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecond % 1000).toString().padLeft(3, '0')}';
  }
}

/// Demo account validation status
class DemoAccountStatus {
  final bool isValid;
  final String status;
  final String message;
  final bool needsReset;

  DemoAccountStatus({
    required this.isValid,
    required this.status,
    required this.message,
    this.needsReset = false,
  });
}

/// Demo session statistics
class DemoSessionStats {
  final String userId;
  final String email;
  final String displayName;
  final String role;
  final DateTime sessionStart;
  final DateTime lastActivity;
  final Duration sessionDuration;
  final bool isActive;

  DemoSessionStats({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.role,
    required this.sessionStart,
    required this.lastActivity,
    required this.sessionDuration,
    required this.isActive,
  });
}

/// Demo usage analytics
class DemoUsageAnalytics {
  final int totalSessions;
  final int activeSessions;
  final Duration averageSessionDuration;
  final int totalResets;
  final int recentResets;
  final DateTime lastUpdated;

  DemoUsageAnalytics({
    required this.totalSessions,
    required this.activeSessions,
    required this.averageSessionDuration,
    required this.totalResets,
    required this.recentResets,
    required this.lastUpdated,
  });
}
