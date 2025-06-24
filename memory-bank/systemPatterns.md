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