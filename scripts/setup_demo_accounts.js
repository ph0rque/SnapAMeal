#!/usr/bin/env node

// Firebase Admin SDK Demo Account Setup Script
// Usage: node scripts/setup_demo_accounts.js

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Demo account data
const demoAccounts = [
  {
    id: 'alice',
    email: 'alice.demo@example.com',
    password: 'DemoAlice2024!',
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
    email: 'bob.demo@example.com',
    password: 'DemoBob2024!',
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
    email: 'charlie.demo@example.com',
    password: 'DemoCharlie2024!',
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

async function setupDemoAccounts() {
  try {
    console.log('🔥 Setting up Firebase Admin SDK...');
    
    // Initialize Firebase Admin SDK
    // You'll need to set up a service account key
    const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH || './firebase-service-account.json';
    
    if (!fs.existsSync(serviceAccountPath)) {
      console.log('❌ Firebase service account key not found');
      console.log('📋 To use this script:');
      console.log('1. Go to Firebase Console > Project Settings > Service Accounts');
      console.log('2. Click "Generate new private key"');
      console.log('3. Save the JSON file as firebase-service-account.json in the project root');
      console.log('4. Or set FIREBASE_SERVICE_ACCOUNT_PATH environment variable');
      console.log('');
      console.log('⚠️  Alternative: Use the manual setup instructions from the Dart script');
      process.exit(1);
    }

    const serviceAccount = require(path.resolve(serviceAccountPath));
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    console.log('✅ Firebase Admin SDK initialized');
    
    const auth = admin.auth();
    const firestore = admin.firestore();
    
    // Create demo accounts
    for (const account of demoAccounts) {
      try {
        console.log(`📝 Creating account for ${account.displayName}...`);
        
        // Check if user already exists
        let userRecord;
        try {
          userRecord = await auth.getUserByEmail(account.email);
          console.log(`✅ User ${account.displayName} already exists`);
        } catch (error) {
          if (error.code === 'auth/user-not-found') {
            // Create new user
            userRecord = await auth.createUser({
              email: account.email,
              password: account.password,
              displayName: account.displayName,
            });
            console.log(`✅ Created user ${account.displayName}`);
          } else {
            throw error;
          }
        }
        
        // Create/update Firestore document
        const userDoc = firestore.collection('users').doc(userRecord.uid);
        await userDoc.set({
          uid: userRecord.uid,
          email: account.email,
          displayName: account.displayName,
          ...account.userData,
          lastReplayTimestamp: null,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        
        console.log(`✅ Updated Firestore data for ${account.displayName}`);
        
      } catch (error) {
        console.log(`❌ Failed to create account for ${account.displayName}:`, error.message);
      }
    }
    
    console.log('🎉 Demo account setup completed!');
    console.log('📋 Demo accounts available:');
    for (const account of demoAccounts) {
      console.log(`  • ${account.displayName} (${account.id}) - ${account.email}`);
    }
    
  } catch (error) {
    console.log('💥 Setup failed:', error.message);
    process.exit(1);
  }
}

// Run the setup
setupDemoAccounts().then(() => {
  console.log('✅ Setup complete');
  process.exit(0);
}); 