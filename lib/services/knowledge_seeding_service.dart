/// Knowledge Base Seeding Service for SnapAMeal Phase II
/// Populates the Pinecone vector database with curated health knowledge
library;

import 'dart:developer' as developer;
import 'rag_service.dart';
import '../data/health_knowledge_data.dart';

class KnowledgeSeedingService {
  final RAGService _ragService;

  KnowledgeSeedingService(this._ragService);

  /// Seed the knowledge base with all health content
  Future<bool> seedKnowledgeBase() async {
    try {
      developer.log('Starting knowledge base seeding...');

      // Get all knowledge documents
      final documents = _getAllKnowledgeDocuments();

      // Store in batches for efficiency
      const batchSize = 10;
      int successCount = 0;

      for (int i = 0; i < documents.length; i += batchSize) {
        final batch = documents.skip(i).take(batchSize).toList();
        final success = await _ragService.storeBatchDocuments(batch);

        if (success) {
          successCount += batch.length;
          developer.log(
            'Stored batch: ${i ~/ batchSize + 1}, Documents: ${batch.length}',
          );
        } else {
          developer.log('Failed to store batch: ${i ~/ batchSize + 1}');
        }

        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }

      developer.log(
        'Knowledge base seeding completed: $successCount/${documents.length} documents',
      );
      return successCount == documents.length;
    } catch (e) {
      developer.log('Error seeding knowledge base: $e');
      return false;
    }
  }

  /// Get all curated knowledge documents
  List<KnowledgeDocument> _getAllKnowledgeDocuments() {
    final documents = <KnowledgeDocument>[];

    documents.addAll(_getNutritionKnowledge());
    documents.addAll(_getFitnessKnowledge());
    documents.addAll(_getFastingKnowledge());
    documents.addAll(_getWeightLossKnowledge());
    documents.addAll(_getMealPlanningKnowledge());
    documents.addAll(_getWellnessKnowledge());
    documents.addAll(_getBehavioralHealthKnowledge());
    documents.addAll(_getRecipeKnowledge());
    documents.addAll(_getSupplementKnowledge());
    documents.addAll(_getHydrationKnowledge());

    return documents;
  }

  /// Nutrition knowledge documents
  List<KnowledgeDocument> _getNutritionKnowledge() {
    final now = DateTime.now();

    return [
      KnowledgeDocument(
        id: 'nutrition_001',
        title: 'Protein for Weight Loss',
        content:
            'Protein is essential for weight loss as it increases satiety, boosts metabolism through the thermic effect of food, and helps preserve lean muscle mass during calorie restriction. Aim for 0.36-0.54g per pound of body weight daily.',
        category: 'nutrition',
        source: 'curated',
        tags: ['protein', 'weight_loss', 'metabolism', 'satiety'],
        confidenceScore: 0.95,
        createdAt: now,
        metadata: {
          'contentType': 'fact',
          'lastUpdated': now.toIso8601String(),
          'userPreferenceMatch': ['weight_loss', 'muscle_building'],
        },
      ),
      KnowledgeDocument(
        id: 'nutrition_002',
        title: 'Fiber for Weight Management',
        content:
            'Fiber-rich foods help with weight management by promoting fullness, slowing digestion, and stabilizing blood sugar levels. Women should aim for 25g daily, men 38g daily. Best sources include vegetables, fruits, legumes, and whole grains.',
        category: 'nutrition',
        source: 'curated',
        tags: ['fiber', 'satiety', 'blood_sugar', 'vegetables'],
        confidenceScore: 0.92,
        createdAt: now,
        metadata: {
          'contentType': 'tip',
          'lastUpdated': now.toIso8601String(),
          'userPreferenceMatch': ['weight_loss', 'healthy_eating'],
        },
      ),
      KnowledgeDocument(
        id: 'protein_requirements',
        title: 'Daily Protein Requirements',
        content:
            'Protein needs vary by activity level and goals. Sedentary adults need 0.36-0.54g per pound of body weight daily. Active individuals and those building muscle may need 0.54-0.8g per pound daily.',
        category: 'Nutrition',
        source: 'curated',
        tags: ['protein', 'nutrition', 'muscle building'],
        confidenceScore: 0.95,
        createdAt: DateTime(2024, 1, 15),
        metadata: {
          'contentType': 'fact',
          'lastUpdated': DateTime(2024, 1, 15).toIso8601String(),
          'userPreferenceMatch': ['weight_loss', 'muscle_building'],
        },
      ),
    ];
  }

  /// Fitness knowledge documents
  List<KnowledgeDocument> _getFitnessKnowledge() {
    return HealthKnowledgeData.getFitnessKnowledge();
  }

  /// Fasting knowledge documents
  List<KnowledgeDocument> _getFastingKnowledge() {
    return HealthKnowledgeData.getFastingKnowledge();
  }

  /// Weight loss knowledge documents
  List<KnowledgeDocument> _getWeightLossKnowledge() {
    return HealthKnowledgeData.getWeightLossKnowledge();
  }

  /// Meal planning knowledge documents
  List<KnowledgeDocument> _getMealPlanningKnowledge() {
    return HealthKnowledgeData.getMealPlanningKnowledge();
  }

  /// Wellness knowledge documents
  List<KnowledgeDocument> _getWellnessKnowledge() {
    return HealthKnowledgeData.getWellnessKnowledge();
  }

  /// Behavioral health knowledge documents
  List<KnowledgeDocument> _getBehavioralHealthKnowledge() {
    return HealthKnowledgeData.getBehavioralHealthKnowledge();
  }

  /// Recipe knowledge documents
  List<KnowledgeDocument> _getRecipeKnowledge() {
    return HealthKnowledgeData.getRecipeKnowledge();
  }

  /// Supplement knowledge documents
  List<KnowledgeDocument> _getSupplementKnowledge() {
    return HealthKnowledgeData.getSupplementKnowledge();
  }

  /// Hydration knowledge documents
  List<KnowledgeDocument> _getHydrationKnowledge() {
    return HealthKnowledgeData.getHydrationKnowledge();
  }
}
