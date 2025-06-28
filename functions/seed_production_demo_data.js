#!/usr/bin/env node

// Production demo data seeding script
// Creates demo data in regular collections for authentic user experience

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

// Health groups to create
const healthGroups = [
  {
    id: 'intermittent_fasting_support',
    name: 'Intermittent Fasting Support',
    description: 'A supportive community for anyone practicing intermittent fasting. Share tips, experiences, and motivation!',
    category: 'fasting',
    isPrivate: false,
    members: ['alice', 'bob', 'charlie'],
    admin: 'alice',
    createdDaysAgo: 28
  },
  {
    id: 'fitness_motivation_squad',
    name: 'Fitness Motivation Squad',
    description: 'Daily motivation and workout sharing for people who want to stay accountable with their fitness goals.',
    category: 'fitness',
    isPrivate: false,
    members: ['alice', 'bob'],
    admin: 'bob',
    createdDaysAgo: 15
  },
  {
    id: 'mindful_eating_circle',
    name: 'Mindful Eating Circle',
    description: 'Focusing on mindful eating practices, nutrition awareness, and healthy relationships with food.',
    category: 'nutrition',
    isPrivate: true,
    members: ['alice', 'charlie'],
    admin: 'charlie',
    createdDaysAgo: 12
  },
  {
    id: 'weight_loss_warriors',
    name: 'Weight Loss Warriors',
    description: 'Supporting each other on our weight loss journeys with evidence-based strategies and encouragement.',
    category: 'weight_loss',
    isPrivate: false,
    members: ['alice', 'charlie'],
    admin: 'alice',
    createdDaysAgo: 20
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

async function createFastingSessions(db) {
  console.log('🍽️ Creating fasting sessions in PRODUCTION collections...');
  
  for (const user of demoUsers) {
    console.log(`  Creating fasting sessions for ${user.displayName}...`);
    
    const sessionsToCreate = user.fastingType === '5:2' ? 20 : 35;
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
          user_id: user.uid,
          type: 'five_two',
          state: Math.random() < 0.9 ? 'completed' : 'broken',
          planned_start_time: sessionDate.toISOString(),
          actual_start_time: sessionDate.toISOString(),
          planned_end_time: new Date(sessionDate.getTime() + 24 * 60 * 60 * 1000).toISOString(),
          actual_end_time: new Date(sessionDate.getTime() + 24 * 60 * 60 * 1000).toISOString(),
          planned_duration_ms: 24 * 60 * 60 * 1000, // 24 hours
          actual_duration_ms: Math.floor(22 + Math.random() * 4) * 60 * 60 * 1000, // 22-26 hours
          completion_percentage: Math.random() * 0.3 + 0.7, // 70-100%
          mood: ['great', 'good', 'okay', 'challenging'][Math.floor(Math.random() * 4)],
          mood_rating: Math.floor(3 + Math.random() * 3), // 3-5 scale
          symptoms_reported: ['hunger', 'clarity', 'energy'][Math.floor(Math.random() * 3)] ? ['hunger'] : [],
          reflection_notes: 'Fasting day went well, feeling accomplished',
          current_streak: 3 + Math.floor(Math.random() * 4),
          longest_streak: 7 + Math.floor(Math.random() * 5),
          is_personal_best: Math.random() < 0.2,
          created_at: sessionDate.toISOString(),
          updated_at: sessionDate.toISOString(),
          engagement: {
            app_opens: Math.floor(5 + Math.random() * 10),
            timer_checks: Math.floor(8 + Math.random() * 15),
            motivation_views: Math.floor(2 + Math.random() * 5),
            snaps_taken: Math.floor(Math.random() * 3),
            total_app_time_ms: Math.floor(10 + Math.random() * 20) * 60 * 1000
          },
          health_metrics: {
            steps: Math.floor(6000 + Math.random() * 4000),
            water_intake: Math.floor(6 + Math.random() * 4)
          },
          isDemo: true // Mark as demo for cleanup purposes
        };
      } else {
        // Daily IF (14:10 or 16:8)
        const fastingHours = user.fastingType === '16:8' ? 16 : 14;
        
        const sessionDate = getRandomDate(daysAgo);
        const startTime = getRandomTime(user.persona === 'bob' ? 20 : 19);
        const endTime = getRandomTime((user.persona === 'bob' ? 20 : 19) + fastingHours, 15);
        
        const startDateTime = new Date(`${sessionDate.toISOString().split('T')[0]}T${startTime}:00`);
        const endDateTime = new Date(`${sessionDate.toISOString().split('T')[0]}T${endTime}:00`);
        
        sessionData = {
          user_id: user.uid,
          type: user.fastingType === '16:8' ? 'intermittent16_8' : 'intermittent14_10',
          state: Math.random() < 0.88 ? 'completed' : 'broken',
          planned_start_time: startDateTime.toISOString(),
          actual_start_time: startDateTime.toISOString(),
          planned_end_time: endDateTime.toISOString(),
          actual_end_time: endDateTime.toISOString(),
          planned_duration_ms: fastingHours * 60 * 60 * 1000,
          actual_duration_ms: Math.floor((fastingHours + (Math.random() - 0.5) * 2) * 60 * 60 * 1000),
          completion_percentage: Math.random() * 0.3 + 0.7, // 70-100%
          mood: ['excellent', 'good', 'okay', 'tough'][Math.floor(Math.random() * 4)],
          mood_rating: Math.floor(3 + Math.random() * 3),
          symptoms_reported: Math.random() < 0.3 ? ['hunger'] : Math.random() < 0.5 ? ['clarity'] : [],
          reflection_notes: user.persona === 'alice' ? 'Good mindful session' : user.persona === 'bob' ? 'Solid workout fasting combo' : 'Peaceful day',
          current_streak: user.persona === 'alice' ? 12 : user.persona === 'bob' ? 8 : 4,
          longest_streak: user.persona === 'alice' ? 18 : user.persona === 'bob' ? 15 : 12,
          is_personal_best: Math.random() < 0.15,
          created_at: sessionDate.toISOString(),
          updated_at: sessionDate.toISOString(),
          engagement: {
            app_opens: Math.floor(3 + Math.random() * 8),
            timer_checks: Math.floor(5 + Math.random() * 12),
            motivation_views: Math.floor(1 + Math.random() * 4),
            snaps_taken: Math.floor(Math.random() * 2),
            total_app_time_ms: Math.floor(5 + Math.random() * 15) * 60 * 1000
          },
          health_metrics: {
            steps: Math.floor(8000 + Math.random() * 6000),
            water_intake: Math.floor(6 + Math.random() * 4),
            sleep_hours: Math.floor(6 + Math.random() * 3)
          },
          metadata: {
            app_version: '1.0.0',
            platform: Math.random() < 0.6 ? 'ios' : 'android'
          },
          isDemo: true // Mark as demo for cleanup purposes
        };
      }
      
      // Use regular production collection
      await db.collection('fasting_sessions').add(sessionData);
      sessionsCreated++;
    }
    
    console.log(`    ✅ Created ${sessionsCreated} sessions for ${user.displayName}`);
  }
}

