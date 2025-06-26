import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/demo_config.dart';
import 'auth_service.dart';
import 'demo_tour_service.dart';

/// Service for managing demo sessions, state, and persistence
class DemoSessionService {
  static DemoSessionService? _instance;
  static DemoSessionService get instance => _instance ??= DemoSessionService._();
  
  DemoSessionService._();

  static const String _sessionKey = 'demo_session';
  static const String _configKey = 'demo_config';
  static const String _analyticsKey = 'demo_analytics';

  DemoSession? _currentSession;
  DemoConfig _currentConfig = DemoConfig.investor;
  final List<DemoAnalyticsEvent> _analyticsBuffer = [];

  /// Get current demo session
  DemoSession? get currentSession => _currentSession;

  /// Get current demo configuration
  DemoConfig get currentConfig => _currentConfig;

  /// Check if demo mode is active
  Future<bool> get isDemoActive async {
    final isDemo = await AuthService().isCurrentUserDemo();
    return isDemo && _currentSession != null && _currentSession!.isActive;
  }

  /// Initialize demo session service
  Future<void> initialize() async {
    await _loadPersistedSession();
    await _loadPersistedConfig();
    await _loadPersistedAnalytics();
  }

  /// Start a new demo session
  Future<DemoSession> startSession({
    String? personaId,
    DemoConfig? config,
  }) async {
    // End any existing session
    await endCurrentSession();

    // Determine persona ID
    personaId ??= await AuthService().getCurrentDemoPersonaId();
    
    // Use provided config or current config
    final sessionConfig = config ?? _currentConfig;

    // Create new session
    final session = DemoSession(
      sessionId: _generateSessionId(),
      personaId: personaId,
      startTime: DateTime.now(),
      config: sessionConfig,
    );

    _currentSession = session;
    _currentConfig = sessionConfig;

    // Persist session
    await _persistSession();
    await _persistConfig();

    // Track analytics
    await _trackEvent(DemoAnalyticsEvent(
      eventType: DemoAnalyticsEvent.sessionStart,
      timestamp: DateTime.now(),
      personaId: personaId,
      sessionId: session.sessionId,
      properties: {
        'config': sessionConfig.toJson(),
      },
    ));

    debugPrint('🎬 Demo session started: ${session.sessionId}');
    return session;
  }

  /// End current demo session
  Future<void> endCurrentSession() async {
    if (_currentSession == null || !_currentSession!.isActive) return;

    final endedSession = _currentSession!.end();
    _currentSession = endedSession;

    // Track analytics
    await _trackEvent(DemoAnalyticsEvent(
      eventType: DemoAnalyticsEvent.sessionEnd,
      timestamp: DateTime.now(),
      personaId: endedSession.personaId,
      sessionId: endedSession.sessionId,
      properties: {
        'duration': endedSession.duration.inMinutes,
        'expired': endedSession.isExpired,
      },
    ));

    // Persist final session state
    await _persistSession();

    debugPrint('🎬 Demo session ended: ${endedSession.sessionId} (${endedSession.duration.inMinutes}m)');
  }

  /// Update current configuration
  Future<void> updateConfig(DemoConfig newConfig) async {
    _currentConfig = newConfig;
    
    // Update current session config if active
    if (_currentSession != null && _currentSession!.isActive) {
      _currentSession = DemoSession(
        sessionId: _currentSession!.sessionId,
        personaId: _currentSession!.personaId,
        startTime: _currentSession!.startTime,
        endTime: _currentSession!.endTime,
        config: newConfig,
        metadata: _currentSession!.metadata,
      );
      await _persistSession();
    }

    await _persistConfig();
    debugPrint('⚙️ Demo config updated: ${newConfig.toString()}');
  }

  /// Add metadata to current session
  Future<void> addSessionMetadata(String key, dynamic value) async {
    if (_currentSession == null) return;

    _currentSession = _currentSession!.withMetadata(key, value);
    await _persistSession();
  }

  /// Check if session has expired and handle accordingly
  Future<void> checkSessionExpiry() async {
    if (_currentSession == null || !_currentSession!.isActive) return;

    if (_currentSession!.isExpired) {
      debugPrint('⏰ Demo session expired, ending session');
      await endCurrentSession();
    }
  }

  /// Reset demo session and state
  Future<void> resetSession() async {
    await endCurrentSession();
    await _clearPersistedData();
    
    // Reset tours
    await DemoTourService.resetAllTours();
    
    debugPrint('🔄 Demo session reset completed');
  }

  /// Track demo analytics event
  Future<void> trackEvent(String eventType, {
    Map<String, dynamic>? properties,
  }) async {
    if (!_currentConfig.enableAnalytics) return;

    final event = DemoAnalyticsEvent(
      eventType: eventType,
      timestamp: DateTime.now(),
      personaId: _currentSession?.personaId,
      sessionId: _currentSession?.sessionId,
      properties: properties ?? {},
    );

    await _trackEvent(event);
  }

