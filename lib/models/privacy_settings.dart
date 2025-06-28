import 'package:cloud_firestore/cloud_firestore.dart';

enum PrivacyLevel { public, friends, private, anonymous }

enum DataCategory {
  personalInfo,
  healthMetrics,
  mealData,
  exerciseData,
  fastingData,
  weightData,
  socialActivity,
  locationData,
  deviceData,
  analyticsData,
}

enum SharingPermission { read, write, delete, share }

enum IntegrationPermission {
  dataRead,
  dataWrite,
  notifications,
  backgroundSync,
  analytics,
  marketing,
}

class PrivacySettings {
  final String userId;
  final Map<DataCategory, PrivacyLevel> dataPrivacyLevels;
  final Map<DataCategory, List<String>> dataAccessWhitelist;
  final Map<DataCategory, List<String>> dataAccessBlacklist;
  final Map<String, List<SharingPermission>> friendPermissions;
  final Map<String, List<IntegrationPermission>> integrationPermissions;
  final bool allowDataCollection;
  final bool allowAnalytics;
  final bool allowPersonalization;
  final bool allowMarketing;
  final bool allowThirdPartySharing;
  final bool allowDataExport;
  final bool allowDataDeletion;
  final bool requireExplicitConsent;
  final Map<String, dynamic> consentHistory;
  final DateTime lastUpdated;
  final DateTime createdAt;
  final bool shareActivityWithFriends;
  final bool allowFriendRequests;
  final bool showInDiscovery;
  final bool enableNotifications;
  final bool shareProgressPhotos;
  final bool allowDataAnalytics;
  final Map<String, bool> notificationPreferences;
  final DateTime updatedAt;
  
  // AI Content Preferences
  final AIContentPreferences aiPreferences;

  PrivacySettings({
    required this.userId,
    required this.dataPrivacyLevels,
    required this.dataAccessWhitelist,
    required this.dataAccessBlacklist,
    required this.friendPermissions,
    required this.integrationPermissions,
    required this.allowDataCollection,
    required this.allowAnalytics,
    required this.allowPersonalization,
    required this.allowMarketing,
    required this.allowThirdPartySharing,
    required this.allowDataExport,
    required this.allowDataDeletion,
    required this.requireExplicitConsent,
    required this.consentHistory,
    required this.lastUpdated,
    required this.createdAt,
    this.shareActivityWithFriends = true,
    this.allowFriendRequests = true,
    this.showInDiscovery = true,
    this.enableNotifications = true,
    this.shareProgressPhotos = false,
    this.allowDataAnalytics = true,
    this.notificationPreferences = const {},
    DateTime? updatedAt,
    AIContentPreferences? aiPreferences,
  }) : updatedAt = updatedAt ?? DateTime.now(),
       aiPreferences = aiPreferences ?? AIContentPreferences._createDefault();

