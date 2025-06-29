# Tasks:  PRD 2.0 — Snap-A-Meal

Based on the Phase 2.0 PRD for transforming SnapAMeal from a Snapchat clone to a health & fitness tracking app with AI/RAG capabilities.

## Technology Decisions
- **Build Strategy**: Extend existing Flutter/Firebase codebase
- **RAG Stack**: Pinecone (vector DB), GPT-4 (LLM), OpenAI embeddings
- **Cost Optimization**: Open-source meal recognition, efficient API usage
- **Privacy**: Standard app privacy, aggressive food content filtering during fasting
- **Target**: Solo developer (AI-enhanced), flexible timeline, all 6 features
- **Integrations**: MyFitnessPal → Apple Health → Google Fit (in priority order)

## Relevant Files

### New Services & Core Logic
- `lib/services/rag_service.dart` - RAG architecture with Pinecone and OpenAI integration
- `lib/services/meal_recognition_service.dart` - Open-source meal recognition and calorie estimation
- `lib/services/fasting_service.dart` - Fasting timer logic and state management
- `lib/services/health_integration_service.dart` - MyFitnessPal, Apple Health, Google Fit integrations
- `lib/services/ai_advice_service.dart` - Personalized AI advice generation using RAG
- `lib/services/content_filter_service.dart` - Food content filtering during fasting mode

### Modified Existing Services
- `lib/services/story_service.dart` - Enhanced with logarithmic permanence logic
- `lib/services/chat_service.dart` - Extended for health-focused group features
- `lib/services/friend_service.dart` - Added AI-based suggestions and health matching
- `lib/services/auth_service.dart` - Extended for health profile data

### New Pages & UI Components
- `lib/pages/fasting_page.dart` - Main fasting timer interface with snap controls
- `lib/pages/meal_logging_page.dart` - AI-powered meal snap and logging interface
- `lib/pages/health_dashboard_page.dart` - Aggregated health data and insights
- `lib/pages/ai_advice_page.dart` - Personalized advice and chat interface
- `lib/pages/health_groups_page.dart` - Health-focused community groups
- `lib/pages/integrations_page.dart` - Health app connections and data export

### Modified Existing Pages
- `lib/pages/home_page.dart` - Transformed for health-focused navigation
- `lib/pages/camera_page.dart` - Extended with meal recognition and fasting snaps
- `lib/pages/story_view_page.dart` - Enhanced with engagement tracking and permanence
- `lib/pages/chats_page.dart` - Updated for health group categorization

### New Design System Components
- `lib/design_system/widgets/fasting_timer_widget.dart` - Circular timer with progress ring
- `lib/design_system/widgets/meal_card_widget.dart` - Meal logging card with AI captions
- `lib/design_system/widgets/advice_bubble_widget.dart` - AI advice display component
- `lib/design_system/widgets/health_metric_widget.dart` - Health data visualization
- `lib/design_system/widgets/integration_tile_widget.dart` - Health app connection tiles

### Models & Data Structures
- `lib/models/fasting_session.dart` - Fasting timer data model
- `lib/models/meal_log.dart` - Meal data with AI analysis results
- `lib/models/health_profile.dart` - User health goals and preferences
- `lib/models/ai_advice.dart` - AI-generated advice with context
- `lib/models/health_integration.dart` - External app connection data

### Utilities & Helpers
- `lib/utils/meal_recognition_helpers.dart` - Image processing and recognition utilities
- `lib/utils/health_calculations.dart` - Calorie, macro, and health metric calculations
- `lib/utils/content_filtering_helpers.dart` - Food content detection and filtering
- `lib/utils/embedding_helpers.dart` - OpenAI embedding generation and processing

### Firebase Functions (Node.js)
- `functions/src/ragProcessor.ts` - Server-side RAG processing for advice generation
- `functions/src/storyPermanence.ts` - Logarithmic story decay based on engagement
- `functions/src/healthDataProcessor.ts` - Process and aggregate health data
- `functions/src/contentFilter.ts` - Server-side content filtering logic

### Configuration & Setup
- `pubspec.yaml` - New dependencies for health integrations and ML
- `lib/config/health_config.dart` - Health app API keys and configurations
- `lib/config/ai_config.dart` - OpenAI and Pinecone configuration

### Notes
- Building on existing Flutter test framework with `flutter test`
- Firebase Functions tested with Firebase emulator suite
- Health integrations require platform-specific permissions and setup
- RAG service requires careful API usage monitoring for cost control

## Tasks

