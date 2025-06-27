#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:snapameal/utils/logger.dart';
import 'package:snapameal/config/demo_personas.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:flutter/widgets.dart';

/// Script to seed demo accounts in Firebase Authentication
/// Usage: dart scripts/seed_demo_accounts.dart
Future<void> main() async {
  Logger.i('Seeding demo accounts...');
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    Logger.i('Firebase initialized');

    final authService = AuthService();
    
    // Create demo accounts for each persona
    for (final persona in DemoPersonas.all) {
      try {
        Logger.i('Creating demo account for ${persona.displayName}...');
        
        // This will create the account if it doesn't exist
        await authService.signInWithDemoAccount(persona.id);
        
        Logger.i('Demo account created/verified for ${persona.displayName} (${persona.email})');
        
        // Sign out after creating each account
        await authService.signOut();
      } catch (e) {
        Logger.i(' Failed to create demo account for ${persona.displayName}: $e');
      }
    }
    
    Logger.i('Demo account seeding completed!');
    Logger.i('Demo accounts available:');
    for (final persona in DemoPersonas.all) {
      Logger.i('  • ${persona.displayName} (${persona.id}) - ${persona.email}');
    }
    
  } catch (e) {
    Logger.i('Demo seeding failed: $e');
    exit(1);
  }
} 