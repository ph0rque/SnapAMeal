import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents the current state of a fasting session
enum FastingState {
  notStarted,
  active,
  paused,
  completed,
  broken,
}

/// Represents different types of fasting protocols
enum FastingType {
  intermittent16_8,    // 16:8 - 16 hours fasting, 8 hours eating
  intermittent18_6,    // 18:6 - 18 hours fasting, 6 hours eating
  intermittent20_4,    // 20:4 - 20 hours fasting, 4 hours eating
  omad,                // One Meal A Day - 23:1
  alternate,           // Alternate Day Fasting
  extended24,          // 24-hour fast
  extended36,          // 36-hour fast
  extended48,          // 48-hour fast
  custom,              // User-defined duration
}

/// Represents how a fasting session was ended
enum FastingEndReason {
  completed,           // Successfully completed the planned duration
  userBreak,          // User intentionally broke the fast
  emergencyBreak,     // Emergency situation required breaking
  appError,           // Technical issue caused session to end
}

/// Tracks motivational content shown during fasting
class FastingMotivation {
  final String id;
  final String type;           // 'quote', 'tip', 'milestone', 'encouragement'
  final String content;
  final DateTime shownAt;
  final bool wasHelpful;       // User feedback

  FastingMotivation({
    required this.id,
    required this.type,
    required this.content,
    required this.shownAt,
    this.wasHelpful = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'content': content,
      'shown_at': shownAt.toIso8601String(),
      'was_helpful': wasHelpful,
    };
  }

  factory FastingMotivation.fromJson(Map<String, dynamic> json) {
    return FastingMotivation(
      id: json['id'],
      type: json['type'],
      content: json['content'],
      shownAt: DateTime.parse(json['shown_at']),
      wasHelpful: json['was_helpful'] ?? false,
    );
  }
}

/// Tracks user interactions and engagement during fasting
class FastingEngagement {
  final int snapsTaken;
  final int motivationViews;
  final int appOpens;
  final int timerChecks;
  final List<String> challengesMet;     // Achievement IDs
  final Map<String, int> featureUsage;  // Feature name -> usage count
  final Duration totalAppTime;

  FastingEngagement({
    this.snapsTaken = 0,
    this.motivationViews = 0,
    this.appOpens = 0,
    this.timerChecks = 0,
    this.challengesMet = const [],
    this.featureUsage = const {},
    this.totalAppTime = Duration.zero,
  });

  Map<String, dynamic> toJson() {
    return {
      'snaps_taken': snapsTaken,
      'motivation_views': motivationViews,
      'app_opens': appOpens,
      'timer_checks': timerChecks,
      'challenges_met': challengesMet,
      'feature_usage': featureUsage,
      'total_app_time_ms': totalAppTime.inMilliseconds,
    };
  }

  factory FastingEngagement.fromJson(Map<String, dynamic> json) {
    return FastingEngagement(
      snapsTaken: json['snaps_taken'] ?? 0,
      motivationViews: json['motivation_views'] ?? 0,
      appOpens: json['app_opens'] ?? 0,
      timerChecks: json['timer_checks'] ?? 0,
      challengesMet: List<String>.from(json['challenges_met'] ?? []),
      featureUsage: Map<String, int>.from(json['feature_usage'] ?? {}),
      totalAppTime: Duration(milliseconds: json['total_app_time_ms'] ?? 0),
    );
  }

  /// Create a copy with updated values
  FastingEngagement copyWith({
    int? snapsTaken,
    int? motivationViews,
    int? appOpens,
    int? timerChecks,
    List<String>? challengesMet,
    Map<String, int>? featureUsage,
    Duration? totalAppTime,
  }) {
    return FastingEngagement(
      snapsTaken: snapsTaken ?? this.snapsTaken,
      motivationViews: motivationViews ?? this.motivationViews,
      appOpens: appOpens ?? this.appOpens,
      timerChecks: timerChecks ?? this.timerChecks,
      challengesMet: challengesMet ?? this.challengesMet,
      featureUsage: featureUsage ?? this.featureUsage,
      totalAppTime: totalAppTime ?? this.totalAppTime,
    );
  }
}

