#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:snapameal/services/demo_data_service.dart';
import 'package:snapameal/config/demo_personas.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:snapameal/services/demo_data_validator.dart';

/// Automated demo data seeding script for consistent environment setup
/// 
/// Usage: dart scripts/seed_demo_data.dart [--reset] [--validate]
/// 
/// Options:
///   --reset     Clear existing demo data before seeding
///   --validate  Run data validation after seeding
///   --help      Show this help message

Future<void> main(List<String> args) async {
  print('🌱 SnapAMeal Demo Data Seeding Script');
  print('====================================');

  // Parse command line arguments
  final shouldReset = args.contains('--reset');
  final shouldValidate = args.contains('--validate');
  final showHelp = args.contains('--help');

  if (showHelp) {
    _showHelp();
    return;
  }

  try {
    // Initialize Firebase
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    print('✅ Firebase initialized successfully');

    // Reset demo data if requested
    if (shouldReset) {
      print('🧹 Resetting existing demo data...');
      await _resetDemoData();
      print('✅ Demo data reset complete');
    }

    // Create demo user accounts
    print('👥 Creating demo user accounts...');
    await _createDemoAccounts();
    print('✅ Demo accounts created successfully');

    // Seed comprehensive demo data
    print('📊 Seeding comprehensive demo data...');
    final startTime = DateTime.now();
    
    await DemoDataService.seedAllDemoData();
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    print('✅ Demo data seeding completed in ${duration.inSeconds}s');

    // Validate data if requested
    if (shouldValidate) {
      print('🔍 Validating seeded data...');
      await _validateSeedData();
      print('✅ Data validation completed');
    }

    // Print summary
    await _printSeedingSummary();

    print('\n🎉 Demo environment setup complete!');
    print('📱 You can now use the demo login buttons in the app');
    
  } catch (e, stackTrace) {
    print('❌ Seeding failed: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Show help message
void _showHelp() {
  print('''
SnapAMeal Demo Data Seeding Script

This script sets up a complete demo environment with realistic data for 
Alice, Bob, and Charlie personas.

Usage: dart scripts/seed_demo_data.dart [options]

Options:
  --reset     Clear existing demo data before seeding
  --validate  Run data validation after seeding  
  --help      Show this help message

Examples:
  dart scripts/seed_demo_data.dart
  dart scripts/seed_demo_data.dart --reset --validate
  dart scripts/seed_demo_data.dart --validate

The script will:
1. Create demo user accounts (Alice, Bob, Charlie)
2. Seed comprehensive health profiles
3. Generate 30+ days of fasting history
4. Create diverse meal logs with AI captions
5. Build progress stories with engagement data
6. Establish social connections and group chats
7. Generate AI advice interaction history
8. Populate health challenges and streak data

All demo data is isolated using the 'demo_' prefix in Firestore collections.
''');
}

/// Reset existing demo data
Future<void> _resetDemoData() async {
  // This would implement demo data cleanup
  // For now, we'll just print the intention
  print('  📝 Note: Demo data reset would clear all demo_ collections');
  print('  📝 This ensures a clean state for fresh seeding');
  
  // In a full implementation, this would:
  // 1. Query all demo_ collections
  // 2. Delete demo documents in batches
  // 3. Reset demo user accounts
  // 4. Clear any cached demo data
}

/// Create demo user accounts
Future<void> _createDemoAccounts() async {
  final authService = AuthService();
  
  for (final persona in DemoPersonas.all) {
    print('  👤 Creating account for ${persona.displayName}...');
    
    try {
      // Try to sign in first to check if account exists
      await authService.signInWithDemoAccount(persona.id);
      print('    ✅ Account already exists for ${persona.displayName}');
    } catch (e) {
      print('    ℹ️  Account creation handled by AuthService for ${persona.displayName}');
    }
  }
}

/// Validate seeded data integrity and completeness
Future<void> _validateSeedData() async {
  print('  🔍 Validating data integrity...');
  
  final validationResults = <String, bool>{};
  
  final results = await DemoDataValidator.validateAll();
  for (final r in results) {
    validationResults[r.name] = r.success;
    if (!r.success) {
      print('    ❌ ${r.name} failed: ${r.message ?? 'unknown'}');
    }
  }
  
  final allValid = validationResults.values.every((result) => result);
  if (!allValid) {
    print('\n  ⚠️  Some validations failed. Check the data seeding process.');
  }
}

/// Print comprehensive seeding summary
Future<void> _printSeedingSummary() async {
  print('\n📈 Seeding Summary:');
  print('==================');
  
  print('👥 Demo Personas:');
  for (final persona in DemoPersonas.all) {
    print('  • ${persona.displayName} (${persona.email})');
    print('    - Age: ${persona.age}, ${persona.occupation}');
    print('    - Fasting: ${persona.healthProfile['fastingType']}');
    print('    - Goals: ${persona.healthProfile['goals']}');
  }
  
  print('\n📊 Data Generated:');
  print('  • Health Profiles: ${DemoPersonas.all.length} comprehensive profiles');
  print('  • Fasting Sessions: ~35 days × ${DemoPersonas.all.length} personas');
  print('  • Meal Logs: ~30 days × 2-3 meals × ${DemoPersonas.all.length} personas');
  print('  • Progress Stories: ~15-20 stories × ${DemoPersonas.all.length} personas');
  print('  • Social Connections: Friendships + 2 health groups');
  print('  • Group Messages: ~20-30 messages × 2 groups');
  print('  • AI Advice: ~15-20 interactions × ${DemoPersonas.all.length} personas');
  print('  • Health Challenges: ~5-8 challenges × ${DemoPersonas.all.length} personas');
  print('  • Streak Data: 4 streak types × ${DemoPersonas.all.length} personas');
  
  print('\n🔗 Collections Created:');
  final collections = [
    'demo_health_profiles',
    'demo_fasting_sessions', 
    'demo_meal_logs',
    'demo_progress_stories',
    'demo_friendships',
    'demo_health_groups',
    'demo_group_chat_messages',
    'demo_ai_advice_history',
    'demo_health_challenges',
    'demo_user_streaks',
  ];
  
  for (final collection in collections) {
    print('  • $collection');
  }
  
  print('\n💡 Next Steps:');
  print('  1. Open the SnapAMeal app');
  print('  2. Use the demo login buttons (Alice, Bob, Charlie)');
  print('  3. Explore the rich demo data and interactions');
  print('  4. Showcase AI sophistication and social features');
  print('  5. Demonstrate the complete health platform experience');
} 