# PRD: Short Video Snaps Feature

## Introduction/Overview

This feature enhances SnapAMeal's existing snap functionality by adding the ability to record and send short video messages (5 seconds or less). Users will be able to create ephemeral video content that behaves identically to photo snaps, providing a richer communication experience while maintaining the core disappearing message concept that defines the platform.

The feature integrates seamlessly into the existing camera interface, allowing users to switch between photo and video capture without disrupting their current workflow.

## Goals

1. **Enhance User Expression**: Enable users to communicate through short video messages, adding a dynamic dimension to their conversations
2. **Maintain Platform Consistency**: Ensure video snaps behave identically to photo snaps in terms of ephemerality and viewing controls
3. **Seamless Integration**: Integrate video recording into the existing camera interface without disrupting current user workflows
4. **Storage Efficiency**: Implement video compression to manage storage and bandwidth costs
5. **Visual Clarity**: Provide clear visual indicators (thumbnails) to distinguish video content from photo content

## User Stories

**As a SnapAMeal user**, I want to record short video messages so that I can share dynamic moments and expressions with my friends.

**As a SnapAMeal user**, I want video snaps to disappear after viewing just like photo snaps so that my privacy is maintained and conversations remain ephemeral.

**As a SnapAMeal user**, I want to control how long my video snap is viewable (1-10 seconds) so that I can determine the appropriate viewing duration for my content.

**As a SnapAMeal user**, I want to see video thumbnails in my snap list so that I can quickly identify video content before opening it.

**As a SnapAMeal user**, I want to post video stories so that I can share dynamic content with all my friends for 24 hours.

**As a SnapAMeal user**, I want videos to autoplay when I open them so that I have a smooth viewing experience without additional taps.

## Functional Requirements

1. **FR-001**: The system must allow users to record videos up to 5 seconds in length using the device's camera
2. **FR-002**: The system must integrate video recording into the existing camera interface with a clear mode toggle between photo and video
3. **FR-003**: The system must apply the same ephemeral behavior to video snaps as photo snaps (disappear after viewing or expiration)
4. **FR-004**: The system must allow users to set viewing duration (1-10 seconds) for video snaps, identical to photo snaps
5. **FR-005**: The system must support video snaps in both individual messaging and stories
6. **FR-006**: The system must compress recorded videos to optimize storage and bandwidth usage
7. **FR-007**: The system must generate and display video thumbnails in snap lists to differentiate video content from photos
8. **FR-008**: The system must autoplay video snaps when opened by recipients
9. **FR-009**: The system must support the same replay functionality for video snaps (one replay per day) as photo snaps
10. **FR-010**: The system must detect and notify senders of screenshots/screen recordings of video snaps
11. **FR-011**: The system must store video snaps in Firebase Storage with the same security and deletion patterns as photo snaps
12. **FR-012**: The system must track video snap metrics (sent, viewed, replayed) identical to photo snap tracking

## Non-Goals (Out of Scope)

1. **Video Editing Features**: No trimming, filters, effects, or other editing capabilities in this version
2. **Video Import**: No ability to import videos from camera roll or gallery
3. **Group Chat Videos**: Video snaps will not be supported in group messaging initially
4. **Extended Duration**: Videos longer than 5 seconds are not supported
5. **Video Quality Controls**: No user-selectable resolution or quality settings
6. **Audio-Only Messages**: Feature is specifically for video with audio, not audio-only messages
7. **Video Stories Collaboration**: No collaborative or shared video story features

## Design Considerations

### Camera Interface Updates
- Add a photo/video toggle button in the existing camera interface
- Show recording duration indicator during video capture
- Maintain consistent UI styling with existing camera controls
- Display clear visual feedback when video mode is active

### Video Thumbnail Design
- Generate thumbnails using the first frame of the video
- Add a video play icon overlay to distinguish from photos
- Maintain consistent sizing with existing photo snap previews
- Show video duration badge on thumbnails

### Viewing Experience
- Implement smooth autoplay without loading delays
- Show video progress indicator during playback
- Maintain existing snap viewing controls (tap to close, etc.)
- Display video duration and remaining viewing time

## Technical Considerations

### Video Storage & Processing
- Integrate with existing Firebase Storage infrastructure
- Implement video compression using Flutter's video processing capabilities
- Generate thumbnails server-side using Cloud Functions for consistency
- Ensure video deletion follows the same patterns as photo snaps

### Performance
- Optimize video upload/download to minimize battery and data usage
- Implement proper video caching to improve viewing experience
- Consider video preloading for better user experience

### Existing Integration Points
- Extend existing `SnapService` to handle video upload/download
- Update `ARCameraPage` to support video recording mode
- Modify `ViewSnapPage` to support video playback
- Update Cloud Functions to handle video deletion and notifications

## Success Metrics

### Phase 1 (Basic Functionality)
- **Technical Success**: Feature launches without critical bugs
- **User Adoption**: At least 10% of active users try video snaps within first week
- **System Performance**: Video snaps load and play within 2 seconds on average
- **Storage Efficiency**: Compressed videos average 50% smaller than uncompressed originals

### Future Considerations
- User engagement increase with video vs photo snaps
- Video snap retention rates compared to photo snaps
- User feedback on video quality and experience

## Open Questions

1. **Video Compression Standards**: What specific compression algorithm/quality should be used to balance file size vs quality?
2. **Storage Limits**: Should there be limits on total video storage per user?
3. **Bandwidth Considerations**: Should video quality adapt based on user's connection speed?
4. **Error Handling**: How should the app handle video recording failures or upload errors?
5. **Device Compatibility**: Are there minimum device requirements for video recording quality?

## Implementation Priority

**High Priority (Must Have)**:
- Basic video recording (FR-001, FR-002)
- Ephemeral behavior (FR-003, FR-004)
- Storage and compression (FR-006, FR-011)

**Medium Priority (Should Have)**:
- Thumbnails and UI indicators (FR-007)
- Autoplay functionality (FR-008)
- Stories integration (FR-005)

**Low Priority (Nice to Have)**:
- Advanced metrics tracking (FR-012)
- Screenshot detection for videos (FR-010) 