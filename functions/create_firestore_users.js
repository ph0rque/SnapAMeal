#!/usr/bin/env node

// Create Firestore user documents for demo accounts
// This adds the user profile data to match the UIDs from Firebase Auth

require('dotenv').config({ path: '../.env' });
const admin = require('firebase-admin');

const projectId = process.env.FIREBASE_PROJECT_ID;

// Demo account UIDs from the successful auth creation
const demoUsers = [
  {
    uid: 'V6zg9AM2t3VykqTbV3zAnA2Ogjr1',
    email: 'alice.demo@example.com',
    displayName: 'Alice',
    userData: {
      username: 'alice_freelancer',
      age: 34,
      occupation: 'Freelancer',
      isDemo: true,
      demoPersonaId: 'alice',
      healthProfile: {
        height: 168,
        weight: 63.5,
        gender: 'female',
        fastingType: '14:10',
        calorieTarget: 1600,
        activityLevel: 'moderate',
        goals: ['weight_loss', 'energy'],
        dietaryRestrictions: [],
      },
    },
  },
  {
    uid: 'w7NYJtbmZcTi1BxbyhIGI0KXXCF2',
    email: 'bob.demo@example.com',
    displayName: 'Bob',
    userData: {
      username: 'bob_retail',
      age: 25,
      occupation: 'Retail Worker',
      isDemo: true,
      demoPersonaId: 'bob',
      healthProfile: {
        height: 178,
        weight: 81.6,
        gender: 'male',
        fastingType: '16:8',
        calorieTarget: 1800,
        activityLevel: 'active',
        goals: ['muscle_gain', 'strength'],
        dietaryRestrictions: [],
      },
    },
  },
  {
    uid: 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2',
    email: 'charlie.demo@example.com',
    displayName: 'Charlie',
    userData: {
      username: 'charlie_teacher',
      age: 41,
      occupation: 'Teacher',
      isDemo: true,
      demoPersonaId: 'charlie',
      healthProfile: {
        height: 163,
        weight: 72.6,
        gender: 'female',
        fastingType: '5:2',
        calorieTarget: 1400,
        activityLevel: 'light',
        goals: ['weight_loss', 'health'],
        dietaryRestrictions: ['vegetarian'],
      },
    },
  },
];

async function initializeFirebase() {
  try {
    if (admin.apps.length === 0) {
      admin.initializeApp({
        projectId: projectId,
      });
      console.log('✅ Firebase initialized with Application Default Credentials');
    }
    return true;
  } catch (error) {
    console.error('❌ Firebase initialization failed:', error.message);
    return false;
  }
}

async function createFirestoreUserDocument(user) {
  try {
    console.log(`📝 Creating Firestore document for ${user.displayName} (${user.uid})`);

    const userData = {
      ...user.userData,
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      lastReplayTimestamp: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Create user document in the main users collection
    await admin.firestore().collection('users').doc(user.uid).set(userData);
    
    console.log(`✅ Created user document for ${user.displayName}`);

    return { success: true, uid: user.uid, email: user.email };
  } catch (error) {
    console.error(`❌ Failed to create Firestore document for ${user.email}:`, error.message);
    return { success: false, error: error.message };
  }
}

async function createAllFirestoreUsers() {
  console.log('🚀 Creating Firestore User Documents');
  console.log(`📍 Project ID: ${projectId}`);
  console.log(`📊 Users to create: ${demoUsers.length}`);

  // Initialize Firebase
  const firebaseReady = await initializeFirebase();
  if (!firebaseReady) {
    process.exit(1);
  }

  const results = [];

  // Create each user document
  for (const user of demoUsers) {
    const result = await createFirestoreUserDocument(user);
    results.push({ user: user.displayName, ...result });
  }

  // Summary
  console.log('\n📊 Firestore User Creation Summary');
  console.log('===================================');
  
  const successful = results.filter(r => r.success);
  const failed = results.filter(r => !r.success);
  
  console.log(`✅ Successful: ${successful.length}`);
  console.log(`❌ Failed: ${failed.length}`);
  
  if (successful.length > 0) {
    console.log('\n✅ Successfully created user documents:');
    successful.forEach(result => {
      console.log(`   ${result.email} - ${result.uid}`);
    });
  }
  
  if (failed.length > 0) {
    console.log('\n❌ Failed user documents:');
    failed.forEach(result => {
      console.log(`   ${result.user}: ${result.error}`);
    });
  }

  console.log('\n🎉 User document creation completed!');
  console.log('Now you can run the demo data seeding script.');
  
  return successful.length === demoUsers.length;
}

// Run the script
if (require.main === module) {
  createAllFirestoreUsers()
    .then((success) => {
      if (success) {
        console.log('\n📋 Next step: Run the demo data seeding script');
        console.log('   cd .. && dart scripts/seed_demo_data.dart');
      }
      process.exit(success ? 0 : 1);
    })
    .catch((error) => {
      console.error('💥 Script failed:', error);
      process.exit(1);
    });
}

module.exports = { createAllFirestoreUsers }; 