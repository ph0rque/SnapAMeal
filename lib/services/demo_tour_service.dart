import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Service for managing guided demo tours and feature walkthroughs
class DemoTourService {
  static const String _tourCompletedKey = 'demo_tour_completed';
  static const String _featureTourPrefix = 'feature_tour_';

  /// Check if the main demo tour has been completed
  static Future<bool> isMainTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tourCompletedKey) ?? false;
  }

  /// Mark the main demo tour as completed
  static Future<void> markMainTourCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tourCompletedKey, true);
  }

  /// Check if a specific feature tour has been completed
  static Future<bool> isFeatureTourCompleted(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_featureTourPrefix$featureId') ?? false;
  }

  /// Mark a specific feature tour as completed
  static Future<void> markFeatureTourCompleted(String featureId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_featureTourPrefix$featureId', true);
  }

  /// Reset all tour progress (for demo reset)
  static Future<void> resetAllTours() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => 
        key == _tourCompletedKey || key.startsWith(_featureTourPrefix));
    
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  /// Show the main demo tour if not completed and user is in demo mode
  static Future<void> showMainTourIfNeeded(BuildContext context) async {
    final isDemo = await AuthService().isCurrentUserDemo();
    if (!isDemo) return;

    final isCompleted = await isMainTourCompleted();
    if (isCompleted) return;

    if (context.mounted) {
      await showMainTour(context);
    }
  }

  /// Show the main demo tour
  static Future<void> showMainTour(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DemoTourOverlay(),
        fullscreenDialog: true,
      ),
    );
    await markMainTourCompleted();
  }

  /// Show a feature-specific tour
  static Future<void> showFeatureTour(
    BuildContext context,
    String featureId,
    List<TourStep> steps,
  ) async {
    final isDemo = await AuthService().isCurrentUserDemo();
    if (!isDemo) return;

    final isCompleted = await isFeatureTourCompleted(featureId);
    if (isCompleted) return;

    if (context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FeatureTourOverlay(
            featureId: featureId,
            steps: steps,
          ),
          fullscreenDialog: true,
        ),
      );
      await markFeatureTourCompleted(featureId);
    }
  }
}

/// Data class for tour steps
class TourStep {
  final String title;
  final String description;
  final IconData icon;
  final GlobalKey? targetKey;
  final VoidCallback? onNext;
  final Duration? highlightDuration;

  const TourStep({
    required this.title,
    required this.description,
    required this.icon,
    this.targetKey,
    this.onNext,
    this.highlightDuration,
  });
}

/// Main demo tour overlay widget
class DemoTourOverlay extends StatefulWidget {
  const DemoTourOverlay({super.key});

  @override
  State<DemoTourOverlay> createState() => _DemoTourOverlayState();
}

class _DemoTourOverlayState extends State<DemoTourOverlay> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<TourStep> _mainTourSteps = [
    TourStep(
      title: 'Welcome to SnapAMeal Demo',
      description: 'This guided tour will showcase our key features and AI capabilities. Let\'s explore what makes SnapAMeal special!',
      icon: Icons.waving_hand,
    ),
    TourStep(
      title: 'AI-Powered Insights',
      description: 'Our RAG-enhanced AI provides personalized health advice based on your unique profile and the latest research.',
      icon: Icons.psychology_outlined,
    ),
    TourStep(
      title: 'Smart Fasting Timer',
      description: 'Intelligent fasting tracking that learns your patterns and provides optimal timing recommendations.',
      icon: Icons.timer_outlined,
    ),
    TourStep(
      title: 'Meal Recognition',
      description: 'Advanced computer vision instantly identifies your food and calculates nutrition data automatically.',
      icon: Icons.camera_alt_outlined,
    ),
    TourStep(
      title: 'Social Features',
      description: 'Connect with health communities, share progress stories, and get motivated by friends with similar goals.',
      icon: Icons.people_outline,
    ),
    TourStep(
      title: 'Ready to Explore!',
      description: 'Your demo environment is fully populated with 30+ days of realistic data. Explore and discover!',
      icon: Icons.rocket_launch,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Tour content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                itemCount: _mainTourSteps.length,
                itemBuilder: (context, index) {
                  return _buildTourStep(_mainTourSteps[index]);
                },
              ),
            ),
            
            // Navigation controls
            _buildNavigationControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Demo Tour',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${_currentStep + 1} of ${_mainTourSteps.length}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTourStep(TourStep step) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: Icon(
              step.icon,
              size: 60,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: const Text(
                'Previous',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Skip Tour',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: () {
              if (_currentStep < _mainTourSteps.length - 1) {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(_currentStep < _mainTourSteps.length - 1 ? 'Next' : 'Start Exploring'),
          ),
        ],
      ),
    );
  }
}

