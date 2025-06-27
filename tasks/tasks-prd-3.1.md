# Tasks for PRD 3.1: Hyper-Personalization Engine

**PRD Reference**: `memory-bank/prd-3.1.md`  
**Priority**: Sequential implementation in order listed  
**Target Users**: < 100 users initially  

## Phase 1: Proactive, Contextual Health Coach

### Task 1.1: Dynamic "Insight of the Day" Infrastructure ✅
**Priority**: High  
**Estimated Time**: 3-4 days  

**Requirements**:
- Create a daily cron job/scheduled task to pre-generate insights for all users
- Cache insights for 24 hours to reduce API costs
- Store generated insights in Firestore with user ID, date, and content
- Handle RAG service failures with fallback content

**Acceptance Criteria**:
- [x] Daily scheduled job runs successfully and generates insights for all users
- [x] Insights are cached in Firestore with proper expiration (24 hours)
- [x] If RAG service fails, system uses predefined fallback content
- [x] No duplicate insights generated for the same user on the same day
- [x] System handles edge cases (new users, users without complete profiles)

**Technical Notes**:
- Use Firebase Cloud Functions for the scheduled job
- Create a new Firestore collection: `daily_insights`
- Document structure: `{userId, date, content, isGenerated, createdAt}`
- Fallback content should be stored in a separate collection or as constants

---

### Task 1.2: Dashboard "Insight of the Day" UI Component ✅
**Priority**: High  
**Estimated Time**: 2-3 days  

**Requirements**:
- Create a new dashboard card widget to display daily insights
- Allow users to dismiss insights they don't want to see
- Store user dismissal preferences to avoid showing similar content
- Integrate with existing dashboard layout

**Acceptance Criteria**:
- [x] New card appears prominently on the health dashboard
- [x] Card displays personalized insight text with proper formatting
- [x] Users can dismiss the card with an "X" or swipe gesture
- [x] Dismissed insights are stored in user preferences
- [x] Card gracefully handles loading states and errors
- [x] Card respects user's dismissal preferences for similar content types

**Technical Notes**:
- Create `InsightOfTheDayCard` widget in `lib/widgets/`
- Add dismissal preferences to user profile document
- Use existing `SnapUI` design system components
- Integrate with `health_dashboard_page.dart`

---

### Task 1.3: Post-Meal Log Insights ✅
**Priority**: High  
**Estimated Time**: 3-4 days  

**Requirements**:
- Trigger insight generation immediately after meal logging
- Display insights as inline cards in meal log history
- Use existing `generateNutritionInsights` function from RAGService
- Implement fallback content for RAG failures
- Allow users to dismiss meal insights

**Acceptance Criteria**:
- [x] Insight generation triggers automatically after successful meal log
- [x] Insights appear as inline cards in the meal log history view
- [x] Cards show relevant, goal-oriented feedback about the logged meal
- [x] Users can dismiss individual meal insights
- [x] System handles cases where RAG service is unavailable
- [x] Insights are cached to avoid regenerating for the same meal
- [x] Loading states are shown while insights are being generated

**Technical Notes**:
- Modify `meal_logging_page.dart` to trigger insight generation
- Create `MealInsightCard` widget
- Cache insights in the meal log document itself
- Add timeout handling (max 5 seconds for insight generation)
- Use existing `generateNutritionInsights` from `RAGService`

---

## Phase 2: Goal-Driven User Journeys

### Task 2.1: RAG-Generated "Missions" System ✅
**Priority**: Medium  
**Estimated Time**: 4-5 days  

**Requirements**:
- Generate personalized starter missions when users select health goals
- Create mission data structure and storage system
- Build UI to display missions with progress tracking
- Implement mission completion logic

**Acceptance Criteria**:
- [x] New users receive a personalized "First 7 Days" mission after goal selection
- [x] Missions are generated using RAGService based on user's goals and activity level
- [x] Mission steps are trackable and can be marked as complete
- [x] Mission progress is saved and persists across app sessions
- [x] Fallback missions exist for common goals if RAG generation fails
- [x] Users can view their current mission from the dashboard or dedicated page

