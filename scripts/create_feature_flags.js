const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'snapameal-cabc7'
});

const db = admin.firestore();

// Default feature flag configurations
const defaultFeatureFlags = [
  {
    flag: 'hybridProcessing',
    enabled: true,
    rolloutPercentage: 100.0,
    allowedUserIds: [],
    allowedVersions: ['4.0.0', '4.0.1', '4.1.0'],
    expiresAt: null,
    parameters: {
      confidence_threshold: 0.7,
      fallback_enabled: true,
      tensorflow_timeout_ms: 5000,
    },
  },
  {
    flag: 'inlineFoodCorrection',
    enabled: true,
    rolloutPercentage: 100.0,
    allowedUserIds: [],
    allowedVersions: ['4.0.0', '4.0.1', '4.1.0'],
    expiresAt: null,
    parameters: {
      autocomplete_enabled: true,
      debounce_ms: 300,
      max_suggestions: 8,
    },
  },
  {
    flag: 'nutritionalQueries',
    enabled: true,
    rolloutPercentage: 90.0,
    allowedUserIds: [],
    allowedVersions: ['4.0.0', '4.0.1', '4.1.0'],
    expiresAt: null,
    parameters: {
      max_results: 5,
      safety_disclaimers: true,
      cache_responses: true,
    },
  },
  {
    flag: 'performanceMonitoring',
    enabled: true,
    rolloutPercentage: 100.0,
    allowedUserIds: [],
    allowedVersions: [],
    expiresAt: null,
    parameters: {
      collect_metrics: true,
      cost_tracking: true,
      circuit_breakers: true,
    },
  },
  {
    flag: 'advancedFirebaseSearch',
    enabled: true,
    rolloutPercentage: 100.0,
    allowedUserIds: [],
    allowedVersions: [],
    expiresAt: null,
    parameters: {
      fuzzy_search: true,
      similarity_threshold: 0.6,
      auto_backfill: true,
    },
  },
  {
    flag: 'usdaKnowledgeBase',
    enabled: true,
    rolloutPercentage: 80.0,
    allowedUserIds: [],
    allowedVersions: ['4.0.0', '4.0.1', '4.1.0'],
    expiresAt: null,
    parameters: {
      enable_indexing: false,
      fallback_to_local: true,
    },
  },
  {
    flag: 'circuitBreakers',
    enabled: true,
    rolloutPercentage: 100.0,
    allowedUserIds: [],
    allowedVersions: [],
    expiresAt: null,
    parameters: {
      failure_threshold: 5,
      recovery_timeout_minutes: 5,
    },
  },
  {
    flag: 'costTracking',
    enabled: true,
    rolloutPercentage: 100.0,
    allowedUserIds: [],
    allowedVersions: [],
    expiresAt: null,
    parameters: {
      track_openai_costs: true,
      track_firebase_usage: true,
      cost_alert_threshold_usd: 10.0,
    },
  },
  {
    flag: 'userFeedbackCollection',
    enabled: true,
    rolloutPercentage: 100.0,
    allowedUserIds: [],
    allowedVersions: [],
    expiresAt: null,
    parameters: {
      collect_satisfaction: true,
      collect_performance_feedback: true,
      collect_error_reports: true,
    },
  },
  {
    flag: 'enhancedErrorHandling',
    enabled: true,
    rolloutPercentage: 100.0,
    allowedUserIds: [],
    allowedVersions: [],
    expiresAt: null,
    parameters: {
      detailed_error_logging: true,
      user_friendly_messages: true,
      automatic_retry: true,
    },
  },
];

async function createFeatureFlags() {
  console.log('🚩 Creating feature flags in Firestore...');
  
  try {
    const batch = db.batch();
    
    for (const config of defaultFeatureFlags) {
      const docRef = db.collection('feature_flags').doc(config.flag);
      batch.set(docRef, config, { merge: true });
      console.log(`✅ Prepared feature flag: ${config.flag}`);
    }
    
    await batch.commit();
    console.log(`🎉 Successfully created ${defaultFeatureFlags.length} feature flags!`);
    
  } catch (error) {
    console.error('❌ Error creating feature flags:', error);
    process.exit(1);
  }
  
  process.exit(0);
}

createFeatureFlags(); 