  // Default privacy settings for new users
  factory PrivacySettings.defaultSettings(String userId) {
    return PrivacySettings(
      userId: userId,
      dataPrivacyLevels: {
        DataCategory.personalInfo: PrivacyLevel.private,
        DataCategory.healthMetrics: PrivacyLevel.private,
        DataCategory.mealData: PrivacyLevel.friends,
        DataCategory.exerciseData: PrivacyLevel.friends,
        DataCategory.fastingData: PrivacyLevel.private,
        DataCategory.weightData: PrivacyLevel.private,
        DataCategory.socialActivity: PrivacyLevel.friends,
        DataCategory.locationData: PrivacyLevel.private,
        DataCategory.deviceData: PrivacyLevel.private,
        DataCategory.analyticsData: PrivacyLevel.private,
      },
      dataAccessWhitelist: {},
      dataAccessBlacklist: {},
      friendPermissions: {},
      integrationPermissions: {},
      allowDataCollection: true,
      allowAnalytics: false,
      allowPersonalization: true,
      allowMarketing: false,
      allowThirdPartySharing: false,
      allowDataExport: true,
      allowDataDeletion: true,
      requireExplicitConsent: true,
      consentHistory: {},
      lastUpdated: DateTime.now(),
      createdAt: DateTime.now(),
      shareActivityWithFriends: true,
      allowFriendRequests: true,
      showInDiscovery: true,
      enableNotifications: true,
      shareProgressPhotos: false,
      allowDataAnalytics: true,
      notificationPreferences: {},
      aiPreferences: AIContentPreferences._createDefault(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'dataPrivacyLevels': dataPrivacyLevels.map(
        (key, value) => MapEntry(key.name, value.name),
      ),
      'dataAccessWhitelist': dataAccessWhitelist.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'dataAccessBlacklist': dataAccessBlacklist.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'friendPermissions': friendPermissions.map(
        (key, value) => MapEntry(key, value.map((p) => p.name).toList()),
      ),
      'integrationPermissions': integrationPermissions.map(
        (key, value) => MapEntry(key, value.map((p) => p.name).toList()),
      ),
      'allowDataCollection': allowDataCollection,
      'allowAnalytics': allowAnalytics,
      'allowPersonalization': allowPersonalization,
      'allowMarketing': allowMarketing,
      'allowThirdPartySharing': allowThirdPartySharing,
      'allowDataExport': allowDataExport,
      'allowDataDeletion': allowDataDeletion,
      'requireExplicitConsent': requireExplicitConsent,
      'consentHistory': consentHistory,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'createdAt': Timestamp.fromDate(createdAt),
      'shareActivityWithFriends': shareActivityWithFriends,
      'allowFriendRequests': allowFriendRequests,
      'showInDiscovery': showInDiscovery,
      'enableNotifications': enableNotifications,
      'shareProgressPhotos': shareProgressPhotos,
      'allowDataAnalytics': allowDataAnalytics,
      'notificationPreferences': notificationPreferences,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'aiPreferences': aiPreferences.toMap(),
    };
  }

  factory PrivacySettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return PrivacySettings(
      userId: data['userId'] ?? '',
      dataPrivacyLevels:
          (data['dataPrivacyLevels'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              DataCategory.values.firstWhere((e) => e.name == key),
              PrivacyLevel.values.firstWhere((e) => e.name == value),
            ),
          ) ??
          {},
      dataAccessWhitelist:
          (data['dataAccessWhitelist'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              DataCategory.values.firstWhere((e) => e.name == key),
              List<String>.from(value),
            ),
          ) ??
          {},
      dataAccessBlacklist:
          (data['dataAccessBlacklist'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              DataCategory.values.firstWhere((e) => e.name == key),
              List<String>.from(value),
            ),
          ) ??
          {},
      friendPermissions:
          (data['friendPermissions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List)
                  .map(
                    (p) =>
                        SharingPermission.values.firstWhere((e) => e.name == p),
                  )
                  .toList(),
            ),
          ) ??
          {},
      integrationPermissions:
          (data['integrationPermissions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              (value as List)
                  .map(
                    (p) => IntegrationPermission.values.firstWhere(
                      (e) => e.name == p,
                    ),
                  )
                  .toList(),
            ),
          ) ??
          {},
      allowDataCollection: data['allowDataCollection'] ?? true,
      allowAnalytics: data['allowAnalytics'] ?? false,
      allowPersonalization: data['allowPersonalization'] ?? true,
      allowMarketing: data['allowMarketing'] ?? false,
      allowThirdPartySharing: data['allowThirdPartySharing'] ?? false,
      allowDataExport: data['allowDataExport'] ?? true,
      allowDataDeletion: data['allowDataDeletion'] ?? true,
      requireExplicitConsent: data['requireExplicitConsent'] ?? true,
      consentHistory: data['consentHistory'] ?? {},
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shareActivityWithFriends: data['shareActivityWithFriends'] ?? true,
      allowFriendRequests: data['allowFriendRequests'] ?? true,
      showInDiscovery: data['showInDiscovery'] ?? true,
      enableNotifications: data['enableNotifications'] ?? true,
      shareProgressPhotos: data['shareProgressPhotos'] ?? false,
      allowDataAnalytics: data['allowDataAnalytics'] ?? true,
      notificationPreferences: Map<String, bool>.from(data['notificationPreferences'] ?? {}),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      aiPreferences: data['aiPreferences'] != null 
          ? AIContentPreferences.fromMap(data['aiPreferences'])
          : AIContentPreferences._createDefault(),
    );
  }