async function createStreaks(db) {
  console.log('🔥 Creating streaks in PRODUCTION collections...');
  
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
        isDemo: true // Mark as demo for cleanup purposes
      };
      
      // Use regular production collection
      await db.collection('streaks').add(streakData);
    }
    
    console.log(`    ✅ Created ${streakTypes.length} streaks for ${user.displayName}`);
  }
}

async function createGoalProgress(db) {
  console.log('🎯 Creating goal progress in PRODUCTION collections...');
  
  for (const user of demoUsers) {
    console.log(`  Creating goal progress for ${user.displayName}...`);
    
    // Weight goals
    const weightGoal = {
      userId: user.uid,
      goalType: 'weight',
      targetValue: user.persona === 'bob' ? 85 : 60,
      currentValue: user.persona === 'alice' ? 63.5 : user.persona === 'bob' ? 81.6 : 72.6,
      startValue: user.persona === 'alice' ? 67 : user.persona === 'bob' ? 79 : 76,
      unit: 'kg',
      targetDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 60 * 24 * 60 * 60 * 1000)),
      progress: user.persona === 'alice' ? 0.6 : user.persona === 'bob' ? 0.43 : 0.4,
      weeklyProgress: [
        { week: 1, value: user.persona === 'alice' ? 66.5 : user.persona === 'bob' ? 79.8 : 75.2, date: admin.firestore.Timestamp.fromDate(getRandomDate(28)) },
        { week: 2, value: user.persona === 'alice' ? 66.0 : user.persona === 'bob' ? 80.3 : 74.8, date: admin.firestore.Timestamp.fromDate(getRandomDate(21)) },
        { week: 3, value: user.persona === 'alice' ? 65.2 : user.persona === 'bob' ? 80.9 : 74.1, date: admin.firestore.Timestamp.fromDate(getRandomDate(14)) },
        { week: 4, value: user.persona === 'alice' ? 63.5 : user.persona === 'bob' ? 81.6 : 72.6, date: admin.firestore.Timestamp.fromDate(getRandomDate(7)) }
      ],
      isActive: true,
      createdAt: admin.firestore.Timestamp.fromDate(getRandomDate(35)),
      updatedAt: admin.firestore.Timestamp.fromDate(getRandomDate(2)),
      isDemo: true // Mark as demo for cleanup purposes
    };
    
    await db.collection('goal_progress').add(weightGoal);
    
    // Exercise goals
    const exerciseGoal = {
      userId: user.uid,
      goalType: 'exercise',
      targetValue: user.persona === 'bob' ? 6 : 4,
      currentValue: user.persona === 'bob' ? 5.2 : user.persona === 'alice' ? 3.8 : 2.9,
      unit: 'days_per_week',
      targetDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 90 * 24 * 60 * 60 * 1000)),
      progress: user.persona === 'bob' ? 0.87 : user.persona === 'alice' ? 0.95 : 0.73,
      weeklyProgress: [
        { week: 1, value: user.persona === 'bob' ? 4 : user.persona === 'alice' ? 3 : 2, date: admin.firestore.Timestamp.fromDate(getRandomDate(28)) },
        { week: 2, value: user.persona === 'bob' ? 5 : user.persona === 'alice' ? 4 : 3, date: admin.firestore.Timestamp.fromDate(getRandomDate(21)) },
        { week: 3, value: user.persona === 'bob' ? 6 : user.persona === 'alice' ? 4 : 3, date: admin.firestore.Timestamp.fromDate(getRandomDate(14)) },
        { week: 4, value: user.persona === 'bob' ? 5 : user.persona === 'alice' ? 4 : 3, date: admin.firestore.Timestamp.fromDate(getRandomDate(7)) }
      ],
      isActive: true,
      createdAt: admin.firestore.Timestamp.fromDate(getRandomDate(30)),
      updatedAt: admin.firestore.Timestamp.fromDate(getRandomDate(1)),
      isDemo: true // Mark as demo for cleanup purposes
    };
    
    await db.collection('goal_progress').add(exerciseGoal);
    
    console.log(`    ✅ Created 2 goal progress entries for ${user.displayName}`);
  }
}

