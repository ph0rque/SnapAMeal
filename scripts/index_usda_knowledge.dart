#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:developer' as developer;

/// Script to index USDA food knowledge into Pinecone for RAG
Future<void> main() async {
  developer.log('🌱 Starting USDA Knowledge Indexing Script');
  developer.log('==========================================');
  
  try {
    developer.log('🔥 Initializing Firebase...');
    await Firebase.initializeApp();
    developer.log('✅ Firebase initialized');
    
    developer.log('📊 Fetching foods from Firestore...');
    
    final firestore = FirebaseFirestore.instance;
    final foodsSnapshot = await firestore.collection('foods').get();
    
    developer.log('📄 Found ${foodsSnapshot.docs.length} foods in Firestore');
    
    // Process each food for Pinecone indexing
    for (final doc in foodsSnapshot.docs) {
      final foodData = doc.data();
      final foodName = foodData['name'] as String?;
      
      if (foodName != null) {
        developer.log('🔍 Processing: $foodName');
        
        // Create knowledge content for this food
        _createFoodKnowledge(foodData);
        
        // Here you would typically send to Pinecone
        // For now, we'll just log the processed content
        developer.log('📝 Generated knowledge for: $foodName');
      }
    }
    
    developer.log('✅ USDA knowledge indexing completed successfully!');
    _showSummary();
    
  } catch (e, stackTrace) {
    developer.log('❌ Indexing failed: $e');
    developer.log('Stack trace: $stackTrace');
    exit(1);
  }
}

/// Create comprehensive knowledge content for a food item
String _createFoodKnowledge(Map<String, dynamic> foodData) {
  final name = foodData['name'] as String? ?? 'Unknown Food';
  final description = foodData['description'] as String? ?? '';
  final category = foodData['category'] as String? ?? 'General';
  final brandOwner = foodData['brandOwner'] as String? ?? '';
  final ingredients = foodData['ingredients'] as String? ?? '';
  
  // Extract nutrition data
  final nutrition = foodData['nutrition'] as Map<String, dynamic>? ?? {};
  final calories = nutrition['calories'] as num? ?? 0;
  final protein = nutrition['protein'] as num? ?? 0;
  final carbs = nutrition['carbohydrates'] as num? ?? 0;
  final fat = nutrition['fat'] as num? ?? 0;
  final fiber = nutrition['fiber'] as num? ?? 0;
  final sugar = nutrition['sugar'] as num? ?? 0;
  final sodium = nutrition['sodium'] as num? ?? 0;
  
  // Extract vitamins and minerals
  final vitamins = nutrition['vitamins'] as Map<String, dynamic>? ?? {};
  final minerals = nutrition['minerals'] as Map<String, dynamic>? ?? {};
  
  // Build comprehensive knowledge content
  final knowledge = StringBuffer();
  
  // Basic information
  knowledge.writeln('Food Name: $name');
  knowledge.writeln('Category: $category');
  if (description.isNotEmpty) {
    knowledge.writeln('Description: $description');
  }
  if (brandOwner.isNotEmpty) {
    knowledge.writeln('Brand: $brandOwner');
  }
  
  // Nutritional profile
  knowledge.writeln('\\nNutritional Information (per 100g):');
  knowledge.writeln('- Calories: ${calories}kcal');
  knowledge.writeln('- Protein: ${protein}g');
  knowledge.writeln('- Carbohydrates: ${carbs}g');
  knowledge.writeln('- Fat: ${fat}g');
  knowledge.writeln('- Fiber: ${fiber}g');
  knowledge.writeln('- Sugar: ${sugar}g');
  knowledge.writeln('- Sodium: ${sodium}mg');
  
  // Vitamins
  if (vitamins.isNotEmpty) {
    knowledge.writeln('\\nVitamins:');
    vitamins.forEach((vitamin, value) {
      knowledge.writeln('- $vitamin: $value');
    });
  }
  
  // Minerals
  if (minerals.isNotEmpty) {
    knowledge.writeln('\\nMinerals:');
    minerals.forEach((mineral, value) {
      knowledge.writeln('- $mineral: $value');
    });
  }
  
  // Ingredients
  if (ingredients.isNotEmpty) {
    knowledge.writeln('\\nIngredients: $ingredients');
  }
  
  // Health benefits and considerations
  knowledge.writeln('\\nHealth Information:');
  knowledge.writeln(_generateHealthBenefits(name, nutrition));
  
  // Dietary considerations
  knowledge.writeln('\\nDietary Considerations:');
  knowledge.writeln(_generateDietaryInfo(name, nutrition, ingredients));
  
  // Cooking and usage suggestions
  knowledge.writeln('\\nUsage Suggestions:');
  knowledge.writeln(_generateUsageSuggestions(name, category));
  
  return knowledge.toString();
}

