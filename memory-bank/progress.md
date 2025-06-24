# Progress

## What Works

- **Phase 1: Foundational Setup & Core Authentication** is complete. This includes environment setup, Firebase integration, and a full email/password authentication flow.
- **Phase 2: Core Messaging** is complete. This includes:
  - Full friend management (search, add, accept, view).
  - One-on-one real-time chat.
  - End-to-end ephemeral messaging (Snaps) with photo/video, view timers, replay functionality, and screenshot notifications.
  - Backend Cloud Functions for deleting viewed/expired snaps.

## What's Left to Build

- **Phase 3: Social Features** is next.
  - Stories
  - Group Messaging
  - Streaks

## Known Issues

- The iOS and Android development environments are fully configured and working. No known environment issues remain.
- The project currently uses temporary, open security rules for both Firestore and Firebase Storage. These must be properly secured before production. 