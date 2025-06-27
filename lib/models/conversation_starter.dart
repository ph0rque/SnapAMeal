import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a conversation starter
enum ConversationStarterStatus {
  active, // Currently visible in the group
  archived, // No longer visible but kept for history
  reported, // Reported by users for review
}

/// Type of conversation starter content
enum ConversationStarterType {
  question, // Open-ended question
  poll, // Poll with options
  challenge, // Challenge or activity suggestion
  discussion, // Discussion topic
  tip, // Health tip with discussion prompt
}

/// Data model for AI-generated conversation starters in health groups
class ConversationStarter {
  final String id;
  final String groupId;
  final String title;
  final String content;
  final ConversationStarterType type;
  final ConversationStarterStatus status;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? scheduledFor;
  final DateTime? postedAt;
  final String? createdBy; // null for AI-generated
  final bool isAIGenerated;
  final int engagementScore;
  final List<String> reactions;
  final List<String> replies;

  ConversationStarter({
    required this.id,
    required this.groupId,
    required this.title,
    required this.content,
    required this.type,
    this.status = ConversationStarterStatus.active,
    this.tags = const [],
    this.metadata = const {},
    required this.createdAt,
    this.scheduledFor,
    this.postedAt,
    this.createdBy,
    this.isAIGenerated = true,
    this.engagementScore = 0,
    this.reactions = const [],
    this.replies = const [],
  });

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'group_id': groupId,
      'title': title,
      'content': content,
      'type': type.name,
      'status': status.name,
      'tags': tags,
      'metadata': metadata,
      'created_at': Timestamp.fromDate(createdAt),
      'scheduled_for': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
      'posted_at': postedAt != null ? Timestamp.fromDate(postedAt!) : null,
      'created_by': createdBy,
      'is_ai_generated': isAIGenerated,
      'engagement_score': engagementScore,
      'reactions': reactions,
      'replies': replies,
    };
  }

  /// Create from Firestore document
  factory ConversationStarter.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ConversationStarter(
      id: doc.id,
      groupId: data['group_id'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      type: ConversationStarterType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ConversationStarterType.discussion,
      ),
      status: ConversationStarterStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => ConversationStarterStatus.active,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      scheduledFor: data['scheduled_for'] != null 
          ? (data['scheduled_for'] as Timestamp).toDate() 
          : null,
      postedAt: data['posted_at'] != null 
          ? (data['posted_at'] as Timestamp).toDate() 
          : null,
      createdBy: data['created_by'],
      isAIGenerated: data['is_ai_generated'] ?? true,
      engagementScore: data['engagement_score'] ?? 0,
      reactions: List<String>.from(data['reactions'] ?? []),
      replies: List<String>.from(data['replies'] ?? []),
    );
  }

  /// Create a copy with updated fields
  ConversationStarter copyWith({
    String? title,
    String? content,
    ConversationStarterType? type,
    ConversationStarterStatus? status,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? scheduledFor,
    DateTime? postedAt,
    int? engagementScore,
    List<String>? reactions,
    List<String>? replies,
  }) {
    return ConversationStarter(
      id: id,
      groupId: groupId,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      postedAt: postedAt ?? this.postedAt,
      createdBy: createdBy,
      isAIGenerated: isAIGenerated,
      engagementScore: engagementScore ?? this.engagementScore,
      reactions: reactions ?? this.reactions,
      replies: replies ?? this.replies,
    );
  }

  /// Get display text for conversation starter type
  String get typeDisplayName {
    switch (type) {
      case ConversationStarterType.question:
        return 'Question';
      case ConversationStarterType.poll:
        return 'Poll';
      case ConversationStarterType.challenge:
        return 'Challenge';
      case ConversationStarterType.discussion:
        return 'Discussion';
      case ConversationStarterType.tip:
        return 'Health Tip';
    }
  }

  /// Get icon for conversation starter type
  String get typeIcon {
    switch (type) {
      case ConversationStarterType.question:
        return '❓';
      case ConversationStarterType.poll:
        return '📊';
      case ConversationStarterType.challenge:
        return '🎯';
      case ConversationStarterType.discussion:
        return '💬';
      case ConversationStarterType.tip:
        return '💡';
    }
  }

  /// Check if conversation starter is currently active
  bool get isActive => status == ConversationStarterStatus.active;

  /// Check if conversation starter is scheduled for future posting
  bool get isScheduled => scheduledFor != null && postedAt == null;

  /// Check if conversation starter has been posted
  bool get isPosted => postedAt != null;

  /// Get engagement level based on score
  String get engagementLevel {
    if (engagementScore >= 20) return 'High';
    if (engagementScore >= 10) return 'Medium';
    if (engagementScore >= 5) return 'Low';
    return 'None';
  }
} 