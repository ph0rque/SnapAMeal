/// Feature Flag System for SnapAMeal Enhanced Meal Analysis
/// Enables gradual rollout and A/B testing of new features
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';

/// Available feature flags for enhanced meal analysis
enum FeatureFlag {
  hybridProcessing,
  inlineFoodCorrection,
  nutritionalQueries,
  performanceMonitoring,
  advancedFirebaseSearch,
  usdaKnowledgeBase,
  circuitBreakers,
  costTracking,
  userFeedbackCollection,
  enhancedErrorHandling,
}

/// Feature flag configuration
class FeatureFlagConfig {
  final FeatureFlag flag;
  final bool enabled;
  final double rolloutPercentage;
  final List<String> allowedUserIds;
  final List<String> allowedVersions;
  final DateTime? expiresAt;
  final Map<String, dynamic> parameters;

  FeatureFlagConfig({
    required this.flag,
    required this.enabled,
    this.rolloutPercentage = 100.0,
    this.allowedUserIds = const [],
    this.allowedVersions = const [],
    this.expiresAt,
    this.parameters = const {},
  });

  factory FeatureFlagConfig.fromJson(Map<String, dynamic> json) {
    return FeatureFlagConfig(
      flag: FeatureFlag.values.firstWhere((e) => e.name == json['flag']),
      enabled: json['enabled'] ?? false,
      rolloutPercentage: json['rolloutPercentage']?.toDouble() ?? 100.0,
      allowedUserIds: List<String>.from(json['allowedUserIds'] ?? []),
      allowedVersions: List<String>.from(json['allowedVersions'] ?? []),
      expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'flag': flag.name,
      'enabled': enabled,
      'rolloutPercentage': rolloutPercentage,
      'allowedUserIds': allowedUserIds,
      'allowedVersions': allowedVersions,
      'expiresAt': expiresAt?.toIso8601String(),
      'parameters': parameters,
    };
  }
}

/// Feature flag service for managing gradual rollouts
class FeatureFlagService {
  static final FeatureFlagService _instance = FeatureFlagService._internal();
  factory FeatureFlagService() => _instance;
  FeatureFlagService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<FeatureFlag, FeatureFlagConfig> _cache = {};
  DateTime? _lastCacheUpdate;
  static const Duration _cacheExpiry = Duration(minutes: 15);

  /// Initialize feature flags with default production-ready settings
  Future<void> initialize() async {
    await _loadDefaultFlags();
    await _loadRemoteFlags();
    Logger.d('🚩 Feature flags initialized');
  }

  /// Check if a feature is enabled for a specific user
  Future<bool> isEnabled(
    FeatureFlag flag, {
    String? userId,
    String? version,
  }) async {
    try {
      final config = await _getFeatureConfig(flag);
      
      // Check if feature is globally disabled
      if (!config.enabled) {
        return false;
      }

      // Check expiration
      if (config.expiresAt != null && DateTime.now().isAfter(config.expiresAt!)) {
        return false;
      }

      // Check version allowlist
      if (config.allowedVersions.isNotEmpty && version != null) {
        if (!config.allowedVersions.contains(version)) {
          return false;
        }
      }

      // Check user allowlist
      if (config.allowedUserIds.isNotEmpty && userId != null) {
        if (config.allowedUserIds.contains(userId)) {
          return true;
        }
      }

      // Check rollout percentage
      if (userId != null) {
        final userHash = _hashUserId(userId);
        final userPercentile = (userHash % 100) + 1;
        return userPercentile <= config.rolloutPercentage;
      }

      // Default to rollout percentage for anonymous users
      return _randomPercentile() <= config.rolloutPercentage;
    } catch (e) {
      Logger.d('❌ Error checking feature flag $flag: $e');
      return _getDefaultFlagState(flag);
    }
  }

  /// Get feature flag parameters
  Future<Map<String, dynamic>> getParameters(FeatureFlag flag) async {
    try {
      final config = await _getFeatureConfig(flag);
      return config.parameters;
    } catch (e) {
      Logger.d('❌ Error getting feature parameters for $flag: $e');
      return {};
    }
  }

