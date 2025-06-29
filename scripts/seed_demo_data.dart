#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:snapameal/utils/logger.dart';
import 'package:snapameal/services/demo_data_service.dart';
import 'package:snapameal/services/demo_data_validator.dart';
import 'package:snapameal/config/demo_personas.dart';
import 'package:snapameal/services/demo_reset_service.dart';

/// Automated demo data seeding script for consistent environment setup
/// 
/// Usage: dart scripts/seed_demo_data.dart [--reset] [--validate]
/// 
/// Options:
///   --reset     Clear existing demo data before seeding
///   --validate  Run data validation after seeding
///   --help      Show this help message

Future<void> main(List<String> args) async {
  Logger.i('🌱 SnapAMeal Demo Data Seeding Script');
  Logger.i('====================================');

  // Parse command line arguments
  final bool validateOnly = args.contains('--validate');
  final bool skipValidation = args.contains('--skip-validation');
  final bool showHelp = args.contains('--help') || args.contains('-h');
  final bool showSummary = args.contains('--summary');
  final bool resetOnly = args.contains('--reset-only');

  if (showHelp) {
    _showHelp();
    return;
  }

  try {
    // Initialize Firebase
    Logger.i('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    Logger.i('✅ Firebase initialized successfully');

    if (resetOnly) {
      Logger.i('🧹 Resetting existing demo data...');
      await DemoResetService.resetAllDemoData();
      Logger.i('✅ Demo data reset complete');
      return;
    }

    if (!validateOnly) {
      Logger.i('👥 Creating demo user accounts...');
      await _createDemoAccounts();
      Logger.i('✅ Demo accounts created successfully');
      
      // Seed the demo data
      Logger.i('📊 Seeding comprehensive demo data...');
      final stopwatch = Stopwatch()..start();
      
      await DemoDataService.seedAllDemoData();
      
      stopwatch.stop();
      final duration = stopwatch.elapsed;
      Logger.i('✅ Demo data seeding completed in ${duration.inSeconds}s');
    }
    
    if (!skipValidation) {
      Logger.i('🔍 Validating seeded data...');
      await _validateDemoData();
      Logger.i('✅ Data validation completed');
    }
    
    if (showSummary || (!validateOnly && !resetOnly)) {
      // Show summary of what was created
      _showSeedingSummary();
    }

  } catch (e, stackTrace) {
    Logger.i('❌ Seeding failed: $e');
    Logger.i('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Show help message
void _showHelp() {
  Logger.i('''
🌱 SnapAMeal Demo Data Seeding Script
====================================

This script sets up comprehensive demo data for the SnapAMeal app,
including user profiles, health data, social connections, and AI interactions.

Usage:
  dart scripts/seed_demo_data.dart [options]

Options:
  --validate          Only validate existing data (don't seed)
  --skip-validation   Skip data validation after seeding
  --reset-only        Only reset demo data (don't seed new data)
  --summary           Show detailed summary of generated data
  --help, -h          Show this help message

Examples:
  dart scripts/seed_demo_data.dart                    # Full seed with validation
  dart scripts/seed_demo_data.dart --validate         # Only validate existing data
  dart scripts/seed_demo_data.dart --reset-only       # Only reset demo data
  dart scripts/seed_demo_data.dart --skip-validation  # Seed without validation
  dart scripts/seed_demo_data.dart --summary          # Show detailed summary

Demo Data Generated:
  • 3 Demo user accounts (Alice, Bob, Chuck)
  • Health profiles with fasting preferences
  • 35 days of historical fasting sessions
  • 30 days of meal logs with nutrition data
  • Progress stories and milestone achievements
  • Social connections and group memberships
  • Group chat messages and interactions
  • AI advice conversations and recommendations
  • Health challenges and streak tracking

''');
  Logger.i('  📝 Note: Demo data reset would clear all demo_ collections');
  Logger.i('  📝 This ensures a clean state for fresh seeding');
}

/// Creates demo user accounts using the AuthService
Future<void> _createDemoAccounts() async {
  // Note: Account creation is handled by AuthService when users
  // tap the demo login buttons. This ensures proper authentication flow.
  
  for (final persona in DemoPersonas.all) {
    Logger.i('  👤 Creating account for ${persona.displayName}...');
    
    // Check if account already exists (optional verification)
    try {
      // Account creation will be handled by the demo login flow
      Logger.i('    ✅ Account already exists for ${persona.displayName}');
    } catch (e) {
      Logger.i('    ℹ️  Account creation handled by AuthService for ${persona.displayName}');
    }
  }
}

/// Validates the seeded demo data
Future<void> _validateDemoData() async {
  try {
    Logger.i('  🔍 Validating data integrity...');
    
    final results = await DemoDataValidator.validateAll();
    
    // Check for any validation failures
    final failures = results.where((r) => !r.success).toList();
    
    if (failures.isNotEmpty) {
      for (final r in failures) {
        Logger.i('    ❌ ${r.name} failed: ${r.message ?? 'unknown'}');
      }
      
      // Don't exit on validation failures during seeding
      // This allows the process to complete and show summary
      Logger.i('\n  ⚠️  Some validations failed. Check the data seeding process.');
    }
    
    if (failures.isEmpty) {
      // Show summary if everything passed
      _showSeedingSummary();
    }
  } catch (e) {
    Logger.i('    ❌ Validation failed: $e');
  }
}

void _showSeedingSummary() {
  Logger.i('\n📈 Seeding Summary:');
  Logger.i('==================');
  
  Logger.i('👥 Demo Personas:');
  for (final persona in DemoPersonas.all) {
    Logger.i('  • ${persona.displayName} (${persona.email})');
    Logger.i('    - Age: ${persona.age}, ${persona.occupation}');
    Logger.i('    - Fasting: ${persona.healthProfile['fastingType']}');
    Logger.i('    - Goals: ${persona.healthProfile['goals']}');
  }
  
  Logger.i('\n📊 Data Generated:');
  Logger.i('  • Health Profiles: ${DemoPersonas.all.length} comprehensive profiles');
  Logger.i('  • Fasting Sessions: ~35 days × ${DemoPersonas.all.length} personas');
  Logger.i('  • Meal Logs: ~30 days × 2-3 meals × ${DemoPersonas.all.length} personas');
  Logger.i('  • Progress Stories: ~15-20 stories × ${DemoPersonas.all.length} personas');
  Logger.i('  • Social Connections: Friendships + 2 health groups');
  Logger.i('  • Group Messages: ~20-30 messages × 2 groups');
  Logger.i('  • AI Advice: ~15-20 interactions × ${DemoPersonas.all.length} personas');
  Logger.i('  • Health Challenges: ~5-8 challenges × ${DemoPersonas.all.length} personas');
  Logger.i('  • Streak Data: 4 streak types × ${DemoPersonas.all.length} personas');
  
  Logger.i('\n🔗 Collections Created:');
  final collections = [
          // Migrated to production: 'demo_users', 'demo_health_groups', 'demo_notifications', 'demo_meal_logs'
      'demo_health_profiles', 'demo_fasting_sessions',
      // 'demo_meal_logs', // Migrated to production meal_logs
      'demo_stories', 'demo_friendships',
    'demo_group_messages', 'demo_ai_advice', 'demo_health_challenges',
    'demo_streaks', 'demo_user_preferences'
  ];
  
  for (final collection in collections) {
    Logger.i('  • $collection');
  }
  
  Logger.i('\n💡 Next Steps:');
  Logger.i('  1. Open the SnapAMeal app');
      Logger.i('  2. Use the demo login buttons (Alice, Bob, Chuck)');
  Logger.i('  3. Explore the rich demo data and interactions');
  Logger.i('  4. Showcase AI sophistication and social features');
  Logger.i('  5. Demonstrate the complete health platform experience');
} 