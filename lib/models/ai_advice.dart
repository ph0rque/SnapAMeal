import 'package:cloud_firestore/cloud_firestore.dart';

enum AdviceType {
  nutrition,
  exercise,
  fasting,
  sleep,
  mentalHealth,
  hydration,
  recovery,
  motivation,
  habitBuilding,
  goalSetting,
  medicalReminder,
  lifestyle,
  social,
  // Additional types referenced in dashboard
  nutritionTip,
  fastingGuidance,
  exerciseRecommendation,
  motivationalMessage,
  custom
}

enum AdvicePriority {
  low,
  medium,
  high,
  urgent
}

enum AdviceCategory {
  tip,
  reminder,
  encouragement,
  warning,
  insight,
  recommendation,
  challenge,
  celebration
}

enum AdviceTrigger {
  scheduled,
  behavioral,
  contextual,
  reactive,
  milestone,
  emergency,
  userRequested
}

class AIAdvice {
  final String id;
  final String userId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Core Advice Content
  final String title;
  final String content;
  final String? summary; // Short version for notifications
  final AdviceType type;
  final AdviceCategory category;
  final AdvicePriority priority;
  
  // Personalization Context
  final Map<String, dynamic> context; // User data that influenced this advice
  final List<String> tags; // Keywords for categorization
  final Map<String, dynamic> personalizationFactors; // What made this advice relevant
  
  // Delivery & Timing
  final AdviceTrigger trigger;
  final DateTime? scheduledFor;
  final DateTime? deliveredAt;
  final DateTime? expiresAt;
  final bool isProactive; // AI-initiated vs user-requested
  
  // User Interaction
  final int? userRating; // -1, 0, 1 (dislike, neutral, like)
  final DateTime? ratedAt;
  final bool isRead;
  final bool isDismissed;
  final bool isBookmarked;
  final DateTime? interactedAt;
  final Map<String, dynamic> interactionData; // Clicks, time spent, etc.
  
  // AI Learning Data
  final String? sourceQuery; // Original user question if applicable
  final List<String> ragSources; // Knowledge base sources used
  final double? confidenceScore; // AI confidence in this advice (0-1)
  final Map<String, dynamic> generationMetadata; // Model version, tokens, etc.
  
  // Follow-up & Actions
  final List<String> suggestedActions; // Actionable steps
  final String? followUpAdviceId; // Link to related advice
  final bool hasReminder;
  final DateTime? reminderAt;
  final Map<String, dynamic> actionTracking; // User completion of suggested actions
  
  // Effectiveness Tracking
  final int viewCount;
  final int shareCount;
  final double? effectivenessScore; // Calculated based on user behavior
  final Map<String, dynamic> outcomeData; // Measured results if applicable

  const AIAdvice({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.updatedAt,
    required this.title,
    required this.content,
    this.summary,
    required this.type,
    required this.category,
    this.priority = AdvicePriority.medium,
    this.context = const {},
    this.tags = const [],
    this.personalizationFactors = const {},
    required this.trigger,
    this.scheduledFor,
    this.deliveredAt,
    this.expiresAt,
    this.isProactive = true,
    this.userRating,
    this.ratedAt,
    this.isRead = false,
    this.isDismissed = false,
    this.isBookmarked = false,
    this.interactedAt,
    this.interactionData = const {},
    this.sourceQuery,
    this.ragSources = const [],
    this.confidenceScore,
    this.generationMetadata = const {},
    this.suggestedActions = const [],
    this.followUpAdviceId,
    this.hasReminder = false,
    this.reminderAt,
    this.actionTracking = const {},
    this.viewCount = 0,
    this.shareCount = 0,
    this.effectivenessScore,
    this.outcomeData = const {},
  });

