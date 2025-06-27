#!/usr/bin/env dart

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple script to create the 3 demo user documents in Firestore
/// This is the minimum needed to enable demo login

Future<void> main() async {
  print('🚀 Creating Demo User Documents');
  print('===============================');

  try {
    // Initialize Firebase
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    final firestore = FirebaseFirestore.instance;

    // Demo users with the UIDs from successful auth creation
    final demoUsers = [
      {
        'uid': 'V6zg9AM2t3VykqTbV3zAnA2Ogjr1',
        'email': 'alice.demo@example.com',
        'displayName': 'Alice',
        'userData': {
          'username': 'alice_freelancer',
          'age': 34,
          'occupation': 'Freelancer',
          'isDemo': true,
          'demoPersonaId': 'alice',
          'healthProfile': {
            'height': 168,
            'weight': 63.5,
            'gender': 'female',
            'fastingType': '14:10',
            'calorieTarget': 1600,
            'activityLevel': 'moderate',
            'goals': ['weight_loss', 'energy'],
            'dietaryRestrictions': [],
          },
        },
      },
      {
        'uid': 'w7NYJtbmZcTi1BxbyhIGI0KXXCF2',
        'email': 'bob.demo@example.com',
        'displayName': 'Bob',
        'userData': {
          'username': 'bob_retail',
          'age': 25,
          'occupation': 'Retail Worker',
          'isDemo': true,
          'demoPersonaId': 'bob',
          'healthProfile': {
            'height': 178,
            'weight': 81.6,
            'gender': 'male',
            'fastingType': '16:8',
            'calorieTarget': 1800,
            'activityLevel': 'active',
            'goals': ['muscle_gain', 'strength'],
            'dietaryRestrictions': [],
          },
        },
      },
      {
        'uid': 'H5Ol6GcK8mbRjtAkZSZyVsJTLWR2',
        'email': 'charlie.demo@example.com',
        'displayName': 'Charlie',
        'userData': {
          'username': 'charlie_teacher',
          'age': 41,
          'occupation': 'Teacher',
          'isDemo': true,
          'demoPersonaId': 'charlie',
          'healthProfile': {
            'height': 163,
            'weight': 72.6,
            'gender': 'female',
            'fastingType': '5:2',
            'calorieTarget': 1400,
            'activityLevel': 'light',
            'goals': ['weight_loss', 'health'],
            'dietaryRestrictions': ['vegetarian'],
          },
        },
      },
    ];

    print('\n📝 Creating user documents...');

    for (final user in demoUsers) {
      final userData = {
        ...user['userData'] as Map<String, dynamic>,
        'uid': user['uid'],
        'email': user['email'],
        'displayName': user['displayName'],
        'lastReplayTimestamp': null,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await firestore.collection('users').doc(user['uid'] as String).set(userData);
      print('✅ Created user document for ${user['displayName']} (${user['email']})');
    }

    print('\n🎉 All user documents created successfully!');
    print('📋 Next step: Run the demo data seeding script');
    print('   dart scripts/seed_demo_data.dart');

  } catch (e, stackTrace) {
    print('❌ Failed to create user documents: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
} 