#!/usr/bin/env node

// Fixed demo data seeding script using correct demo_ prefixed collections
// This ensures demo users see their data in the app

require('dotenv').config({ path: '../.env' });
const admin = require('firebase-admin');

const projectId = process.env.FIREBASE_PROJECT_ID;

// Demo users
const demoUsers = [
  {
    uid: 'V6zg9AM2t3VykqTbV3zAnA2Ogjr1',
    email: 'alice.demo@example.com',
    displayName: 'Alice',
    persona: 'alice',
    fastingType: '14:10'
  },
  {
    uid: 'w7NYJtbmZcTi1BxbyhIGI0KXXCF2',
    email: 'bob.demo@example.com',
    displayName: 'Bob',
    persona: 'bob',
    fastingType: '16:8'
  },
  {
    uid: 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2',
    email: 'charlie.demo@example.com',
    displayName: 'Chuck',
    persona: 'charlie',
    fastingType: '5:2'
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
    return admin.firestore();
  } catch (error) {
    console.error('❌ Firebase initialization failed:', error.message);
    return null;
  }
}

function getRandomDate(daysAgo, variationDays = 2) {
  const baseDate = new Date();
  baseDate.setDate(baseDate.getDate() - daysAgo);
  const variation = (Math.random() - 0.5) * variationDays * 24 * 60 * 60 * 1000;
  return new Date(baseDate.getTime() + variation);
}

function getRandomTime(hour, minuteVariation = 30) {
  const baseMinutes = hour * 60;
  const variation = (Math.random() - 0.5) * minuteVariation * 2;
  const totalMinutes = baseMinutes + variation;
  const h = Math.floor(totalMinutes / 60) % 24;
  const m = Math.floor(totalMinutes % 60);
  return `${h.toString().padStart(2, '0')}:${m.toString().padStart(2, '0')}`;
}

