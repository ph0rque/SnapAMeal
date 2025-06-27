#!/usr/bin/env node

// Demo Account Seeding Script using Environment Variables
// Reads demo account data from .env file and creates accounts in Firebase

require('dotenv').config({ path: '../.env' });
const admin = require('firebase-admin');

// Initialize Firebase Admin
const projectId = process.env.FIREBASE_PROJECT_ID;

if (!projectId) {
  console.error('❌ FIREBASE_PROJECT_ID not found in environment variables');
  process.exit(1);
}

// Demo account data from environment variables
const demoAccounts = [
  {
    id: 'alice',
    email: process.env.DEMO_USER_1_EMAIL,
    password: process.env.DEMO_USER_1_PASSWORD,
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
    id: 'bob',
    email: process.env.DEMO_USER_2_EMAIL,
    password: process.env.DEMO_USER_2_PASSWORD,
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
    id: 'charlie',
    email: process.env.DEMO_USER_3_EMAIL,
    password: process.env.DEMO_USER_3_PASSWORD,
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
    // Check if Firebase is already initialized
    if (admin.apps.length === 0) {
      // Use Application Default Credentials (works with Firebase CLI login)
      admin.initializeApp({
        projectId: projectId,
      });
      console.log('✅ Firebase initialized with Application Default Credentials');
    }
    return true;
  } catch (error) {
    console.error('❌ Firebase initialization failed:', error.message);
    console.error('💡 Make sure you are logged in with Firebase CLI: firebase login');
    console.error('💡 And the project is set: firebase use ' + projectId);
    return false;
  }
}

async function createDemoAccount(account) {
  try {
    // Validate account data
    if (!account.email || !account.password) {
      throw new Error(`Missing email or password for ${account.id}`);
    }

    console.log(`\n📝 Creating demo account: ${account.displayName} (${account.email})`);

    // Create user in Firebase Authentication
    const userRecord = await admin.auth().createUser({
      email: account.email,
      password: account.password,
      displayName: account.displayName,
      emailVerified: true,
    });

    console.log(`✅ Authentication user created: ${userRecord.uid}`);

    // Add user data to Firestore
    const userData = {
      ...account.userData,
      uid: userRecord.uid,
      email: account.email,
      displayName: account.displayName,
      lastReplayTimestamp: null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await admin.firestore().collection('users').doc(userRecord.uid).set(userData);
    console.log(`✅ Firestore document created for ${account.displayName}`);

    return {
      success: true,
      uid: userRecord.uid,
      email: account.email,
    };
  } catch (error) {
    if (error.code === 'auth/email-already-exists') {
      console.log(`⚠️  Account ${account.email} already exists`);
      
      // Try to get existing user and update Firestore
      try {
        const existingUser = await admin.auth().getUserByEmail(account.email);
        const userData = {
          ...account.userData,
          uid: existingUser.uid,
          email: account.email,
          displayName: account.displayName,
          lastReplayTimestamp: null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        
        await admin.firestore().collection('users').doc(existingUser.uid).set(userData, { merge: true });
        console.log(`✅ Updated Firestore document for existing user ${account.displayName}`);
        
        return {
          success: true,
          uid: existingUser.uid,
          email: account.email,
          existed: true,
        };
      } catch (updateError) {
        console.error(`❌ Failed to update existing user ${account.email}:`, updateError.message);
        return { success: false, error: updateError.message };
      }
    } else {
      console.error(`❌ Failed to create ${account.email}:`, error.message);
      return { success: false, error: error.message };
    }
  }
}

async function seedDemoAccounts() {
  console.log('🚀 Starting Demo Account Seeding');
  console.log(`📍 Project ID: ${projectId}`);
  console.log(`📊 Accounts to create: ${demoAccounts.length}`);

  // Validate environment variables
  const missingVars = [];
  if (!process.env.DEMO_USER_1_EMAIL) missingVars.push('DEMO_USER_1_EMAIL');
  if (!process.env.DEMO_USER_1_PASSWORD) missingVars.push('DEMO_USER_1_PASSWORD');
  if (!process.env.DEMO_USER_2_EMAIL) missingVars.push('DEMO_USER_2_EMAIL');
  if (!process.env.DEMO_USER_2_PASSWORD) missingVars.push('DEMO_USER_2_PASSWORD');
  if (!process.env.DEMO_USER_3_EMAIL) missingVars.push('DEMO_USER_3_EMAIL');
  if (!process.env.DEMO_USER_3_PASSWORD) missingVars.push('DEMO_USER_3_PASSWORD');

  if (missingVars.length > 0) {
    console.error('❌ Missing environment variables:', missingVars.join(', '));
    console.error('Make sure your .env file contains all required DEMO_USER_* variables');
    process.exit(1);
  }

  // Show loaded environment variables (without passwords)
  console.log('\n📋 Environment Variables Loaded:');
  console.log(`   DEMO_USER_1_EMAIL: ${process.env.DEMO_USER_1_EMAIL}`);
  console.log(`   DEMO_USER_2_EMAIL: ${process.env.DEMO_USER_2_EMAIL}`);
  console.log(`   DEMO_USER_3_EMAIL: ${process.env.DEMO_USER_3_EMAIL}`);

  // Initialize Firebase
  const firebaseReady = await initializeFirebase();
  if (!firebaseReady) {
    process.exit(1);
  }

  const results = [];

  // Create each demo account
  for (const account of demoAccounts) {
    const result = await createDemoAccount(account);
    results.push({ account: account.id, ...result });
  }

  // Summary
  console.log('\n📊 Demo Account Seeding Summary');
  console.log('=====================================');
  
  const successful = results.filter(r => r.success);
  const failed = results.filter(r => !r.success);
  
  console.log(`✅ Successful: ${successful.length}`);
  console.log(`❌ Failed: ${failed.length}`);
  
  if (successful.length > 0) {
    console.log('\n✅ Successfully created/updated accounts:');
    successful.forEach(result => {
      const status = result.existed ? '(updated)' : '(created)';
      console.log(`   ${result.email} - ${result.uid} ${status}`);
    });
  }
  
  if (failed.length > 0) {
    console.log('\n❌ Failed accounts:');
    failed.forEach(result => {
      console.log(`   ${result.account}: ${result.error}`);
    });
  }

  console.log('\n🎉 Demo account seeding completed!');
  console.log('You can now use these accounts to demo the application.');
}

// Run the script
if (require.main === module) {
  seedDemoAccounts()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error('💥 Script failed:', error);
      process.exit(1);
    });
}

module.exports = { seedDemoAccounts, createDemoAccount }; 