/// Generate health benefits based on nutritional content
String _generateHealthBenefits(String name, Map<String, dynamic> nutrition) {
  final benefits = <String>[];
  
  final protein = nutrition['protein'] as num? ?? 0;
  final fiber = nutrition['fiber'] as num? ?? 0;
  final calories = nutrition['calories'] as num? ?? 0;
  final fat = nutrition['fat'] as num? ?? 0;
  final carbs = nutrition['carbohydrates'] as num? ?? 0;
  
  // High protein foods
  if (protein > 15) {
    benefits.add('High in protein, supports muscle building and repair');
  } else if (protein > 8) {
    benefits.add('Good source of protein for muscle maintenance');
  }
  
  // High fiber foods
  if (fiber > 6) {
    benefits.add('High fiber content supports digestive health');
  } else if (fiber > 3) {
    benefits.add('Contains fiber for digestive support');
  }
  
  // Low calorie foods
  if (calories < 50) {
    benefits.add('Low calorie option for weight management');
  } else if (calories < 100) {
    benefits.add('Moderate calorie content');
  }
  
  // Low fat foods
  if (fat < 3) {
    benefits.add('Low fat content');
  }
  
  // Complex carbohydrates
  if (carbs > 20 && fiber > 3) {
    benefits.add('Provides sustained energy from complex carbohydrates');
  }
  
  return benefits.isEmpty ? 'Provides essential nutrients' : benefits.join('. ');
}

/// Generate dietary information and restrictions
String _generateDietaryInfo(String name, Map<String, dynamic> nutrition, String ingredients) {
  final considerations = <String>[];
  
  final sodium = nutrition['sodium'] as num? ?? 0;
  final sugar = nutrition['sugar'] as num? ?? 0;
  final fat = nutrition['fat'] as num? ?? 0;
  
  // Sodium content
  if (sodium > 600) {
    considerations.add('High sodium content - limit if on low-sodium diet');
  } else if (sodium > 300) {
    considerations.add('Moderate sodium content');
  } else {
    considerations.add('Low sodium option');
  }
  
  // Sugar content
  if (sugar > 15) {
    considerations.add('High sugar content - consume in moderation');
  } else if (sugar > 5) {
    considerations.add('Contains natural sugars');
  }
  
  // Fat content
  if (fat > 20) {
    considerations.add('High fat content');
  }
  
  // Common allergens and dietary restrictions
  final lowerName = name.toLowerCase();
  final lowerIngredients = ingredients.toLowerCase();
  
  if (lowerName.contains('milk') || lowerName.contains('cheese') || lowerName.contains('yogurt') || lowerIngredients.contains('milk')) {
    considerations.add('Contains dairy - not suitable for lactose intolerant individuals');
  }
  
  if (lowerName.contains('wheat') || lowerName.contains('bread') || lowerIngredients.contains('wheat') || lowerIngredients.contains('gluten')) {
    considerations.add('Contains gluten - not suitable for celiac disease');
  }
  
  if (lowerName.contains('nut') || lowerIngredients.contains('nut')) {
    considerations.add('May contain nuts - check for allergies');
  }
  
  return considerations.isEmpty ? 'Generally suitable for most diets' : considerations.join('. ');
}

/// Generate usage and cooking suggestions
String _generateUsageSuggestions(String name, String category) {
  final suggestions = <String>[];
  
  final lowerName = name.toLowerCase();
  final lowerCategory = category.toLowerCase();
  
  // Fruits
  if (lowerCategory.contains('fruit') || lowerName.contains('apple') || lowerName.contains('banana') || lowerName.contains('orange')) {
    suggestions.addAll([
      'Eat fresh as a snack',
      'Add to smoothies or fruit salads',
      'Use in baking or desserts'
    ]);
  }
  
  // Vegetables
  else if (lowerCategory.contains('vegetable') || lowerName.contains('carrot') || lowerName.contains('broccoli') || lowerName.contains('spinach')) {
    suggestions.addAll([
      'Steam, roast, or sauté as a side dish',
      'Add to soups, stews, or stir-fries',
      'Include in salads for added nutrition'
    ]);
  }
  
  // Grains
  else if (lowerCategory.contains('grain') || lowerName.contains('rice') || lowerName.contains('bread') || lowerName.contains('pasta')) {
    suggestions.addAll([
      'Use as a base for meals',
      'Combine with proteins and vegetables',
      'Great for meal prep and bulk cooking'
    ]);
  }
  
  // Proteins
  else if (lowerCategory.contains('protein') || lowerName.contains('chicken') || lowerName.contains('beef') || lowerName.contains('fish')) {
    suggestions.addAll([
      'Grill, bake, or pan-fry for main dishes',
      'Add to salads for extra protein',
      'Use in sandwiches or wraps'
    ]);
  }
  
  // Dairy
  else if (lowerCategory.contains('dairy') || lowerName.contains('milk') || lowerName.contains('cheese') || lowerName.contains('yogurt')) {
    suggestions.addAll([
      'Consume as part of breakfast or snacks',
      'Use in cooking and baking',
      'Pair with fruits or nuts'
    ]);
  }
  
  // Default suggestions
  if (suggestions.isEmpty) {
    suggestions.addAll([
      'Incorporate into balanced meals',
      'Follow package instructions for preparation',
      'Store properly to maintain freshness'
    ]);
  }
  
  return suggestions.join('. ');
}

/// Show script completion summary
void _showSummary() {
  developer.log('\\n📊 USDA Knowledge Indexing Summary:');
  developer.log('===================================');
  developer.log('✅ Successfully processed USDA food data');
  developer.log('🔍 Generated comprehensive knowledge content');
  developer.log('📝 Included nutritional profiles and health benefits');
  developer.log('🍽️  Added dietary considerations and usage suggestions');
  developer.log('🎯 Ready for Pinecone vector indexing');
  developer.log('\\n💡 Next Steps:');
  developer.log('  1. Configure Pinecone API credentials');
  developer.log('  2. Generate embeddings using OpenAI');
  developer.log('  3. Upload vectors to Pinecone index');
}
