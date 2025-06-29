# PRD 4.0: Intelligent Meal Analysis V2

## 1. Introduction

The current meal analysis system provides a strong foundation by leveraging AI to identify foods and estimate their nutritional value. However, it relies on a small, hard-coded database for common foods and does not fully utilize the potential of its integrated services. This upgrade will enhance the system's accuracy, scalability, and intelligence by replacing the static data source with a comprehensive Firebase database, enabling hybrid on-device/cloud processing, and creating a more sophisticated, nutrition-aware user experience.

## 2. Goals & Objectives

**Primary Goal**: To significantly improve the accuracy, speed, and intelligence of the meal and calorie analysis feature while maintaining cost efficiency and user experience quality.

**Objectives**:
- Increase nutritional data accuracy by replacing the local cache with a comprehensive Firebase food database that matches USDA data complexity
- Improve performance and reduce API costs through hybrid processing (TensorFlow Lite + OpenAI fallback)
- Enhance user trust and engagement by implementing inline editing during analysis review
- Create personalized, nutrition-aware recipe suggestions and guidance
- Transform the app into a knowledgeable nutritional assistant by integrating curated USDA data into the RAG system
- Maintain production-quality experience across all users (demo flag only affects user-specific features, not data quality)

## 3. User Stories

- **As a health-conscious user**, I want the app to recognize a wide variety of foods with comprehensive nutritional data (including vitamins and minerals) so I can make informed dietary decisions.
- **As a user on the go**, I want quick initial analysis with detailed follow-up, even with poor internet connectivity, so I can efficiently log meals without waiting.
- **As a detail-oriented user**, I want to correct misidentified ingredients during the review process so my meal log is accurate before saving.
- **As a user with specific dietary goals**, I want recipe suggestions that consider my nutritional targets (e.g., "under 500 calories with 30g protein") not just ingredient matching.
- **As a curious user**, I want to ask detailed nutritional questions about my food using the app's knowledge base, such as "Which ingredient has more fiber?" or "What are the health benefits of salmon?"

## 4. Functional Requirements

### 4.1. Firebase Comprehensive Food Database

**Action**: Replace the hard-coded `_getNutritionFromDatabase` function with a comprehensive Firebase-based food database.

**Implementation**:
- Create Firestore collection `foods` with schema matching full USDA data complexity:
  ```json
  {
    "foodName": "string",
    "searchableKeywords": ["array", "of", "strings"],
    "fdcId": "number (optional, for USDA foods)",
    "dataType": "string (foundation/sr_legacy/survey/custom)",
    "nutritionPer100g": {
      "calories": "number",
      "protein": "number",
      "carbs": "number", 
      "fat": "number",
      "fiber": "number",
      "sugar": "number",
      "sodium": "number",
      "vitamins": {
        "A": "number",
        "C": "number",
        "D": "number",
        // ... full vitamin profile
      },
      "minerals": {
        "calcium": "number",
        "iron": "number",
        "magnesium": "number",
        // ... full mineral profile
      }
    },
    "allergens": ["array", "of", "allergen", "strings"],
    "category": "string",
    "createdAt": "timestamp",
    "source": "string (usda/custom/user_contributed)"
  }
  ```
- Update `MealRecognitionService.estimateNutrition()` to query Firebase as primary fallback after USDA API
- Create local script `scripts/populate_firebase_foods.dart` to seed database with curated USDA subset
- Implement automatic backfill: if food not found in Firebase, fetch from USDA and store for future use

### 4.2. Hybrid Food Recognition (TensorFlow Lite + OpenAI)

**Action**: Implement hybrid processing with TensorFlow Lite for initial analysis and OpenAI for detailed fallback.

**Implementation**:
- Source/train food-specific TensorFlow Lite model (research existing food classification models)
- Create `assets/models/` directory with:
  - `food_classifier.tflite` (food-specific model, not generic MobileNet)
  - `food_labels.txt` (corresponding food categories)
- Update `meal_recognition_service.dart`:
  - Change condition to `if (true && _interpreter != null)`
  - Implement confidence threshold logic (70% minimum for TFLite-only results)
  - Add loading state management: "Analyzing locally..." → "Getting detailed analysis..."
- User experience flow:
  1. Show "Analyzing locally..." while TFLite processes
  2. If confidence ≥ 70%: show results immediately
  3. If confidence < 70%: show "Getting detailed analysis..." and call OpenAI
  4. Merge results with TFLite providing speed, OpenAI providing accuracy

### 4.3. Enhanced Nutrition-Aware RAG System

**Action**: Extend existing `RAGService.performSemanticSearch` to include nutritional filtering and integrate curated USDA data.

**Implementation**:
- Update `performSemanticSearch` method signature:
  ```dart
  Future<List<SearchResult>> performSemanticSearch({
    required String query,
    HealthQueryContext? healthContext,
    int maxResults = 10,
    double minSimilarityScore = 0.7,
    List<String>? categoryFilter,
    List<String>? tagFilter,
    // NEW: Nutritional filters
    double? maxCalories,
    double? minProtein,
    double? maxCarbs,
    double? maxFat,
    Map<String, double>? customNutrientLimits,
  })
  ```
- Update Pinecone vector storage to include nutritional metadata for all documents
- Create data pipeline to convert curated USDA foods into searchable documents:
  - Each food becomes a document with nutritional benefits, usage tips, health information
  - Integrate into existing namespace (no separate USDA namespace)
  - Limit to ~10,000 most common/useful foods to stay within Pinecone free tier