async function createHealthGroups(db) {
  console.log('👥 Creating health groups in PRODUCTION collections...');
  
  const groupDocs = {};
  
  for (const group of healthGroups) {
    console.log(`  Creating group: ${group.name}...`);
    
    const groupData = {
      name: group.name,
      description: group.description,
      category: group.category,
      isPrivate: group.isPrivate,
      memberCount: group.members.length,
      adminId: demoUsers.find(u => u.persona === group.admin).uid,
      createdAt: admin.firestore.Timestamp.fromDate(getRandomDate(group.createdDaysAgo)),
      updatedAt: admin.firestore.Timestamp.fromDate(getRandomDate(1)),
      tags: [group.category, 'support'],
      rules: [
        'Be respectful and supportive',
        'Share experiences, not medical advice',
        'Keep discussions relevant to the group topic'
      ],
      isActive: true,
      isDemo: true // Mark as demo for cleanup purposes
    };
    
    const groupRef = await db.collection('health_groups').add(groupData);
    groupDocs[group.id] = groupRef.id;
    
    // Add members to the group
    for (const memberPersona of group.members) {
      const member = demoUsers.find(u => u.persona === memberPersona);
      const isAdmin = memberPersona === group.admin;
      
      const memberData = {
        userId: member.uid,
        displayName: member.displayName,
        email: member.email,
        role: isAdmin ? 'admin' : 'member',
        joinedAt: admin.firestore.Timestamp.fromDate(getRandomDate(group.createdDaysAgo - Math.floor(Math.random() * 5))),
        lastActiveAt: admin.firestore.Timestamp.fromDate(getRandomDate(Math.floor(Math.random() * 3))),
        messageCount: Math.floor(Math.random() * 20) + (isAdmin ? 10 : 0),
        isActive: true,
        notifications: {
          newMessages: true,
          mentionOnly: false,
          dailyDigest: memberPersona === 'charlie'
        },
        isDemo: true // Mark as demo for cleanup purposes
      };
      
      await db.collection('health_groups')
        .doc(groupRef.id)
        .collection('members')
        .doc(member.uid)
        .set(memberData);
    }
  }
  
  return groupDocs;
}