**Technical Notes**:
- Create new Firestore collection: `user_missions`
- Add mission generation method to `RAGService`
- Create `MissionCard` and `MissionDetailPage` widgets
- Mission structure: `{id, userId, title, description, steps[], progress, createdAt, goalType}`

---

### Task 2.2: Hyper-Personalized Content Feed Integration ✅
**Priority**: Medium  
**Estimated Time**: 3-4 days  

**Requirements**:
- Augment existing social feed with RAG-generated content
- Query knowledge base for goal-relevant articles/tips
- Mix AI content with user-generated content in feed
- Cache content to reduce API calls

**Acceptance Criteria**:
- [x] Social feed includes relevant health articles/tips based on user goals
- [x] AI-generated content is clearly marked as such
- [x] Content is refreshed periodically (daily or when user pulls to refresh)
- [x] Users can dismiss AI content they don't want to see
- [x] Content respects user's dietary restrictions and preferences
- [x] Feed maintains good balance between social and AI content (e.g., 1 AI post per 5 user posts)

**Technical Notes**:
- Modify existing feed logic in `home_page.dart` or relevant feed component
- Create `AIContentCard` widget to display knowledge base content
- Add content generation method to `RAGService`
- Store generated content in Firestore with expiration dates

---

## Phase 3: RAG-Infused Social Features

### Task 3.1: AI-Powered Conversation Starters for Groups
**Priority**: Low  
**Estimated Time**: 3-4 days  

**Requirements**:
- Generate discussion topics for health-focused community groups
- Post conversation starters automatically or on-demand
- Ensure topics are relevant to group themes and current trends

**Acceptance Criteria**:
- [ ] Groups receive relevant discussion prompts based on their focus area
- [ ] Conversation starters are posted at appropriate intervals (not spam)
- [ ] Topics are engaging and encourage user participation
- [ ] Group admins can control frequency of AI-generated prompts
- [ ] Fallback topics exist for common group types

**Technical Notes**:
- Extend `health_community_service.dart` with conversation generation
- Create scheduled job for posting conversation starters
- Add group settings for AI prompt preferences
- Use RAGService to generate contextual discussion topics

---

### Task 3.2: Enhanced Friend Matching with AI Justifications
**Priority**: Low  
**Estimated Time**: 2-3 days  

**Requirements**:
- Enhance existing friend matching with RAG-generated explanations
- Provide specific, personalized reasons for friend suggestions
- Use health profiles and goals to find meaningful connections

**Acceptance Criteria**:
- [ ] Friend suggestions include specific reasons for the match
- [ ] Reasons are personalized and mention common goals/interests
- [ ] Explanations are natural and encouraging
- [ ] System handles cases where no good matches are found
- [ ] Fallback explanations exist for generic matches

**Technical Notes**:
- Modify `friend_service.dart` to include justification generation
- Add method to RAGService for generating match explanations
- Update friend suggestion UI to display reasons
- Cache justifications to avoid regenerating for same user pairs

---

## Phase 4: Personalized Weekly & Monthly Reviews

### Task 4.1: Weekly Review Data Collection and Analysis
**Priority**: Medium  
**Estimated Time**: 3-4 days  

**Requirements**:
- Collect and analyze user activity data for weekly summaries
- Integrate with existing `generateWeeklyDigest` function
- Store review data for historical access
- Handle users with minimal activity gracefully

**Acceptance Criteria**:
- [ ] System collects relevant user activity data (stories, meals, fasting, etc.)
- [ ] Weekly analysis runs automatically for all users
- [ ] Reviews are generated using existing RAGService functions
- [ ] Historical reviews are stored and accessible
- [ ] System handles edge cases (new users, inactive users)
- [ ] Reviews include actionable insights and encouragement

**Technical Notes**:
- Create scheduled job to run weekly review generation
- Use existing `generateWeeklyDigest` from RAGService
- Store reviews in new Firestore collection: `user_reviews`
- Review structure: `{userId, weekOf, summary, highlights, insights, generatedAt}`

---

### Task 4.2: Weekly Review UI and Navigation
**Priority**: Medium  
**Estimated Time**: 2-3 days  

**Requirements**:
- Create dedicated page for viewing weekly reviews
- Add menu access point for reviews
- Display reviews in engaging, visual format
- Allow users to share or save favorite reviews

