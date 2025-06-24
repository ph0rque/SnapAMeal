# SnapAMeal Development Plan

This document outlines the tasks, subtasks, and estimated timelines for developing "SnapAMeal," a Snapchat-like mobile application built with Flutter and Firebase. The development is structured in phases as per the PRD, with timelines based on a small to medium-sized team with moderate expertise.

## Phase 1.1: Foundational Setup & Core Authentication

This phase establishes the core infrastructure and user authentication systems.

### Tasks and Subtasks

**1. Configure Android Environment**
*   **Subtasks:**
    *   Resolve current blockers (e.g., Android SDK issues)
    *   Set up necessary tools (Android Studio, Flutter, etc.)
    *   Test the environment with a sample Flutter project
*   **Estimate:** 1–2 days
*   **Status:** Done

**2. Set Up Firebase Project**
*   **Subtasks:**
    *   Create the Firebase project in the console
    *   Integrate configuration files (google-services.json, GoogleService-Info.plist) into Android and iOS projects
    *   Verify setup with a test function (e.g., authentication or Firestore read)
*   **Estimate:** 0.5–1 day
*   **Status:** Done

**3. Implement Email/Password Authentication**
*   **Subtasks:**
    *   Design and build registration and login UI screens
    *   Integrate Firebase Authentication for user creation and sign-in
    *   Create user documents in Firestore upon registration
    *   Implement an AuthGate to manage user sessions and direct users to the correct screen
    *   Test authentication flows (sign-up, login, error handling)
*   **Estimate:** 1–2 weeks
*   **Status:** Done

**4. Refine Core Implementation Based on Developer Feedback**
*   **Subtasks:**
    *   **UI Components:** Refactor `MyButton` and `MyTextField` to remove hardcoded margins, deferring spacing control to parent layout widgets (e.g., `Padding`).
    *   **Button Implementation:** Replace custom `GestureDetector`-based buttons with standard Material buttons (e.g., `ElevatedButton`) to improve UX and accessibility.
    *   **Service Management:** Refactor `AuthService` to use a singleton pattern or a service locator to ensure a single, efficient instance throughout the app.
    *   **Async Operations:** Review and refactor all authentication methods to correctly `await` asynchronous Firebase calls for robust error handling.
*   **Estimate:** 2-4 days
*   **Status:** Done

**5. Solidify Firestore Security Rules**
*   **Subtasks:**
    *   Write initial security rules to protect user data (e.g., users can only create their own profiles)
    *   Test rules with various scenarios (e.g., unauthorized access attempts)
    *   Deploy rules to Firestore
*   **Estimate:** 2–3 days
*   **Status:** Holding off until after Phase 4.

**Total Estimate for Phase 1.1:** 2–3.5 weeks

## Phase 2: Core Messaging

This phase builds the essential messaging features: friend management, one-on-one chat, and ephemeral snaps.

### Tasks and Subtasks

**1. Friend Management**
*   **Subtasks:**
    *   Implement friend search by username
    *   Add functionality to send, accept, and remove friend requests
    *   Optionally sync contacts for friend suggestions
    *   Update Firestore to manage friend relationships
*   **Estimate:** 1–2 weeks
*   **Status:** Done

**2. One-on-One Chat**
*   **Subtasks:**
    *   Design and build the chat interface
    *   Implement real-time messaging using Firestore collections and listeners
    *   Enforce disappearing message logic (messages disappear after viewing or after 24 hours)
    *   Allow users to save messages by tapping
    *   Test chat functionality and edge cases (e.g., offline behavior)
*   **Estimate:** 2–3 weeks
*   **Status:** Done

**3. Ephemeral Messaging (Snaps)**
*   **Subtasks:**
    *   Integrate Flutter's camera package for photo and video capture
    *   Implement customizable view times for photos (1–10 seconds) and one-time video playback
    *   Store media temporarily in Firebase Storage and metadata in Firestore
    *   Implement deletion logic using Cloud Functions post-viewing or expiration
    *   Add replay functionality (one replay per day) and screenshot notifications via FCM
    *   Test snap sending, viewing, and deletion flows
*   **Estimate:** 2–3 weeks
*   **Status:** Done

**Total Estimate for Phase 2:** 5–7 weeks

## Phase 3: Social Features

This phase introduces social features: stories, group messaging, and streaks.

### Tasks and Subtasks

**1. Stories**
*   **Subtasks:**
    *   Build the story posting interface (photo/video upload)
    *   Implement 24-hour visibility with multiple views allowed
    *   Track and display viewers using Firestore real-time listeners
    *   Set up auto-deletion of stories after 24 hours via Cloud Functions
    *   Test story posting, viewing, and deletion
*   **Estimate:** 1–2 weeks
*   **Status:** Done

**2. Group Messaging**
*   **Subtasks:**
    *   Extend chat functionality to support group chats (up to 16 users)
    *   Implement disappearing message rules for group chats
    *   Optimize Firestore queries for multi-user chats
    *   Test group chat creation, messaging, and deletion logic
*   **Estimate:** 1–2 weeks
*   **Status:** Done

**3. Streaks**
*   **Subtasks:**
    *   Track consecutive snap exchanges between friends using Firestore
    *   Display streak count and visual indicators (e.g., 🔥 emoji)
    *   Implement real-time updates for streak status
    *   Set up FCM notifications for streak maintenance and expiration
    *   Test streak logic and notifications
*   **Estimate:** 1–2 weeks
*   **Status:** Done

**Total Estimate for Phase 3:** 4–6 weeks

## Phase 4: Advanced Features (High-Risk R&D)

This phase focuses on integrating AR filters, a complex feature requiring native integration.

### Tasks and Subtasks

**1. AR Filters**
*   **Subtasks:**
    *   Research and select AR libraries (e.g., ARKit for iOS, ARCore for Android)
    *   Implement platform channels in Flutter to access native AR capabilities
    *   Develop a set of simple AR filters (e.g., face distortions, color effects)
    *   Optimize filter rendering for smooth camera previews
    *   Test AR filters on various devices for compatibility and performance
*   **Estimate:** 4–8 weeks

**Total Estimate for Phase 4:** 4–8 weeks

## Overall Project Timeline

**Total Estimated Time:** 16–25 weeks (4–6 months)

### Breakdown by Phase

*   Phase 1.1: 2–3.5 weeks
*   Phase 2: 5–7 weeks
*   Phase 3: 4–6 weeks
*   Phase 4: 4–8 weeks

### Key Considerations

*   **Parallel Development:** Tasks like UI design and backend development can overlap to shorten the timeline.
*   **Team Size:** A larger, experienced team could reduce the duration.
*   **AR Filters:** High-risk feature; consider basic implementation first with enhancements later.
*   **Testing:** Includes time for bug fixing and minor iterations, but not major requirement changes.

### Future Technical Debt & Refinements
*   **Firestore Security Rules:** The project currently lacks deployed Firestore security rules, operating in a less secure test mode. **This is a critical task that must be revisited and completed after Phase 4** to ensure the production application is secure.

## Conclusion

The SnapAMeal development plan leverages Flutter and Firebase to deliver a scalable, real-time social app. The 4–6 month timeline ensures a robust foundation, core features, and advanced enhancements while managing complexity and risk. 
