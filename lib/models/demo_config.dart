import 'package:flutter/foundation.dart';

/// Configuration model for demo mode features and settings
class DemoConfig {
  final bool isEnabled;
  final bool showIndicators;
  final bool enableTours;
  final bool enableTooltips;
  final bool enableReset;
  final bool enableOnboarding;
  final bool enableDataSeeding;
  final bool enableAnalytics;
  final Duration sessionTimeout;
  final Map<String, bool> featureFlags;
  final Map<String, dynamic> customSettings;

  const DemoConfig({
    this.isEnabled = true,
    this.showIndicators = true,
    this.enableTours = true,
    this.enableTooltips = true,
    this.enableReset = true,
    this.enableOnboarding = true,
    this.enableDataSeeding = true,
    this.enableAnalytics = false,
    this.sessionTimeout = const Duration(hours: 2),
    this.featureFlags = const {},
    this.customSettings = const {},
  });

  /// Create a copy with modified values
  DemoConfig copyWith({
    bool? isEnabled,
    bool? showIndicators,
    bool? enableTours,
    bool? enableTooltips,
    bool? enableReset,
    bool? enableOnboarding,
    bool? enableDataSeeding,
    bool? enableAnalytics,
    Duration? sessionTimeout,
    Map<String, bool>? featureFlags,
    Map<String, dynamic>? customSettings,
  }) {
    return DemoConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      showIndicators: showIndicators ?? this.showIndicators,
      enableTours: enableTours ?? this.enableTours,
      enableTooltips: enableTooltips ?? this.enableTooltips,
      enableReset: enableReset ?? this.enableReset,
      enableOnboarding: enableOnboarding ?? this.enableOnboarding,
      enableDataSeeding: enableDataSeeding ?? this.enableDataSeeding,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      sessionTimeout: sessionTimeout ?? this.sessionTimeout,
      featureFlags: featureFlags ?? this.featureFlags,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'showIndicators': showIndicators,
      'enableTours': enableTours,
      'enableTooltips': enableTooltips,
      'enableReset': enableReset,
      'enableOnboarding': enableOnboarding,
      'enableDataSeeding': enableDataSeeding,
      'enableAnalytics': enableAnalytics,
      'sessionTimeoutMinutes': sessionTimeout.inMinutes,
      'featureFlags': featureFlags,
      'customSettings': customSettings,
    };
  }

  /// Create from JSON
  factory DemoConfig.fromJson(Map<String, dynamic> json) {
    return DemoConfig(
      isEnabled: json['isEnabled'] ?? true,
      showIndicators: json['showIndicators'] ?? true,
      enableTours: json['enableTours'] ?? true,
      enableTooltips: json['enableTooltips'] ?? true,
      enableReset: json['enableReset'] ?? true,
      enableOnboarding: json['enableOnboarding'] ?? true,
      enableDataSeeding: json['enableDataSeeding'] ?? true,
      enableAnalytics: json['enableAnalytics'] ?? false,
      sessionTimeout: Duration(minutes: json['sessionTimeoutMinutes'] ?? 120),
      featureFlags: Map<String, bool>.from(json['featureFlags'] ?? {}),
      customSettings: Map<String, dynamic>.from(json['customSettings'] ?? {}),
    );
  }

  /// Check if a specific feature is enabled
  bool isFeatureEnabled(String featureKey) {
    return featureFlags[featureKey] ?? false;
  }

  /// Get a custom setting value
  T? getCustomSetting<T>(String key, [T? defaultValue]) {
    final value = customSettings[key];
    if (value is T) return value;
    return defaultValue;
  }

  /// Default configuration for investor demos
  static const DemoConfig investor = DemoConfig(
    isEnabled: true,
    showIndicators: true,
    enableTours: true,
    enableTooltips: true,
    enableReset: true,
    enableOnboarding: true,
    enableDataSeeding: true,
    enableAnalytics: true,
    sessionTimeout: Duration(hours: 4),
    featureFlags: {
      'showAIInsights': true,
      'enableRAGTooltips': true,
      'showTechnicalDetails': true,
      'enableMetrics': true,
      'showPerformanceStats': true,
    },
  );

  /// Configuration for user testing
  static const DemoConfig userTesting = DemoConfig(
    isEnabled: true,
    showIndicators: false,
    enableTours: false,
    enableTooltips: false,
    enableReset: true,
    enableOnboarding: false,
    enableDataSeeding: true,
    enableAnalytics: true,
    sessionTimeout: Duration(minutes: 30),
    featureFlags: {
      'hideComplexFeatures': true,
      'simplifiedUI': true,
      'focusedFlow': true,
    },
  );

  /// Minimal configuration for development
  static const DemoConfig development = DemoConfig(
    isEnabled: true,
    showIndicators: true,
    enableTours: false,
    enableTooltips: false,
    enableReset: true,
    enableOnboarding: false,
    enableDataSeeding: false,
    enableAnalytics: false,
    sessionTimeout: Duration(hours: 8),
    featureFlags: {'debugMode': true, 'showInternalMetrics': true},
  );

  /// Disabled configuration
  static const DemoConfig disabled = DemoConfig(
    isEnabled: false,
    showIndicators: false,
    enableTours: false,
    enableTooltips: false,
    enableReset: false,
    enableOnboarding: false,
    enableDataSeeding: false,
    enableAnalytics: false,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DemoConfig &&
        other.isEnabled == isEnabled &&
        other.showIndicators == showIndicators &&
        other.enableTours == enableTours &&
        other.enableTooltips == enableTooltips &&
        other.enableReset == enableReset &&
        other.enableOnboarding == enableOnboarding &&
        other.enableDataSeeding == enableDataSeeding &&
        other.enableAnalytics == enableAnalytics &&
        other.sessionTimeout == sessionTimeout &&
        mapEquals(other.featureFlags, featureFlags) &&
        mapEquals(other.customSettings, customSettings);
  }

  @override
  int get hashCode {
    return Object.hash(
      isEnabled,
      showIndicators,
      enableTours,
      enableTooltips,
      enableReset,
      enableOnboarding,
      enableDataSeeding,
      enableAnalytics,
      sessionTimeout,
      featureFlags,
      customSettings,
    );
  }

  @override
  String toString() {
    return 'DemoConfig(isEnabled: $isEnabled, showIndicators: $showIndicators, '
        'enableTours: $enableTours, enableTooltips: $enableTooltips, '
        'enableReset: $enableReset, enableOnboarding: $enableOnboarding, '
        'enableDataSeeding: $enableDataSeeding, enableAnalytics: $enableAnalytics, '
        'sessionTimeout: $sessionTimeout, featureFlags: $featureFlags, '
        'customSettings: $customSettings)';
  }
}

