import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum AIContentType {
  article,
  tip,
  recipe,
  exercise,
  motivation,
  nutrition,
  fasting,
  general,
}

enum AIContentPriority {
  low,
  medium,
  high,
}

class AIContent {
  final String id;
  final String title;
  final String content;
  final String? summary;
  final AIContentType type;
  final AIContentPriority priority;
  final List<String> tags;
  final List<String> targetGoals; // Which health goals this content applies to
  final List<String> dietaryRestrictions; // Which dietary restrictions this respects
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? imageUrl;
  final String? sourceUrl;
  final Map<String, dynamic> metadata;
  final bool isPersonalized; // Whether this was generated for specific user
  final String? targetUserId; // If personalized, which user

  AIContent({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.type,
    this.priority = AIContentPriority.medium,
    this.tags = const [],
    this.targetGoals = const [],
    this.dietaryRestrictions = const [],
    required this.createdAt,
    this.expiresAt,
    this.imageUrl,
    this.sourceUrl,
    this.metadata = const {},
    this.isPersonalized = false,
    this.targetUserId,
  });

  factory AIContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIContent(
      id: doc.id,
      title: data['title'],
      content: data['content'],
      summary: data['summary'],
      type: AIContentType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => AIContentType.general,
      ),
      priority: AIContentPriority.values.firstWhere(
        (priority) => priority.name == data['priority'],
        orElse: () => AIContentPriority.medium,
      ),
      tags: List<String>.from(data['tags'] ?? []),
      targetGoals: List<String>.from(data['targetGoals'] ?? []),
      dietaryRestrictions: List<String>.from(data['dietaryRestrictions'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      imageUrl: data['imageUrl'],
      sourceUrl: data['sourceUrl'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      isPersonalized: data['isPersonalized'] ?? false,
      targetUserId: data['targetUserId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'summary': summary,
      'type': type.name,
      'priority': priority.name,
      'tags': tags,
      'targetGoals': targetGoals,
      'dietaryRestrictions': dietaryRestrictions,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'imageUrl': imageUrl,
      'sourceUrl': sourceUrl,
      'metadata': metadata,
      'isPersonalized': isPersonalized,
      'targetUserId': targetUserId,
    };
  }

  // Utility methods
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  String get displayType {
    switch (type) {
      case AIContentType.article:
        return 'Article';
      case AIContentType.tip:
        return 'Tip';
      case AIContentType.recipe:
        return 'Recipe';
      case AIContentType.exercise:
        return 'Exercise';
      case AIContentType.motivation:
        return 'Motivation';
      case AIContentType.nutrition:
        return 'Nutrition';
      case AIContentType.fasting:
        return 'Fasting';
      case AIContentType.general:
        return 'Health';
    }
  }

  Color get typeColor {
    switch (type) {
      case AIContentType.article:
        return const Color(0xFF2196F3); // Blue
      case AIContentType.tip:
        return const Color(0xFFFFC107); // Yellow
      case AIContentType.recipe:
        return const Color(0xFF4CAF50); // Green
      case AIContentType.exercise:
        return const Color(0xFFE91E63); // Pink
      case AIContentType.motivation:
        return const Color(0xFF9C27B0); // Purple
      case AIContentType.nutrition:
        return const Color(0xFF4CAF50); // Green
      case AIContentType.fasting:
        return const Color(0xFFFF9800); // Orange
      case AIContentType.general:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AIContentType.article:
        return Icons.article;
      case AIContentType.tip:
        return Icons.lightbulb;
      case AIContentType.recipe:
        return Icons.restaurant;
      case AIContentType.exercise:
        return Icons.fitness_center;
      case AIContentType.motivation:
        return Icons.favorite;
      case AIContentType.nutrition:
        return Icons.local_dining;
      case AIContentType.fasting:
        return Icons.timer;
      case AIContentType.general:
        return Icons.health_and_safety;
    }
  }

  AIContent copyWith({
    String? title,
    String? content,
    String? summary,
    AIContentType? type,
    AIContentPriority? priority,
    List<String>? tags,
    List<String>? targetGoals,
    List<String>? dietaryRestrictions,
    DateTime? expiresAt,
    String? imageUrl,
    String? sourceUrl,
    Map<String, dynamic>? metadata,
    bool? isPersonalized,
    String? targetUserId,
  }) {
    return AIContent(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      tags: tags ?? this.tags,
      targetGoals: targetGoals ?? this.targetGoals,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      metadata: metadata ?? this.metadata,
      isPersonalized: isPersonalized ?? this.isPersonalized,
      targetUserId: targetUserId ?? this.targetUserId,
    );
  }
}

 