async function createDemoFastingSessions(db) {
  console.log('🍽️ Creating DEMO fasting sessions...');
  
  for (const user of demoUsers) {
    console.log(`  Creating fasting sessions for ${user.displayName}...`);
    
    const sessionsToCreate = user.fastingType === '5:2' ? 20 : 35; // 5:2 only has fasting days 2x/week
    let sessionsCreated = 0;
    
    for (let i = 0; i < 50 && sessionsCreated < sessionsToCreate; i++) {
      const daysAgo = i + 1;
      
      // Skip some days randomly to make it realistic (about 85% compliance)
      if (Math.random() < 0.15) continue;
      
      let sessionData;
      
      if (user.fastingType === '5:2') {
        // 5:2 fasting - only create sessions for fasting days (Mon/Thu)
        const sessionDate = getRandomDate(daysAgo);
        const dayOfWeek = sessionDate.getDay();
        
        // Only create sessions for Monday (1) and Thursday (4)
        if (dayOfWeek !== 1 && dayOfWeek !== 4) continue;
        
        sessionData = {
          userId: user.uid,
          user_id: user.uid, // Both formats for compatibility
          fastingType: '5:2',
          type: 'five_two',
          state: Math.random() < 0.9 ? 'completed' : 'broken',
          startTime: admin.firestore.Timestamp.fromDate(sessionDate),
          endTime: admin.firestore.Timestamp.fromDate(new Date(sessionDate.getTime() + 24 * 60 * 60 * 1000)),
          actualStartTime: admin.firestore.Timestamp.fromDate(sessionDate),
          actualEndTime: admin.firestore.Timestamp.fromDate(new Date(sessionDate.getTime() + 24 * 60 * 60 * 1000)),
          plannedDuration: 24 * 60, // 24 hours in minutes
          actualDuration: Math.floor(22 + Math.random() * 4) * 60, // 22-26 hours
          targetCalories: 500,
          actualCalories: Math.floor(450 + Math.random() * 100),
          isCompleted: Math.random() < 0.9,
          completionPercentage: Math.random() * 0.3 + 0.7, // 70-100%
          mood: ['great', 'good', 'okay', 'challenging'][Math.floor(Math.random() * 4)],
          moodRating: Math.floor(3 + Math.random() * 3), // 3-5 scale
          energyLevel: Math.floor(3 + Math.random() * 3),
          notes: ['Felt good today', 'Challenging but worth it', 'Easy day', ''][Math.floor(Math.random() * 4)],
          reflectionNotes: 'Fasting day went well, feeling accomplished',
          currentStreak: 3 + Math.floor(Math.random() * 4),
          longestStreak: 7 + Math.floor(Math.random() * 5),
          createdAt: admin.firestore.Timestamp.fromDate(sessionDate),
          updatedAt: admin.firestore.Timestamp.fromDate(sessionDate),
          isDemo: true
        };
      } else {
        // Daily IF (14:10 or 16:8)
        const fastingHours = user.fastingType === '16:8' ? 16 : 14;
        const eatingHours = user.fastingType === '16:8' ? 8 : 10;
        
        const sessionDate = getRandomDate(daysAgo);
        const startTime = getRandomTime(user.persona === 'bob' ? 20 : 19); // Bob starts later
        const endTime = getRandomTime((user.persona === 'bob' ? 20 : 19) + fastingHours, 15);
        
        const startDateTime = new Date(`${sessionDate.toISOString().split('T')[0]}T${startTime}:00`);
        const endDateTime = new Date(`${sessionDate.toISOString().split('T')[0]}T${endTime}:00`);
        
        sessionData = {
          userId: user.uid,
          user_id: user.uid, // Both formats for compatibility
          fastingType: user.fastingType,
          type: user.fastingType === '16:8' ? 'intermittent16_8' : 'intermittent14_10',
          state: Math.random() < 0.88 ? 'completed' : 'broken',
          startTime: admin.firestore.Timestamp.fromDate(startDateTime),
          endTime: admin.firestore.Timestamp.fromDate(endDateTime),
          actualStartTime: admin.firestore.Timestamp.fromDate(startDateTime),
          actualEndTime: admin.firestore.Timestamp.fromDate(endDateTime),
          plannedStartTime: admin.firestore.Timestamp.fromDate(startDateTime),
          plannedEndTime: admin.firestore.Timestamp.fromDate(endDateTime),
          plannedDuration: fastingHours * 60, // in minutes
          actualDuration: Math.floor((fastingHours + (Math.random() - 0.5) * 2) * 60), // Slight variation
          targetHours: fastingHours,
          actualHours: fastingHours + (Math.random() - 0.5) * 2,
          isCompleted: Math.random() < 0.88,
          completionPercentage: Math.random() * 0.3 + 0.7, // 70-100%
          mood: ['excellent', 'good', 'okay', 'tough'][Math.floor(Math.random() * 4)],
          moodRating: Math.floor(3 + Math.random() * 3),
          energyLevel: Math.floor(3 + Math.random() * 3),
          notes: ['Smooth sailing', 'Felt hungry at hour 12', 'Great energy', 'Broke fast early'][Math.floor(Math.random() * 4)],
          reflectionNotes: user.persona === 'alice' ? 'Good mindful session' : user.persona === 'bob' ? 'Solid workout fasting combo' : 'Peaceful day',
          currentStreak: user.persona === 'alice' ? 12 : user.persona === 'bob' ? 8 : 4,
          longestStreak: user.persona === 'alice' ? 18 : user.persona === 'bob' ? 15 : 12,
          createdAt: admin.firestore.Timestamp.fromDate(sessionDate),
          updatedAt: admin.firestore.Timestamp.fromDate(sessionDate),
          isDemo: true
        };
      }
      
      // Use demo_ prefixed collection
      await db.collection('demo_fasting_sessions').add(sessionData);
      sessionsCreated++;
    }
    
    console.log(`    ✅ Created ${sessionsCreated} sessions for ${user.displayName}`);
  }
}

