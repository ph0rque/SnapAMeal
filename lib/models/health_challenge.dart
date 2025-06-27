import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of health challenges available
enum ChallengeType {
  fasting, // Fasting streak challenges
  steps, // Daily step count challenges
  calories, // Calorie tracking challenges
  workouts, // Exercise frequency challenges
  water, // Water intake challenges
  weight, // Weight loss/maintenance challenges
  meditation, // Mindfulness and wellness challenges
  custom, // User-defined challenges
}

/// Challenge difficulty levels
enum ChallengeDifficulty { beginner, intermediate, advanced, expert }

/// Challenge frequency patterns
enum ChallengeFrequency { daily, weekly, monthly, oneTime }

/// Challenge participation status
enum ParticipationStatus { pending, active, completed, failed, withdrawn }

/// Individual participant data
class ChallengeParticipant {
  final String userId;
  final String displayName;
  final DateTime joinedAt;
  final ParticipationStatus status;
  final Map<String, dynamic> progress;
  final Map<String, dynamic> stats;
  final bool isAnonymous;
  final String? avatarUrl;

  ChallengeParticipant({
    required this.userId,
    required this.displayName,
    required this.joinedAt,
    required this.status,
    required this.progress,
    required this.stats,
    this.isAnonymous = false,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'display_name': displayName,
      'joined_at': Timestamp.fromDate(joinedAt),
      'status': status.name,
      'progress': progress,
      'stats': stats,
      'is_anonymous': isAnonymous,
      'avatar_url': avatarUrl,
    };
  }

  factory ChallengeParticipant.fromMap(Map<String, dynamic> map) {
    return ChallengeParticipant(
      userId: map['user_id'] ?? '',
      displayName: map['display_name'] ?? '',
      joinedAt: (map['joined_at'] as Timestamp).toDate(),
      status: ParticipationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ParticipationStatus.pending,
      ),
      progress: Map<String, dynamic>.from(map['progress'] ?? {}),
      stats: Map<String, dynamic>.from(map['stats'] ?? {}),
      isAnonymous: map['is_anonymous'] ?? false,
      avatarUrl: map['avatar_url'],
    );
  }
}

/// Data model for health challenges
class HealthChallenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeDifficulty difficulty;
  final ChallengeFrequency frequency;
  final String creatorId;
  final List<ChallengeParticipant> participants;
  final Map<String, dynamic> goals;
  final Map<String, dynamic> rules;
  final Map<String, dynamic> rewards;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final bool isPublic;
  final bool allowTeams;
  final int maxParticipants;
  final List<String> tags;
  final String? imageUrl;
  final Map<String, dynamic> leaderboard;
  final Map<String, dynamic> metadata;

  HealthChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.difficulty,
    required this.frequency,
    required this.creatorId,
    required this.participants,
    required this.goals,
    required this.rules,
    required this.rewards,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.isPublic = true,
    this.allowTeams = false,
    this.maxParticipants = 100,
    this.tags = const [],
    this.imageUrl,
    this.leaderboard = const {},
    this.metadata = const {},
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type.name,
      'difficulty': difficulty.name,
      'frequency': frequency.name,
      'creator_id': creatorId,
      'participants': participants.map((p) => p.toMap()).toList(),
      'goals': goals,
      'rules': rules,
      'rewards': rewards,
      'start_date': Timestamp.fromDate(startDate),
      'end_date': Timestamp.fromDate(endDate),
      'created_at': Timestamp.fromDate(createdAt),
      'is_public': isPublic,
      'allow_teams': allowTeams,
      'max_participants': maxParticipants,
      'tags': tags,
      'image_url': imageUrl,
      'leaderboard': leaderboard,
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory HealthChallenge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return HealthChallenge(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: ChallengeType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ChallengeType.custom,
      ),
      difficulty: ChallengeDifficulty.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => ChallengeDifficulty.beginner,
      ),
      frequency: ChallengeFrequency.values.firstWhere(
        (e) => e.name == data['frequency'],
        orElse: () => ChallengeFrequency.daily,
      ),
      creatorId: data['creator_id'] ?? '',
      participants:
          (data['participants'] as List<dynamic>?)
              ?.map((p) => ChallengeParticipant.fromMap(p))
              .toList() ??
          [],
      goals: Map<String, dynamic>.from(data['goals'] ?? {}),
      rules: Map<String, dynamic>.from(data['rules'] ?? {}),
      rewards: Map<String, dynamic>.from(data['rewards'] ?? {}),
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: (data['end_date'] as Timestamp).toDate(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      isPublic: data['is_public'] ?? true,
      allowTeams: data['allow_teams'] ?? false,
      maxParticipants: data['max_participants'] ?? 100,
      tags: List<String>.from(data['tags'] ?? []),
      imageUrl: data['image_url'],
      leaderboard: Map<String, dynamic>.from(data['leaderboard'] ?? {}),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Get display text for challenge type
  String get typeDisplayName {
    switch (type) {
      case ChallengeType.fasting:
        return 'Fasting Challenge';
      case ChallengeType.steps:
        return 'Step Challenge';
      case ChallengeType.calories:
        return 'Calorie Challenge';
      case ChallengeType.workouts:
        return 'Workout Challenge';
      case ChallengeType.water:
        return 'Hydration Challenge';
      case ChallengeType.weight:
        return 'Weight Challenge';
      case ChallengeType.meditation:
        return 'Mindfulness Challenge';
      case ChallengeType.custom:
        return 'Custom Challenge';
    }
  }

  /// Get icon for challenge type
  String get typeIcon {
    switch (type) {
      case ChallengeType.fasting:
        return '⏰';
      case ChallengeType.steps:
        return '👟';
      case ChallengeType.calories:
        return '🔥';
      case ChallengeType.workouts:
        return '💪';
      case ChallengeType.water:
        return '💧';
      case ChallengeType.weight:
        return '⚖️';
      case ChallengeType.meditation:
        return '🧘';
      case ChallengeType.custom:
        return '🎯';
    }
  }

  /// Get difficulty color
  String get difficultyColor {
    switch (difficulty) {
      case ChallengeDifficulty.beginner:
        return '#4CAF50'; // Green
      case ChallengeDifficulty.intermediate:
        return '#FF9800'; // Orange
      case ChallengeDifficulty.advanced:
        return '#F44336'; // Red
      case ChallengeDifficulty.expert:
        return '#9C27B0'; // Purple
    }
  }

  /// Check if challenge is active
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Check if challenge has started
  bool get hasStarted => DateTime.now().isAfter(startDate);

  /// Check if challenge has ended
  bool get hasEnded => DateTime.now().isAfter(endDate);

  /// Check if user is participating
  bool isParticipating(String userId) {
    return participants.any((p) => p.userId == userId);
  }

  /// Check if challenge is full
  bool get isFull => participants.length >= maxParticipants;

  /// Get participant count
  int get participantCount => participants.length;

  /// Get active participant count
  int get activeParticipantCount {
    return participants
        .where((p) => p.status == ParticipationStatus.active)
        .length;
  }

  /// Get challenge duration in days
  int get durationInDays => endDate.difference(startDate).inDays;

  /// Get remaining days
  int get remainingDays {
    if (hasEnded) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (!hasStarted) return 0.0;
    if (hasEnded) return 1.0;

    final totalDuration = endDate.difference(startDate).inMilliseconds;
    final elapsed = DateTime.now().difference(startDate).inMilliseconds;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }
}