  PrivacySettings copyWith({
    String? userId,
    Map<DataCategory, PrivacyLevel>? dataPrivacyLevels,
    Map<DataCategory, List<String>>? dataAccessWhitelist,
    Map<DataCategory, List<String>>? dataAccessBlacklist,
    Map<String, List<SharingPermission>>? friendPermissions,
    Map<String, List<IntegrationPermission>>? integrationPermissions,
    bool? allowDataCollection,
    bool? allowAnalytics,
    bool? allowPersonalization,
    bool? allowMarketing,
    bool? allowThirdPartySharing,
    bool? allowDataExport,
    bool? allowDataDeletion,
    bool? requireExplicitConsent,
    Map<String, dynamic>? consentHistory,
    DateTime? lastUpdated,
    DateTime? createdAt,
    bool? shareActivityWithFriends,
    bool? allowFriendRequests,
    bool? showInDiscovery,
    bool? enableNotifications,
    bool? shareProgressPhotos,
    bool? allowDataAnalytics,
    Map<String, bool>? notificationPreferences,
    DateTime? updatedAt,
    AIContentPreferences? aiPreferences,
  }) {
    return PrivacySettings(
      userId: userId ?? this.userId,
      dataPrivacyLevels: dataPrivacyLevels ?? this.dataPrivacyLevels,
      dataAccessWhitelist: dataAccessWhitelist ?? this.dataAccessWhitelist,
      dataAccessBlacklist: dataAccessBlacklist ?? this.dataAccessBlacklist,
      friendPermissions: friendPermissions ?? this.friendPermissions,
      integrationPermissions:
          integrationPermissions ?? this.integrationPermissions,
      allowDataCollection: allowDataCollection ?? this.allowDataCollection,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowPersonalization: allowPersonalization ?? this.allowPersonalization,
      allowMarketing: allowMarketing ?? this.allowMarketing,
      allowThirdPartySharing:
          allowThirdPartySharing ?? this.allowThirdPartySharing,
      allowDataExport: allowDataExport ?? this.allowDataExport,
      allowDataDeletion: allowDataDeletion ?? this.allowDataDeletion,
      requireExplicitConsent:
          requireExplicitConsent ?? this.requireExplicitConsent,
      consentHistory: consentHistory ?? this.consentHistory,
      lastUpdated: lastUpdated ?? DateTime.now(),
      createdAt: createdAt ?? this.createdAt,
      shareActivityWithFriends: shareActivityWithFriends ?? this.shareActivityWithFriends,
      allowFriendRequests: allowFriendRequests ?? this.allowFriendRequests,
      showInDiscovery: showInDiscovery ?? this.showInDiscovery,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      shareProgressPhotos: shareProgressPhotos ?? this.shareProgressPhotos,
      allowDataAnalytics: allowDataAnalytics ?? this.allowDataAnalytics,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      updatedAt: updatedAt ?? this.updatedAt,
      aiPreferences: aiPreferences ?? this.aiPreferences,
    );
  }

  /// Check if a user has permission to access specific data
  bool hasAccessPermission(String requestingUserId, DataCategory category) {
    final privacyLevel = dataPrivacyLevels[category] ?? PrivacyLevel.private;

    switch (privacyLevel) {
      case PrivacyLevel.public:
        return true;
      case PrivacyLevel.friends:
        return friendPermissions.containsKey(requestingUserId);
      case PrivacyLevel.private:
        return requestingUserId == userId;
      case PrivacyLevel.anonymous:
        return false;
    }
  }

  /// Check if a friend has specific sharing permission
  bool hasSharingPermission(String friendId, SharingPermission permission) {
    final permissions = friendPermissions[friendId] ?? [];
    return permissions.contains(permission);
  }

  /// Check if an integration has specific permission
  bool hasIntegrationPermission(
    String integrationId,
    IntegrationPermission permission,
  ) {
    final permissions = integrationPermissions[integrationId] ?? [];
    return permissions.contains(permission);
  }

  /// Check if data category is whitelisted for a user
  bool isWhitelisted(String userId, DataCategory category) {
    final whitelist = dataAccessWhitelist[category] ?? [];
    return whitelist.contains(userId);
  }

