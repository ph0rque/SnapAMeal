#!/usr/bin/env node

// Comprehensive demo data seeding script
// Adds streaks, sessions, goal progress, groups, and interactions

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
  console.log('🍽️ Creating fasting sessions...');
  
  for (const user of demoUsers) {
    console.log(`  Creating fasting sessions for ${user.displayName}...`);
    
    const sessionsToCreate = user.fastingType === '5:2' ? 35 : 42; // More sessions for daily fasters
    
    for (let i = 0; i < sessionsToCreate; i++) {
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
          fastingType: '5:2',
          startTime: admin.firestore.Timestamp.fromDate(sessionDate),
          endTime: admin.firestore.Timestamp.fromDate(new Date(sessionDate.getTime() + 24 * 60 * 60 * 1000)),
          targetCalories: 500,
          actualCalories: Math.floor(450 + Math.random() * 100),
          isCompleted: Math.random() < 0.9,
          mood: ['great', 'good', 'okay', 'challenging'][Math.floor(Math.random() * 4)],
          energyLevel: Math.floor(3 + Math.random() * 3), // 3-5 scale
          notes: ['Felt good today', 'Challenging but worth it', 'Easy day', ''][Math.floor(Math.random() * 4)],
          createdAt: admin.firestore.Timestamp.fromDate(sessionDate),
          isDemo: true
        };
      } else {
        // Daily IF (14:10 or 16:8)
        const fastingHours = user.fastingType === '16:8' ? 16 : 14;
        const eatingHours = user.fastingType === '16:8' ? 8 : 10;
        
        const sessionDate = getRandomDate(daysAgo);
        const startTime = getRandomTime(user.persona === 'bob' ? 20 : 19); // Bob starts later
        const endTime = getRandomTime((user.persona === 'bob' ? 20 : 19) + fastingHours, 15);
        
        sessionData = {
          userId: user.uid,
          fastingType: user.fastingType,
          startTime: admin.firestore.Timestamp.fromDate(new Date(`${sessionDate.toISOString().split('T')[0]}T${startTime}:00`)),
          endTime: admin.firestore.Timestamp.fromDate(new Date(`${sessionDate.toISOString().split('T')[0]}T${endTime}:00`)),
          targetHours: fastingHours,
          actualHours: fastingHours + (Math.random() - 0.5) * 2, // Slight variation
          isCompleted: Math.random() < 0.88,
          mood: ['excellent', 'good', 'okay', 'tough'][Math.floor(Math.random() * 4)],
          energyLevel: Math.floor(3 + Math.random() * 3),
          notes: ['Smooth sailing', 'Felt hungry at hour 12', 'Great energy', 'Broke fast early'][Math.floor(Math.random() * 4)],
          createdAt: admin.firestore.Timestamp.fromDate(sessionDate),
          isDemo: true
        };
      }
      
      await db.collection('fasting_sessions').add(sessionData);
    }
  }
}

async function createStreaks(db) {
  console.log('🔥 Creating streaks...');
  
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
          { days: 7, achieved: true, achievedAt: admin.firestore.Timestamp.fromDate(getRandomDate(currentStreak + 7)) },
          { days: 14, achieved: currentStreak >= 14, achievedAt: currentStreak >= 14 ? admin.firestore.Timestamp.fromDate(getRandomDate(currentStreak - 7)) : null },
          { days: 30, achieved: longestStreak >= 30, achievedAt: longestStreak >= 30 ? admin.firestore.Timestamp.fromDate(getRandomDate(15)) : null }
        ],
        createdAt: admin.firestore.Timestamp.fromDate(getRandomDate(totalDays + 10)),
        updatedAt: admin.firestore.Timestamp.fromDate(getRandomDate(1)),
        isDemo: true
      };
      
      await db.collection('streaks').add(streakData);
    }
  }
}

async function createGoalProgress(db) {
  console.log('🎯 Creating goal progress...');
  
  for (const user of demoUsers) {
    console.log(`  Creating goal progress for ${user.displayName}...`);
    
    // Weight goals
    const weightGoal = {
      userId: user.uid,
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
    
    await db.collection('goal_progress').add(weightGoal);
    
    // Exercise goals
    const exerciseGoal = {
      userId: user.uid,
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
    
    await db.collection('goal_progress').add(exerciseGoal);
  }
}

async function createHealthGroups(db) {
  console.log('👥 Creating health groups...');
  
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
      tags: [group.category, 'demo', 'support'],
      rules: [
        'Be respectful and supportive',
        'Share experiences, not medical advice',
        'Keep discussions relevant to the group topic'
      ],
      isActive: true,
      isDemo: true
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
          dailyDigest: memberPersona === 'charlie' // Charlie prefers less frequent notifications
        },
        isDemo: true
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
  console.log('💬 Creating group messages...');
  
  const messageTemplates = {
    'intermittent_fasting_support': [
      { author: 'alice', message: 'Good morning everyone! Starting my 14:10 fast now. Who else is fasting today? 💪', daysAgo: 2 },
      { author: 'bob', message: 'Just finished an amazing 16-hour fast! Feeling energized and ready for my workout 🔥', daysAgo: 3 },
      { author: 'charlie', message: 'Today is one of my 5:2 fasting days. Anyone have tips for staying motivated on the harder days?', daysAgo: 1 },
      { author: 'alice', message: '@Charlie I find herbal tea and staying busy really help! You\'ve got this! 🌟', daysAgo: 1 },
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
        isDemo: true
      };
      
      await db.collection('health_groups')
        .doc(groupId)
        .collection('messages')
        .add(messageData);
    }
  }
}

