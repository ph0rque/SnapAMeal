#!/usr/bin/env node

// Simple Demo Data Generator
// Generates properly formatted demo data for Firebase import

require('dotenv').config({ path: '../.env' });

const fs = require('fs');

console.log('🚀 Generating Complete Demo Data');
console.log('===============================');

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
    displayName: 'Charlie',
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
    
    const mealsPerDay = Math.floor(Math.random() * 2) + 2; // 2-3 meals per day
    
    for (let i = 0; i < mealsPerDay; i++) {
      const mealType = mealTypes[i % mealTypes.length];
      
      meals.push({
        userId: userId,
        timestamp: date.toISOString(),
        mealType: mealType,
        description: getMealDescription(persona, mealType),
        calories: getMealCalories(persona, mealType),
        nutrition: getNutritionData(persona, mealType),
        isDemo: true,
        createdAt: new Date().toISOString()
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
    
    // Skip some days randomly for realism
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
    startTime: startTime.toISOString(),
    endTime: endTime.toISOString(),
    duration: (endTime - startTime) / (1000 * 60 * 60),
    completed: Math.random() < 0.85,
    type: fastingType,
    isDemo: true,
    createdAt: new Date().toISOString()
  };
}

// Main generation function
function generateCompleteDemo() {
  const userData = {};
  let totalCount = 0;

  console.log('📝 Generating user profiles and demo data...\n');

  demoUsers.forEach(user => {
    // User profile
    const userProfile = {
      ...user.userData,
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      lastReplayTimestamp: null,
      createdAt: new Date().toISOString(),
    };

    // Generate demo data
    const mealData = generateMealData(user.uid, user.persona, 30);
    const fastingData = generateFastingData(user.uid, user.persona, 35);

    console.log(`✅ ${user.displayName} (${user.email}):`);
    console.log(`   - User profile: 1 document`);
    console.log(`   - Meal logs: ${mealData.length} documents`);
    console.log(`   - Fasting sessions: ${fastingData.length} documents`);
    
    totalCount += 1 + mealData.length + fastingData.length;

    // Store in userData object
    userData[user.uid] = {
      profile: userProfile,
      meals: mealData,
      fasting: fastingData
    };
  });

  console.log(`\n📊 Total documents to create: ${totalCount}`);

  // Write manual instructions
  const instructions = `
# Manual Demo Data Setup Instructions

## ✅ Authentication Accounts (Already Created)
${demoUsers.map(user => `- ${user.email} - UID: ${user.uid}`).join('\n')}

## 📝 Next: Create User Documents in Firestore

Go to Firebase Console → Firestore Database → Create the following documents:

### Collection: "users"

${demoUsers.map(user => `
#### Document ID: ${user.uid}
\`\`\`json
${JSON.stringify(userData[user.uid].profile, null, 2)}
\`\`\`
`).join('\n')}

## 📱 App Will Handle the Rest

Once user documents are created, the app's built-in demo data services will automatically generate:
- Historical meal logs (${demoUsers.reduce((sum, user) => sum + userData[user.uid].meals.length, 0)} total)
- Fasting session history (${demoUsers.reduce((sum, user) => sum + userData[user.uid].fasting.length, 0)} total)
- AI advice conversations
- Social connections
- Health challenges
- Progress stories

The app creates this data when demo users log in and use features.

## 🎉 Ready to Test!

1. Create the 3 user documents above in Firestore
2. Test logging in with demo accounts
3. Verify the demo experience works as expected

All demo accounts use password: "demopass123"
`;

  // Write detailed data (for reference or advanced setup)
  const detailedData = {
    userProfiles: Object.fromEntries(demoUsers.map(user => [user.uid, userData[user.uid].profile])),
    mealLogs: Object.fromEntries(demoUsers.flatMap(user => 
      userData[user.uid].meals.map((meal, i) => [`${user.uid}_meal_${i}`, meal])
    )),
    fastingSessions: Object.fromEntries(demoUsers.flatMap(user => 
      userData[user.uid].fasting.map((session, i) => [`${user.uid}_fast_${i}`, session])
    ))
  };

  // Write files
  fs.writeFileSync('../DEMO_SETUP_INSTRUCTIONS.md', instructions);
  fs.writeFileSync('../demo-data-complete.json', JSON.stringify(detailedData, null, 2));

  console.log('\n📄 Files created:');
  console.log('   - DEMO_SETUP_INSTRUCTIONS.md (Manual setup guide)');
  console.log('   - demo-data-complete.json (Complete data for reference)');

  console.log('\n🎯 RECOMMENDED NEXT STEPS:');
  console.log('1. Follow instructions in DEMO_SETUP_INSTRUCTIONS.md');
  console.log('2. Create the 3 user documents manually in Firestore Console');
  console.log('3. Test demo login functionality');
  console.log('4. App will auto-generate additional demo data as needed');

  return true;
}

// Run the generator
if (require.main === module) {
  try {
    const success = generateCompleteDemo();
    console.log('\n🏁 Demo data generation completed successfully!');
    process.exit(success ? 0 : 1);
  } catch (error) {
    console.error('💥 Generation failed:', error);
    process.exit(1);
  }
}

module.exports = { generateCompleteDemo }; 