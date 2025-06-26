#!/usr/bin/env dart

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:snapameal/config/demo_personas.dart';
import 'package:snapameal/services/auth_service.dart';

/// Script to seed demo accounts in Firebase Authentication
/// Usage: dart scripts/seed_demo_accounts.dart
Future<void> main() async {
  print('🌱 Seeding demo accounts...');
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialized');

    final authService = AuthService();
    
    // Create demo accounts for each persona
    for (final persona in DemoPersonas.all) {
      try {
        print('Creating demo account for ${persona.displayName}...');
        
        // Try to create the demo account
        await authService.signInWithDemoAccount(persona.id);
        print('✅ Demo account created/verified for ${persona.displayName} (${persona.email})');
        
        // Sign out after creation
        await authService.signOut();
        
      } catch (e) {
        print('❌ Failed to create demo account for ${persona.displayName}: $e');
      }
    }
    
    print('\n🎉 Demo account seeding completed!');
    print('Demo accounts available:');
    for (final persona in DemoPersonas.all) {
      print('  • ${persona.displayName} (${persona.id}) - ${persona.email}');
    }
    
  } catch (e) {
    print('❌ Demo seeding failed: $e');
    exit(1);
  }
} 