- [x] 1.0 RAG Architecture Foundation & AI Services Setup
  - [x] 1.1 Set up Pinecone vector database account and create index for health knowledge
  - [x] 1.2 Create OpenAI API integration service with GPT-4 and embeddings endpoints
  - [x] 1.3 Implement RAG service architecture with embedding generation and vector storage
  - [x] 1.4 Create health knowledge base seeding (nutrition, fitness, wellness content)
  - [x] 1.5 Build vector retrieval and context injection system for LLM queries
  - [x] 1.6 Implement API usage monitoring and cost optimization strategies

- [x] 2.0 Snap-Based Fasting Timer with Content Filtering
  - [x] 2.1 Create fasting service with timer logic and state persistence
  - [x] 2.2 Design and implement circular timer UI with progress visualization
  - [x] 2.3 Integrate snap-to-start/end functionality with camera triggers
  - [x] 2.4 Build motivational AR filters/lenses for fasting mode
  - [x] 2.5 Implement aggressive food content filtering system
  - [x] 2.6 Create fasting mode state management across app navigation
  - [x] 2.7 Add visual cues (badges, color shifts) for fasting status

- [x] 3.0 AI-Powered Meal Recognition and Logging System
  - [x] 3.1 Research and integrate open-source meal recognition library (TensorFlow Lite)
  - [x] 3.2 Create meal snap capture and preprocessing pipeline
  - [x] 3.3 Implement calorie and macro estimation algorithms
  - [x] 3.4 Build AI caption generation system (witty, motivational, health tips)
  - [x] 3.5 Create meal logging UI with photo, tags, and mood tracking
  - [x] 3.6 Implement RAG-enhanced recipe suggestions based on meal content
  - [x] 3.7 Add meal logging to Firestore with proper data structure

- [x] 4.0 Enhanced Stories with Logarithmic Permanence
  - [x] 4.1 Modify existing story service to track engagement metrics
  - [x] 4.2 Implement logarithmic duration calculation based on views/likes/comments
  - [x] 4.3 Create Cloud Function for dynamic story expiration management
  - [x] 4.4 Build timeline/scrapbook view for persistent milestone stories
  - [x] 4.5 Implement RAG-powered story summary generation for time periods
  - [x] 4.6 Update story UI to show permanence status and engagement

- [x] 5.0 Health-Focused Community Features
  - [x] 5.1 Repurpose existing chat service for health-focused group types
  - [x] 5.2 Create specialized group categories (fasting, calorie goals, workout types)
  - [x] 5.3 Implement shared streak tracking between group members
  - [x] 5.4 Build AI-based friend/group suggestion system using RAG and user similarity
  - [x] 5.5 Add anonymity mode for sensitive health sharing
  - [x] 5.6 Update group chat UI with health-specific features and themes

- [x] 6.0 Personalized AI Advice Engine
  - [x] 6.1 Create comprehensive user health profile tracking system
  - [x] 6.2 Implement behavior pattern analysis (meal timing, fasting frequency, app usage)
  - [x] 6.3 Build RAG-powered advice generation using health knowledge base
  - [x] 6.4 Create feedback mechanism (thumbs up/down) for advice quality
  - [x] 6.5 Implement adaptive learning system that improves recommendations over time
  - [x] 6.6 Build conversational AI advice interface with chat-like experience
  - [x] 6.7 Add proactive advice triggers based on user context and timing

- [x] 7.0 Health App Integrations & Data Export
  - [x] 7.1 Implement MyFitnessPal API integration for food database and logging sync
  - [x] 7.2 Build Apple Health integration for iOS health data sync
  - [x] 7.3 Create Google Fit integration for Android health data sync
  - [x] 7.4 Design modular integration dashboard for connection management
  - [x] 7.5 Implement comprehensive data export functionality (CSV, JSON formats)
  - [x] 7.6 Create data conflict resolution logic for overlapping information
  - [x] 7.7 Add privacy controls for data sharing and integration permissions

- [x] 8.0 User Experience Transformation & Health Data Migration
  - [x] 8.1 Redesign main navigation from social media to health-focused layout
  - [x] 8.2 Create new onboarding flow for health goals and persona setup
  - [x] 8.3 Update app branding and visual theme for health/wellness focus
  - [x] 8.4 Implement health data models and migrate existing user structures
  - [x] 8.5 Create health dashboard as new app home with key metrics and insights
  - [x] 8.6 Update notification system for health-focused alerts and reminders
  - [x] 8.7 Implement user preference migration from social to health contexts