- Enhance recipe suggestion prompts to use nutritional context:
  - "Suggest recipes using [ingredients] that are under [maxCalories] calories"
  - "Find high-protein recipes with these ingredients"

### 4.4. Inline Food Correction Interface

**Action**: Add inline editing capability during analysis review phase in `MealLoggingPage`.

**Implementation**:
- Update `_buildNutritionSection()` in `meal_logging_page.dart`:
  - Add edit icon next to each detected food item
  - Implement `_showFoodCorrectionDialog()` method
  - Food correction dialog features:
    - Search Firebase `foods` collection with autocomplete
    - Allow custom food name entry
    - Show nutritional impact of the change
    - Update analysis results in real-time
- Create `FoodCorrectionDialog` widget:
  - Firebase-powered search with debounced queries
  - Visual nutrition comparison (old vs new)
  - Save corrections to `feedback_corrections` collection
- Update `MealRecognitionResult` to track user modifications:
  ```dart
  class MealRecognitionResult {
    // ... existing fields
    final List<FoodCorrection> userCorrections;
    final bool hasUserModifications;
  }
  ```

### 4.5. USDA Knowledge Base Integration

**Action**: Index curated USDA nutritional data into the RAG knowledge base for detailed nutritional queries.

**Implementation**:
- Create `scripts/index_usda_knowledge.dart` to process USDA data:
  - Convert top 10,000 foods into knowledge documents
  - Include health benefits, nutritional highlights, usage tips
  - Format as searchable content: "Salmon is rich in omega-3 fatty acids..."
- Integrate into existing Pinecone namespace with category `nutrition_facts`
- Add `RAGService.queryNutritionalFacts()` method for specific nutrition questions
- Enable queries like:
  - "What are the health benefits of salmon?"
  - "Compare the iron content of spinach and beef"
  - "Which foods are high in vitamin C?"

## 5. Technical Implementation Details

### 5.1. Loading State Management
```dart
enum AnalysisState {
  localProcessing,    // "Analyzing locally..."
  cloudProcessing,    // "Getting detailed analysis..."
  complete,
  error
}
```

### 5.2. Firebase Query Optimization
- Implement composite indexes for common search patterns
- Use Firestore's built-in text search capabilities
- Cache frequent queries in memory (500ms response time target)

### 5.3. Data Pipeline Scripts
- `scripts/populate_firebase_foods.dart`: One-time Firebase seeding
- `scripts/index_usda_knowledge.dart`: Pinecone knowledge indexing
- Both scripts run locally, no Cloud Functions needed

## 6. Non-Functional Requirements

### 6.1. Performance
- On-device TensorFlow Lite analysis: < 2 seconds
- Firebase food queries: < 500ms (using built-in search)
- Hybrid analysis total time: < 5 seconds for complex cases
- Real-time inline editing with immediate UI updates

### 6.2. Cost Management
- Reduce OpenAI API calls by 40-60% through TensorFlow Lite first-pass
- Stay within Pinecone free tier (~10,000 USDA foods + existing content)
- Firebase Firestore usage optimized with appropriate indexes

### 6.3. Data Quality
- Firebase food database matches full USDA nutritional complexity
- Automatic backfill ensures comprehensive coverage
- User corrections improve system accuracy over time

### 6.4. User Experience
- Seamless transition between local and cloud processing
- Inline editing preserves user flow without navigation
- Production-quality experience for all users (demo flag only affects user-specific features)

## 7. Success Metrics

- **Accuracy**: 90%+ user satisfaction with food identification
- **Performance**: 60% reduction in analysis time for common foods
- **Cost**: 50% reduction in OpenAI API costs
- **Engagement**: 25% increase in meal logging frequency
- **Data Quality**: 95% of foods have comprehensive nutritional data

## 8. Implementation Phases

### Phase 1: Foundation (Weeks 1-2)
- Create Firebase food database schema
- Develop data population scripts
- Source/integrate food-specific TensorFlow Lite model

### Phase 2: Core Features (Weeks 3-4)
- Implement hybrid processing logic
- Build inline editing interface
- Extend RAG system with nutritional filtering

### Phase 3: Knowledge Integration (Weeks 5-6)
- Index USDA knowledge into Pinecone
- Implement nutritional query capabilities
- Performance optimization and testing

### Phase 4: Polish & Launch (Week 7)
- User testing and feedback integration
- Performance monitoring setup
- Production deployment

## 9. Out of Scope

- Automated model fine-tuning pipeline (data collection only)
- Real-time TensorFlow Lite model updates (app release cycle)
- Advanced nutritional analysis (meal planning, dietary recommendations)
- Multi-language food recognition
- Barcode scanning integration

## 10. Risk Mitigation

- **TensorFlow Lite Model Availability**: Research existing food classification models; fallback to generic model with food-specific labels if needed
- **Firebase Performance**: Implement caching and pagination for large result sets
- **Pinecone Capacity**: Monitor usage and implement intelligent content pruning if approaching limits
- **User Adoption**: A/B test inline editing vs. separate correction flow

This PRD provides a comprehensive roadmap for enhancing the meal analysis system while maintaining cost efficiency and user experience quality. The hybrid approach balances performance, accuracy, and cost considerations while providing users with unprecedented nutritional intelligence and control over their meal logging experience. 