#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simplified script to seed demo accounts in Firebase Authentication
/// Usage: dart scripts/seed_demo_accounts_simple.dart
class DemoPersona {
  final String id;
  final String email;
  final String password;
  final String username;
  final String displayName;
  final int age;
  final String occupation;
  final Map<String, dynamic> healthProfile;

  const DemoPersona({
    required this.id,
    required this.email,
    required this.password,
    required this.username,
    required this.displayName,
    required this.age,
    required this.occupation,
    required this.healthProfile,
  });
}

final personas = [
  DemoPersona(
    id: 'alice',
          email: 'alice.demo@example.com',
    password: 'DemoAlice2024!',
    username: 'alice_freelancer',
    displayName: 'Alice',
    age: 34,
    occupation: 'Freelancer',
    healthProfile: const {
      'height': 168, // 5'6" in cm
      'weight': 63.5, // 140 lbs in kg
      'gender': 'female',
      'fastingType': '14:10',
      'calorieTarget': 1600,
      'activityLevel': 'moderate',
      'goals': ['weight_loss', 'energy'],
      'dietaryRestrictions': [],
    },
  ),
  DemoPersona(
    id: 'bob',
          email: 'bob.demo@example.com',
    password: 'DemoBob2024!',
    username: 'bob_retail',
    displayName: 'Bob',
    age: 25,
    occupation: 'Retail Worker',
    healthProfile: const {
      'height': 178, // 5'10" in cm
      'weight': 81.6, // 180 lbs in kg
      'gender': 'male',
      'fastingType': '16:8',
      'calorieTarget': 1800,
      'activityLevel': 'active',
      'goals': ['muscle_gain', 'strength'],
      'dietaryRestrictions': [],
    },
  ),
  DemoPersona(
    id: 'charlie',
          email: 'charlie.demo@example.com',
    password: 'DemoCharlie2024!',
    username: 'charlie_teacher',
    displayName: 'Charlie',
    age: 41,
    occupation: 'Teacher',
    healthProfile: const {
      'height': 163, // 5'4" in cm
      'weight': 72.6, // 160 lbs in kg
      'gender': 'female',
      'fastingType': '5:2',
      'calorieTarget': 1400,
      'activityLevel': 'light',
      'goals': ['weight_loss', 'health'],
      'dietaryRestrictions': ['vegetarian'],
    },
  ),
];

Future<void> main() async {
  print('🔥 Seeding demo accounts...');
  
  try {
    // Initialize Firebase (without Flutter widgets)
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    
    // Create demo accounts for each persona
    for (final persona in personas) {
      try {
        print('📝 Creating demo account for ${persona.displayName}...');
        
        UserCredential? userCredential;
        
        // Try to sign in first to see if account exists
        try {
          userCredential = await auth.signInWithEmailAndPassword(
            email: persona.email,
            password: persona.password,
          );
          print('✅ Demo account already exists for ${persona.displayName}');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'user-not-found') {
            // Create the account if it doesn't exist
            try {
              userCredential = await auth.createUserWithEmailAndPassword(
                email: persona.email,
                password: persona.password,
              );
              print('✅ Created new demo account for ${persona.displayName}');
              
              // Save user info in Firestore
              await firestore.collection("users").doc(userCredential.user!.uid).set({
                'uid': userCredential.user!.uid,
                'email': persona.email,
                'username': persona.username,
                'displayName': persona.displayName,
                'isDemo': true,
                'demoPersonaId': persona.id,
                'age': persona.age,
                'occupation': persona.occupation,
                'healthProfile': persona.healthProfile,
                'lastReplayTimestamp': null,
                'createdAt': FieldValue.serverTimestamp(),
              });
              print('✅ Saved user data to Firestore for ${persona.displayName}');
              
            } on FirebaseAuthException catch (createError) {
              if (createError.code == 'email-already-in-use') {
                print('⚠️  Account might exist but wrong password for ${persona.displayName}');
              } else {
                print('❌ Failed to create account for ${persona.displayName}: ${createError.message}');
              }
              continue;
            }
          } else {
            print('❌ Authentication error for ${persona.displayName}: ${e.message}');
            continue;
          }
        }
        
        // Sign out after processing each account
        await auth.signOut();
        
      } catch (e) {
        print('❌ Failed to process demo account for ${persona.displayName}: $e');
      }
    }
    
    print('🎉 Demo account seeding completed!');
    print('📋 Demo accounts available:');
    for (final persona in personas) {
      print('  • ${persona.displayName} (${persona.id}) - ${persona.email}');
    }
    
  } catch (e) {
    print('💥 Demo seeding failed: $e');
    exit(1);
  }
} 