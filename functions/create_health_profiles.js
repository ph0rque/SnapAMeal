#!/usr/bin/env node

// Create health profile documents for demo users
// This fixes the logout issue by ensuring users have proper health profiles

require('dotenv').config({ path: '../.env' });
const admin = require('firebase-admin');

const projectId = process.env.FIREBASE_PROJECT_ID;

// Demo users with their health profile data
const demoUsers = [
  {
    uid: 'V6zg9AM2t3VykqTbV3zAnA2Ogjr1',
    email: 'alice.demo@example.com',
    displayName: 'Alice',
    healthProfile: {
      userId: 'V6zg9AM2t3VykqTbV3zAnA2Ogjr1',
      age: 34,
      gender: 'female',
      heightCm: 168,
      weightKg: 63.5,
      targetWeightKg: 58.0, // Target weight
      activityLevel: 'moderatelyActive',
      primaryGoals: ['weightLoss', 'increaseEnergy'],
      dietaryPreferences: [],
      healthConditions: [],
      allergies: [],
      medications: [],
      mealPatterns: {},
      fastingPatterns: {
        type: '14:10',
        preferredFastingWindow: {
          start: '20:00',
          end: '10:00'
        }
      },
      exercisePatterns: {},
      sleepPatterns: {},
      appUsagePatterns: {},
      receiveAdvice: true,
      preferredAdviceCategories: ['nutrition', 'fasting', 'exercise'],
      notificationPreferences: {
        fastingReminders: true,
        mealLogging: true,
        progressUpdates: true
      },
      timezone: 'America/New_York',
      language: 'en',
      adviceFeedback: {},
      dismissedAdviceTypes: [],
      personalizedInsights: {},
      engagementScore: 0.85,
      bmr: 1450,
      tdee: 1900,
      healthScores: {},
      createdAt: new Date(),
      updatedAt: new Date()
    }
  },
  {
    uid: 'w7NYJtbmZcTi1BxbyhIGI0KXXCF2',
    email: 'bob.demo@example.com',
    displayName: 'Bob',
    healthProfile: {
      userId: 'w7NYJtbmZcTi1BxbyhIGI0KXXCF2',
      age: 25,
      gender: 'male',
      heightCm: 178,
      weightKg: 81.6,
      targetWeightKg: 85.0, // Target weight for muscle gain
      activityLevel: 'veryActive',
      primaryGoals: ['muscleGain', 'enduranceImprovement'],
      dietaryPreferences: [],
      healthConditions: [],
      allergies: [],
      medications: [],
      mealPatterns: {},
      fastingPatterns: {
        type: '16:8',
        preferredFastingWindow: {
          start: '20:00',
          end: '12:00'
        }
      },
      exercisePatterns: {},
      sleepPatterns: {},
      appUsagePatterns: {},
      receiveAdvice: true,
      preferredAdviceCategories: ['nutrition', 'exercise', 'fasting'],
      notificationPreferences: {
        fastingReminders: true,
        mealLogging: false,
        progressUpdates: true
      },
      timezone: 'America/New_York',
      language: 'en',
      adviceFeedback: {},
      dismissedAdviceTypes: [],
      personalizedInsights: {},
      engagementScore: 0.75,
      bmr: 1850,
      tdee: 2500,
      healthScores: {},
      createdAt: new Date(),
      updatedAt: new Date()
    }
  },
  {
    uid: 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2',
    email: 'charlie.demo@example.com',
    displayName: 'Chuck',
    healthProfile: {
      userId: 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2',
      age: 41,
      gender: 'female',
      heightCm: 163,
      weightKg: 72.6,
      targetWeightKg: 65.0, // Target weight
      activityLevel: 'lightlyActive',
      primaryGoals: ['weightLoss', 'stressReduction'],
      dietaryPreferences: ['vegetarian'],
      healthConditions: [],
      allergies: [],
      medications: [],
      mealPatterns: {},
      fastingPatterns: {
        type: '5:2',
        fastingDays: ['monday', 'thursday']
      },
      exercisePatterns: {},
      sleepPatterns: {},
      appUsagePatterns: {},
      receiveAdvice: true,
      preferredAdviceCategories: ['nutrition', 'mindfulness', 'sleep'],
      notificationPreferences: {
        fastingReminders: true,
        mealLogging: true,
        progressUpdates: false
      },
      timezone: 'America/New_York',
      language: 'en',
      adviceFeedback: {},
      dismissedAdviceTypes: [],
      personalizedInsights: {},
      engagementScore: 0.60,
      bmr: 1320,
      tdee: 1650,
      healthScores: {},
      createdAt: new Date(),
      updatedAt: new Date()
    }
  }
];

async function initializeFirebase() {
  try {
    if (admin.apps.length === 0) {
      admin.initializeApp({
        projectId: projectId,
      });
      console.log('✅ Firebase Admin initialized');
    }
    return true;
  } catch (error) {
    console.error('❌ Firebase initialization failed:', error.message);
    return false;
  }
}

async function createHealthProfile(user) {
  try {
    console.log(`📝 Creating health profile for ${user.displayName} (${user.uid})`);

    // Convert dates to Firestore timestamps
    const healthProfileData = {
      ...user.healthProfile,
      createdAt: admin.firestore.Timestamp.fromDate(user.healthProfile.createdAt),
      updatedAt: admin.firestore.Timestamp.fromDate(user.healthProfile.updatedAt),
    };

    // Create health profile document
    await admin.firestore()
      .collection('health_profiles')
      .doc(user.uid)
      .set(healthProfileData);
    
    console.log(`✅ Health profile created for ${user.displayName}`);
    return { success: true, uid: user.uid, email: user.email };
  } catch (error) {
    console.error(`❌ Failed to create health profile for ${user.email}:`, error.message);
    return { success: false, error: error.message };
  }
}

async function createAllHealthProfiles() {
  console.log('🚀 Creating Health Profiles for Demo Users');
  console.log(`📍 Project ID: ${projectId}`);
  console.log(`📊 Users to process: ${demoUsers.length}`);

  // Initialize Firebase
  const firebaseReady = await initializeFirebase();
  if (!firebaseReady) {
    process.exit(1);
  }

  const results = [];

  // Create health profile for each user
  for (const user of demoUsers) {
    const result = await createHealthProfile(user);
    results.push({ user: user.displayName, ...result });
  }

  // Summary
  console.log('\n📊 Health Profile Creation Summary');
  console.log('===================================');
  
  const successful = results.filter(r => r.success);
  const failed = results.filter(r => !r.success);
  
  console.log(`✅ Successful: ${successful.length}`);
  console.log(`❌ Failed: ${failed.length}`);
  
  if (successful.length > 0) {
    console.log('\n✅ Successfully created health profiles:');
    successful.forEach(result => {
      console.log(`   ${result.email} - ${result.uid}`);
    });
  }
  
  if (failed.length > 0) {
    console.log('\n❌ Failed health profiles:');
    failed.forEach(result => {
      console.log(`   ${result.user}: ${result.error}`);
    });
  }

  console.log('\n🎉 Health profile creation completed!');
  console.log('Now demo users should be able to access the main app and logout properly.');
  
  return successful.length === demoUsers.length;
}

// Run the script
if (require.main === module) {
  createAllHealthProfiles()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('💥 Script failed:', error);
      process.exit(1);
    });
}

module.exports = { createAllHealthProfiles }; 