async function createGroupMessages(db, groupDocs) {
  console.log('💬 Creating group messages in PRODUCTION collections...');
  
  const messageTemplates = {
    'intermittent_fasting_support': [
      { author: 'alice', message: 'Good morning everyone! Starting my 14:10 fast now. Who else is fasting today? 💪', daysAgo: 2 },
      { author: 'bob', message: 'Just finished an amazing 16-hour fast! Feeling energized and ready for my workout 🔥', daysAgo: 3 },
      { author: 'charlie', message: 'Today is one of my 5:2 fasting days. Anyone have tips for staying motivated on the harder days?', daysAgo: 1 },
      { author: 'alice', message: '@Chuck I find herbal tea and staying busy really help! You\'ve got this! 🌟', daysAgo: 1 },
      { author: 'bob', message: 'Pro tip: drink lots of water and don\'t watch cooking shows during your fast 😂', daysAgo: 1 },
      { author: 'charlie', message: 'Haha thanks @Bob! Good advice 😊 How long have you all been doing IF?', daysAgo: 0 }
    ],
    'fitness_motivation_squad': [
      { author: 'bob', message: 'Just crushed a 45-minute workout! Deadlifts were tough today but feeling great 💪', daysAgo: 1 },
      { author: 'alice', message: 'Nice work @Bob! I did a yoga session this morning - loving the mind-body connection 🧘‍♀️', daysAgo: 1 },
      { author: 'bob', message: 'Yoga is awesome! Maybe I should add some flexibility work to my routine', daysAgo: 0 },
      { author: 'alice', message: 'Definitely! I can share some beginner sequences if you\'re interested', daysAgo: 0 }
    ],
    'mindful_eating_circle': [
      { author: 'charlie', message: 'Practicing mindful eating with my lunch today. Taking time to really taste each bite 🥗', daysAgo: 2 },
      { author: 'alice', message: 'I love that approach! I\'ve been putting my phone away during meals and it makes such a difference', daysAgo: 2 },
      { author: 'charlie', message: 'Yes! Being present with our food is so important. How do you handle eating when stressed?', daysAgo: 1 },
      { author: 'alice', message: 'I try to pause and take 3 deep breaths before eating. Helps me check in with my hunger cues', daysAgo: 0 }
    ],
    'weight_loss_warriors': [
      { author: 'alice', message: 'Down another pound this week! Slow and steady progress 🎉', daysAgo: 3 },
      { author: 'charlie', message: 'Congratulations @Alice! That\'s amazing consistency. What\'s been working best for you?', daysAgo: 3 },
      { author: 'alice', message: 'Thanks! I think it\'s the combination of IF and staying active. Also tracking my meals helps a lot', daysAgo: 2 },
      { author: 'charlie', message: 'I need to get better at meal tracking. Any app recommendations?', daysAgo: 2 },
      { author: 'alice', message: 'SnapAMeal has been great for me! The AI meal recognition makes it so easy 📱', daysAgo: 1 }
    ]
  };
  
  for (const [groupKey, messages] of Object.entries(messageTemplates)) {
    const groupId = groupDocs[groupKey];
    if (!groupId) continue;
    
    console.log(`  Adding messages to ${groupKey}...`);
    
    for (const template of messages) {
      const author = demoUsers.find(u => u.persona === template.author);
      
      const messageData = {
        authorId: author.uid,
        authorName: author.displayName,
        content: template.message,
        timestamp: admin.firestore.Timestamp.fromDate(getRandomDate(template.daysAgo)),
        messageType: 'text',
        reactions: Math.random() < 0.6 ? {
          '👍': Math.floor(Math.random() * 3) + 1,
          '❤️': Math.random() < 0.4 ? Math.floor(Math.random() * 2) + 1 : 0
        } : {},
        isEdited: false,
        isDemo: true // Mark as demo for cleanup purposes
      };
      
      await db.collection('health_groups')
        .doc(groupId)
        .collection('messages')
        .add(messageData);
    }
  }
}

