# System Patterns

## Architecture

The application follows a standard client-server architecture with Flutter as the client and Firebase as the backend. The app has matured into a production-ready system with proper error handling, logging, and clean code patterns.

## Current State

### Core Architecture
- **Client**: Flutter app with multi-platform support (iOS, Android, macOS)
- **Backend**: Firebase services (Firestore, Storage, Authentication, Cloud Functions, Messaging)
- **Real-time Features**: Firestore listeners for live updates
- **Media Handling**: Firebase Storage with proper cleanup via Cloud Functions

### Code Quality Patterns
- **Error Handling**: Proper try-catch blocks with mounted checks for async operations
- **Logging**: DebugPrint statements replace production-unsafe print calls
- **State Management**: Proper widget lifecycle management
- **Dependency Management**: Updated packages with no deprecated API usage

### System Components
1. **Authentication Flow**: Email/password with user profile creation
2. **Messaging System**: 
   - Real-time chat with disappearing messages
   - Ephemeral snap sharing with view timers
   - Screenshot detection and notifications
3. **Social Features**:
   - Friend management system
   - Stories with 24-hour auto-deletion
   - Streak tracking between friends
4. **Media Pipeline**:
   - Camera integration with AR face detection
   - Photo/video capture and processing
   - Secure storage with automatic cleanup

### Security Patterns
- Firebase rules configured (currently open for development)
- Push notification entitlements properly set
- Bundle ID consistency across platforms
- Proper Firebase initialization with duplicate detection

## Technical Debt Status

**Minimal technical debt remains:**
- Only 3 minor async context warnings (properly guarded)
- Production Firebase security rules need deployment
- All deprecated APIs updated
- All unused code removed
- All critical errors resolved

## Performance Characteristics
- Optimized widget rebuilds
- Efficient Firestore queries
- Proper resource disposal
- Clean dependency management

## Meal Analysis Architecture

### Intelligent Meal Type Classification System
The meal recognition system has been enhanced with intelligent classification that distinguishes between different types of meal content for more contextually appropriate features.

#### Core Components
1. **MealType Enum**: 
   - `ingredients`: Raw/uncooked items for recipe suggestions
   - `readyMade`: Prepared dishes requiring no cooking
   - `mixed`: Combination of both types
   - `unknown`: Cannot determine meal type

2. **Enhanced OpenAI Vision API Integration**:
   - **Prompt Engineering**: Multi-step analysis prompt with meal type classification
   - **Confidence Scoring**: Returns classification confidence percentage
   - **Reasoning**: Provides explanation for meal type determination
   - **Dual Analysis**: Both food detection AND meal type classification in single API call

3. **Conditional Recipe Generation**:
   - **Smart Triggering**: Recipe suggestions only for ingredients and mixed meals (low confidence)
   - **RAG Integration**: Leverages existing vector database for recipe recommendations
   - **Performance Optimization**: Avoids unnecessary API calls for ready-made meals
   - **User Experience**: Context-aware messaging based on meal type

#### Data Flow
```
Image Input → OpenAI Vision API → {
  Food Detection: [FoodItem, ...]
  Meal Classification: {
    type: MealType,
    confidence: double,
    reason: string
  }
} → Conditional Recipe Generation → UI Presentation
```

#### UI/UX Patterns
- **Visual Indicators**: Color-coded meal type badges with confidence percentages
- **Conditional Sections**: Recipe suggestions shown/hidden based on meal type
- **Smart Messaging**: Different success messages for different meal types
- **Progressive Disclosure**: Explanatory text for why recipes aren't shown

#### Fallback Strategy
For TensorFlow Lite offline processing:
- **Heuristic Classification**: Analyzes food names for preparation state indicators
- **Pattern Matching**: Identifies typical raw ingredients vs prepared foods
- **Lower Confidence**: Fallback detection has reduced confidence scores
- **Graceful Degradation**: System works with or without advanced classification

This architecture ensures users get contextually appropriate features while optimizing API usage and maintaining excellent user experience.

## USDA FoodData Central Integration

### Enhanced Nutrition Data Architecture
The nutrition estimation system has been enhanced with comprehensive USDA integration, providing government-grade accuracy for meal analysis.

#### Data Source Hierarchy
```
USDA FoodData Central (Primary)
    ↓ Fallback to
Local Food Database (Secondary)
    ↓ Fallback to  
AI Nutrition Estimation (Tertiary)
    ↓ Fallback to
Default Estimation (Safety Net)
```

#### USDA Service Components
1. **USDANutritionService**: 
   - Integrates with USDA FoodData Central API v1
   - Handles search, food details retrieval, and nutrition conversion
   - Manages intelligent caching with 6-hour expiration
   - Supports 350,000+ food items with comprehensive nutrient profiles

2. **Data Quality Management**:
   - **Foundation Foods**: Highest priority - nutrient profiles from agricultural samples
   - **SR Legacy**: Standard Reference data - comprehensive, lab-analyzed values
   - **Survey (FNDDS)**: Food and Nutrient Database for Dietary Studies
   - **Branded Foods**: Commercial product data

3. **Performance Optimization**:
   - **Smart Caching**: 6-hour TTL with automatic cleanup
   - **Request Bundling**: Efficient API usage with timeout controls
   - **Error Recovery**: Graceful degradation to local/AI estimation
   - **Rate Limiting**: Built-in timeout and request management

#### Integration Points
- **Meal Recognition Service**: Primary nutrition estimation method
- **OpenAI Vision Analysis**: Enhanced with USDA-accurate nutrition data
- **TensorFlow Lite Fallback**: Uses USDA data when available
- **Meal Logging**: Stores USDA-sourced nutrition information

#### Configuration
```dart
// Environment Variables Required:
USDA_API_KEY=your_api_key_here

// API Configuration:
- Base URL: https://api.nal.usda.gov/fdc/v1
- Timeout: 30 seconds
- Max Results: 25 per search
- Cache Duration: 6 hours
```

This integration provides enterprise-grade nutrition accuracy while maintaining system performance and user experience. 