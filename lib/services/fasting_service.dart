import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/fasting_session.dart';
import '../services/rag_service.dart';
import '../services/notification_service.dart';
import '../config/ai_config.dart';

/// Service for managing fasting sessions with timer logic and state persistence
class FastingService {
  // Dependencies
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final RAGService _ragService;
  final NotificationService _notificationService;
  
  // Current session state
  FastingSession? _currentSession;
  Timer? _timer;
  StreamController<FastingSession?> _sessionController = StreamController<FastingSession?>.broadcast();
  
  // Session tracking
  int _timerTicks = 0;
  DateTime? _lastAppOpen;
  DateTime? _sessionStartTime;
  
  // Motivational content
  final List<String> _motivationalQuotes = [
    "Every moment of resistance makes you stronger.",
    "Discipline is choosing between what you want now and what you want most.",
    "Your body is adapting, your mind is strengthening.",
    "This hunger is temporary, but your progress is permanent.",
    "You're not just fasting, you're building willpower.",
    "Each hour completed is a victory worth celebrating.",
    "Your future self will thank you for this dedication.",
    "Strength comes from overcoming the things you thought you couldn't.",
    "You're in control of your choices and your health.",
    "This is your time to prove what you're capable of.",
  ];

  FastingService(this._ragService, this._notificationService);

  /// Stream of current fasting session updates
  Stream<FastingSession?> get sessionStream => _sessionController.stream;

  /// Get the current active session
  FastingSession? get currentSession => _currentSession;

  /// Check if there's an active fasting session
  bool get hasActiveSession => _currentSession?.isActive == true || _currentSession?.isPaused == true;

  /// Initialize the service and restore any active session
  Future<void> initialize() async {
    await _loadActiveSession();
    _schedulePeriodicUpdates();
  }

  /// Start a new fasting session
  Future<FastingSession?> startFastingSession({
    required FastingType type,
    Duration? customDuration,
    String? personalGoal,
    double? targetWeight,
    List<String> motivationalTags = const [],
    DateTime? plannedStartTime,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // End any existing session first
      if (_currentSession != null && _currentSession!.isActive) {
        await endFastingSession(FastingEndReason.userBreak, 'Started new session');
      }

      final now = DateTime.now();
      final startTime = plannedStartTime ?? now;
      final duration = customDuration ?? FastingSession.getStandardDuration(type);
      final endTime = startTime.add(duration);

      // Create new session
      final sessionId = _firestore.collection('fasting_sessions').doc().id;
      final session = FastingSession(
        id: sessionId,
        userId: user.uid,
        type: type,
        state: FastingState.active,
        plannedStartTime: startTime,
        actualStartTime: now,
        plannedEndTime: endTime,
        plannedDuration: duration,
        personalGoal: personalGoal,
        targetWeight: targetWeight,
        motivationalTags: motivationalTags,
        createdAt: now,
        updatedAt: now,
      );

      // Save to Firestore
      await _firestore
          .collection('fasting_sessions')
          .doc(sessionId)
          .set(session.toFirestore());

      // Update local state
      _currentSession = session;
      _sessionStartTime = now;
      _startTimer();
      
      // Schedule notifications
      await _scheduleSessionNotifications(session);
      
      // Save to local storage for persistence
      await _saveActiveSession(session);
      
      // Emit update
      _sessionController.add(_currentSession);

      print('Started fasting session: ${session.typeDescription}');
      return session;
    } catch (e) {
      print('Error starting fasting session: $e');
      return null;
    }
  }

  /// Pause the current fasting session
  Future<bool> pauseFastingSession() async {
    if (_currentSession == null || !_currentSession!.isActive) {
      return false;
    }

    try {
      final now = DateTime.now();
      final updatedSession = _currentSession!.copyWith(
        state: FastingState.paused,
        pausedTimes: [..._currentSession!.pausedTimes, now],
        updatedAt: now,
      );

      await _updateSession(updatedSession);
      _stopTimer();
      
      print('Paused fasting session');
      return true;
    } catch (e) {
      print('Error pausing fasting session: $e');
      return false;
    }
  }

