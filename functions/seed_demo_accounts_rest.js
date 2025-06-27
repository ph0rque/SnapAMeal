#!/usr/bin/env node

// Demo Account Seeding Script using Firebase REST API
// Uses Firebase Auth REST API to create demo accounts

require('dotenv').config({ path: '../.env' });

// Firebase configuration from environment
const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY_ANDROID || process.env.FIREBASE_API_KEY_IOS,
  projectId: process.env.FIREBASE_PROJECT_ID,
};

if (!firebaseConfig.apiKey || !firebaseConfig.projectId) {
  console.error('❌ Missing Firebase configuration in .env file');
  console.error('Required: FIREBASE_API_KEY_ANDROID (or FIREBASE_API_KEY_IOS) and FIREBASE_PROJECT_ID');
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

async function createFirebaseUser(email, password, displayName) {
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${firebaseConfig.apiKey}`;
  
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email: email,
      password: password,
      displayName: displayName,
      returnSecureToken: true,
    }),
  });

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.error?.message || 'Failed to create user');
  }

  return {
    uid: data.localId,
    email: data.email,
    token: data.idToken,
  };
}

async function createDemoAccount(account) {
  try {
    // Validate account data
    if (!account.email || !account.password) {
      throw new Error(`Missing email or password for ${account.id}`);
    }

    console.log(`\n📝 Creating demo account: ${account.displayName} (${account.email})`);

    // Create user in Firebase Authentication using REST API
    const userResult = await createFirebaseUser(
      account.email,
      account.password,
      account.displayName
    );

    console.log(`✅ Authentication user created: ${userResult.uid}`);

    // For Firestore, we'll need to use the Firebase Admin SDK or provide manual instructions
    console.log(`ℹ️  User data structure for Firestore (collection: users, doc: ${userResult.uid}):`);
    const userData = {
      ...account.userData,
      uid: userResult.uid,
      email: account.email,
      displayName: account.displayName,
      lastReplayTimestamp: null,
      createdAt: new Date().toISOString(),
    };
    
    console.log(JSON.stringify(userData, null, 2));

    return {
      success: true,
      uid: userResult.uid,
      email: account.email,
      userData: userData,
    };
  } catch (error) {
    if (error.message.includes('EMAIL_EXISTS')) {
      console.log(`⚠️  Account ${account.email} already exists`);
      return {
        success: true,
        uid: 'existing',
        email: account.email,
        existed: true,
      };
    } else {
      console.error(`❌ Failed to create ${account.email}:`, error.message);
      return { success: false, error: error.message };
    }
  }
}

async function seedDemoAccounts() {
  console.log('🚀 Starting Demo Account Seeding (REST API Mode)');
  console.log(`📍 Project ID: ${firebaseConfig.projectId}`);
  console.log(`🔑 Using API Key: ${firebaseConfig.apiKey.substring(0, 10)}...`);
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
    process.exit(1);
  }

  const results = [];
  const firestoreData = [];

  // Create each demo account
  for (const account of demoAccounts) {
    const result = await createDemoAccount(account);
    results.push({ account: account.id, ...result });
    
    if (result.success && result.userData) {
      firestoreData.push({
        uid: result.uid,
        data: result.userData,
      });
    }
  }

  // Summary
  console.log('\n📊 Demo Account Seeding Summary');
  console.log('=====================================');
  
  const successful = results.filter(r => r.success);
  const failed = results.filter(r => !r.success);
  
  console.log(`✅ Successful: ${successful.length}`);
  console.log(`❌ Failed: ${failed.length}`);
  
  if (successful.length > 0) {
    console.log('\n✅ Successfully created accounts in Firebase Auth:');
    successful.forEach(result => {
      const status = result.existed ? '(already existed)' : '(newly created)';
      console.log(`   ${result.email} - ${result.uid} ${status}`);
    });
  }
  
  if (failed.length > 0) {
    console.log('\n❌ Failed accounts:');
    failed.forEach(result => {
      console.log(`   ${result.account}: ${result.error}`);
    });
  }

  // Firestore instructions
  if (firestoreData.length > 0) {
    console.log('\n📄 Next Steps: Add User Data to Firestore');
    console.log('==========================================');
    console.log('Go to Firebase Console > Firestore Database > users collection');
    console.log('Create documents with the following UIDs and data:');
    
    firestoreData.forEach((item, index) => {
      console.log(`\n${index + 1}. Document ID: ${item.uid}`);
      console.log('   Data: (copy the JSON structure shown above for each user)');
    });
    
    console.log('\nAlternatively, you can run these commands in Firebase Console:');
    console.log('firebase firestore:import ./demo-data (if you create a backup file)');
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