/// Comprehensive model for a fasting session with full state tracking
class FastingSession {
  final String id;
  final String userId;
  final FastingType type;
  final FastingState state;
  
  // Timing information
  final DateTime? plannedStartTime;
  final DateTime? actualStartTime;
  final DateTime? plannedEndTime;
  final DateTime? actualEndTime;
  final Duration plannedDuration;
  final Duration? actualDuration;
  
  // Session management
  final List<DateTime> pausedTimes;      // When session was paused
  final List<DateTime> resumedTimes;     // When session was resumed
  final Duration totalPausedDuration;
  
  // Goals and progress
  final String? personalGoal;            // User's personal goal for this session
  final double? targetWeight;            // Weight goal if applicable
  final List<String> motivationalTags;   // Tags like 'discipline', 'health', etc.
  
  // Completion tracking
  final FastingEndReason? endReason;
  final String? endNotes;               // User notes about ending the session
  final double completionPercentage;    // How much of planned duration was completed
  
  // Content and engagement
  final List<FastingMotivation> motivationShown;
  final FastingEngagement engagement;
  final List<String> snapIds;          // IDs of snaps taken during fasting
  
  // Health integration
  final Map<String, dynamic> healthMetrics;  // Heart rate, steps, sleep, etc.
  final List<String> symptomsReported;       // 'hunger', 'fatigue', 'clarity', etc.
  final int moodRating;                      // 1-10 scale
  final String? reflectionNotes;             // Post-session reflection
  
  // Streak and pattern tracking
  final int currentStreak;              // Current consecutive successful fasts
  final int longestStreak;              // Longest streak achieved
  final bool isPersonalBest;           // Is this the longest fast for the user?
  
  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;  // Additional flexible data

