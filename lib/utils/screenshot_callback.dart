/// A lightweight stub to replace the deprecated `screenshot_callback` package.
///
/// On platforms where screenshot detection is unsupported or intentionally
/// disabled (e.g., Android), this stub prevents compilation errors while
/// preserving the existing API surface so that calling code remains unchanged.
///
/// To enable real screenshot detection on supported platforms, simply replace
/// this file with an implementation backed by a platform-specific plugin.
class ScreenshotCallback {
  /// Registers a listener that is invoked when a screenshot is taken.
  ///
  /// On stub builds this does nothing.
  void addListener(void Function() listener) {
    // No-op on unsupported platforms.
  }

  /// Disposes any resources used by the callback.
  void dispose() {
    // No-op.
  }
} 