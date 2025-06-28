import 'package:flutter/material.dart';
import 'dart:async';
import '../models/fasting_session.dart';
import '../services/fasting_service.dart';
import '../services/content_filter_service.dart';
import '../utils/logger.dart';

/// Comprehensive fasting state management for the entire app
class FastingStateProvider extends ChangeNotifier {
  final FastingService _fastingService;
  final ContentFilterService? _contentFilterService;

  // Core fasting state
  FastingSession? _currentSession;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // App-wide fasting mode settings
  bool _fastingModeEnabled = false;
  FilterSeverity _filterSeverity = FilterSeverity.moderate;
  bool _showMotivationalContent = true;
  bool _enableNotifications = true;
  bool _enableProgressSharing = false;

  // Navigation and UI state
  Color _appThemeColor = Colors.blue;
  String _appBarTitle = 'SnapAMeal';
  IconData _primaryIcon = Icons.home;
  List<String> _hiddenNavigationItems = [];

  // Real-time updates
  StreamSubscription<FastingSession?>? _sessionSubscription;
  Timer? _progressUpdateTimer;

  // Session statistics
  int _totalSessionsCount = 0;
  int _completedSessionsCount = 0;
  Duration _totalFastingTime = Duration.zero;
  DateTime? _longestStreakStart;
  int _currentStreak = 0;

  FastingStateProvider({
    required FastingService fastingService,
    ContentFilterService? contentFilterService,
  }) : _fastingService = fastingService,
       _contentFilterService = contentFilterService {
    _initialize();
  }

  // Getters for current state
  FastingSession? get currentSession => _currentSession;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isActiveFasting => _currentSession?.isActive ?? false;
  bool get fastingModeEnabled => _fastingModeEnabled;
  FilterSeverity get filterSeverity => _filterSeverity;
  bool get showMotivationalContent => _showMotivationalContent;
  bool get enableNotifications => _enableNotifications;
  bool get enableProgressSharing => _enableProgressSharing;

  // UI State getters
  Color get appThemeColor => _appThemeColor;
  String get appBarTitle => _appBarTitle;
  IconData get primaryIcon => _primaryIcon;
  List<String> get hiddenNavigationItems => _hiddenNavigationItems;

  // Statistics getters
  int get totalSessionsCount => _totalSessionsCount;
  int get completedSessionsCount => _completedSessionsCount;
  Duration get totalFastingTime => _totalFastingTime;
  DateTime? get longestStreakStart => _longestStreakStart;
  int get currentStreak => _currentStreak;
  double get completionRate => _totalSessionsCount > 0
      ? _completedSessionsCount / _totalSessionsCount
      : 0.0;

  // Progress information
  double get progressPercentage => _currentSession?.progressPercentage ?? 0.0;
  Duration get elapsedTime => _currentSession?.elapsedTime ?? Duration.zero;
  Duration get remainingTime => _currentSession?.remainingTime ?? Duration.zero;
  String get fastingTypeDisplay =>
      _currentSession?.typeDescription ?? 'Not Fasting';
  String get sessionGoal => _currentSession?.personalGoal ?? '';

  /// Initialize the provider
  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load current session
      await _loadCurrentSession();

      // Load app settings
      await _loadAppSettings();

      // Load statistics
      await _loadStatistics();

      // Set up real-time monitoring
      _setupRealtimeMonitoring();

