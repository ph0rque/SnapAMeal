#!/usr/bin/env node

// Simple User Document Creator
// Just creates the 3 user documents needed for demo login

require('dotenv').config({ path: '../.env' });

const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY_ANDROID || process.env.FIREBASE_API_KEY_IOS,
  projectId: process.env.FIREBASE_PROJECT_ID,
};

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

async function createUserDocuments() {
  console.log('🚀 Creating Demo User Documents');
  console.log('===============================');
  
  console.log('\n📋 Manual Setup Instructions:');
  console.log('Go to Firebase Console → Firestore Database → Create these documents:');
  console.log('\n📁 Collection: "users"');
  
  demoUsers.forEach((user, index) => {
    const userData = {
      ...user.userData,
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      lastReplayTimestamp: null,
      createdAt: new Date().toISOString(),
    };
    
    console.log(`\n${index + 1}. Document ID: ${user.uid}`);
    console.log('   Data:');
    console.log(JSON.stringify(userData, null, 4));
    console.log('\n' + '='.repeat(60));
  });
  
  console.log('\n✅ After creating these 3 documents:');
  console.log('   - Demo accounts can log in');
  console.log('   - App will generate additional demo data automatically');
  console.log('   - Test with alice.demo@example.com / demopass123');
  console.log('   - Test with bob.demo@example.com / demopass123');
  console.log('   - Test with charlie.demo@example.com / demopass123');
  
  return true;
}

// Run the script
if (require.main === module) {
  createUserDocuments()
    .then(() => {
      console.log('\n🎉 Instructions generated successfully!');
      process.exit(0);
    })
    .catch((error) => {
      console.error('💥 Script failed:', error);
      process.exit(1);
    });
} 