/// Demo session information
class DemoSession {
  final String sessionId;
  final String? personaId;
  final DateTime startTime;
  final DateTime? endTime;
  final DemoConfig config;
  final Map<String, dynamic> metadata;

  const DemoSession({
    required this.sessionId,
    this.personaId,
    required this.startTime,
    this.endTime,
    required this.config,
    this.metadata = const {},
  });

  /// Check if session is active
  bool get isActive => endTime == null;

  /// Get session duration
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Check if session has expired
  bool get isExpired {
    if (!isActive) return true;
    return duration >= config.sessionTimeout;
  }

  /// End the session
  DemoSession end() {
    return DemoSession(
      sessionId: sessionId,
      personaId: personaId,
      startTime: startTime,
      endTime: DateTime.now(),
      config: config,
      metadata: metadata,
    );
  }

  /// Add metadata
  DemoSession withMetadata(String key, dynamic value) {
    final newMetadata = Map<String, dynamic>.from(metadata);
    newMetadata[key] = value;
    return DemoSession(
      sessionId: sessionId,
      personaId: personaId,
      startTime: startTime,
      endTime: endTime,
      config: config,
      metadata: newMetadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'personaId': personaId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'config': config.toJson(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory DemoSession.fromJson(Map<String, dynamic> json) {
    return DemoSession(
      sessionId: json['sessionId'],
      personaId: json['personaId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      config: DemoConfig.fromJson(json['config']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

/// Demo analytics event
class DemoAnalyticsEvent {
  final String eventType;
  final DateTime timestamp;
  final String? personaId;
  final String? sessionId;
  final Map<String, dynamic> properties;

  const DemoAnalyticsEvent({
    required this.eventType,
    required this.timestamp,
    this.personaId,
    this.sessionId,
    this.properties = const {},
  });

  /// Common event types
  static const String sessionStart = 'demo_session_start';
  static const String sessionEnd = 'demo_session_end';
  static const String featureInteraction = 'demo_feature_interaction';
  static const String tourStart = 'demo_tour_start';
  static const String tourComplete = 'demo_tour_complete';
  static const String tooltipView = 'demo_tooltip_view';
  static const String resetTriggered = 'demo_reset_triggered';
  static const String onboardingComplete = 'demo_onboarding_complete';

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'eventType': eventType,
      'timestamp': timestamp.toIso8601String(),
      'personaId': personaId,
      'sessionId': sessionId,
      'properties': properties,
    };
  }

  /// Create from JSON
  factory DemoAnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return DemoAnalyticsEvent(
      eventType: json['eventType'],
      timestamp: DateTime.parse(json['timestamp']),
      personaId: json['personaId'],
      sessionId: json['sessionId'],
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    );
  }
}