  FastingSession({
    required this.id,
    required this.userId,
    required this.type,
    required this.state,
    this.plannedStartTime,
    this.actualStartTime,
    this.plannedEndTime,
    this.actualEndTime,
    required this.plannedDuration,
    this.actualDuration,
    this.pausedTimes = const [],
    this.resumedTimes = const [],
    this.totalPausedDuration = Duration.zero,
    this.personalGoal,
    this.targetWeight,
    this.motivationalTags = const [],
    this.endReason,
    this.endNotes,
    this.completionPercentage = 0.0,
    this.motivationShown = const [],
    this.engagement = const FastingEngagement(),
    this.snapIds = const [],
    this.healthMetrics = const {},
    this.symptomsReported = const [],
    this.moodRating = 5,
    this.reflectionNotes,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.isPersonalBest = false,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'state': state.name,
      'planned_start_time': plannedStartTime?.toIso8601String(),
      'actual_start_time': actualStartTime?.toIso8601String(),
      'planned_end_time': plannedEndTime?.toIso8601String(),
      'actual_end_time': actualEndTime?.toIso8601String(),
      'planned_duration_ms': plannedDuration.inMilliseconds,
      'actual_duration_ms': actualDuration?.inMilliseconds,
      'paused_times': pausedTimes.map((t) => t.toIso8601String()).toList(),
      'resumed_times': resumedTimes.map((t) => t.toIso8601String()).toList(),
      'total_paused_duration_ms': totalPausedDuration.inMilliseconds,
      'personal_goal': personalGoal,
      'target_weight': targetWeight,
      'motivational_tags': motivationalTags,
      'end_reason': endReason?.name,
      'end_notes': endNotes,
      'completion_percentage': completionPercentage,
      'motivation_shown': motivationShown.map((m) => m.toJson()).toList(),
      'engagement': engagement.toJson(),
      'snap_ids': snapIds,
      'health_metrics': healthMetrics,
      'symptoms_reported': symptomsReported,
      'mood_rating': moodRating,
      'reflection_notes': reflectionNotes,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'is_personal_best': isPersonalBest,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON (Firestore document)
  factory FastingSession.fromJson(Map<String, dynamic> json) {
    return FastingSession(
      id: json['id'],
      userId: json['user_id'],
      type: FastingType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => FastingType.intermittent16_8,
      ),
      state: FastingState.values.firstWhere(
        (s) => s.name == json['state'],
        orElse: () => FastingState.notStarted,
      ),
      plannedStartTime: json['planned_start_time'] != null 
          ? DateTime.parse(json['planned_start_time']) 
          : null,
      actualStartTime: json['actual_start_time'] != null 
          ? DateTime.parse(json['actual_start_time']) 
          : null,
      plannedEndTime: json['planned_end_time'] != null 
          ? DateTime.parse(json['planned_end_time']) 
          : null,
      actualEndTime: json['actual_end_time'] != null 
          ? DateTime.parse(json['actual_end_time']) 
          : null,
      plannedDuration: Duration(milliseconds: json['planned_duration_ms'] ?? 0),
      actualDuration: json['actual_duration_ms'] != null 
          ? Duration(milliseconds: json['actual_duration_ms']) 
          : null,
      pausedTimes: (json['paused_times'] as List<dynamic>?)
          ?.map((t) => DateTime.parse(t))
          .toList() ?? [],
      resumedTimes: (json['resumed_times'] as List<dynamic>?)
          ?.map((t) => DateTime.parse(t))
          .toList() ?? [],
      totalPausedDuration: Duration(milliseconds: json['total_paused_duration_ms'] ?? 0),
      personalGoal: json['personal_goal'],
      targetWeight: json['target_weight']?.toDouble(),
      motivationalTags: List<String>.from(json['motivational_tags'] ?? []),
      endReason: json['end_reason'] != null 
          ? FastingEndReason.values.firstWhere(
              (r) => r.name == json['end_reason'],
              orElse: () => FastingEndReason.userBreak,
            )
          : null,
      endNotes: json['end_notes'],
      completionPercentage: json['completion_percentage']?.toDouble() ?? 0.0,
      motivationShown: (json['motivation_shown'] as List<dynamic>?)
          ?.map((m) => FastingMotivation.fromJson(m))
          .toList() ?? [],
      engagement: json['engagement'] != null 
          ? FastingEngagement.fromJson(json['engagement'])
          : FastingEngagement(),
      snapIds: List<String>.from(json['snap_ids'] ?? []),
      healthMetrics: Map<String, dynamic>.from(json['health_metrics'] ?? {}),
      symptomsReported: List<String>.from(json['symptoms_reported'] ?? []),
      moodRating: json['mood_rating'] ?? 5,
      reflectionNotes: json['reflection_notes'],
      currentStreak: json['current_streak'] ?? 0,
      longestStreak: json['longest_streak'] ?? 0,
      isPersonalBest: json['is_personal_best'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Create from Firestore DocumentSnapshot
  factory FastingSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    data['id'] = doc.id;
    return FastingSession.fromJson(data);
  }

  /// Convert to Firestore document data (without ID)
  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data.remove('id'); // Firestore handles document ID separately
    return data;
  }

  /// Create a copy with updated fields
  FastingSession copyWith({
    String? id,
    String? userId,
    FastingType? type,
    FastingState? state,
    DateTime? plannedStartTime,
    DateTime? actualStartTime,
    DateTime? plannedEndTime,
    DateTime? actualEndTime,
    Duration? plannedDuration,
    Duration? actualDuration,
    List<DateTime>? pausedTimes,
    List<DateTime>? resumedTimes,
    Duration? totalPausedDuration,
    String? personalGoal,
    double? targetWeight,
    List<String>? motivationalTags,
    FastingEndReason? endReason,
    String? endNotes,
    double? completionPercentage,
    List<FastingMotivation>? motivationShown,
    FastingEngagement? engagement,
    List<String>? snapIds,
    Map<String, dynamic>? healthMetrics,
    List<String>? symptomsReported,
    int? moodRating,
    String? reflectionNotes,
    int? currentStreak,
    int? longestStreak,
    bool? isPersonalBest,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return FastingSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      state: state ?? this.state,
      plannedStartTime: plannedStartTime ?? this.plannedStartTime,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      plannedEndTime: plannedEndTime ?? this.plannedEndTime,
      actualEndTime: actualEndTime ?? this.actualEndTime,
      plannedDuration: plannedDuration ?? this.plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      pausedTimes: pausedTimes ?? this.pausedTimes,
      resumedTimes: resumedTimes ?? this.resumedTimes,
      totalPausedDuration: totalPausedDuration ?? this.totalPausedDuration,
      personalGoal: personalGoal ?? this.personalGoal,
      targetWeight: targetWeight ?? this.targetWeight,
      motivationalTags: motivationalTags ?? this.motivationalTags,
      endReason: endReason ?? this.endReason,
      endNotes: endNotes ?? this.endNotes,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      motivationShown: motivationShown ?? this.motivationShown,
      engagement: engagement ?? this.engagement,
      snapIds: snapIds ?? this.snapIds,
      healthMetrics: healthMetrics ?? this.healthMetrics,
      symptomsReported: symptomsReported ?? this.symptomsReported,
      moodRating: moodRating ?? this.moodRating,
      reflectionNotes: reflectionNotes ?? this.reflectionNotes,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      isPersonalBest: isPersonalBest ?? this.isPersonalBest,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get the current progress as a percentage (0.0 to 1.0)
  double get progressPercentage {
    if (state == FastingState.notStarted || actualStartTime == null) {
      return 0.0;
    }
    
    final now = DateTime.now();
    final elapsed = now.difference(actualStartTime!);
    final adjustedElapsed = elapsed - totalPausedDuration;
    
    if (adjustedElapsed.inMilliseconds <= 0) return 0.0;
    if (adjustedElapsed >= plannedDuration) return 1.0;
    
    return adjustedElapsed.inMilliseconds / plannedDuration.inMilliseconds;
  }

  /// Get remaining time in the fasting session
  Duration get remainingTime {
    if (state == FastingState.notStarted || actualStartTime == null) {
      return plannedDuration;
    }
    
    if (state == FastingState.completed) {
      return Duration.zero;
    }
    
    final now = DateTime.now();
    final elapsed = now.difference(actualStartTime!);
    final adjustedElapsed = elapsed - totalPausedDuration;
    
    final remaining = plannedDuration - adjustedElapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get elapsed time in the fasting session
  Duration get elapsedTime {
    if (state == FastingState.notStarted || actualStartTime == null) {
      return Duration.zero;
    }
    
    final now = actualEndTime ?? DateTime.now();
    final elapsed = now.difference(actualStartTime!);
    return elapsed - totalPausedDuration;
  }

  /// Check if the session is currently active (not paused, not ended)
  bool get isActive {
    return state == FastingState.active;
  }

  /// Check if the session is paused
  bool get isPaused {
    return state == FastingState.paused;
  }

  /// Check if the session is completed successfully
  bool get isCompleted {
    return state == FastingState.completed && 
           endReason == FastingEndReason.completed;
  }

  /// Check if the session was broken/ended early
  bool get wasBroken {
    return state == FastingState.broken || 
           (state == FastingState.completed && endReason != FastingEndReason.completed);
  }

  /// Get a human-readable description of the fasting type
  String get typeDescription {
    switch (type) {
      case FastingType.intermittent16_8:
        return '16:8 Intermittent Fasting';
      case FastingType.intermittent18_6:
        return '18:6 Intermittent Fasting';
      case FastingType.intermittent20_4:
        return '20:4 Intermittent Fasting';
      case FastingType.omad:
        return 'One Meal A Day (OMAD)';
      case FastingType.alternate:
        return 'Alternate Day Fasting';
      case FastingType.extended24:
        return '24-Hour Extended Fast';
      case FastingType.extended36:
        return '36-Hour Extended Fast';
      case FastingType.extended48:
        return '48-Hour Extended Fast';
      case FastingType.custom:
        return 'Custom Fasting Duration';
    }
  }

  /// Get the standard duration for a fasting type
  static Duration getStandardDuration(FastingType type) {
    switch (type) {
      case FastingType.intermittent16_8:
        return Duration(hours: 16);
      case FastingType.intermittent18_6:
        return Duration(hours: 18);
      case FastingType.intermittent20_4:
        return Duration(hours: 20);
      case FastingType.omad:
        return Duration(hours: 23);
      case FastingType.alternate:
        return Duration(hours: 24);
      case FastingType.extended24:
        return Duration(hours: 24);
      case FastingType.extended36:
        return Duration(hours: 36);
      case FastingType.extended48:
        return Duration(hours: 48);
      case FastingType.custom:
        return Duration(hours: 16); // Default fallback
    }
  }
} 