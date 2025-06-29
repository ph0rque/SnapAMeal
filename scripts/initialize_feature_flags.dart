#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:snapameal/config/feature_flags.dart';
import 'dart:developer' as developer;

/// Script to initialize feature flags collection in Firestore
/// This ensures the feature flags are available for the app to read
///
/// Usage: dart run scripts/initialize_feature_flags.dart

Future<void> main() async {
  developer.log('🚀 Initializing Feature Flags...');
  
  try {
    // Initialize Firebase
    developer.log('🔥 Connecting to Firebase...');
    await Firebase.initializeApp();
    developer.log('✅ Firebase connected successfully');
    
    final firestore = FirebaseFirestore.instance;
    
    // Create feature flags collection
    developer.log('📝 Creating feature flags in Firestore...');
    
    final batch = firestore.batch();
    
    // Define feature flags with their default states
    final featureFlags = {
      FeatureFlag.hybridProcessing: {
        'enabled': true,
        'rolloutPercentage': 100,
        'description': 'Hybrid processing for meal recognition',
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      FeatureFlag.inlineFoodCorrection: {
        'enabled': true,
        'rolloutPercentage': 90,
        'description': 'Inline food correction interface',
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      FeatureFlag.nutritionalQueries: {
        'enabled': true,
        'rolloutPercentage': 80,
        'description': 'Natural language nutritional queries',
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      FeatureFlag.performanceMonitoring: {
        'enabled': true,
        'rolloutPercentage': 100,
        'description': 'Performance monitoring and metrics',
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      FeatureFlag.advancedFirebaseSearch: {
        'enabled': true,
        'rolloutPercentage': 100,
        'description': 'Advanced Firebase search capabilities',
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      FeatureFlag.usdaKnowledgeBase: {
        'enabled': true,
        'rolloutPercentage': 80,
        'description': 'USDA knowledge base integration',
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      FeatureFlag.circuitBreakers: {
        'enabled': true,
        'rolloutPercentage': 100,
        'description': 'Circuit breakers for service resilience',
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      FeatureFlag.costTracking: {
        'enabled': true,
        'rolloutPercentage': 100,
        'description': 'Cost tracking and monitoring',
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      FeatureFlag.userFeedbackCollection: {
        'enabled': true,
        'rolloutPercentage': 100,
        'description': 'User feedback collection system',
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      FeatureFlag.enhancedErrorHandling: {
        'enabled': true,
        'rolloutPercentage': 100,
        'description': 'Enhanced error handling and recovery',
        'lastUpdated': FieldValue.serverTimestamp(),
      },
    };
    
    // Add each feature flag to the batch
    for (final entry in featureFlags.entries) {
      final flagName = entry.key.toString().split('.').last;
      final flagData = entry.value;
      
      final docRef = firestore.collection('feature_flags').doc(flagName);
      batch.set(docRef, flagData);
      
      final isEnabled = flagData['enabled'] as bool;
      developer.log('  📋 Added: $flagName (${isEnabled ? 'enabled' : 'disabled'})');
    }
    
    // Commit the batch
    await batch.commit();
    developer.log('✅ Feature flags initialized successfully!');
    
  } catch (e) {
    developer.log('❌ Failed to initialize feature flags: $e');
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