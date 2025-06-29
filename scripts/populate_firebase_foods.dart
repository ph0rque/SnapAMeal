#!/usr/bin/env dart

// ignore_for_file: avoid_print

import "dart:io";
import "package:firebase_core/firebase_core.dart";
import "package:cloud_firestore/cloud_firestore.dart";

/// Simple script to populate Firebase foods collection with USDA data
Future<void> main(List<String> args) async {
  print("🍎 Starting Firebase foods collection population...");
  
  // Load USDA API key from .env
  final envFile = File(".env");
  if (!envFile.existsSync()) {
    print("❌ .env file not found");
    exit(1);
  }
  
  final envContent = await envFile.readAsString();
  final usdaApiKey = _extractEnvValue(envContent, "USDA_API_KEY");
  
  if (usdaApiKey.isEmpty) {
    print("❌ USDA_API_KEY not found in .env file");
    exit(1);
  }
  
  try {
    await Firebase.initializeApp();
    print("✅ Firebase initialized");
    
    final firestore = FirebaseFirestore.instance;
    
    // Sample food data for testing
    final sampleFoods = [
      {
        "foodName": "Apple, raw",
        "searchableKeywords": ["apple", "raw apple", "fresh apple", "fruit"],
        "fdcId": 171688,
        "dataType": "foundation",
        "category": "fruits",
        "nutritionPer100g": {
          "calories": 52,
          "protein": 0.26,
          "fat": 0.17,
          "carbs": 13.81,
          "fiber": 2.4,
          "sugar": 10.39,
        },
        "allergens": [],
        "servingSizes": {"1 medium": 150, "1 cup": 125},
        "source": "USDA",
        "createdAt": FieldValue.serverTimestamp(),
        "version": 1,
      },
      {
        "foodName": "Banana, raw",
        "searchableKeywords": ["banana", "raw banana", "fresh banana", "fruit"],
        "fdcId": 173944,
        "dataType": "foundation", 
        "category": "fruits",
        "nutritionPer100g": {
          "calories": 89,
          "protein": 1.09,
          "fat": 0.33,
          "carbs": 22.84,
          "fiber": 2.6,
          "sugar": 12.23,
        },
        "allergens": [],
        "servingSizes": {"1 medium": 118, "1 cup": 150},
        "source": "USDA",
        "createdAt": FieldValue.serverTimestamp(),
        "version": 1,
      },
    ];
    
    // Upload sample data
    final batch = firestore.batch();
    for (final food in sampleFoods) {
      final docRef = firestore.collection("foods").doc();
      batch.set(docRef, food);
    }
    
    await batch.commit();
    print("✅ Uploaded ${sampleFoods.length} sample foods to Firebase");
    print("🎉 Population completed!");
    
  } catch (e) {
    print("💥 Script failed: $e");
    exit(1);
  }
}

String _extractEnvValue(String envContent, String key) {
  final lines = envContent.split("\n");
  for (final line in lines) {
    if (line.trim().startsWith("$key=")) {
      return line.split("=")[1].trim().replaceAll("\"", "");
    }
  }
  return "";
}
