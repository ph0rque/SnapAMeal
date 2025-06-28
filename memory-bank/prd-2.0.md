# 📄 Phase II PRD — Snap-A-Meal

## 🧍 Persona Recap: Alex

- **Name**: Alex  
- **Age**: 38  
- **Occupation**: Marketing Coordinator  
- **Health Goals**: Lose 35 lbs in 6 months via fasting, calorie restriction, and light workouts  
- **Tech Savvy**: Comfortable with Snapchat and mobile apps  
- **Pain Points**: 
  - Struggles with motivation
  - Hates tedious tracking
  - Needs privacy and simplicity
  - Short on time
  - Wants to avoid food temptation during fasts  
- **Goals**:
  - Easy and fun tracking
  - Personalized, evolving advice
  - Private yet supportive sharing
  - Enjoyable social interactions

---

## 🚀 Core Objectives

1. **Seamless Tracking** — Make meal and fasting tracking effortless, visual, and AI-assisted.
2. **Personalized Guidance** — Build trust through tailored and evolving recommendations.
3. **Community + Privacy** — Enable intimate, supportive sharing without public exposure.
4. **Fun & Gamification** — Inject motivation through stories, AI captions, streaks, and challenges.
5. **Modular Integration** — Play well with external health/fitness tools for serious users.

---

## 📦 Features (Phase II)

### 1. 🕓 Snap-Based Fasting Timer with Conditional Content

**Description**: Users start/end fasts by snapping (like opening a fast-themed lens), triggering UI/state changes.

**Functionality**:
- Snap to "Start Fast" or "End Fast"
- App enters "Fasting Mode" (blurs/hides food-related content)
- Motivational filters (e.g., "Fasting Flame", "Willpower Lens")
- Visual cues (badge, color shift, progress ring)

**RAG Use**:
- *Content Filtering*: During fasting mode, retrieve and rank suitable motivational content from a curated database (e.g., quotes, images) via RAG.
- *Optional Extension*: Dynamically suppress food-related content using AI image/text classification combined with retrieval-based topic filtering.

**User Story**:  
> "As Alex, I want to snap to start and end my fasts and have the app hide food content during fasting so I can stay focused."

---

### 2. 🍽️ AI-Powered Meal Snap Logging with Captions

**Description**: Users snap meals for instant calorie estimates and receive fun or educational captions.

**Functionality**:
- Snap and auto-analyze meals for calorie/macro estimate (ML model)
- Option to select:
  - Witty caption
  - Motivational quote
  - Health tip or recipe suggestion
- Tag meal with mood/hunger for journaling

**RAG Use**:
- *Caption Generation*: Use RAG to generate captions grounded in a database of fitness quotes, humorous templates, or real-time health tip repositories.
- *Recipe Suggestions*: Retrieve healthy recipe suggestions based on meal contents and dietary preferences using RAG-enhanced retrieval.

**User Story**:  
> "As Alex, I want to snap meals for calorie estimates and get fun captions or recipe suggestions to make logging enjoyable and inspire healthier choices."

---

### 3. 🔒 Private Progress Stories with Logarithmic Permanence

**Description**: Private stories that decay over time unless interacted with. High-impact stories persist longer.

**Functionality**:
- Story posts visible to self or private circle
- Engagement (views/likes/comments) increases duration:
  - e.g., 7 days → 3 weeks → 2 months → 3 quarters
- Generate time-period summaries
- Timeline or "Scrapbook" view of milestones

**RAG Use**:
- *Summary Generation*: Retrieve meaningful highlights (e.g., best meals, longest fasts, streaks) from user history for recap generation, grounded in personal activity logs via RAG.

**User Story**:  
> "As Alex, I want to share progress privately, with engaging posts lasting longer based on quality and interaction, so I can celebrate milestones over time."

---

### 4. 👥 Community Group Chats with Smart Suggestions

**Description**: Users join interest-based private groups, build streaks, and connect with suggested friends.

**Functionality**:
- Join or create niche groups (e.g., "Fasting Fridays", "1600 Cal Crew")
- Maintain shared streaks (e.g., log 5 days together)
- AI-based friend and group suggestions based on behavioral similarity and tags
- Anonymity mode for sensitive sharing

**RAG Use**:
- *Group Suggestions*: RAG can retrieve contextual matches for group chats or peer recommendations by grounding suggestions in a dynamic graph of user content, goals, and habits.

**User Story**:  
> "As Alex, I want to join private chats with streaks and get friend suggestions to build a supportive network of like-minded individuals."

---

### 5. 🤖 Personalized AI Advice with Progressive Profile

**Description**: AI assistant evolves based on snaps, behavior, and interaction feedback.

**Functionality**:
- Basic phase: general wellness tips
- Learns from:
  - Meal and fast logging
  - Time of use, content preferences
  - Thumbs up/down on advice
- Advanced phase: personalized recommendations based on tracked patterns

**RAG Use**:
- *Advice Generation*: Use RAG to ground suggestions in a database of evidence-based fitness, nutrition, and behavioral science tips.
- *Profile-Aware Retrieval*: Advice is tailored by retrieving guidance aligned with user progress, patterns, and expressed preferences.

**User Story**:  
> "As Alex, I want tailored advice that improves as the app learns my preferences, so I can make informed fitness and nutrition choices effortlessly."

---

### 6. 🔌 App Integrations

**Description**: Sync with major wellness tools to avoid data duplication and improve insights.

**Functionality**:
- Syncs with Apple Health / Google Fit
- Optional connections to:
  - Fasting apps (Zero, Fastic)
  - Fitness trackers (Fitbit, Garmin)
  - Nutrition apps (MyFitnessPal, Cronometer)
- Modular dashboard for imports

**User Story**:  
> "As Alex, I want the app to work with my other tools so I can keep everything in one place without duplication."

---

## 🧪 Phase II Milestones

| Phase | Goals | Key Deliverables |
|-------|-------|------------------|
| Q1 | Foundation | Snap-to-fast UI, basic AI meal logging, Private Stories |
| Q2 | Community & Challenges | Group chats, Streaks, Smart suggestions |
| Q3 | Personalization | AI advisor MVP, integration API layer, story lifespan logic |
| Q4 | Polish & Scale | Challenge platform, recap engine, meal model tuning |

---

## 🧩 Tech Stack Notes

- **Flutter**: Continue cross-platform development
- **Firebase**: 
  - Firestore for ephemeral/private content
  - Cloud Functions for story decay + summary generation
- **AI/ML**:
  - Vision model (MLKit or custom CNN) for meal recognition
  - RAG architecture for captioning, recipe lookup, and advice delivery
- **RAG Stack**:
  - Vector DB (e.g., Pinecone, Weaviate)
  - Embedding Model (OpenAI, Cohere, or SentenceTransformers)
  - LLM Layer (GPT-4, Claude, or open-source)
- **Privacy**:
  - Scoped encryption for private content
  - Per-post visibility settings with local-first storage fallback 