  /// Check if data category is blacklisted for a user
  bool isBlacklisted(String userId, DataCategory category) {
    final blacklist = dataAccessBlacklist[category] ?? [];
    return blacklist.contains(userId);
  }

  /// Get privacy level for a data category
  PrivacyLevel getPrivacyLevel(DataCategory category) {
    return dataPrivacyLevels[category] ?? PrivacyLevel.private;
  }

  /// Get effective privacy level considering whitelist/blacklist
  PrivacyLevel getEffectivePrivacyLevel(
    String requestingUserId,
    DataCategory category,
  ) {
    if (isBlacklisted(requestingUserId, category)) {
      return PrivacyLevel.private;
    }

    if (isWhitelisted(requestingUserId, category)) {
      return PrivacyLevel.public;
    }

    return getPrivacyLevel(category);
  }

  /// Check if user requires explicit consent for data operations
  bool requiresExplicitConsent(DataCategory category) {
    return requireExplicitConsent &&
        (category == DataCategory.personalInfo ||
            category == DataCategory.healthMetrics ||
            category == DataCategory.locationData);
  }

  /// Get consent status for a specific operation
  bool hasConsent(String operation) {
    return consentHistory[operation] == true;
  }

  /// Get data categories that are shareable
  List<DataCategory> getShareableCategories() {
    return dataPrivacyLevels.entries
        .where((entry) => entry.value != PrivacyLevel.private)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get data categories that are public
  List<DataCategory> getPublicCategories() {
    return dataPrivacyLevels.entries
        .where((entry) => entry.value == PrivacyLevel.public)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get friends with specific permission
  List<String> getFriendsWithPermission(SharingPermission permission) {
    return friendPermissions.entries
        .where((entry) => entry.value.contains(permission))
        .map((entry) => entry.key)
        .toList();
  }

  /// Get integrations with specific permission
  List<String> getIntegrationsWithPermission(IntegrationPermission permission) {
    return integrationPermissions.entries
        .where((entry) => entry.value.contains(permission))
        .map((entry) => entry.key)
        .toList();
  }

  /// Check if privacy settings are compliant with regulations
  bool isGDPRCompliant() {
    return allowDataDeletion &&
        allowDataExport &&
        requireExplicitConsent &&
        !allowThirdPartySharing;
  }

  /// Check if privacy settings are compliant with HIPAA
  bool isHIPAACompliant() {
    return dataPrivacyLevels[DataCategory.healthMetrics] ==
            PrivacyLevel.private &&
        dataPrivacyLevels[DataCategory.personalInfo] == PrivacyLevel.private &&
        !allowThirdPartySharing &&
        requireExplicitConsent;
  }

  /// Get privacy score (0-100, higher is more private)
  int getPrivacyScore() {
    int score = 0;

    // Base score for privacy levels
    for (final level in dataPrivacyLevels.values) {
      switch (level) {
        case PrivacyLevel.private:
          score += 10;
          break;
        case PrivacyLevel.friends:
          score += 7;
          break;
        case PrivacyLevel.public:
          score += 3;
          break;
        case PrivacyLevel.anonymous:
          score += 10;
          break;
      }
    }

    // Bonus for restrictive settings
    if (!allowDataCollection) score += 10;
    if (!allowAnalytics) score += 10;
    if (!allowMarketing) score += 10;
    if (!allowThirdPartySharing) score += 15;
    if (requireExplicitConsent) score += 10;

    return (score / (dataPrivacyLevels.length + 5) * 10).round().clamp(0, 100);
  }

  @override
  String toString() {
    return 'PrivacySettings(userId: $userId, privacyScore: ${getPrivacyScore()})';
  }
}

class ConsentRecord {
  final String userId;
  final String operation;
  final DataCategory category;
  final bool granted;
  final DateTime timestamp;
  final String? reason;
  final Map<String, dynamic>? metadata;

  const ConsentRecord({
    required this.userId,
    required this.operation,
    required this.category,
    required this.granted,
    required this.timestamp,
    this.reason,
    this.metadata,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'operation': operation,
      'category': category.name,
      'granted': granted,
      'timestamp': Timestamp.fromDate(timestamp),
      'reason': reason,
      'metadata': metadata,
    };
  }

  factory ConsentRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ConsentRecord(
      userId: data['userId'] ?? '',
      operation: data['operation'] ?? '',
      category: DataCategory.values.firstWhere(
        (e) => e.name == data['category'],
      ),
      granted: data['granted'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: data['reason'],
      metadata: data['metadata'],
    );
  }
}

/// AI Content Preferences for customizing AI-generated content
class AIContentPreferences {
  // General AI Settings
  final bool enableAIContent;
  final AIContentFrequency dailyInsightFrequency;
  final AIContentFrequency mealInsightFrequency;
  final AIContentFrequency feedContentFrequency;
  
  // Content Type Preferences
  final Map<String, bool> contentTypePreferences;
  final Map<String, bool> dismissedContentTypes;
  
  // Personalization Settings
  final bool usePersonalizedContent;
  final bool allowGoalBasedContent;
  final bool allowDietaryContent;
  final bool allowFitnessContent;
  
  // Social AI Features
  final bool enableConversationStarters;
  final bool enableFriendMatchingAI;
  final bool allowAIInGroups;
  
  // Review and Insights
  final bool enableWeeklyReviews;
  final bool enableMonthlyReviews;
  final bool enableGoalTracking;
  
  // Content Safety
  final bool reportInappropriateContent;
  final List<String> blockedKeywords;
  
  final DateTime updatedAt;

  AIContentPreferences({
    this.enableAIContent = true,
    this.dailyInsightFrequency = AIContentFrequency.daily,
    this.mealInsightFrequency = AIContentFrequency.always,
    this.feedContentFrequency = AIContentFrequency.moderate,
    Map<String, bool>? contentTypePreferences,
    Map<String, bool>? dismissedContentTypes,
    this.usePersonalizedContent = true,
    this.allowGoalBasedContent = true,
    this.allowDietaryContent = true,
    this.allowFitnessContent = true,
    this.enableConversationStarters = true,
    this.enableFriendMatchingAI = true,
    this.allowAIInGroups = true,
    this.enableWeeklyReviews = true,
    this.enableMonthlyReviews = true,
    this.enableGoalTracking = true,
    this.reportInappropriateContent = true,
    this.blockedKeywords = const [],
    DateTime? updatedAt,
  }) : contentTypePreferences = contentTypePreferences ?? const {
        'motivation': true,
        'nutrition': true,
        'fitness': true,
        'recipes': true,
        'tips': true,
        'articles': true,
      },
      dismissedContentTypes = dismissedContentTypes ?? const {},
      updatedAt = updatedAt ?? DateTime.now();

  static AIContentPreferences _createDefault() {
    return AIContentPreferences(
      enableAIContent: true,
      dailyInsightFrequency: AIContentFrequency.daily,
      mealInsightFrequency: AIContentFrequency.always,
      feedContentFrequency: AIContentFrequency.moderate,
      contentTypePreferences: const {
        'motivation': true,
        'nutrition': true,
        'fitness': true,
        'recipes': true,
        'tips': true,
        'articles': true,
      },
      dismissedContentTypes: const {},
      usePersonalizedContent: true,
      allowGoalBasedContent: true,
      allowDietaryContent: true,
      allowFitnessContent: true,
      enableConversationStarters: true,
      enableFriendMatchingAI: true,
      allowAIInGroups: true,
      enableWeeklyReviews: true,
      enableMonthlyReviews: true,
      enableGoalTracking: true,
      reportInappropriateContent: true,
      blockedKeywords: const [],
      updatedAt: DateTime(2024, 12, 19),
    );
  }

  factory AIContentPreferences.fromMap(Map<String, dynamic> data) {
    return AIContentPreferences(
      enableAIContent: data['enableAIContent'] ?? true,
      dailyInsightFrequency: AIContentFrequency.values.firstWhere(
        (f) => f.name == data['dailyInsightFrequency'],
        orElse: () => AIContentFrequency.daily,
      ),
      mealInsightFrequency: AIContentFrequency.values.firstWhere(
        (f) => f.name == data['mealInsightFrequency'],
        orElse: () => AIContentFrequency.always,
      ),
      feedContentFrequency: AIContentFrequency.values.firstWhere(
        (f) => f.name == data['feedContentFrequency'],
        orElse: () => AIContentFrequency.moderate,
      ),
      contentTypePreferences: Map<String, bool>.from(data['contentTypePreferences'] ?? {
        'motivation': true,
        'nutrition': true,
        'fitness': true,
        'recipes': true,
        'tips': true,
        'articles': true,
      }),
      dismissedContentTypes: Map<String, bool>.from(data['dismissedContentTypes'] ?? {}),
      usePersonalizedContent: data['usePersonalizedContent'] ?? true,
      allowGoalBasedContent: data['allowGoalBasedContent'] ?? true,
      allowDietaryContent: data['allowDietaryContent'] ?? true,
      allowFitnessContent: data['allowFitnessContent'] ?? true,
      enableConversationStarters: data['enableConversationStarters'] ?? true,
      enableFriendMatchingAI: data['enableFriendMatchingAI'] ?? true,
      allowAIInGroups: data['allowAIInGroups'] ?? true,
      enableWeeklyReviews: data['enableWeeklyReviews'] ?? true,
      enableMonthlyReviews: data['enableMonthlyReviews'] ?? true,
      enableGoalTracking: data['enableGoalTracking'] ?? true,
      reportInappropriateContent: data['reportInappropriateContent'] ?? true,
      blockedKeywords: List<String>.from(data['blockedKeywords'] ?? []),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableAIContent': enableAIContent,
      'dailyInsightFrequency': dailyInsightFrequency.name,
      'mealInsightFrequency': mealInsightFrequency.name,
      'feedContentFrequency': feedContentFrequency.name,
      'contentTypePreferences': contentTypePreferences,
      'dismissedContentTypes': dismissedContentTypes,
      'usePersonalizedContent': usePersonalizedContent,
      'allowGoalBasedContent': allowGoalBasedContent,
      'allowDietaryContent': allowDietaryContent,
      'allowFitnessContent': allowFitnessContent,
      'enableConversationStarters': enableConversationStarters,
      'enableFriendMatchingAI': enableFriendMatchingAI,
      'allowAIInGroups': allowAIInGroups,
      'enableWeeklyReviews': enableWeeklyReviews,
      'enableMonthlyReviews': enableMonthlyReviews,
      'enableGoalTracking': enableGoalTracking,
      'reportInappropriateContent': reportInappropriateContent,
      'blockedKeywords': blockedKeywords,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AIContentPreferences copyWith({
    bool? enableAIContent,
    AIContentFrequency? dailyInsightFrequency,
    AIContentFrequency? mealInsightFrequency,
    AIContentFrequency? feedContentFrequency,
    Map<String, bool>? contentTypePreferences,
    Map<String, bool>? dismissedContentTypes,
    bool? usePersonalizedContent,
    bool? allowGoalBasedContent,
    bool? allowDietaryContent,
    bool? allowFitnessContent,
    bool? enableConversationStarters,
    bool? enableFriendMatchingAI,
    bool? allowAIInGroups,
    bool? enableWeeklyReviews,
    bool? enableMonthlyReviews,
    bool? enableGoalTracking,
    bool? reportInappropriateContent,
    List<String>? blockedKeywords,
    DateTime? updatedAt,
  }) {
    return AIContentPreferences(
      enableAIContent: enableAIContent ?? this.enableAIContent,
      dailyInsightFrequency: dailyInsightFrequency ?? this.dailyInsightFrequency,
      mealInsightFrequency: mealInsightFrequency ?? this.mealInsightFrequency,
      feedContentFrequency: feedContentFrequency ?? this.feedContentFrequency,
      contentTypePreferences: contentTypePreferences ?? this.contentTypePreferences,
      dismissedContentTypes: dismissedContentTypes ?? this.dismissedContentTypes,
      usePersonalizedContent: usePersonalizedContent ?? this.usePersonalizedContent,
      allowGoalBasedContent: allowGoalBasedContent ?? this.allowGoalBasedContent,
      allowDietaryContent: allowDietaryContent ?? this.allowDietaryContent,
      allowFitnessContent: allowFitnessContent ?? this.allowFitnessContent,
      enableConversationStarters: enableConversationStarters ?? this.enableConversationStarters,
      enableFriendMatchingAI: enableFriendMatchingAI ?? this.enableFriendMatchingAI,
      allowAIInGroups: allowAIInGroups ?? this.allowAIInGroups,
      enableWeeklyReviews: enableWeeklyReviews ?? this.enableWeeklyReviews,
      enableMonthlyReviews: enableMonthlyReviews ?? this.enableMonthlyReviews,
      enableGoalTracking: enableGoalTracking ?? this.enableGoalTracking,
      reportInappropriateContent: reportInappropriateContent ?? this.reportInappropriateContent,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if a specific content type is enabled
  bool isContentTypeEnabled(String contentType) {
    return contentTypePreferences[contentType] ?? true;
  }

  /// Check if a content type has been dismissed
  bool isContentTypeDismissed(String contentType) {
    return dismissedContentTypes[contentType] ?? false;
  }

  /// Check if AI content should be shown based on frequency settings
  bool shouldShowDailyInsight() {
    if (!enableAIContent) return false;
    
    switch (dailyInsightFrequency) {
      case AIContentFrequency.never:
        return false;
      case AIContentFrequency.weekly:
        return DateTime.now().weekday == 1; // Monday only
      case AIContentFrequency.moderate:
        return DateTime.now().weekday % 2 == 1; // Every other day
      case AIContentFrequency.daily:
        return true;
      case AIContentFrequency.always:
        return true;
    }
  }

  /// Check if meal insights should be shown
  bool shouldShowMealInsight() {
    if (!enableAIContent) return false;
    
    switch (mealInsightFrequency) {
      case AIContentFrequency.never:
        return false;
      case AIContentFrequency.weekly:
        return DateTime.now().weekday == 1; // Monday only
      case AIContentFrequency.moderate:
        return DateTime.now().hour % 2 == 0; // Every other meal time
      case AIContentFrequency.daily:
        return true;
      case AIContentFrequency.always:
        return true;
    }
  }

  /// Check if feed content should be shown
  bool shouldShowFeedContent() {
    if (!enableAIContent) return false;
    
    switch (feedContentFrequency) {
      case AIContentFrequency.never:
        return false;
      case AIContentFrequency.weekly:
        return DateTime.now().weekday <= 2; // Monday-Tuesday only
      case AIContentFrequency.moderate:
        return DateTime.now().day % 2 == 1; // Every other day
      case AIContentFrequency.daily:
        return true;
      case AIContentFrequency.always:
        return true;
    }
  }

  /// Reset preferences to defaults
  AIContentPreferences resetToDefaults() {
    return AIContentPreferences();
  }

  /// Get summary of current preferences
  Map<String, dynamic> getPreferencesSummary() {
    return {
      'ai_enabled': enableAIContent,
      'personalized': usePersonalizedContent,
      'daily_insights': dailyInsightFrequency.name,
      'meal_insights': mealInsightFrequency.name,
      'feed_content': feedContentFrequency.name,
      'enabled_content_types': contentTypePreferences.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList(),
      'social_features': {
        'conversation_starters': enableConversationStarters,
        'friend_matching': enableFriendMatchingAI,
        'group_ai': allowAIInGroups,
      },
      'reviews': {
        'weekly': enableWeeklyReviews,
        'monthly': enableMonthlyReviews,
        'goal_tracking': enableGoalTracking,
      },
    };
  }
}

/// Frequency options for AI content
enum AIContentFrequency {
  never,
  weekly,
  moderate,
  daily,
  always;

  String get displayName {
    switch (this) {
      case AIContentFrequency.never:
        return 'Never';
      case AIContentFrequency.weekly:
        return 'Weekly';
      case AIContentFrequency.moderate:
        return 'Moderate';
      case AIContentFrequency.daily:
        return 'Daily';
      case AIContentFrequency.always:
        return 'Always';
    }
  }

  String get description {
    switch (this) {
      case AIContentFrequency.never:
        return 'No AI content';
      case AIContentFrequency.weekly:
        return 'Once per week';
      case AIContentFrequency.moderate:
        return 'A few times per week';
      case AIContentFrequency.daily:
        return 'Once per day';
      case AIContentFrequency.always:
        return 'Multiple times per day';
    }
  }
}