async function cleanupOldDemoData(db) {
  console.log('🧹 Cleaning up old demo data...');
  
  const collections = [
    'fasting_sessions',
    'streaks', 
    'goal_progress',
    'health_groups',
    'health_challenges',
    'demo_fasting_sessions',
    'demo_streaks',
    'demo_goal_progress',
    'demo_health_groups'
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

async function seedProductionDemoData() {
  console.log('🌱 Starting PRODUCTION demo data seeding...');
  console.log(`📍 Project ID: ${projectId}`);
  console.log('🎯 Creating demo data in regular collections for authentic experience');
  
  const db = await initializeFirebase();
  if (!db) {
    console.error('❌ Failed to initialize Firebase');
    return false;
  }
  
  try {
    // Clean up any old demo data
    await cleanupOldDemoData(db);
    
    // Create all the demo data in regular production collections
    await createFastingSessions(db);
    await createStreaks(db);
    await createGoalProgress(db);
    
    const groupDocs = await createHealthGroups(db);
    await createGroupMessages(db, groupDocs);
    
    console.log('\n🎉 PRODUCTION demo data seeding completed!');
    console.log('\n📊 Data Created in REGULAR Collections:');
    console.log('✅ fasting_sessions (20-35 per user)');
    console.log('✅ streaks (5 types per user)');
    console.log('✅ goal_progress (2 goals per user)');
    console.log('✅ health_groups (4 groups with conversations)');
    console.log('✅ group memberships and messages');
    
    console.log('\n💡 Demo users now have REAL user experience:');
    console.log('  • Data in same collections as real users');
    console.log('  • Full app functionality and UI');
    console.log('  • Authentic fasting history and streaks');
    console.log('  • Real group interactions and social features');
    console.log('  • Indistinguishable from actual user data');
    
    return true;
  } catch (error) {
    console.error('❌ Error seeding production demo data:', error);
    return false;
  }
}

// Run the script
if (require.main === module) {
  seedProductionDemoData()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('💥 Script failed:', error);
      process.exit(1);
    });
}

module.exports = { seedProductionDemoData }; 