      // Update UI theme based on fasting state
      _updateAppTheme();

      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = 'Failed to initialize fasting state: $e';
      Logger.d('FastingStateProvider initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load current fasting session
  Future<void> _loadCurrentSession() async {
    try {
      _currentSession = await _fastingService.getCurrentSession();

      // Enable fasting mode if there's an active session
      if (_currentSession?.isActive == true) {
        _fastingModeEnabled = true;
      }
    } catch (e) {
      Logger.d('Error loading current session: $e');
    }
  }

  /// Load app-wide fasting settings
  Future<void> _loadAppSettings() async {
    try {
      final settings = await _fastingService.getFastingSettings();

      _filterSeverity = FilterSeverity.values.firstWhere(
        (severity) => severity.name == settings['filterSeverity'],
        orElse: () => FilterSeverity.moderate,
      );

      _showMotivationalContent = settings['showMotivationalContent'] ?? true;
      _enableNotifications = settings['enableNotifications'] ?? true;
      _enableProgressSharing = settings['enableProgressSharing'] ?? false;
    } catch (e) {
      Logger.d('Error loading app settings: $e');
    }
  }

  /// Load fasting statistics
  Future<void> _loadStatistics() async {
    try {
      final stats = await _fastingService.getFastingStatistics();

      _totalSessionsCount = stats['totalSessions'] ?? 0;
      _completedSessionsCount = stats['completedSessions'] ?? 0;
      _totalFastingTime = Duration(seconds: stats['totalFastingSeconds'] ?? 0);
      _currentStreak = stats['currentStreak'] ?? 0;

      if (stats['longestStreakStart'] != null) {
        _longestStreakStart = DateTime.parse(stats['longestStreakStart']);
      }
    } catch (e) {
      Logger.d('Error loading statistics: $e');
    }
  }

  /// Set up real-time monitoring of fasting sessions
  void _setupRealtimeMonitoring() {
    // Listen to session changes
    _sessionSubscription = _fastingService.currentSessionStream().listen(
      (session) {
        final wasActive = _currentSession?.isActive ?? false;
        _currentSession = session;

        // Update fasting mode when session state changes
        _fastingModeEnabled = session?.isActive ?? false;

        // Update app theme when fasting state changes
        if (wasActive != (session?.isActive ?? false)) {
          _updateAppTheme();
        }

        notifyListeners();
      },
      onError: (error) {
        _error = 'Session monitoring error: $error';
        Logger.d('Session stream error: $error');
        notifyListeners();
      },
    );

    // Set up periodic progress updates
    _progressUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateProgress(),
    );
  }

  /// Update progress and notify listeners
  void _updateProgress() {
    if (_currentSession?.isActive == true) {
      notifyListeners();
    }
  }

  /// Update app theme based on fasting state
  void _updateAppTheme() {
    if (_fastingModeEnabled && _currentSession?.isActive == true) {
      // Fasting mode theme
      _appThemeColor = _getFastingThemeColor();
      _appBarTitle = 'Fasting ${_getFastingProgressText()}';
      _primaryIcon = Icons.timer;
      _hiddenNavigationItems = ['food_discovery', 'restaurant_finder'];
    } else {
      // Normal mode theme
      _appThemeColor = Colors.blue;
      _appBarTitle = 'SnapAMeal';
      _primaryIcon = Icons.home;
      _hiddenNavigationItems = [];
    }
  }

  /// Get theme color based on fasting progress
  Color _getFastingThemeColor() {
    final progress = progressPercentage;

    if (progress < 0.25) {
      return Colors.red.shade400; // Early stage - challenging
    } else if (progress < 0.5) {
      return Colors.orange.shade400; // Getting stronger
    } else if (progress < 0.75) {
      return Colors.green.shade400; // Making good progress
    } else {
      return Colors.blue.shade600; // Nearly complete - calm confidence
    }
  }

  /// Get fasting progress text for app bar
  String _getFastingProgressText() {
    if (_currentSession == null) return '';

    final hours = elapsedTime.inHours;
    final minutes = elapsedTime.inMinutes.remainder(60);

    return '${hours}h ${minutes}m';
  }