  /// Update feature flag configuration (admin only)
  Future<bool> updateFeatureFlag(FeatureFlagConfig config) async {
    try {
      await _firestore
          .collection('feature_flags')
          .doc(config.flag.name)
          .set(config.toJson());
      
      // Update cache
      _cache[config.flag] = config;
      
      Logger.d('✅ Updated feature flag: ${config.flag.name}');
      return true;
    } catch (e) {
      Logger.d('❌ Error updating feature flag: $e');
      return false;
    }
  }

  /// Get all feature flag statuses for debugging
  Future<Map<FeatureFlag, bool>> getAllFlagStatuses({
    String? userId,
    String? version,
  }) async {
    final statuses = <FeatureFlag, bool>{};
    
    for (final flag in FeatureFlag.values) {
      statuses[flag] = await isEnabled(flag, userId: userId, version: version);
    }
    
    return statuses;
  }

  /// Load default feature flag configurations
  Future<void> _loadDefaultFlags() async {
    // Production-ready default configurations for PRD 4.0
    final defaultConfigs = {
      FeatureFlag.hybridProcessing: FeatureFlagConfig(
        flag: FeatureFlag.hybridProcessing,
        enabled: true,
        rolloutPercentage: 100.0, // Fully rolled out
        allowedVersions: ['4.0.0', '4.0.1'],
        parameters: {
          'confidence_threshold': 0.7,
          'fallback_enabled': true,
          'tensorflow_timeout_ms': 5000,
        },
      ),
      FeatureFlag.inlineFoodCorrection: FeatureFlagConfig(
        flag: FeatureFlag.inlineFoodCorrection,
        enabled: true,
        rolloutPercentage: 100.0,
        allowedVersions: ['4.0.0', '4.0.1'],
        parameters: {
          'autocomplete_enabled': true,
          'debounce_ms': 300,
          'max_suggestions': 8,
        },
      ),
      FeatureFlag.nutritionalQueries: FeatureFlagConfig(
        flag: FeatureFlag.nutritionalQueries,
        enabled: true,
        rolloutPercentage: 90.0, // 90% rollout initially
        allowedVersions: ['4.0.0', '4.0.1'],
        parameters: {
          'max_results': 5,
          'safety_disclaimers': true,
          'cache_responses': true,
        },
      ),
      FeatureFlag.performanceMonitoring: FeatureFlagConfig(
        flag: FeatureFlag.performanceMonitoring,
        enabled: true,
        rolloutPercentage: 100.0,
        parameters: {
          'collect_metrics': true,
          'cost_tracking': true,
          'circuit_breakers': true,
        },
      ),
      FeatureFlag.advancedFirebaseSearch: FeatureFlagConfig(
        flag: FeatureFlag.advancedFirebaseSearch,
        enabled: true,
        rolloutPercentage: 100.0,
        parameters: {
          'fuzzy_search': true,
          'similarity_threshold': 0.6,
          'auto_backfill': true,
        },
      ),
      FeatureFlag.usdaKnowledgeBase: FeatureFlagConfig(
        flag: FeatureFlag.usdaKnowledgeBase,
        enabled: true,
        rolloutPercentage: 80.0, // 80% rollout
        parameters: {
          'enable_indexing': false, // Disabled until Pinecone is fully configured
          'fallback_to_local': true,
        },
      ),
      FeatureFlag.circuitBreakers: FeatureFlagConfig(
        flag: FeatureFlag.circuitBreakers,
        enabled: true,
        rolloutPercentage: 100.0,
        parameters: {
          'failure_threshold': 5,
          'recovery_timeout_minutes': 5,
        },
      ),
      FeatureFlag.costTracking: FeatureFlagConfig(
        flag: FeatureFlag.costTracking,
        enabled: true,
        rolloutPercentage: 100.0,
        parameters: {
          'track_openai_costs': true,
          'track_firebase_usage': true,
          'cost_alert_threshold_usd': 10.0,
        },
      ),
      FeatureFlag.userFeedbackCollection: FeatureFlagConfig(
        flag: FeatureFlag.userFeedbackCollection,
        enabled: true,
        rolloutPercentage: 100.0,
        parameters: {
          'collect_satisfaction': true,
          'collect_performance_feedback': true,
          'collect_error_reports': true,
        },
      ),
      FeatureFlag.enhancedErrorHandling: FeatureFlagConfig(
        flag: FeatureFlag.enhancedErrorHandling,
        enabled: true,
        rolloutPercentage: 100.0,
        parameters: {
          'detailed_error_logging': true,
          'user_friendly_messages': true,
          'automatic_retry': true,
        },
      ),
    };

    // Cache default configurations
    _cache.addAll(defaultConfigs);
  }

