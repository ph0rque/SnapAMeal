/// AI Configuration for SnapAMeal Phase II
/// Handles Pinecone vector database and OpenAI API configurations
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIConfig {
  // Pinecone Configuration - Updated for 2025 API
  static String get pineconeApiKey => dotenv.env['PINECONE_API_KEY'] ?? '';

  static String get pineconeIndexName =>
      dotenv.env['PINECONE_INDEX_NAME'] ?? 'snapameal-health-knowledge';

  // Modern Pinecone API base URL (2025 format)
  static String get pineconeBaseUrl => 'https://api.pinecone.io';

  // Index-specific host URL - to be retrieved dynamically
  static String? _indexHost;
  static String? get indexHost => _indexHost;
  static void setIndexHost(String host) {
    _indexHost = host;
  }

  // OpenAI Configuration
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  static String get openaiModel =>
      dotenv.env['OPENAI_MODEL'] ?? 'gpt-4-turbo-preview';

  // MyFitnessPal Configuration
  static String get myFitnessPalApiKey =>
      dotenv.env['MYFITNESSPAL_API_KEY'] ?? '';

  // USDA FoodData Central Configuration
  static String get usdaApiKey => dotenv.env['USDA_API_KEY'] ?? '';
  static const String usdaBaseUrl = 'https://api.nal.usda.gov/fdc/v1';
  static const int maxUsdaSearchResults = 25;
  static const int usdaTimeoutSeconds = 30;

  static String get openaiEmbeddingModel =>
      dotenv.env['OPENAI_EMBEDDING_MODEL'] ?? 'text-embedding-3-small';

  // Vector Database Settings
  static const int embeddingDimensions =
      1536; // text-embedding-3-small dimensions
  static const String vectorMetric = 'cosine'; // Best for semantic similarity
  static const int maxRetrievalResults = 5; // Limit for cost control

  // Health Knowledge Categories
  static const List<String> healthCategories = [
    'nutrition',
    'fitness',
    'fasting',
    'weight_loss',
    'meal_planning',
    'wellness',
    'behavioral_health',
    'recipes',
    'supplements',
    'hydration',
  ];

  // API Usage Limits (for cost control)
  static const int maxDailyChatRequests = 100;
  static const int maxDailyEmbeddingRequests = 500;
  static const int maxContextTokens = 4000; // Leave room for response

  // Validation
  static bool get isConfigured {
    return pineconeApiKey.isNotEmpty && openaiApiKey.isNotEmpty;
  }

  static bool get isUSDAConfigured {
    return usdaApiKey.isNotEmpty;
  }

  // Cost optimization settings
  static const bool enableCaching = true;
  static const int cacheExpirationHours = 24;
  static const double similarityThreshold =
      0.7; // Minimum similarity for results
  static const int maxCacheSize = 1000;
  static const int rateLimitBackoffSeconds = 1;
  static const double maxDailyBudget = 10.0; // $10 daily budget
  static const int rateLimitDelayMs = 100;
  static const String pineconeNamespace = 'default';

  // Modern Pinecone API version
  static const String pineconeApiVersion = '2025-04';
}