async function createDemoStreaks(db) {
  console.log('🔥 Creating DEMO streaks...');
  
  const streakTypes = ['fasting', 'exercise', 'water_intake', 'sleep', 'meditation'];
  
  for (const user of demoUsers) {
    console.log(`  Creating streaks for ${user.displayName}...`);
    
    for (const streakType of streakTypes) {
      let currentStreak, longestStreak, totalDays;
      
      // Customize streaks per persona
      switch (user.persona) {
        case 'alice':
          currentStreak = streakType === 'fasting' ? 12 : 
                         streakType === 'exercise' ? 6 :
                         streakType === 'water_intake' ? 18 :
                         streakType === 'meditation' ? 9 : 4;
          break;
        case 'bob':
          currentStreak = streakType === 'exercise' ? 21 :
                         streakType === 'fasting' ? 8 :
                         streakType === 'sleep' ? 5 :
                         streakType === 'water_intake' ? 12 : 3;
          break;
        case 'charlie':
          currentStreak = streakType === 'meditation' ? 15 :
                         streakType === 'fasting' ? 4 :
                         streakType === 'water_intake' ? 7 :
                         streakType === 'sleep' ? 11 : 2;
          break;
        default:
          currentStreak = Math.floor(Math.random() * 15) + 1;
      }
      
      longestStreak = currentStreak + Math.floor(Math.random() * 10) + 5;
      totalDays = longestStreak + Math.floor(Math.random() * 20) + 10;
      
      const streakData = {
        userId: user.uid,
        user_id: user.uid, // Both formats for compatibility
        type: streakType,
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        totalDays: totalDays,
        lastActivityDate: admin.firestore.Timestamp.fromDate(getRandomDate(0, 1)),
        startDate: admin.firestore.Timestamp.fromDate(getRandomDate(totalDays + 5)),
        isActive: currentStreak > 0,
        milestones: [
          { 
            days: 7, 
            achieved: true, 
            achievedAt: admin.firestore.Timestamp.fromDate(getRandomDate(currentStreak + 7)),
            name: '7 Day Streak',
            description: 'One week strong!'
          },
          { 
            days: 14, 
            achieved: currentStreak >= 14, 
            achievedAt: currentStreak >= 14 ? admin.firestore.Timestamp.fromDate(getRandomDate(currentStreak - 7)) : null,
            name: '14 Day Streak',
            description: 'Two weeks of consistency!'
          },
          { 
            days: 30, 
            achieved: longestStreak >= 30, 
            achievedAt: longestStreak >= 30 ? admin.firestore.Timestamp.fromDate(getRandomDate(15)) : null,
            name: '30 Day Streak',
            description: 'Monthly milestone achieved!'
          }
        ],
        createdAt: admin.firestore.Timestamp.fromDate(getRandomDate(totalDays + 10)),
        updatedAt: admin.firestore.Timestamp.fromDate(getRandomDate(1)),
        isDemo: true
      };
      
      // Use demo_ prefixed collection
      await db.collection('demo_streaks').add(streakData);
    }
    
    console.log(`    ✅ Created ${streakTypes.length} streaks for ${user.displayName}`);
  }
}

