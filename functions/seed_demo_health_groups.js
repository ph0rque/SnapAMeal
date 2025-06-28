#!/usr/bin/env node

// Demo health groups seeding script
// Creates groups in demo_health_groups collection with proper HealthGroup model structure

require('dotenv').config({ path: '../.env' });
const admin = require('firebase-admin');

const projectId = process.env.FIREBASE_PROJECT_ID;

// Demo users
const demoUsers = [
  {
    uid: 'V6zg9AM2t3VykqTbV3zAnA2Ogjr1',
    email: 'alice.demo@example.com',
    displayName: 'Alice',
    persona: 'alice'
  },
  {
    uid: 'w7NYJtbmZcTi1BxbyhIGI0KXXCF2',
    email: 'bob.demo@example.com',
    displayName: 'Bob',
    persona: 'bob'
  },
  {
    uid: 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2',
    email: 'charlie.demo@example.com',
    displayName: 'Chuck',
    persona: 'charlie'
  }
];

// Health groups with proper HealthGroup model structure
const healthGroups = [
  {
    name: 'Intermittent Fasting Support',
    description: 'A supportive community for anyone practicing intermittent fasting. Share tips, experiences, and motivation!',
    type: 'fasting',
    privacy: 'public',
    creatorId: 'V6zg9AM2t3VykqTbV3zAnA2Ogjr1', // Alice
    memberIds: ['V6zg9AM2t3VykqTbV3zAnA2Ogjr1', 'w7NYJtbmZcTi1BxbyhIGI0KXXCF2', 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2'],
    adminIds: ['V6zg9AM2t3VykqTbV3zAnA2Ogjr1'],
    tags: ['fasting', 'intermittent', 'support', 'demo'],
    groupGoals: {
      'target_fasting_hours': 16,
      'weekly_fasting_days': 7,
      'support_level': 'high'
    },
    groupStats: {
      'total_messages': 24,
      'avg_fasting_hours': 15.5,
      'success_rate': 0.87
    },
    activityLevel: 'high',
    createdDaysAgo: 28,
    maxMembers: 50,
    allowAnonymous: false,
    requireApproval: false
  },
  {
    name: 'Fitness Motivation Squad',
    description: 'Daily motivation and workout sharing for people who want to stay accountable with their fitness goals.',
    type: 'workoutBuddies',
    privacy: 'public',
    creatorId: 'w7NYJtbmZcTi1BxbyhIGI0KXXCF2', // Bob
    memberIds: ['V6zg9AM2t3VykqTbV3zAnA2Ogjr1', 'w7NYJtbmZcTi1BxbyhIGI0KXXCF2'],
    adminIds: ['w7NYJtbmZcTi1BxbyhIGI0KXXCF2'],
    tags: ['fitness', 'workout', 'motivation', 'demo'],
    groupGoals: {
      'weekly_workouts': 5,
      'workout_minutes': 45,
      'accountability_level': 'high'
    },
    groupStats: {
      'total_messages': 18,
      'avg_workouts_weekly': 4.2,
      'completion_rate': 0.92
    },
    activityLevel: 'medium',
    createdDaysAgo: 15,
    maxMembers: 30,
    allowAnonymous: false,
    requireApproval: false
  },
  {
    name: 'Mindful Eating Circle',
    description: 'Focusing on mindful eating practices, nutrition awareness, and healthy relationships with food.',
    type: 'nutrition',
    privacy: 'private',
    creatorId: 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2', // Charlie
    memberIds: ['V6zg9AM2t3VykqTbV3zAnA2Ogjr1', 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2'],
    adminIds: ['H5Ol6GcK8mbRjtAkZSZyVsJTLWR2'],
    tags: ['nutrition', 'mindful', 'eating', 'wellness', 'demo'],
    groupGoals: {
      'mindful_meals_daily': 3,
      'nutrition_awareness': 'high',
      'emotional_eating_control': 'medium'
    },
    groupStats: {
      'total_messages': 12,
      'mindfulness_score': 8.4,
      'participation_rate': 0.95
    },
    activityLevel: 'medium',
    createdDaysAgo: 12,
    maxMembers: 15,
    allowAnonymous: true,
    requireApproval: true
  },
  {
    name: 'Weight Loss Warriors',
    description: 'Supporting each other on our weight loss journeys with evidence-based strategies and encouragement.',
    type: 'calorieGoals',
    privacy: 'public',
    creatorId: 'V6zg9AM2t3VykqTbV3zAnA2Ogjr1', // Alice
    memberIds: ['V6zg9AM2t3VykqTbV3zAnA2Ogjr1', 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2'],
    adminIds: ['V6zg9AM2t3VykqTbV3zAnA2Ogjr1'],
    tags: ['weight-loss', 'calories', 'goals', 'support', 'demo'],
    groupGoals: {
      'weekly_weight_loss': 1.0,
      'calorie_deficit': 500,
      'tracking_consistency': 'daily'
    },
    groupStats: {
      'total_messages': 15,
      'avg_weight_loss': 0.8,
      'tracking_rate': 0.89
    },
    activityLevel: 'medium',
    createdDaysAgo: 20,
    maxMembers: 40,
    allowAnonymous: false,
    requireApproval: false
  },
  {
    name: 'Healthy Recipe Exchange',
    description: 'Share and discover delicious, nutritious recipes that fit your health goals.',
    type: 'recipes',
    privacy: 'public',
    creatorId: 'V6zg9AM2t3VykqTbV3zAnA2Ogjr1', // Alice
    memberIds: ['V6zg9AM2t3VykqTbV3zAnA2Ogjr1', 'w7NYJtbmZcTi1BxbyhIGI0KXXCF2', 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2'],
    adminIds: ['V6zg9AM2t3VykqTbV3zAnA2Ogjr1'],
    tags: ['recipes', 'healthy', 'cooking', 'nutrition', 'demo'],
    groupGoals: {
      'weekly_recipes': 2,
      'healthy_ingredients': 'high',
      'variety_score': 8
    },
    groupStats: {
      'total_messages': 21,
      'recipes_shared': 35,
      'avg_rating': 4.6
    },
    activityLevel: 'high',
    createdDaysAgo: 10,
    maxMembers: 100,
    allowAnonymous: false,
    requireApproval: false
  },
  {
    name: 'Wellness Warriors',
    description: 'A holistic approach to health including mental wellness, stress management, and overall wellbeing.',
    type: 'wellness',
    privacy: 'public',
    creatorId: 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2', // Charlie
    memberIds: ['V6zg9AM2t3VykqTbV3zAnA2Ogjr1', 'w7NYJtbmZcTi1BxbyhIGI0KXXCF2', 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2'],
    adminIds: ['H5Ol6GcK8mbRjtAkZSZyVsJTLWR2'],
    tags: ['wellness', 'mental-health', 'stress', 'mindfulness', 'demo'],
    groupGoals: {
      'meditation_minutes': 15,
      'stress_level': 'low',
      'sleep_hours': 8
    },
    groupStats: {
      'total_messages': 19,
      'wellness_score': 7.8,
      'engagement_rate': 0.91
    },
    activityLevel: 'medium',
    createdDaysAgo: 8,
    maxMembers: 50,
    allowAnonymous: true,
    requireApproval: false
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

async function createDemoHealthGroups(db) {
  console.log('👥 Creating demo health groups...');
  
  // Clean up existing demo groups first
  try {
    const existingGroups = await db.collection('demo_health_groups').get();
    if (!existingGroups.empty) {
      console.log(`🧹 Cleaning up ${existingGroups.size} existing demo groups...`);
      const batch = db.batch();
      existingGroups.docs.forEach(doc => {
        batch.delete(doc.ref);
      });
      await batch.commit();
    }
  } catch (error) {
    console.log('  No existing demo groups to clean up');
  }
  
  for (const group of healthGroups) {
    console.log(`  Creating group: ${group.name}...`);
    
    const now = new Date();
    const createdAt = getRandomDate(group.createdDaysAgo);
    const lastActivity = getRandomDate(Math.floor(Math.random() * 3) + 1);
    
    const groupData = {
      name: group.name,
      description: group.description,
      type: group.type,
      privacy: group.privacy,
      creator_id: group.creatorId,
      member_ids: group.memberIds,
      admin_ids: group.adminIds,
      tags: group.tags,
      group_goals: group.groupGoals,
      group_stats: group.groupStats,
      activity_level: group.activityLevel,
      created_at: admin.firestore.Timestamp.fromDate(createdAt),
      last_activity: admin.firestore.Timestamp.fromDate(lastActivity),
      max_members: group.maxMembers,
      allow_anonymous: group.allowAnonymous,
      require_approval: group.requireApproval,
      image_url: null,
      metadata: {
        isDemo: true,
        seedVersion: '1.0'
      }
    };
    
    await db.collection('demo_health_groups').add(groupData);
  }
  
  console.log(`✅ Created ${healthGroups.length} demo health groups`);
}

async function seedDemoHealthGroups() {
  console.log('🌱 Starting demo health groups seeding...');
  console.log(`📍 Project ID: ${projectId}`);
  
  const db = await initializeFirebase();
  if (!db) {
    console.error('❌ Failed to initialize Firebase');
    return false;
  }
  
  try {
    await createDemoHealthGroups(db);
    
    console.log('\n🎉 Demo health groups seeding completed!');
    console.log('\n📊 Groups Created:');
    healthGroups.forEach(group => {
      console.log(`✅ ${group.name} (${group.type}, ${group.privacy})`);
    });
    
    console.log('\n💡 Demo users can now discover multiple groups in the Community tab!');
    
    return true;
  } catch (error) {
    console.error('❌ Error seeding demo health groups:', error);
    return false;
  }
}

// Run the script
if (require.main === module) {
  seedDemoHealthGroups()
    .then(success => {
      process.exit(success ? 0 : 1);
    })
    .catch(error => {
      console.error('💥 Script failed:', error);
      process.exit(1);
    });
}

module.exports = { seedDemoHealthGroups }; 