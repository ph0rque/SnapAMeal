import 'package:cloud_firestore/cloud_firestore.dart';

enum PrivacyLevel {
  public,
  friends,
  private,
  anonymous,
}

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

enum SharingPermission {
  read,
  write,
  delete,
  share,
}

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

  const PrivacySettings({
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
  });

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
    };
  }

  factory PrivacySettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PrivacySettings(
      userId: data['userId'] ?? '',
      dataPrivacyLevels: (data['dataPrivacyLevels'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
                DataCategory.values.firstWhere((e) => e.name == key),
                PrivacyLevel.values.firstWhere((e) => e.name == value),
              )) ?? {},
      dataAccessWhitelist: (data['dataAccessWhitelist'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
                DataCategory.values.firstWhere((e) => e.name == key),
                List<String>.from(value),
              )) ?? {},
      dataAccessBlacklist: (data['dataAccessBlacklist'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
                DataCategory.values.firstWhere((e) => e.name == key),
                List<String>.from(value),
              )) ?? {},
      friendPermissions: (data['friendPermissions'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
                key,
                (value as List).map((p) => 
                  SharingPermission.values.firstWhere((e) => e.name == p)
                ).toList(),
              )) ?? {},
      integrationPermissions: (data['integrationPermissions'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
                key,
                (value as List).map((p) => 
                  IntegrationPermission.values.firstWhere((e) => e.name == p)
                ).toList(),
              )) ?? {},
      allowDataCollection: data['allowDataCollection'] ?? true,
      allowAnalytics: data['allowAnalytics'] ?? false,
      allowPersonalization: data['allowPersonalization'] ?? true,
      allowMarketing: data['allowMarketing'] ?? false,
      allowThirdPartySharing: data['allowThirdPartySharing'] ?? false,
      allowDataExport: data['allowDataExport'] ?? true,
      allowDataDeletion: data['allowDataDeletion'] ?? true,
      requireExplicitConsent: data['requireExplicitConsent'] ?? true,
      consentHistory: data['consentHistory'] ?? {},
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
  }) {
    return PrivacySettings(
      userId: userId ?? this.userId,
      dataPrivacyLevels: dataPrivacyLevels ?? this.dataPrivacyLevels,
      dataAccessWhitelist: dataAccessWhitelist ?? this.dataAccessWhitelist,
      dataAccessBlacklist: dataAccessBlacklist ?? this.dataAccessBlacklist,
      friendPermissions: friendPermissions ?? this.friendPermissions,
      integrationPermissions: integrationPermissions ?? this.integrationPermissions,
      allowDataCollection: allowDataCollection ?? this.allowDataCollection,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      allowPersonalization: allowPersonalization ?? this.allowPersonalization,
      allowMarketing: allowMarketing ?? this.allowMarketing,
      allowThirdPartySharing: allowThirdPartySharing ?? this.allowThirdPartySharing,
      allowDataExport: allowDataExport ?? this.allowDataExport,
      allowDataDeletion: allowDataDeletion ?? this.allowDataDeletion,
      requireExplicitConsent: requireExplicitConsent ?? this.requireExplicitConsent,
      consentHistory: consentHistory ?? this.consentHistory,
      lastUpdated: lastUpdated ?? DateTime.now(),
      createdAt: createdAt ?? this.createdAt,
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
  bool hasIntegrationPermission(String integrationId, IntegrationPermission permission) {
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
  PrivacyLevel getEffectivePrivacyLevel(String requestingUserId, DataCategory category) {
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
    return dataPrivacyLevels[DataCategory.healthMetrics] == PrivacyLevel.private &&
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
      category: DataCategory.values.firstWhere((e) => e.name == data['category']),
      granted: data['granted'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: data['reason'],
      metadata: data['metadata'],
    );
  }
}