  /// Load remote feature flag configurations from Firestore
  Future<void> _loadRemoteFlags() async {
    try {
      // Skip if cache is still fresh
      if (_lastCacheUpdate != null && 
          DateTime.now().difference(_lastCacheUpdate!) < _cacheExpiry) {
        return;
      }

      final snapshot = await _firestore.collection('feature_flags').get();
      
      if (snapshot.docs.isEmpty) {
        Logger.d('📝 No remote feature flags found, using defaults');
        _lastCacheUpdate = DateTime.now();
        return;
      }
      
      for (final doc in snapshot.docs) {
        try {
          final config = FeatureFlagConfig.fromJson(doc.data());
          _cache[config.flag] = config;
        } catch (e) {
          Logger.d('❌ Error parsing feature flag ${doc.id}: $e');
        }
      }

      _lastCacheUpdate = DateTime.now();
      Logger.d('✅ Loaded ${snapshot.docs.length} remote feature flags');
    } catch (e) {
      Logger.d('❌ Error loading remote feature flags: $e');
      // Continue with cached/default flags - this is expected for new installations
      _lastCacheUpdate = DateTime.now();
    }
  }

  /// Get feature configuration (with caching)
  Future<FeatureFlagConfig> _getFeatureConfig(FeatureFlag flag) async {
    // Refresh cache if needed
    if (_lastCacheUpdate == null || 
        DateTime.now().difference(_lastCacheUpdate!) > _cacheExpiry) {
      await _loadRemoteFlags();
    }

    return _cache[flag] ?? FeatureFlagConfig(
      flag: flag,
      enabled: _getDefaultFlagState(flag),
    );
  }

  /// Get default state for a feature flag
  bool _getDefaultFlagState(FeatureFlag flag) {
    // Conservative defaults - disable new features if configuration fails
    switch (flag) {
      case FeatureFlag.hybridProcessing:
      case FeatureFlag.inlineFoodCorrection:
      case FeatureFlag.performanceMonitoring:
      case FeatureFlag.advancedFirebaseSearch:
      case FeatureFlag.circuitBreakers:
      case FeatureFlag.costTracking:
      case FeatureFlag.userFeedbackCollection:
      case FeatureFlag.enhancedErrorHandling:
        return true; // Core features - safe to enable by default
      
      case FeatureFlag.nutritionalQueries:
      case FeatureFlag.usdaKnowledgeBase:
        return false; // Advanced features - disable by default if config fails
    }
  }

  /// Hash user ID for consistent rollout percentage
  int _hashUserId(String userId) {
    return userId.hashCode.abs();
  }

  /// Generate random percentile for anonymous users
  double _randomPercentile() {
    return (DateTime.now().millisecondsSinceEpoch % 100) + 1;
  }

  /// Clear cache (for testing)
  void clearCache() {
    _cache.clear();
    _lastCacheUpdate = null;
  }
}

/// Extension for easy feature flag checking
extension FeatureFlagExtension on FeatureFlag {
  /// Check if this feature is enabled for the current user
  Future<bool> isEnabled({String? userId, String? version}) async {
    return await FeatureFlagService().isEnabled(this, userId: userId, version: version);
  }

  /// Get parameters for this feature
  Future<Map<String, dynamic>> getParameters() async {
    return await FeatureFlagService().getParameters(this);
  }
} 