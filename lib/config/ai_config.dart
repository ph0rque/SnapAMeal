/// AI Configuration for SnapAMeal Phase II
/// Handles Pinecone vector database and OpenAI API configurations

class AIConfig {
  // Pinecone Configuration
  static const String pineconeEnvironment = String.fromEnvironment(
    'PINECONE_ENVIRONMENT',
    defaultValue: 'us-east1-gcp-free', // Free tier default
  );
  
  static const String pineconeApiKey = String.fromEnvironment(
    'PINECONE_API_KEY',
    defaultValue: '', // Must be set in environment
  );
  
  static const String pineconeIndexName = String.fromEnvironment(
    'PINECONE_INDEX_NAME',
    defaultValue: 'snapameal-health-knowledge',
  );
  
  // OpenAI Configuration
  static const String openaiApiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: '', // Must be set in environment
  );
  
  static const String openaiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-4-turbo-preview', // Cost-optimized GPT-4 variant
  );
  
  static const String openaiEmbeddingModel = String.fromEnvironment(
    'OPENAI_EMBEDDING_MODEL',
    defaultValue: 'text-embedding-3-small', // Cost-efficient embedding model
  );
  
  // Vector Database Settings
  static const int embeddingDimensions = 1536; // text-embedding-3-small dimensions
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
    return pineconeApiKey.isNotEmpty && 
           openaiApiKey.isNotEmpty;
  }
  
  static String get pineconeBaseUrl {
    return 'https://$pineconeIndexName-$pineconeEnvironment.pineconeapi.io';
  }
  
  // Cost optimization settings
  static const bool enableCaching = true;
  static const int cacheExpirationHours = 24;
  static const double similarityThreshold = 0.7; // Minimum similarity for results
  static const int maxCacheSize = 1000;
  static const int rateLimitBackoffSeconds = 1;
  static const double maxDailyBudget = 10.0; // $10 daily budget
  static const int rateLimitDelayMs = 100;
  static const String pineconeNamespace = 'default';
} 