/// Feature-specific tour overlay
class FeatureTourOverlay extends StatefulWidget {
  final String featureId;
  final List<TourStep> steps;

  const FeatureTourOverlay({
    super.key,
    required this.featureId,
    required this.steps,
  });

  @override
  State<FeatureTourOverlay> createState() => _FeatureTourOverlayState();
}

class _FeatureTourOverlayState extends State<FeatureTourOverlay> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Feature Tour',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Tour content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                itemCount: widget.steps.length,
                itemBuilder: (context, index) {
                  return _buildFeatureTourStep(widget.steps[index]);
                },
              ),
            ),
            
            // Navigation
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text(
                        'Previous',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentStep < widget.steps.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Text(_currentStep < widget.steps.length - 1 ? 'Next' : 'Got it!'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTourStep(TourStep step) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            step.icon,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            step.description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Predefined tour steps for common features
class SnapAMealTours {
  /// Fasting feature tour
  static List<TourStep> get fastingTour => [
    const TourStep(
      title: 'Smart Fasting Timer',
      description: 'Your intelligent fasting companion that learns your patterns and optimizes your fasting windows.',
      icon: Icons.timer_outlined,
    ),
    const TourStep(
      title: 'Personalized Insights',
      description: 'Get AI-powered recommendations for optimal fasting duration based on your goals and past performance.',
      icon: Icons.insights_outlined,
    ),
    const TourStep(
      title: 'Progress Tracking',
      description: 'Monitor your fasting streaks, mood changes, and energy levels to understand what works best for you.',
      icon: Icons.trending_up_outlined,
    ),
  ];

  /// Meal logging tour
  static List<TourStep> get mealLoggingTour => [
    const TourStep(
      title: 'AI Meal Recognition',
      description: 'Simply take a photo of your meal and our AI will instantly identify the food and calculate nutrition.',
      icon: Icons.camera_alt_outlined,
    ),
    const TourStep(
      title: 'Nutrition Analysis',
      description: 'Get detailed breakdown of calories, macros, and micronutrients with suggestions for improvement.',
      icon: Icons.analytics_outlined,
    ),
    const TourStep(
      title: 'Pattern Learning',
      description: 'The AI learns your eating patterns and provides personalized meal timing and portion recommendations.',
      icon: Icons.psychology_outlined,
    ),
  ];

  /// Social features tour
  static List<TourStep> get socialTour => [
    const TourStep(
      title: 'Health Communities',
      description: 'Join groups focused on your specific health goals and connect with like-minded individuals.',
      icon: Icons.groups_outlined,
    ),
    const TourStep(
      title: 'Progress Stories',
      description: 'Share your journey with photos and milestones. Popular stories become more permanent.',
      icon: Icons.auto_stories_outlined,
    ),
    const TourStep(
      title: 'Friend Challenges',
      description: 'Compete and support each other with shared health challenges and streak tracking.',
      icon: Icons.emoji_events_outlined,
    ),
  ];

  /// AI insights tour
  static List<TourStep> get aiInsightsTour => [
    const TourStep(
      title: 'RAG-Powered Advice',
      description: 'Our AI combines your personal data with the latest health research to provide personalized insights.',
      icon: Icons.psychology_outlined,
    ),
    const TourStep(
      title: 'Contextual Recommendations',
      description: 'Get advice that considers your current health status, goals, and preferences.',
      icon: Icons.lightbulb_outlined,
    ),
    const TourStep(
      title: 'Learning & Adaptation',
      description: 'The AI continuously learns from your feedback and adjusts recommendations over time.',
      icon: Icons.auto_awesome_outlined,
    ),
  ];
} 