async function createHealthChallenges(db) {
  console.log('🏆 Creating health challenges...');
  
  const challenges = [
    {
      title: '30-Day Hydration Challenge',
      description: 'Drink at least 8 glasses of water every day for 30 days',
      type: 'hydration',
      duration: 30,
      targetValue: 8,
      unit: 'glasses_per_day',
      participants: ['alice', 'charlie']
    },
    {
      title: '21-Day Morning Workout',
      description: 'Complete a morning workout every day for 21 days',
      type: 'exercise',
      duration: 21,
      targetValue: 1,
      unit: 'workouts_per_day',
      participants: ['bob', 'alice']
    },
    {
      title: '14-Day Mindful Eating',
      description: 'Practice mindful eating techniques for 14 days',
      type: 'mindfulness',
      duration: 14,
      targetValue: 3,
      unit: 'mindful_meals_per_day',
      participants: ['charlie', 'alice']
    }
  ];
  
  for (const challenge of challenges) {
    const challengeData = {
      title: challenge.title,
      description: challenge.description,
      type: challenge.type,
      duration: challenge.duration,
      targetValue: challenge.targetValue,
      unit: challenge.unit,
      startDate: admin.firestore.Timestamp.fromDate(getRandomDate(15)),
      endDate: admin.firestore.Timestamp.fromDate(getRandomDate(15 - challenge.duration)),
      participantCount: challenge.participants.length,
      isActive: true,
      createdAt: admin.firestore.Timestamp.fromDate(getRandomDate(20)),
      isDemo: true
    };
    
    const challengeRef = await db.collection('health_challenges').add(challengeData);
    
    // Add participants
    for (const participantPersona of challenge.participants) {
      const participant = demoUsers.find(u => u.persona === participantPersona);
      const progress = Math.random() * 0.6 + 0.3; // 30-90% progress
      
      const participantData = {
        userId: participant.uid,
        displayName: participant.displayName,
        joinedAt: admin.firestore.Timestamp.fromDate(getRandomDate(16)),
        progress: progress,
        currentValue: Math.floor(challenge.targetValue * challenge.duration * progress),
        dailyEntries: [], // Could populate with daily progress
        isCompleted: progress >= 1.0,
        completedAt: progress >= 1.0 ? admin.firestore.Timestamp.fromDate(getRandomDate(5)) : null,
        isDemo: true
      };
      
      await db.collection('health_challenges')
        .doc(challengeRef.id)
        .collection('participants')
        .doc(participant.uid)
        .set(participantData);
    }
  }
}

async function seedComprehensiveDemoData() {
  console.log('🌱 Starting comprehensive demo data seeding...');
  console.log(`📍 Project ID: ${projectId}`);
  
  const db = await initializeFirebase();
  if (!db) {
    console.error('❌ Failed to initialize Firebase');
    return false;
  }
  
  try {
    // Create all the additional demo data
    await createFastingSessions(db);
    await createStreaks(db);
    await createGoalProgress(db);
    
    const groupDocs = await createHealthGroups(db);
    await createGroupMessages(db, groupDocs);
    await createHealthChallenges(db);
    
    console.log('\n🎉 Comprehensive demo data seeding completed!');
    console.log('\n📊 Data Created:');
    console.log('✅ Fasting sessions (35-42 per user)');
    console.log('✅ Streaks (5 types per user)');
    console.log('✅ Goal progress tracking (weight & exercise)');
    console.log('✅ Health groups (4 groups with realistic conversations)');
    console.log('✅ Group memberships and messages');
    console.log('✅ Health challenges with participants');
    
    console.log('\n💡 The demo users now have:');
    console.log('  • Rich fasting history and streaks');
    console.log('  • Goal progress tracking');
    console.log('  • Active group memberships');
    console.log('  • Realistic social interactions');
    console.log('  • Challenge participation');
    
    return true;
  } catch (error) {
    console.error('❌ Error seeding demo data:', error);
    return false;
  }
}

// Run the script
if (require.main === module) {
  seedComprehensiveDemoData()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('💥 Script failed:', error);
      process.exit(1);
    });
}

module.exports = { seedComprehensiveDemoData }; 