  /// Resume a paused fasting session
  Future<bool> resumeFastingSession() async {
    if (_currentSession == null || !_currentSession!.isPaused) {
      return false;
    }

    try {
      final now = DateTime.now();
      
      // Calculate additional paused time
      final lastPauseTime = _currentSession!.pausedTimes.last;
      final additionalPausedDuration = now.difference(lastPauseTime);
      final totalPausedDuration = _currentSession!.totalPausedDuration + additionalPausedDuration;

      final updatedSession = _currentSession!.copyWith(
        state: FastingState.active,
        resumedTimes: [..._currentSession!.resumedTimes, now],
        totalPausedDuration: totalPausedDuration,
        updatedAt: now,
      );

      await _updateSession(updatedSession);
      _startTimer();
      
      print('Resumed fasting session');
      return true;
    } catch (e) {
      print('Error resuming fasting session: $e');
      return false;
    }
  }

  /// End the current fasting session
  Future<bool> endFastingSession(FastingEndReason reason, [String? notes]) async {
    if (_currentSession == null) return false;

    try {
      final now = DateTime.now();
      final actualDuration = _currentSession!.elapsedTime;
      final completionPercentage = actualDuration.inMilliseconds / _currentSession!.plannedDuration.inMilliseconds;
      
      // Determine final state
      final finalState = reason == FastingEndReason.completed 
          ? FastingState.completed 
          : FastingState.broken;

      // Update streak information
      final streakData = await _updateStreakData(reason == FastingEndReason.completed);

      final updatedSession = _currentSession!.copyWith(
        state: finalState,
        actualEndTime: now,
        actualDuration: actualDuration,
        endReason: reason,
        endNotes: notes,
        completionPercentage: completionPercentage,
        currentStreak: streakData['currentStreak'],
        longestStreak: streakData['longestStreak'],
        isPersonalBest: streakData['isPersonalBest'],
        updatedAt: now,
      );

      await _updateSession(updatedSession);
      _stopTimer();
      
      // Clear local storage
      await _clearActiveSession();
      
      // Cancel notifications
      await _notificationService.cancelAllNotifications();
      
      // Generate post-session insights using RAG
      await _generateSessionInsights(updatedSession);
      
      print('Ended fasting session: $reason');
      return true;
    } catch (e) {
      print('Error ending fasting session: $e');
      return false;
    }
  }

  /// Record user engagement during fasting
  Future<void> recordEngagement({
    bool? snapTaken,
    bool? motivationViewed,
    bool? appOpened,
    bool? timerChecked,
    String? challengeMet,
    String? featureUsed,
  }) async {
    if (_currentSession == null) return;

    try {
      final currentEngagement = _currentSession!.engagement;
      final updatedEngagement = currentEngagement.copyWith(
        snapsTaken: snapTaken == true ? currentEngagement.snapsTaken + 1 : currentEngagement.snapsTaken,
        motivationViews: motivationViewed == true ? currentEngagement.motivationViews + 1 : currentEngagement.motivationViews,
        appOpens: appOpened == true ? currentEngagement.appOpens + 1 : currentEngagement.appOpens,
        timerChecks: timerChecked == true ? currentEngagement.timerChecks + 1 : currentEngagement.timerChecks,
        challengesMet: challengeMet != null 
            ? [...currentEngagement.challengesMet, challengeMet]
            : currentEngagement.challengesMet,
        featureUsage: featureUsed != null 
            ? {
                ...currentEngagement.featureUsage,
                featureUsed: (currentEngagement.featureUsage[featureUsed] ?? 0) + 1,
              }
            : currentEngagement.featureUsage,
      );

      final updatedSession = _currentSession!.copyWith(
        engagement: updatedEngagement,
        updatedAt: DateTime.now(),
      );

      await _updateSession(updatedSession);
    } catch (e) {
      print('Error recording engagement: $e');
    }
  }

