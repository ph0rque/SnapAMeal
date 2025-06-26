import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of health-focused groups available in the app
enum HealthGroupType {
  fasting,        // Intermittent fasting support groups
  calorieGoals,   // Calorie tracking and weight management
  workoutBuddies, // Exercise and fitness accountability
  nutrition,      // Healthy eating and meal planning
  wellness,       // General wellness and mental health
  challenges,     // Fitness challenges and competitions
  support,        // General health support and motivation
  recipes,        // Healthy recipe sharing
}

/// Privacy levels for health groups
enum HealthGroupPrivacy {
  public,    // Anyone can join and see content
  private,   // Invite-only, content visible to members
  anonymous, // Members can share anonymously
}

/// Activity levels for health groups
enum HealthGroupActivity {
  high,      // Very active (multiple posts daily)
  medium,    // Moderately active (few posts daily)
  low,       // Less active (few posts weekly)
  inactive,  // No recent activity
}

/// Data model for health-focused groups
class HealthGroup {
  final String id;
  final String name;
  final String description;
  final HealthGroupType type;
  final HealthGroupPrivacy privacy;
  final String creatorId;
  final List<String> memberIds;
  final List<String> adminIds;
  final List<String> tags;
  final Map<String, dynamic> groupGoals;
  final Map<String, dynamic> groupStats;
  final HealthGroupActivity activityLevel;
  final DateTime createdAt;
  final DateTime lastActivity;
  final int maxMembers;
  final bool allowAnonymous;
  final bool requireApproval;
  final String? imageUrl;
  final Map<String, dynamic> metadata;

  HealthGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.privacy,
    required this.creatorId,
    required this.memberIds,
    required this.adminIds,
    required this.tags,
    required this.groupGoals,
    required this.groupStats,
    required this.activityLevel,
    required this.createdAt,
    required this.lastActivity,
    this.maxMembers = 50,
    this.allowAnonymous = false,
    this.requireApproval = false,
    this.imageUrl,
    this.metadata = const {},
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.name,
      'privacy': privacy.name,
      'creator_id': creatorId,
      'member_ids': memberIds,
      'admin_ids': adminIds,
      'tags': tags,
      'group_goals': groupGoals,
      'group_stats': groupStats,
      'activity_level': activityLevel.name,
      'created_at': Timestamp.fromDate(createdAt),
      'last_activity': Timestamp.fromDate(lastActivity),
      'max_members': maxMembers,
      'allow_anonymous': allowAnonymous,
      'require_approval': requireApproval,
      'image_url': imageUrl,
      'metadata': metadata,
    };
  }

  /// Create from Firestore document
  factory HealthGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return HealthGroup(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: HealthGroupType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => HealthGroupType.support,
      ),
      privacy: HealthGroupPrivacy.values.firstWhere(
        (e) => e.name == data['privacy'],
        orElse: () => HealthGroupPrivacy.public,
      ),
      creatorId: data['creator_id'] ?? '',
      memberIds: List<String>.from(data['member_ids'] ?? []),
      adminIds: List<String>.from(data['admin_ids'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      groupGoals: Map<String, dynamic>.from(data['group_goals'] ?? {}),
      groupStats: Map<String, dynamic>.from(data['group_stats'] ?? {}),
      activityLevel: HealthGroupActivity.values.firstWhere(
        (e) => e.name == data['activity_level'],
        orElse: () => HealthGroupActivity.low,
      ),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      lastActivity: (data['last_activity'] as Timestamp).toDate(),
      maxMembers: data['max_members'] ?? 50,
      allowAnonymous: data['allow_anonymous'] ?? false,
      requireApproval: data['require_approval'] ?? false,
      imageUrl: data['image_url'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Create a copy with updated fields
  HealthGroup copyWith({
    String? name,
    String? description,
    HealthGroupType? type,
    HealthGroupPrivacy? privacy,
    List<String>? memberIds,
    List<String>? adminIds,
    List<String>? tags,
    Map<String, dynamic>? groupGoals,
    Map<String, dynamic>? groupStats,
    HealthGroupActivity? activityLevel,
    DateTime? lastActivity,
    int? maxMembers,
    bool? allowAnonymous,
    bool? requireApproval,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return HealthGroup(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      privacy: privacy ?? this.privacy,
      creatorId: creatorId,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      tags: tags ?? this.tags,
      groupGoals: groupGoals ?? this.groupGoals,
      groupStats: groupStats ?? this.groupStats,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt,
      lastActivity: lastActivity ?? this.lastActivity,
      maxMembers: maxMembers ?? this.maxMembers,
      allowAnonymous: allowAnonymous ?? this.allowAnonymous,
      requireApproval: requireApproval ?? this.requireApproval,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get display text for group type
  String get typeDisplayName {
    switch (type) {
      case HealthGroupType.fasting:
        return 'Fasting Support';
      case HealthGroupType.calorieGoals:
        return 'Calorie Goals';
      case HealthGroupType.workoutBuddies:
        return 'Workout Buddies';
      case HealthGroupType.nutrition:
        return 'Nutrition';
      case HealthGroupType.wellness:
        return 'Wellness';
      case HealthGroupType.challenges:
        return 'Challenges';
      case HealthGroupType.support:
        return 'Support';
      case HealthGroupType.recipes:
        return 'Recipes';
    }
  }

  /// Get icon for group type
  String get typeIcon {
    switch (type) {
      case HealthGroupType.fasting:
        return '⏰';
      case HealthGroupType.calorieGoals:
        return '📊';
      case HealthGroupType.workoutBuddies:
        return '💪';
      case HealthGroupType.nutrition:
        return '🥗';
      case HealthGroupType.wellness:
        return '🧘';
      case HealthGroupType.challenges:
        return '🏆';
      case HealthGroupType.support:
        return '🤝';
      case HealthGroupType.recipes:
        return '👨‍🍳';
    }
  }

  /// Check if user is member of the group
  bool isMember(String userId) => memberIds.contains(userId);

  /// Check if user is admin of the group
  bool isAdmin(String userId) => adminIds.contains(userId);

  /// Check if user is creator of the group
  bool isCreator(String userId) => creatorId == userId;

  /// Check if group is full
  bool get isFull => memberIds.length >= maxMembers;

  /// Get member count
  int get memberCount => memberIds.length;
} 