#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';

/// Minimal Firebase-only demo account seeding script
/// This approach uses Firebase Admin SDK or HTTP API directly
/// Usage: dart scripts/seed_accounts_firebase_only.dart

class DemoAccount {
  final String id;
  final String email;
  final String password;
  final String displayName;
  final Map<String, dynamic> userData;

  const DemoAccount({
    required this.id,
    required this.email,
    required this.password,
    required this.displayName,
    required this.userData,
  });
}

final demoAccounts = [
  DemoAccount(
    id: 'alice',
    email: 'alice.demo@example.com',
    password: 'DemoAlice2024!',
    displayName: 'Alice',
    userData: {
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
  ),
  DemoAccount(
    id: 'bob',
    email: 'bob.demo@example.com',
    password: 'DemoBob2024!',
    displayName: 'Bob',
    userData: {
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
  ),
  DemoAccount(
    id: 'charlie',
    email: 'charlie.demo@example.com',
    password: 'DemoCharlie2024!',
    displayName: 'Charlie',
    userData: {
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
  ),
];

Future<void> main() async {
  print('🔥 Demo Account Seeding Instructions');
  print('=====================================');
  print('');
  
  print('Due to Flutter SDK compilation issues, please manually create these demo accounts:');
  print('');
  
  for (final account in demoAccounts) {
    print('📝 Account: ${account.displayName}');
    print('   Email: ${account.email}');
    print('   Password: ${account.password}');
    print('   Display Name: ${account.displayName}');
    print('   Demo ID: ${account.id}');
    print('');
  }
  
  print('🛠️  Manual Setup Instructions:');
  print('1. Go to Firebase Console > Authentication > Users');
  print('2. Click "Add user" for each account above');
  print('3. Use the exact email and password provided');
  print('4. After creating each user in Authentication, add their data to Firestore:');
  print('');
  
  print('📊 Firestore Data Structure:');
  print('Collection: users');
  print('Document ID: [user UID from Authentication]');
  print('');
  
  for (final account in demoAccounts) {
    print('Document for ${account.displayName}:');
    print('{');
    account.userData.forEach((key, value) {
      if (key == 'healthProfile') {
        print('  "$key": {');
        (value as Map<String, dynamic>).forEach((hKey, hValue) {
          if (hValue is List) {
            print('    "$hKey": ${hValue.toString()},');
          } else if (hValue is String) {
            print('    "$hKey": "$hValue",');
          } else {
            print('    "$hKey": $hValue,');
          }
        });
        print('  },');
      } else if (value is String) {
        print('  "$key": "$value",');
      } else {
        print('  "$key": $value,');
      }
    });
    print('  "uid": "[USER_UID_FROM_AUTH]",');
    print('  "email": "${account.email}",');
    print('  "lastReplayTimestamp": null,');
    print('  "createdAt": [SERVER_TIMESTAMP]');
    print('}');
    print('');
  }
  
  print('⚡ Alternative: Use Firebase Admin SDK');
  print('You could also use the Firebase Admin SDK with a service account key to programmatically create these accounts.');
  print('');
  
  print('🚀 Testing the Demo Accounts');
  print('Once created, you can test the demo login functionality in the app.');
  print('The app should be able to authenticate with these accounts using the demo login feature.');
  
  exit(0);
} 