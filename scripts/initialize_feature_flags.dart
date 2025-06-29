import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Script to initialize feature flags collection in Firestore
/// This ensures the feature flags are available for the app to read
///
/// Usage: dart run scripts/initialize_feature_flags.dart

void main() async {
  print('🚩 Initializing feature flags in Firestore...');
  
  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    exit(1);
  }

  final initializer = FeatureFlagInitializer();
  
  try {
    await initializer.initializeFeatureFlags();
    print('🎉 Feature flags initialization completed successfully!');
  } catch (e) {
    print('❌ Error during initialization: $e');
    exit(1);
  }
}

/// Initializes feature flags in Firestore
class FeatureFlagInitializer {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize all feature flags with production-ready defaults
  Future<void> initializeFeatureFlags() async {
    print('📝 Creating default feature flag configurations...');
    
    final defaultConfigs = _getDefaultConfigurations();
    
    for (final config in defaultConfigs) {
      try {
        await _firestore
            .collection('feature_flags')
            .doc(config['flag'])
            .set(config, SetOptions(merge: true));
        
        print('✅ Created feature flag: ${config['flag']}');
      } catch (e) {
        print('❌ Error creating feature flag ${config['flag']}: $e');
      }
    }
    
    print('📊 Successfully initialized ${defaultConfigs.length} feature flags');
  }

  /// Get default feature flag configurations for production
  List<Map<String, dynamic>> _getDefaultConfigurations() {
    return [
      {
        'flag': 'hybridProcessing',
        'enabled': true,
        'rolloutPercentage': 100.0,
        'allowedUserIds': [],
        'allowedVersions': ['4.0.0', '4.0.1', '4.1.0'],
        'expiresAt': null,
        'parameters': {
          'confidence_threshold': 0.7,
          'fallback_enabled': true,
          'tensorflow_timeout_ms': 5000,
        },
      },
      {
        'flag': 'inlineFoodCorrection',
        'enabled': true,
        'rolloutPercentage': 100.0,
        'allowedUserIds': [],
        'allowedVersions': ['4.0.0', '4.0.1', '4.1.0'],
        'expiresAt': null,
        'parameters': {
          'autocomplete_enabled': true,
          'debounce_ms': 300,
          'max_suggestions': 8,
        },
      },
      {
        'flag': 'nutritionalQueries',
        'enabled': true,
        'rolloutPercentage': 90.0,
        'allowedUserIds': [],
        'allowedVersions': ['4.0.0', '4.0.1', '4.1.0'],
        'expiresAt': null,
        'parameters': {
          'max_results': 5,
          'safety_disclaimers': true,
          'cache_responses': true,
        },
      },
      {
        'flag': 'performanceMonitoring',
        'enabled': true,
        'rolloutPercentage': 100.0,
        'allowedUserIds': [],
        'allowedVersions': [],
        'expiresAt': null,
        'parameters': {
          'collect_metrics': true,
          'cost_tracking': true,
          'circuit_breakers': true,
        },
      },
      {
        'flag': 'advancedFirebaseSearch',
        'enabled': true,
        'rolloutPercentage': 100.0,
        'allowedUserIds': [],
        'allowedVersions': [],
        'expiresAt': null,
        'parameters': {
          'fuzzy_search': true,
          'similarity_threshold': 0.6,
          'auto_backfill': true,
        },
      },
      {
        'flag': 'usdaKnowledgeBase',
        'enabled': true,
        'rolloutPercentage': 80.0,
        'allowedUserIds': [],
        'allowedVersions': ['4.0.0', '4.0.1', '4.1.0'],
        'expiresAt': null,
        'parameters': {
          'enable_indexing': false,
          'fallback_to_local': true,
        },
      },
      {
        'flag': 'circuitBreakers',
        'enabled': true,
        'rolloutPercentage': 100.0,
        'allowedUserIds': [],
        'allowedVersions': [],
        'expiresAt': null,
        'parameters': {
          'failure_threshold': 5,
          'recovery_timeout_minutes': 5,
        },
      },
      {
        'flag': 'costTracking',
        'enabled': true,
        'rolloutPercentage': 100.0,
        'allowedUserIds': [],
        'allowedVersions': [],
        'expiresAt': null,
        'parameters': {
          'track_openai_costs': true,
          'track_firebase_usage': true,
          'cost_alert_threshold_usd': 10.0,
        },
      },
      {
        'flag': 'userFeedbackCollection',
        'enabled': true,
        'rolloutPercentage': 100.0,
        'allowedUserIds': [],
        'allowedVersions': [],
        'expiresAt': null,
        'parameters': {
          'collect_satisfaction': true,
          'collect_performance_feedback': true,
          'collect_error_reports': true,
        },
      },
      {
        'flag': 'enhancedErrorHandling',
        'enabled': true,
        'rolloutPercentage': 100.0,
        'allowedUserIds': [],
        'allowedVersions': [],
        'expiresAt': null,
        'parameters': {
          'detailed_error_logging': true,
          'user_friendly_messages': true,
          'automatic_retry': true,
        },
      },
    ];
  }
} 