**Acceptance Criteria**:
- [ ] Users can access weekly reviews from main menu
- [ ] Review page displays current and historical reviews
- [ ] Reviews are presented in visually appealing format
- [ ] Users can navigate between different weeks
- [ ] Loading states and empty states are handled properly
- [ ] Reviews are readable and well-formatted

**Technical Notes**:
- Create `WeeklyReviewPage` in `lib/pages/`
- Add navigation menu item
- Create `ReviewCard` widget for displaying review content
- Use existing design system components
- Implement pagination for historical reviews

---

## Infrastructure and Support Tasks

### Task I.1: Content Safety and Medical Advice Filtering ✅
**Priority**: High (should be completed early)  
**Estimated Time**: 2-3 days  

**Requirements**:
- Implement content filtering to avoid medical advice
- Add safety prompts to RAG service calls
- Create content validation system
- Implement user reporting mechanism

**Acceptance Criteria**:
- [x] All RAG-generated content includes disclaimers about not being medical advice
- [x] System prompts explicitly instruct AI to avoid medical recommendations
- [x] Content is filtered for potentially harmful advice
- [x] Users can report inappropriate AI-generated content
- [x] Fallback content is safe and appropriate

**Technical Notes**:
- Modify RAGService system prompts to include safety guidelines
- Add content validation before displaying to users
- Create content reporting mechanism
- Store reported content for review

---

### Task I.2: User Preference System for AI Content
**Priority**: Medium  
**Estimated Time**: 2-3 days  

**Requirements**:
- Allow users to customize AI content preferences
- Implement dismissal tracking across all AI features
- Create settings page for AI personalization options
- Store preferences in user profile

**Acceptance Criteria**:
- [ ] Users can adjust frequency of AI suggestions
- [ ] Dismissed content types are remembered and avoided
- [ ] Settings page allows granular control over AI features
- [ ] Preferences are synced across all devices
- [ ] Users can reset preferences to defaults

**Technical Notes**:
- Extend user profile model with AI preferences
- Create AI settings page
- Implement preference checking in all AI content generation
- Add preference sync logic

---

### Task I.3: Fallback Content System
**Priority**: High  
**Estimated Time**: 2 days  

**Requirements**:
- Create comprehensive fallback content for all AI features
- Implement graceful degradation when RAG service fails
- Ensure fallback content is goal-appropriate
- Create content management system for fallbacks

**Acceptance Criteria**:
- [ ] Fallback content exists for all AI-generated features
- [ ] Content is categorized by user goals and scenarios
- [ ] Fallback system activates seamlessly when RAG fails
- [ ] Content is regularly updated and maintained
- [ ] Users cannot distinguish between generated and fallback content

**Technical Notes**:
- Create `fallback_content.dart` with categorized content
- Implement fallback logic in RAGService
- Store fallback content in Firestore for easy updates
- Add content versioning for updates

---

## Testing and Quality Assurance

### Task Q.1: Comprehensive Testing Suite
**Priority**: Medium  
**Estimated Time**: 3-4 days  

**Requirements**:
- Create unit tests for all new services and methods
- Implement integration tests for AI content generation
- Test error handling and fallback scenarios
- Performance testing for content generation

**Acceptance Criteria**:
- [ ] All new methods have corresponding unit tests
- [ ] Integration tests cover RAG service interactions
- [ ] Error scenarios are thoroughly tested
- [ ] Performance benchmarks are established
- [ ] Tests run successfully in CI/CD pipeline

---

## Summary

**Total Estimated Time**: 35-45 days  
**Critical Path**: Tasks 1.1 → 1.2 → 1.3 → I.1 → I.3  
**Parallel Work Opportunities**: Tasks I.1, I.2, I.3 can be worked on alongside Phase 1 tasks

**Key Dependencies**:
- All tasks depend on existing RAGService functionality
- UI tasks depend on existing design system components
- Scheduled tasks require Firebase Cloud Functions setup
- Content safety (I.1) should be completed before any user-facing AI features

**Risk Mitigation**:
- Fallback content system ensures features work even if RAG service fails
- Caching reduces API costs and improves performance
- User preferences allow customization and reduce complaints
- Sequential priority allows for iterative testing and feedback 