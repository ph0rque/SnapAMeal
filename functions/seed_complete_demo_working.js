#!/usr/bin/env node

// Complete Demo Data Seeding Script - Working Version
// Creates user documents and all demo data directly in Firestore

require('dotenv').config({ path: '../.env' });

// Initialize Firebase Admin without explicit credentials (uses application default)
const admin = require('firebase-admin');

try {
  // Try to initialize with minimal config
  if (admin.apps.length === 0) {
    admin.initializeApp({
      projectId: process.env.FIREBASE_PROJECT_ID,
    });
  }
  console.log('✅ Firebase Admin initialized');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin:', error.message);
  console.log('💡 Trying alternative initialization...');
  
  // Alternative: try with explicit credential path if available
  try {
    const serviceAccount = require('./serviceAccountKey.json');
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: process.env.FIREBASE_PROJECT_ID,
    });
    console.log('✅ Firebase Admin initialized with service account');
  } catch (altError) {
    console.error('❌ Alternative initialization failed:', altError.message);
    console.log('🔧 Running without Firebase Admin - will generate data files only');
  }
}

const db = admin.firestore ? admin.firestore() : null;

// Demo account UIDs from successful auth creation
const demoUsers = [
  {
    uid: 'V6zg9AM2t3VykqTbV3zAnA2Ogjr1',
    email: 'alice.demo@example.com',
    displayName: 'Alice',
    persona: 'alice',
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
    persona: 'bob',
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
    displayName: 'Chuck',
    persona: 'charlie',
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

// Generate realistic meal data
function generateMealData(userId, persona, daysBack) {
  const meals = [];
  const mealTypes = ['breakfast', 'lunch', 'dinner', 'snack'];
  
  for (let day = 0; day < daysBack; day++) {
    const date = new Date();
    date.setDate(date.getDate() - day);
    
    const mealsPerDay = Math.floor(Math.random() * 2) + 2;
    
    for (let i = 0; i < mealsPerDay; i++) {
      const mealType = mealTypes[i % mealTypes.length];
      
      meals.push({
        userId: userId,
        timestamp: admin.firestore ? admin.firestore.Timestamp.fromDate(date) : date.toISOString(),
        mealType: mealType,
        description: getMealDescription(persona, mealType),
        calories: getMealCalories(persona, mealType),
        nutrition: getNutritionData(persona, mealType),
        isDemo: true,
        createdAt: admin.firestore ? admin.firestore.FieldValue.serverTimestamp() : new Date().toISOString()
      });
    }
  }
  
  return meals;
}

function getMealDescription(persona, mealType) {
  const meals = {
    alice: {
      breakfast: ['Overnight oats with berries', 'Green smoothie bowl', 'Avocado toast'],
      lunch: ['Quinoa salad', 'Grilled chicken wrap', 'Buddha bowl'],
      dinner: ['Salmon with vegetables', 'Stir-fry with tofu', 'Zucchini noodles'],
      snack: ['Apple with almond butter', 'Greek yogurt', 'Mixed nuts']
    },
    bob: {
      breakfast: ['Protein pancakes', 'Eggs and oatmeal', 'Protein smoothie'],
      lunch: ['Chicken and rice', 'Turkey sandwich', 'Protein bowl'],
      dinner: ['Lean beef with quinoa', 'Grilled fish', 'Chicken stir-fry'],
      snack: ['Protein bar', 'Cottage cheese', 'Whey shake']
    },
    charlie: {
      breakfast: ['Vegetarian omelet', 'Chia pudding', 'Whole grain toast'],
      lunch: ['Lentil soup', 'Veggie wrap', 'Quinoa salad'],
      dinner: ['Vegetable curry', 'Pasta primavera', 'Stuffed bell peppers'],
      snack: ['Hummus with vegetables', 'Trail mix', 'Herbal tea']
    }
  };
  
  const options = meals[persona]?.[mealType] || ['Healthy meal'];
  return options[Math.floor(Math.random() * options.length)];
}

function getMealCalories(persona, mealType) {
  const ranges = {
    alice: { breakfast: [300, 400], lunch: [400, 500], dinner: [500, 600], snack: [100, 200] },
    bob: { breakfast: [500, 600], lunch: [600, 700], dinner: [700, 800], snack: [200, 300] },
    charlie: { breakfast: [250, 350], lunch: [350, 450], dinner: [400, 500], snack: [100, 150] }
  };
  
  const range = ranges[persona]?.[mealType] || [300, 500];
  return Math.floor(Math.random() * (range[1] - range[0]) + range[0]);
}

function getNutritionData(persona, mealType) {
  return {
    protein: Math.floor(Math.random() * 30) + 10,
    carbs: Math.floor(Math.random() * 50) + 20,
    fat: Math.floor(Math.random() * 20) + 5,
    fiber: Math.floor(Math.random() * 15) + 3
  };
}

// Generate fasting session data
function generateFastingData(userId, persona, daysBack) {
  const sessions = [];
  const userData = demoUsers.find(u => u.uid === userId);
  const fastingType = userData.userData.healthProfile.fastingType;
  
  for (let day = 0; day < daysBack; day++) {
    const date = new Date();
    date.setDate(date.getDate() - day);
    
    if (Math.random() < 0.15) continue;
    
    const session = generateFastingSession(fastingType, date, userId);
    if (session) {
      sessions.push(session);
    }
  }
  
  return sessions;
}

function generateFastingSession(fastingType, date, userId) {
  let startTime, endTime;
  
  switch (fastingType) {
    case '14:10':
      startTime = new Date(date);
      startTime.setHours(20, 0, 0, 0);
      endTime = new Date(startTime);
      endTime.setHours(endTime.getHours() + 14);
      break;
    case '16:8':
      startTime = new Date(date);
      startTime.setHours(20, 0, 0, 0);
      endTime = new Date(startTime);
      endTime.setHours(endTime.getHours() + 16);
      break;
    case '5:2':
      if (date.getDay() === 1 || date.getDay() === 4) {
        startTime = new Date(date);
        startTime.setHours(18, 0, 0, 0);
        endTime = new Date(startTime);
        endTime.setHours(endTime.getHours() + 24);
      } else {
        return null;
      }
      break;
    default:
      return null;
  }
  
  return {
    userId: userId,
    startTime: admin.firestore ? admin.firestore.Timestamp.fromDate(startTime) : startTime.toISOString(),
    endTime: admin.firestore ? admin.firestore.Timestamp.fromDate(endTime) : endTime.toISOString(),
    duration: (endTime - startTime) / (1000 * 60 * 60),
    completed: Math.random() < 0.85,
    type: fastingType,
    isDemo: true,
    createdAt: admin.firestore ? admin.firestore.FieldValue.serverTimestamp() : new Date().toISOString()
  };
}

// Upload data to Firestore in batches
async function uploadToFirestore(collection, data) {
  if (!db) {
    console.log(`   ❌ Firestore not available - skipping ${collection} upload`);
    return 0;
  }

  const batchSize = 500;
  let uploadedCount = 0;
  
  for (let i = 0; i < data.length; i += batchSize) {
    const batch = db.batch();
    const chunk = data.slice(i, i + batchSize);
    
    chunk.forEach((item, index) => {
      const docRef = db.collection(collection).doc();
      batch.set(docRef, item);
    });
    
    try {
      await batch.commit();
      uploadedCount += chunk.length;
      console.log(`   Uploaded ${uploadedCount}/${data.length} ${collection} documents`);
    } catch (error) {
      console.error(`   Failed to upload batch: ${error.message}`);
    }
  }
  
  return uploadedCount;
}

// Create user documents and all demo data
async function createCompleteUserData(user) {
  console.log(`\n📝 Creating complete data for ${user.displayName}...`);
  
  try {
    const userData = {
      ...user.userData,
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      lastReplayTimestamp: null,
      createdAt: admin.firestore ? admin.firestore.FieldValue.serverTimestamp() : new Date().toISOString(),
    };

    // Generate all demo data
    const mealData = generateMealData(user.uid, user.persona, 30);
    const fastingData = generateFastingData(user.uid, user.persona, 35);

    console.log(`📊 Generated data for ${user.displayName}:`);
    console.log(`   - User profile: 1 document`);
    console.log(`   - Meal logs: ${mealData.length} documents`);
    console.log(`   - Fasting sessions: ${fastingData.length} documents`);

    if (db) {
      // Upload user document
      await db.collection('users').doc(user.uid).set(userData);
      console.log(`✅ User profile uploaded`);

      // Upload meal logs
      const mealsUploaded = await uploadToFirestore('meal_logs', mealData);
      console.log(`✅ Meal logs uploaded: ${mealsUploaded}/${mealData.length}`);

      // Upload fasting sessions  
      const fastingUploaded = await uploadToFirestore('fasting_sessions', fastingData);
      console.log(`✅ Fasting sessions uploaded: ${fastingUploaded}/${fastingData.length}`);

      return {
        success: true,
        counts: {
          user: 1,
          meals: mealsUploaded,
          fasting: fastingUploaded
        }
      };
    } else {
      console.log(`⚠️  Firestore not available - data generated but not uploaded`);
      return {
        success: false,
        error: 'Firestore not available',
        data: { userData, mealData, fastingData }
      };
    }
  } catch (error) {
    console.error(`❌ Failed to create data for ${user.email}:`, error.message);
    return { success: false, error: error.message };
  }
}

// Main seeding function
async function seedCompleteDemo() {
  console.log('🚀 Starting Complete Demo Data Seeding');
  console.log(`📍 Project ID: ${process.env.FIREBASE_PROJECT_ID}`);
  console.log(`📊 Users to process: ${demoUsers.length}`);
  console.log(`🔧 Firestore available: ${db ? 'Yes' : 'No'}`);

  const results = [];
  let totalCounts = { user: 0, meals: 0, fasting: 0 };

  // Create data for each user
  for (const user of demoUsers) {
    const result = await createCompleteUserData(user);
    results.push(result);
    
    if (result.success) {
      totalCounts.user += result.counts.user;
      totalCounts.meals += result.counts.meals;
      totalCounts.fasting += result.counts.fasting;
    }
  }

  // Summary
  console.log('\n📊 Complete Demo Data Seeding Summary');
  console.log('====================================');
  
  const successful = results.filter(r => r.success);
  const failed = results.filter(r => !r.success);
  
  console.log(`✅ Successful: ${successful.length}`);
  console.log(`❌ Failed: ${failed.length}`);
  
  if (successful.length > 0) {
    console.log('\n📈 Total documents uploaded:');
    console.log(`   - User profiles: ${totalCounts.user}`);
    console.log(`   - Meal logs: ${totalCounts.meals}`);
    console.log(`   - Fasting sessions: ${totalCounts.fasting}`);
    console.log(`   - GRAND TOTAL: ${totalCounts.user + totalCounts.meals + totalCounts.fasting} documents`);
    
    console.log('\n✅ Successfully seeded data for:');
    successful.forEach((result, index) => {
      const user = demoUsers[index];
      console.log(`   ${user.email} - ${user.uid}`);
    });
  }
  
  if (failed.length > 0) {
    console.log('\n❌ Failed data upload:');
    failed.forEach((result, index) => {
      const user = demoUsers[index];
      console.log(`   ${user.email}: ${result.error}`);
    });
  }

  console.log('\n🎉 Demo data seeding completed!');
  console.log('📋 Next steps:');
  console.log('   1. Test demo login in your app');
  console.log('   2. Verify all data appears correctly');
  console.log('   3. Check Firestore console to confirm data structure');
  
  return successful.length === demoUsers.length;
}

// Run the script
if (require.main === module) {
  seedCompleteDemo()
    .then((success) => {
      console.log('\n🏁 Script completed');
      process.exit(success ? 0 : 1);
    })
    .catch((error) => {
      console.error('💥 Script failed:', error);
      process.exit(1);
    });
}

module.exports = { seedCompleteDemo }; 