async function createDemoGoalProgress(db) {
  console.log('🎯 Creating DEMO goal progress...');
  
  for (const user of demoUsers) {
    console.log(`  Creating goal progress for ${user.displayName}...`);
    
    // Weight goals
    const weightGoal = {
      userId: user.uid,
      user_id: user.uid, // Both formats for compatibility
      goalType: 'weight',
      targetValue: user.persona === 'bob' ? 85 : 60, // Bob wants to gain, others lose
      currentValue: user.persona === 'alice' ? 63.5 : user.persona === 'bob' ? 81.6 : 72.6,
      startValue: user.persona === 'alice' ? 67 : user.persona === 'bob' ? 79 : 76,
      unit: 'kg',
      targetDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 60 * 24 * 60 * 60 * 1000)), // 60 days from now
      progress: user.persona === 'alice' ? 0.6 : user.persona === 'bob' ? 0.43 : 0.4,
      weeklyProgress: [
        { week: 1, value: user.persona === 'alice' ? 66.5 : user.persona === 'bob' ? 79.8 : 75.2, date: getRandomDate(28) },
        { week: 2, value: user.persona === 'alice' ? 66.0 : user.persona === 'bob' ? 80.3 : 74.8, date: getRandomDate(21) },
        { week: 3, value: user.persona === 'alice' ? 65.2 : user.persona === 'bob' ? 80.9 : 74.1, date: getRandomDate(14) },
        { week: 4, value: user.persona === 'alice' ? 63.5 : user.persona === 'bob' ? 81.6 : 72.6, date: getRandomDate(7) }
      ],
      isActive: true,
      createdAt: admin.firestore.Timestamp.fromDate(getRandomDate(35)),
      updatedAt: admin.firestore.Timestamp.fromDate(getRandomDate(2)),
      isDemo: true
    };
    
    // Use demo_ prefixed collection
    await db.collection('demo_goal_progress').add(weightGoal);
    
    // Exercise goals
    const exerciseGoal = {
      userId: user.uid,
      user_id: user.uid, // Both formats for compatibility
      goalType: 'exercise',
      targetValue: user.persona === 'bob' ? 6 : 4, // days per week
      currentValue: user.persona === 'bob' ? 5.2 : user.persona === 'alice' ? 3.8 : 2.9,
      unit: 'days_per_week',
      targetDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 90 * 24 * 60 * 60 * 1000)),
      progress: user.persona === 'bob' ? 0.87 : user.persona === 'alice' ? 0.95 : 0.73,
      weeklyProgress: [
        { week: 1, value: user.persona === 'bob' ? 4 : user.persona === 'alice' ? 3 : 2, date: getRandomDate(28) },
        { week: 2, value: user.persona === 'bob' ? 5 : user.persona === 'alice' ? 4 : 3, date: getRandomDate(21) },
        { week: 3, value: user.persona === 'bob' ? 6 : user.persona === 'alice' ? 4 : 3, date: getRandomDate(14) },
        { week: 4, value: user.persona === 'bob' ? 5 : user.persona === 'alice' ? 4 : 3, date: getRandomDate(7) }
      ],
      isActive: true,
      createdAt: admin.firestore.Timestamp.fromDate(getRandomDate(30)),
      updatedAt: admin.firestore.Timestamp.fromDate(getRandomDate(1)),
      isDemo: true
    };
    
    await db.collection('demo_goal_progress').add(exerciseGoal);
    
    console.log(`    ✅ Created 2 goal progress entries for ${user.displayName}`);
  }
}

async function cleanupOldData(db) {
  console.log('🧹 Cleaning up old data...');
  
  const collections = [
    'fasting_sessions',
    'streaks', 
    'goal_progress',
    'health_groups',
    'health_challenges'
  ];
  
  for (const collection of collections) {
    try {
      const snapshot = await db.collection(collection)
        .where('isDemo', '==', true)
        .get();
      
      if (!snapshot.empty) {
        console.log(`  Deleting ${snapshot.size} old demo docs from ${collection}...`);
        const batch = db.batch();
        snapshot.docs.forEach(doc => {
          batch.delete(doc.ref);
        });
        await batch.commit();
      }
    } catch (error) {
      console.log(`  No old data found in ${collection} (expected)`);
    }
  }
}

async function seedDemoCollectionsData() {
  console.log('🌱 Starting DEMO collections data seeding...');
  console.log(`📍 Project ID: ${projectId}`);
  
  const db = await initializeFirebase();
  if (!db) {
    console.error('❌ Failed to initialize Firebase');
    return false;
  }
  
  try {
    // Clean up any old demo data in regular collections
    await cleanupOldData(db);
    
    // Create all the demo data in correct collections
    await createDemoFastingSessions(db);
    await createDemoStreaks(db);
    await createDemoGoalProgress(db);
    
    console.log('\n🎉 DEMO collections data seeding completed!');
    console.log('\n📊 Data Created in demo_ Collections:');
    console.log('✅ demo_fasting_sessions (20-35 per user)');
    console.log('✅ demo_streaks (5 types per user)');
    console.log('✅ demo_goal_progress (2 goals per user)');
    
    console.log('\n💡 The demo users should now see:');
    console.log('  • Rich fasting history and streaks');
    console.log('  • Goal progress tracking');
    console.log('  • Realistic session data');
    console.log('  • Proper completion percentages');
    
    return true;
  } catch (error) {
    console.error('❌ Error seeding demo data:', error);
    return false;
  }
}

// Run the script
if (require.main === module) {
  seedDemoCollectionsData()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('💥 Script failed:', error);
      process.exit(1);
    });
}

module.exports = { seedDemoCollectionsData }; 