  // Factory constructor from Firestore document
  factory AIAdvice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AIAdvice(
      id: doc.id,
      userId: data['userId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      title: data['title'],
      content: data['content'],
      summary: data['summary'],
      type: AdviceType.values.firstWhere(
        (type) => type.name == data['type'],
        orElse: () => AdviceType.custom,
      ),
      category: AdviceCategory.values.firstWhere(
        (category) => category.name == data['category'],
        orElse: () => AdviceCategory.tip,
      ),
      priority: AdvicePriority.values.firstWhere(
        (priority) => priority.name == data['priority'],
        orElse: () => AdvicePriority.medium,
      ),
      context: Map<String, dynamic>.from(data['context'] ?? {}),
      tags: List<String>.from(data['tags'] ?? []),
      personalizationFactors: Map<String, dynamic>.from(data['personalizationFactors'] ?? {}),
      trigger: AdviceTrigger.values.firstWhere(
        (trigger) => trigger.name == data['trigger'],
        orElse: () => AdviceTrigger.scheduled,
      ),
      scheduledFor: data['scheduledFor'] != null ? (data['scheduledFor'] as Timestamp).toDate() : null,
      deliveredAt: data['deliveredAt'] != null ? (data['deliveredAt'] as Timestamp).toDate() : null,
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
      isProactive: data['isProactive'] ?? true,
      userRating: data['userRating'],
      ratedAt: data['ratedAt'] != null ? (data['ratedAt'] as Timestamp).toDate() : null,
      isRead: data['isRead'] ?? false,
      isDismissed: data['isDismissed'] ?? false,
      isBookmarked: data['isBookmarked'] ?? false,
      interactedAt: data['interactedAt'] != null ? (data['interactedAt'] as Timestamp).toDate() : null,
      interactionData: Map<String, dynamic>.from(data['interactionData'] ?? {}),
      sourceQuery: data['sourceQuery'],
      ragSources: List<String>.from(data['ragSources'] ?? []),
      confidenceScore: data['confidenceScore']?.toDouble(),
      generationMetadata: Map<String, dynamic>.from(data['generationMetadata'] ?? {}),
      suggestedActions: List<String>.from(data['suggestedActions'] ?? []),
      followUpAdviceId: data['followUpAdviceId'],
      hasReminder: data['hasReminder'] ?? false,
      reminderAt: data['reminderAt'] != null ? (data['reminderAt'] as Timestamp).toDate() : null,
      actionTracking: Map<String, dynamic>.from(data['actionTracking'] ?? {}),
      viewCount: data['viewCount'] ?? 0,
      shareCount: data['shareCount'] ?? 0,
      effectivenessScore: data['effectivenessScore']?.toDouble(),
      outcomeData: Map<String, dynamic>.from(data['outcomeData'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'title': title,
      'content': content,
      'summary': summary,
      'type': type.name,
      'category': category.name,
      'priority': priority.name,
      'context': context,
      'tags': tags,
      'personalizationFactors': personalizationFactors,
      'trigger': trigger.name,
      'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isProactive': isProactive,
      'userRating': userRating,
      'ratedAt': ratedAt != null ? Timestamp.fromDate(ratedAt!) : null,
      'isRead': isRead,
      'isDismissed': isDismissed,
      'isBookmarked': isBookmarked,
      'interactedAt': interactedAt != null ? Timestamp.fromDate(interactedAt!) : null,
      'interactionData': interactionData,
      'sourceQuery': sourceQuery,
      'ragSources': ragSources,
      'confidenceScore': confidenceScore,
      'generationMetadata': generationMetadata,
      'suggestedActions': suggestedActions,
      'followUpAdviceId': followUpAdviceId,
      'hasReminder': hasReminder,
      'reminderAt': reminderAt != null ? Timestamp.fromDate(reminderAt!) : null,
      'actionTracking': actionTracking,
      'viewCount': viewCount,
      'shareCount': shareCount,
      'effectivenessScore': effectivenessScore,
      'outcomeData': outcomeData,
    };
  }

  // Copy with method for updates
  AIAdvice copyWith({
    DateTime? updatedAt,
    String? title,
    String? content,
    String? summary,
    AdviceType? type,
    AdviceCategory? category,
    AdvicePriority? priority,
    Map<String, dynamic>? context,
    List<String>? tags,
    Map<String, dynamic>? personalizationFactors,
    AdviceTrigger? trigger,
    DateTime? scheduledFor,
    DateTime? deliveredAt,
    DateTime? expiresAt,
    bool? isProactive,
    int? userRating,
    DateTime? ratedAt,
    bool? isRead,
    bool? isDismissed,
    bool? isBookmarked,
    DateTime? interactedAt,
    Map<String, dynamic>? interactionData,
    String? sourceQuery,
    List<String>? ragSources,
    double? confidenceScore,
    Map<String, dynamic>? generationMetadata,
    List<String>? suggestedActions,
    String? followUpAdviceId,
    bool? hasReminder,
    DateTime? reminderAt,
    Map<String, dynamic>? actionTracking,
    int? viewCount,
    int? shareCount,
    double? effectivenessScore,
    Map<String, dynamic>? outcomeData,
  }) {
    return AIAdvice(
      id: id,
      userId: userId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      type: type ?? this.type,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      context: context ?? this.context,
      tags: tags ?? this.tags,
      personalizationFactors: personalizationFactors ?? this.personalizationFactors,
      trigger: trigger ?? this.trigger,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isProactive: isProactive ?? this.isProactive,
      userRating: userRating ?? this.userRating,
      ratedAt: ratedAt ?? this.ratedAt,
      isRead: isRead ?? this.isRead,
      isDismissed: isDismissed ?? this.isDismissed,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      interactedAt: interactedAt ?? this.interactedAt,
      interactionData: interactionData ?? this.interactionData,
      sourceQuery: sourceQuery ?? this.sourceQuery,
      ragSources: ragSources ?? this.ragSources,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      generationMetadata: generationMetadata ?? this.generationMetadata,
      suggestedActions: suggestedActions ?? this.suggestedActions,
      followUpAdviceId: followUpAdviceId ?? this.followUpAdviceId,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderAt: reminderAt ?? this.reminderAt,
      actionTracking: actionTracking ?? this.actionTracking,
      viewCount: viewCount ?? this.viewCount,
      shareCount: shareCount ?? this.shareCount,
      effectivenessScore: effectivenessScore ?? this.effectivenessScore,
      outcomeData: outcomeData ?? this.outcomeData,
    );
  }

  // Utility methods
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get isScheduled => scheduledFor != null && DateTime.now().isBefore(scheduledFor!);
  bool get isDelivered => deliveredAt != null;
  bool get isPending => !isDelivered && !isExpired;
  bool get hasUserFeedback => userRating != null;
  bool get isPositivelyRated => userRating != null && userRating! > 0;
  bool get isNegativelyRated => userRating != null && userRating! < 0;

  // Display methods
  String get typeDisplayName {
    switch (type) {
      case AdviceType.nutrition:
        return 'Nutrition';
      case AdviceType.exercise:
        return 'Exercise';
      case AdviceType.fasting:
        return 'Fasting';
      case AdviceType.sleep:
        return 'Sleep';
      case AdviceType.mentalHealth:
        return 'Mental Health';
      case AdviceType.hydration:
        return 'Hydration';
      case AdviceType.recovery:
        return 'Recovery';
      case AdviceType.motivation:
        return 'Motivation';
      case AdviceType.habitBuilding:
        return 'Habit Building';
      case AdviceType.goalSetting:
        return 'Goal Setting';
      case AdviceType.medicalReminder:
        return 'Medical Reminder';
      case AdviceType.lifestyle:
        return 'Lifestyle';
      case AdviceType.social:
        return 'Social';
      case AdviceType.nutritionTip:
        return 'Nutrition Tip';
      case AdviceType.fastingGuidance:
        return 'Fasting Guidance';
      case AdviceType.exerciseRecommendation:
        return 'Exercise Recommendation';
      case AdviceType.motivationalMessage:
        return 'Motivational Message';
      case AdviceType.custom:
        return 'Custom';
    }
  }

  String get categoryDisplayName {
    switch (category) {
      case AdviceCategory.tip:
        return 'Tip';
      case AdviceCategory.reminder:
        return 'Reminder';
      case AdviceCategory.encouragement:
        return 'Encouragement';
      case AdviceCategory.warning:
        return 'Warning';
      case AdviceCategory.insight:
        return 'Insight';
      case AdviceCategory.recommendation:
        return 'Recommendation';
      case AdviceCategory.challenge:
        return 'Challenge';
      case AdviceCategory.celebration:
        return 'Celebration';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case AdvicePriority.low:
        return 'Low';
      case AdvicePriority.medium:
        return 'Medium';
      case AdvicePriority.high:
        return 'High';
      case AdvicePriority.urgent:
        return 'Urgent';
    }
  }

  // Calculate engagement score based on interactions
  double calculateEngagementScore() {
    double score = 0.0;
    
    // Base score for reading
    if (isRead) score += 0.2;
    
    // Rating feedback
    if (userRating != null) {
      score += 0.3;
      if (userRating! > 0) score += 0.2; // Bonus for positive rating
    }
    
    // Bookmarking shows high engagement
    if (isBookmarked) score += 0.4;
    
    // View count contribution (diminishing returns)
    score += (viewCount * 0.1).clamp(0.0, 0.3);
    
    // Share count shows very high engagement
    score += shareCount * 0.2;
    
    // Action completion
    final completedActions = actionTracking.values.where((completed) => completed == true).length;
    final totalActions = suggestedActions.length;
    if (totalActions > 0) {
      score += (completedActions / totalActions) * 0.3;
    }
    
    return score.clamp(0.0, 1.0);
  }

  // Generate summary statistics
  Map<String, dynamic> getStatistics() {
    return {
      'engagementScore': calculateEngagementScore(),
      'isActive': !isDismissed && !isExpired,
      'hasPositiveFeedback': isPositivelyRated,
      'completionRate': suggestedActions.isEmpty ? 0.0 : 
          actionTracking.values.where((completed) => completed == true).length / suggestedActions.length,
      'daysActive': deliveredAt != null ? 
          DateTime.now().difference(deliveredAt!).inDays : 0,
    };
  }
}