  /// Track feature interaction
  Future<void> trackFeatureInteraction(String featureName, {
    Map<String, dynamic>? additionalData,
  }) async {
    await trackEvent(DemoAnalyticsEvent.featureInteraction, properties: {
      'featureName': featureName,
      'timestamp': DateTime.now().toIso8601String(),
      ...?additionalData,
    });
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    if (_currentSession == null) return {};

    return {
      'sessionId': _currentSession!.sessionId,
      'personaId': _currentSession!.personaId,
      'duration': _currentSession!.duration.inMinutes,
      'isActive': _currentSession!.isActive,
      'isExpired': _currentSession!.isExpired,
      'config': _currentSession!.config.toJson(),
      'metadata': _currentSession!.metadata,
      'analyticsEvents': _analyticsBuffer.length,
    };
  }

  /// Get analytics summary
  Map<String, dynamic> getAnalyticsSummary() {
    final events = _analyticsBuffer;
    final eventTypes = <String, int>{};
    final features = <String, int>{};

    for (final event in events) {
      eventTypes[event.eventType] = (eventTypes[event.eventType] ?? 0) + 1;
      
      if (event.eventType == DemoAnalyticsEvent.featureInteraction) {
        final featureName = event.properties['featureName'] as String?;
        if (featureName != null) {
          features[featureName] = (features[featureName] ?? 0) + 1;
        }
      }
    }

    return {
      'totalEvents': events.length,
      'eventTypes': eventTypes,
      'featureInteractions': features,
      'sessionCount': eventTypes[DemoAnalyticsEvent.sessionStart] ?? 0,
    };
  }

  /// Export analytics data
  List<Map<String, dynamic>> exportAnalytics() {
    return _analyticsBuffer.map((event) => event.toJson()).toList();
  }

  /// Clear analytics data
  Future<void> clearAnalytics() async {
    _analyticsBuffer.clear();
    await _persistAnalytics();
  }

  // Private methods

  String _generateSessionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(9999).toString().padLeft(4, '0');
    return 'demo_${timestamp}_$randomSuffix';
  }

  Future<void> _trackEvent(DemoAnalyticsEvent event) async {
    _analyticsBuffer.add(event);
    
    // Keep buffer size manageable
    if (_analyticsBuffer.length > 1000) {
      _analyticsBuffer.removeRange(0, 100);
    }

    await _persistAnalytics();
    debugPrint('📊 Analytics: ${event.eventType}');
  }

  Future<void> _persistSession() async {
    if (_currentSession == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = json.encode(_currentSession!.toJson());
      await prefs.setString(_sessionKey, sessionJson);
    } catch (e) {
      debugPrint('❌ Failed to persist demo session: $e');
    }
  }

  Future<void> _persistConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = json.encode(_currentConfig.toJson());
      await prefs.setString(_configKey, configJson);
    } catch (e) {
      debugPrint('❌ Failed to persist demo config: $e');
    }
  }

  Future<void> _persistAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsJson = json.encode(
        _analyticsBuffer.map((event) => event.toJson()).toList(),
      );
      await prefs.setString(_analyticsKey, analyticsJson);
    } catch (e) {
      debugPrint('❌ Failed to persist demo analytics: $e');
    }
  }

  Future<void> _loadPersistedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionJson = prefs.getString(_sessionKey);
      
      if (sessionJson != null) {
        final sessionData = json.decode(sessionJson) as Map<String, dynamic>;
        _currentSession = DemoSession.fromJson(sessionData);
        
        // Check if session is still valid
        if (_currentSession!.isExpired) {
          _currentSession = _currentSession!.end();
          await _persistSession();
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to load persisted demo session: $e');
    }
  }

  Future<void> _loadPersistedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);
      
      if (configJson != null) {
        final configData = json.decode(configJson) as Map<String, dynamic>;
        _currentConfig = DemoConfig.fromJson(configData);
      }
    } catch (e) {
      debugPrint('❌ Failed to load persisted demo config: $e');
    }
  }

  Future<void> _loadPersistedAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyticsJson = prefs.getString(_analyticsKey);
      
      if (analyticsJson != null) {
        final analyticsList = json.decode(analyticsJson) as List<dynamic>;
        _analyticsBuffer.clear();
        _analyticsBuffer.addAll(
          analyticsList.map((data) => DemoAnalyticsEvent.fromJson(data)),
        );
      }
    } catch (e) {
      debugPrint('❌ Failed to load persisted demo analytics: $e');
    }
  }

  Future<void> _clearPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_configKey);
      await prefs.remove(_analyticsKey);
      
      _currentSession = null;
      _currentConfig = DemoConfig.investor;
      _analyticsBuffer.clear();
    } catch (e) {
      debugPrint('❌ Failed to clear persisted demo data: $e');
    }
  }
}

/// Extension for easy demo session access
extension DemoSessionExtension on BuildContext {
  /// Get the demo session service
  DemoSessionService get demoSession => DemoSessionService.instance;
  
  /// Check if currently in an active demo session
  Future<bool> get isInDemoSession async {
    return await DemoSessionService.instance.isDemoActive;
  }
  
  /// Track a demo feature interaction
  Future<void> trackDemoInteraction(String featureName, {
    Map<String, dynamic>? data,
  }) async {
    await DemoSessionService.instance.trackFeatureInteraction(
      featureName,
      additionalData: data,
    );
  }
} 