  /// Get motivational content for the current session
  Future<String?> getMotivationalContent() async {
    if (_currentSession == null) return null;

    try {
      // Use RAG service to get personalized motivational content
      final healthContext = HealthQueryContext(
        userId: _currentSession!.userId,
        queryType: 'motivation',
        userProfile: {
          'fasting_type': _currentSession!.type.name,
          'session_progress': _currentSession!.progressPercentage,
          'personal_goal': _currentSession!.personalGoal,
        },
        currentGoals: ['fasting', 'discipline', ..._currentSession!.motivationalTags],
        dietaryRestrictions: [],
        recentActivity: {
          'session_duration': _currentSession!.elapsedTime.inHours,
          'engagement': _currentSession!.engagement.toJson(),
        },
        contextTimestamp: DateTime.now(),
      );

      final motivationalContent = await _ragService.generateContextualizedResponse(
        userQuery: 'Give me encouragement for my ${_currentSession!.typeDescription} session. I\'m ${(_currentSession!.progressPercentage * 100).toInt()}% complete.',
        healthContext: healthContext,
        maxContextLength: 1000,
      );

      if (motivationalContent != null) {
        // Record the motivation as shown
        final motivation = FastingMotivation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'ai_encouragement',
          content: motivationalContent,
          shownAt: DateTime.now(),
        );

        final updatedSession = _currentSession!.copyWith(
          motivationShown: [..._currentSession!.motivationShown, motivation],
          updatedAt: DateTime.now(),
        );

        await _updateSession(updatedSession);
        await recordEngagement(motivationViewed: true);

        return motivationalContent;
      }

      // Fallback to predefined quotes
      final randomQuote = _motivationalQuotes[Random().nextInt(_motivationalQuotes.length)];
      return randomQuote;
    } catch (e) {
      print('Error getting motivational content: $e');
      // Fallback to predefined quotes
      return _motivationalQuotes[Random().nextInt(_motivationalQuotes.length)];
    }
  }

  /// Get user's fasting history
  Future<List<FastingSession>> getFastingHistory({int limit = 20}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final query = await _firestore
          .collection('fasting_sessions')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) => FastingSession.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting fasting history: $e');
      return [];
    }
  }

  /// Get fasting statistics
  Future<Map<String, dynamic>> getFastingStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final sessions = await getFastingHistory(limit: 100);
      
      final completedSessions = sessions.where((s) => s.isCompleted).toList();
      final totalSessions = sessions.length;
      final successRate = totalSessions > 0 ? completedSessions.length / totalSessions : 0.0;
      
      final totalFastingTime = sessions.fold<Duration>(
        Duration.zero,
        (total, session) => total + (session.actualDuration ?? Duration.zero),
      );
      
      final averageSessionLength = completedSessions.isNotEmpty
          ? totalFastingTime.inHours / completedSessions.length
          : 0.0;
      
      final longestSession = sessions.isNotEmpty
          ? sessions.map((s) => s.actualDuration?.inHours ?? 0).reduce(max)
          : 0;
      
      final currentStreak = sessions.isNotEmpty ? sessions.first.currentStreak : 0;
      final longestStreak = sessions.isNotEmpty 
          ? sessions.map((s) => s.longestStreak).reduce(max)
          : 0;

      return {
        'total_sessions': totalSessions,
        'completed_sessions': completedSessions.length,
        'success_rate': successRate,
        'total_fasting_hours': totalFastingTime.inHours,
        'average_session_hours': averageSessionLength,
        'longest_session_hours': longestSession,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_session_date': sessions.isNotEmpty ? sessions.first.createdAt : null,
      };
    } catch (e) {
      print('Error getting fasting stats: $e');
      return {};
    }
  }

  /// Check session completion and auto-complete if needed
  Future<void> checkSessionCompletion() async {
    if (_currentSession == null || !_currentSession!.isActive) return;

    if (_currentSession!.remainingTime <= Duration.zero) {
      await endFastingSession(FastingEndReason.completed, 'Session completed automatically');
    }
  }

  /// Private helper methods

  /// Load active session from local storage
  Future<void> _loadActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString('active_fasting_session');
      
      if (sessionJson != null) {
        final sessionData = jsonDecode(sessionJson);
        final session = FastingSession.fromJson(sessionData);
        
        // Verify session is still valid and not completed
        if (session.isActive || session.isPaused) {
          _currentSession = session;
          
          // Sync with Firestore to get latest state
          await _syncSessionWithFirestore();
          
          if (_currentSession != null && _currentSession!.isActive) {
            _startTimer();
          }
          
          _sessionController.add(_currentSession);
        } else {
          await _clearActiveSession();
        }
      }
    } catch (e) {
      print('Error loading active session: $e');
      await _clearActiveSession();
    }
  }

  /// Save active session to local storage
  Future<void> _saveActiveSession(FastingSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_fasting_session', jsonEncode(session.toJson()));
    } catch (e) {
      print('Error saving active session: $e');
    }
  }

  /// Clear active session from local storage
  Future<void> _clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_fasting_session');
      _currentSession = null;
      _sessionController.add(null);
    } catch (e) {
      print('Error clearing active session: $e');
    }
  }

  /// Sync local session with Firestore
  Future<void> _syncSessionWithFirestore() async {
    if (_currentSession == null) return;

    try {
      final doc = await _firestore
          .collection('fasting_sessions')
          .doc(_currentSession!.id)
          .get();

      if (doc.exists) {
        _currentSession = FastingSession.fromFirestore(doc);
      }
    } catch (e) {
      print('Error syncing session with Firestore: $e');
    }
  }

  /// Update session in Firestore and local storage
  Future<void> _updateSession(FastingSession session) async {
    try {
      await _firestore
          .collection('fasting_sessions')
          .doc(session.id)
          .update(session.toFirestore());

      _currentSession = session;
      await _saveActiveSession(session);
      _sessionController.add(_currentSession);
    } catch (e) {
      print('Error updating session: $e');
    }
  }

  /// Start the session timer
  void _startTimer() {
    _stopTimer(); // Ensure no duplicate timers
    
    _timer = Timer.periodic(Duration(seconds: 30), (timer) async {
      _timerTicks++;
      
      // Update session every 30 seconds
      if (_currentSession != null && _currentSession!.isActive) {
        await recordEngagement(timerChecked: true);
        await checkSessionCompletion();
        
        // Show motivational content at milestones
        if (_shouldShowMotivation()) {
          await getMotivationalContent();
        }
      }
    });
  }

  /// Stop the session timer
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Schedule periodic updates for background sync
  void _schedulePeriodicUpdates() {
    Timer.periodic(Duration(minutes: 5), (timer) async {
      if (_currentSession != null) {
        await _syncSessionWithFirestore();
      }
    });
  }

  /// Schedule notifications for the session
  Future<void> _scheduleSessionNotifications(FastingSession session) async {
    // Schedule milestone notifications
    final milestones = [0.25, 0.5, 0.75, 0.9]; // 25%, 50%, 75%, 90%
    
    for (final milestone in milestones) {
      final notificationTime = session.actualStartTime!.add(
        Duration(milliseconds: (session.plannedDuration.inMilliseconds * milestone).round()),
      );
      
      await _notificationService.scheduleNotification(
        id: '${session.id}_milestone_${(milestone * 100).toInt()}',
        title: 'Fasting Progress',
        body: 'You\'re ${(milestone * 100).toInt()}% through your ${session.typeDescription}!',
        scheduledDate: notificationTime,
      );
    }
    
    // Schedule completion notification
    await _notificationService.scheduleNotification(
      id: '${session.id}_completion',
      title: 'Fasting Complete! 🎉',
      body: 'Congratulations! You\'ve completed your ${session.typeDescription}.',
      scheduledDate: session.plannedEndTime!,
    );
  }

  /// Check if motivational content should be shown
  bool _shouldShowMotivation() {
    if (_currentSession == null) return false;
    
    // Show motivation at regular intervals based on session progress
    final progress = _currentSession!.progressPercentage;
    final motivationCount = _currentSession!.motivationShown.length;
    
    // Show motivation every 10% progress, but not more than once per hour
    final expectedMotivations = (progress * 10).floor();
    final lastMotivationTime = _currentSession!.motivationShown.isNotEmpty
        ? _currentSession!.motivationShown.last.shownAt
        : _currentSession!.actualStartTime!;
    
    final timeSinceLastMotivation = DateTime.now().difference(lastMotivationTime);
    
    return motivationCount < expectedMotivations && 
           timeSinceLastMotivation.inMinutes >= 60;
  }

  /// Update streak data based on session completion
  Future<Map<String, dynamic>> _updateStreakData(bool sessionCompleted) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'currentStreak': 0, 'longestStreak': 0, 'isPersonalBest': false};

      // Get recent sessions to calculate streak
      final recentSessions = await _firestore
          .collection('fasting_sessions')
          .where('user_id', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      final sessions = recentSessions.docs
          .map((doc) => FastingSession.fromFirestore(doc))
          .toList();

      int currentStreak = 0;
      int longestStreak = 0;
      int tempStreak = 0;

      // Calculate current streak (from most recent backwards)
      if (sessionCompleted) {
        currentStreak = 1; // This session counts
        for (final session in sessions.skip(1)) { // Skip current session
          if (session.isCompleted) {
            currentStreak++;
          } else {
            break;
          }
        }
      }

      // Calculate longest streak
      for (final session in sessions) {
        if (session.isCompleted) {
          tempStreak++;
          longestStreak = max(longestStreak, tempStreak);
        } else {
          tempStreak = 0;
        }
      }

      // Check if this is a personal best duration
      final currentDuration = _currentSession?.elapsedTime.inHours ?? 0;
      final longestDuration = sessions.isNotEmpty
          ? sessions.map((s) => s.actualDuration?.inHours ?? 0).reduce(max)
          : 0;
      final isPersonalBest = currentDuration > longestDuration;

      return {
        'currentStreak': currentStreak,
        'longestStreak': max(longestStreak, currentStreak),
        'isPersonalBest': isPersonalBest,
      };
    } catch (e) {
      print('Error updating streak data: $e');
      return {'currentStreak': 0, 'longestStreak': 0, 'isPersonalBest': false};
    }
  }

  /// Generate post-session insights using RAG
  Future<void> _generateSessionInsights(FastingSession session) async {
    try {
      final healthContext = HealthQueryContext(
        userId: session.userId,
        queryType: 'advice',
        userProfile: {
          'fasting_type': session.type.name,
          'completion_percentage': session.completionPercentage,
          'session_duration': session.actualDuration?.inHours ?? 0,
        },
        currentGoals: ['fasting', 'health', ...session.motivationalTags],
        dietaryRestrictions: [],
        recentActivity: {
          'session_completed': session.isCompleted,
          'engagement': session.engagement.toJson(),
          'end_reason': session.endReason?.name,
        },
        contextTimestamp: DateTime.now(),
      );

      final insights = await _ragService.generateContextualizedResponse(
        userQuery: 'Provide insights and advice based on my fasting session. I ${session.isCompleted ? 'completed' : 'ended'} a ${session.typeDescription} with ${(session.completionPercentage * 100).toInt()}% completion.',
        healthContext: healthContext,
        maxContextLength: 2000,
      );

      if (insights != null) {
        // Store insights in session metadata
        final updatedSession = session.copyWith(
          metadata: {
            ...session.metadata,
            'ai_insights': insights,
            'insights_generated_at': DateTime.now().toIso8601String(),
          },
        );

        await _firestore
            .collection('fasting_sessions')
            .doc(session.id)
            .update(updatedSession.toFirestore());
      }
    } catch (e) {
      print('Error generating session insights: $e');
    }
  }

  /// Get fasting settings for app-wide configuration
  Future<Map<String, dynamic>> getFastingSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final doc = await _firestore
          .collection('user_settings')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['fasting_settings'] ?? {};
      }

      // Return default settings
      return {
        'filterSeverity': 'moderate',
        'showMotivationalContent': true,
        'enableNotifications': true,
        'enableProgressSharing': false,
      };
    } catch (e) {
      print('Error getting fasting settings: $e');
      return {
        'filterSeverity': 'moderate',
        'showMotivationalContent': true,
        'enableNotifications': true,
        'enableProgressSharing': false,
      };
    }
  }

  /// Update fasting settings
  Future<void> updateFastingSettings(Map<String, dynamic> settings) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('user_settings')
          .doc(user.uid)
          .set({
        'fasting_settings': settings,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating fasting settings: $e');
    }
  }

  /// Get comprehensive fasting statistics for state management
  Future<Map<String, dynamic>> getFastingStatistics() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final sessions = await getFastingHistory(limit: 100);
      
      final completedSessions = sessions.where((s) => s.isCompleted).toList();
      final totalSessions = sessions.length;
      
      final totalFastingTime = sessions.fold<Duration>(
        Duration.zero,
        (total, session) => total + (session.actualDuration ?? Duration.zero),
      );
      
      // Calculate current and longest streaks
      int currentStreak = 0;
      int longestStreak = 0;
      int tempStreak = 0;
      
      // Calculate current streak from most recent sessions
      for (final session in sessions) {
        if (session.isCompleted) {
          if (currentStreak == 0) currentStreak = 1; // Start counting
          tempStreak++;
          longestStreak = max(longestStreak, tempStreak);
        } else {
          if (currentStreak == 0) break; // Only count from most recent completed
          tempStreak = 0;
        }
      }
      
      // Find longest streak start date
      DateTime? longestStreakStart;
      if (longestStreak > 0 && sessions.isNotEmpty) {
        // This is a simplified calculation - in production, you'd want more precise tracking
        longestStreakStart = sessions.first.createdAt;
      }

      return {
        'totalSessions': totalSessions,
        'completedSessions': completedSessions.length,
        'totalFastingSeconds': totalFastingTime.inSeconds,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'longestStreakStart': longestStreakStart?.toIso8601String(),
        'lastSessionDate': sessions.isNotEmpty ? sessions.first.createdAt.toIso8601String() : null,
        'averageDuration': completedSessions.isNotEmpty 
            ? totalFastingTime.inSeconds / completedSessions.length 
            : 0,
        'successRate': totalSessions > 0 ? completedSessions.length / totalSessions : 0.0,
      };
    } catch (e) {
      print('Error getting fasting statistics: $e');
      return {};
    }
  }

  /// Get current session stream for real-time updates
  Stream<FastingSession?> currentSessionStream() {
    return _sessionController.stream;
  }

  /// Pause current fasting session
  Future<bool> pauseFasting() async {
    if (_currentSession == null || !_currentSession!.isActive) {
      return false;
    }

    try {
      final pausedSession = _currentSession!.copyWith(
        isPaused: true,
        pausedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _updateSession(pausedSession);
      _stopTimer();

      return true;
    } catch (e) {
      print('Error pausing fasting session: $e');
      return false;
    }
  }

  /// Resume paused fasting session
  Future<bool> resumeFasting() async {
    if (_currentSession == null || !_currentSession!.isPaused) {
      return false;
    }

    try {
      final resumedSession = _currentSession!.copyWith(
        isPaused: false,
        pausedAt: null,
        updatedAt: DateTime.now(),
      );

      await _updateSession(resumedSession);
      _startTimer();

      return true;
    } catch (e) {
      print('Error resuming fasting session: $e');
      return false;
    }
  }

  /// Get current session (synchronous access)
  Future<FastingSession?> getCurrentSession() async {
    return _currentSession;
  }

  /// End current fasting session with completion status
  Future<bool> endFasting({bool completed = false}) async {
    if (_currentSession == null) return false;

    try {
      final endReason = completed 
          ? FastingEndReason.completed 
          : FastingEndReason.userStopped;

      await endFastingSession(endReason, completed ? 'Session completed' : 'User ended session');
      return true;
    } catch (e) {
      print('Error ending fasting session: $e');
      return false;
    }
  }

  /// Start a fasting session with custom duration support
  Future<bool> startFasting({
    required FastingType type,
    String? personalGoal,
    Duration? customDuration,
  }) async {
    try {
      final duration = customDuration ?? type.duration;
      
      await startFastingSession(
        type,
        personalGoal ?? 'Stay focused and healthy',
        duration,
      );

      return _currentSession != null && _currentSession!.isActive;
    } catch (e) {
      print('Error starting fasting session: $e');
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    _stopTimer();
    _sessionController.close();
  }
} 