  /// Start a new fasting session
  Future<bool> startFastingSession({
    required FastingType type,
    String? personalGoal,
    Map<String, dynamic>? customSettings,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _fastingService.startFasting(
        type: type,
        personalGoal: personalGoal,
        customDuration: customSettings?['customDuration'],
      );

      if (success) {
        _fastingModeEnabled = true;
        await _loadCurrentSession();
        await _loadStatistics();
        _updateAppTheme();

        // Send fasting start notification
        _sendFastingStartNotification();
      }

      _error = null;
      return success;
    } catch (e) {
      _error = 'Failed to start fasting session: $e';
      Logger.d('Error starting fasting session: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// End current fasting session
  Future<bool> endFastingSession({bool completed = false}) async {
    if (_currentSession == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await _fastingService.endFasting(completed: completed);

      if (success) {
        _fastingModeEnabled = false;
        _currentSession = null;
        await _loadStatistics();
        _updateAppTheme();

        // Send completion notification if completed
        if (completed) {
          _sendFastingCompletionNotification();
        }
      }

      _error = null;
      return success;
    } catch (e) {
      _error = 'Failed to end fasting session: $e';
      Logger.d('Error ending fasting session: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Pause current fasting session
  Future<bool> pauseFastingSession() async {
    if (_currentSession == null) return false;

    try {
      final success = await _fastingService.pauseFasting();
      if (success) {
        await _loadCurrentSession();
      }
      return success;
    } catch (e) {
      Logger.d('Error pausing fasting session: $e');
      return false;
    }
  }

  /// Pause fasting - alias for dashboard compatibility
  Future<void> pauseFasting() async {
    await pauseFastingSession();
  }

  /// End fasting - alias for dashboard compatibility
  Future<void> endFasting() async {
    await endFastingSession(completed: false);
  }

  /// Start fasting with specified type
  Future<void> startFasting(FastingType type) async {
    await startFastingSession(type: type);
  }

  /// Resume current fasting session
  Future<bool> resumeFastingSession() async {
    if (_currentSession == null) return false;

    try {
      final success = await _fastingService.resumeFasting();
      if (success) {
        await _loadCurrentSession();
      }
      return success;
    } catch (e) {
      Logger.d('Error resuming fasting session: $e');
      return false;
    }
  }

  /// Update fasting mode settings
  Future<void> updateFastingSettings({
    FilterSeverity? filterSeverity,
    bool? showMotivationalContent,
    bool? enableNotifications,
    bool? enableProgressSharing,
  }) async {
    try {
      final settings = <String, dynamic>{};

      if (filterSeverity != null) {
        _filterSeverity = filterSeverity;
        settings['filterSeverity'] = filterSeverity.name;
      }

      if (showMotivationalContent != null) {
        _showMotivationalContent = showMotivationalContent;
        settings['showMotivationalContent'] = showMotivationalContent;
      }

      if (enableNotifications != null) {
        _enableNotifications = enableNotifications;
        settings['enableNotifications'] = enableNotifications;
      }

      if (enableProgressSharing != null) {
        _enableProgressSharing = enableProgressSharing;
        settings['enableProgressSharing'] = enableProgressSharing;
      }

      await _fastingService.updateFastingSettings(settings);
      notifyListeners();
    } catch (e) {
      Logger.d('Error updating fasting settings: $e');
    }
  }

  /// Check if content should be filtered
  Future<bool> shouldFilterContent(
    String content,
    ContentType contentType,
  ) async {
    if (!_fastingModeEnabled || _contentFilterService == null) {
      return false;
    }

    try {
      final result = await _contentFilterService!.shouldFilterContent(
        content: content,
        contentType: contentType,
        fastingSession: _currentSession,
        customSeverity: _filterSeverity,
      );

      return result.shouldFilter;
    } catch (e) {
      Logger.d('Error checking content filter: $e');
      return false;
    }
  }

  /// Get alternative content for filtered item
  Future<AlternativeContent?> getAlternativeContent(
    FilterCategory category,
  ) async {
    final currentSession = _currentSession;
    if (!_fastingModeEnabled ||
        _contentFilterService == null ||
        currentSession == null) {
      return null;
    }

    try {
      return await _contentFilterService!.generateAlternativeContent(
        category,
        currentSession,
      );
    } catch (e) {
      Logger.d('Error getting alternative content: $e');
      return null;
    }
  }

  /// Check if navigation item should be hidden
  bool shouldHideNavigationItem(String itemKey) {
    return _fastingModeEnabled && _hiddenNavigationItems.contains(itemKey);
  }

  /// Get current app navigation configuration
  Map<String, dynamic> getNavigationConfig() {
    return {
      'fastingModeEnabled': _fastingModeEnabled,
      'themeColor': _appThemeColor,
      'appBarTitle': _appBarTitle,
      'primaryIcon': _primaryIcon,
      'hiddenItems': _hiddenNavigationItems,
      'showMotivationalContent': _showMotivationalContent,
    };
  }

  /// Send fasting start notification
  void _sendFastingStartNotification() {
    if (_enableNotifications && _currentSession != null) {
      // Implementation would depend on notification service
      Logger.d('Fasting session started: ${_currentSession?.typeDescription}');
    }
  }

  /// Send fasting completion notification
  void _sendFastingCompletionNotification() {
    if (_enableNotifications) {
      // Implementation would depend on notification service
      Logger.d('Fasting session completed successfully!');
    }
  }

  /// Refresh all state data
  Future<void> refresh() async {
    await _loadCurrentSession();
    await _loadStatistics();
    _updateAppTheme();
    notifyListeners();
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isLoading': _isLoading,
      'error': _error,
      'fastingModeEnabled': _fastingModeEnabled,
      'currentSession': _currentSession?.toMap(),
      'totalSessions': _totalSessionsCount,
      'completedSessions': _completedSessionsCount,
      'currentStreak': _currentStreak,
      'filterSeverity': _filterSeverity.name,
      'appThemeColor': _appThemeColor.toString(),
      'hiddenNavigationItems': _hiddenNavigationItems,
    };
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _progressUpdateTimer?.cancel();
    super.dispose();
  }
}
