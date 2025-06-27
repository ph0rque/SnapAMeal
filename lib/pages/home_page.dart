import 'package:snapameal/pages/ar_camera_page.dart';

import 'package:snapameal/pages/meal_logging_page.dart';
import 'package:snapameal/pages/milestone_stories_page.dart';
import 'package:snapameal/pages/weekly_review_page.dart';
import 'package:snapameal/pages/ai_settings_page.dart';
import 'package:snapameal/services/auth_service.dart';
import 'package:flutter/material.dart';

import 'package:snapameal/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:snapameal/services/story_service.dart';

import 'package:snapameal/design_system/snap_ui.dart';

import 'package:provider/provider.dart';
import '../providers/fasting_state_provider.dart';
import '../widgets/fasting_aware_navigation.dart';
import '../widgets/demo_fasting_showcase.dart';
import '../widgets/demo_meal_showcase.dart';
import '../widgets/demo_health_dashboard_showcase.dart';
import '../widgets/demo_ai_advice_showcase.dart';
import '../widgets/demo_social_showcase.dart';
import '../widgets/demo_story_showcase.dart';
import '../widgets/demo_friend_matching_showcase.dart';
import '../widgets/demo_story_permanence_showcase.dart';
import '../widgets/demo_performance_showcase.dart';
import '../widgets/demo_ai_sophistication_showcase.dart';

import '../design_system/widgets/fasting_status_indicators.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  final StoryService _storyService = StoryService();

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        // Home - already on home page
        setState(() {
          _selectedIndex = index;
        });
        break;
      case 1:
        // Camera options
        _showCameraOptions();
        break;
      case 2:
        // Chats
        Navigator.pushNamed(context, '/chats');
        break;
      case 3:
        // Friends
        Navigator.pushNamed(context, '/friends');
        break;
    }
  }

  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture moments with AR filters'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ARCameraPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restaurant),
              title: const Text('Log Meal'),
              subtitle: const Text('AI-powered meal recognition and tracking'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealLoggingPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  void logout() {
    _authService.signOut();
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: SnapUIColors.accentRed,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FastingStateProvider>(
      builder: (context, fastingState, _) {
        return Scaffold(
          appBar: FastingAwareAppBar(
            title: null, // Uses fastingState.appBarTitle automatically
            actions: [
              IconButton(
                icon: Icon(
                  fastingState.fastingModeEnabled
                      ? Icons.shield
                      : Icons.settings,
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle_outlined),
                onSelected: (value) {
                  switch (value) {
                    case 'reviews':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const WeeklyReviewPage(),
                        ),
                      );
                      break;
                    case 'ai_settings':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AISettingsPage(),
                        ),
                      );
                      break;
                    case 'logout':
                      _showLogoutDialog();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reviews',
                    child: Row(
                      children: [
                        Icon(Icons.assessment),
                        SizedBox(width: 8),
                        Text('My Reviews'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'ai_settings',
                    child: Row(
                      children: [
                        Icon(Icons.smart_toy),
                        SizedBox(width: 8),
                        Text('AI Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: SnapUIColors.accentRed),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(color: SnapUIColors.accentRed),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _buildBody(fastingState),
          bottomNavigationBar: FastingAwareBottomNavigation(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: _getNavigationItems(),
          ),
          floatingActionButton: _buildFloatingActionButton(fastingState),
        );
      },
    );
  }

  /// Build main body with fasting-aware content
  Widget _buildBody(FastingStateProvider fastingState) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              // Add top padding when banner is showing
              if (fastingState.isActiveFasting) SizedBox(height: 80),

              // Fasting status card (shown when fasting is active)
              if (fastingState.isActiveFasting)
                _buildFastingStatusCard(fastingState),

              // Main content with conditional visibility
              _buildMainContent(fastingState),

              // Fasting insights (shown after sessions)
              if (fastingState.totalSessionsCount > 0)
                _buildFastingInsights(fastingState),
            ],
          ),
        ),

        // Floating status banner
        if (fastingState.isActiveFasting)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FastingStatusBanner(
              fastingState: fastingState,
              showDismiss: true,
            ),
          ),
      ],
    );
  }

  /// Build fasting status card
  Widget _buildFastingStatusCard(FastingStateProvider fastingState) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              fastingState.appThemeColor.withValues(alpha: 0.15),
              fastingState.appThemeColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.timer, size: 40, color: fastingState.appThemeColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fasting in Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: fastingState.appThemeColor,
                        ),
                      ),
                      Text(
                        fastingState.fastingTypeDisplay,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                CircularProgressIndicator(
                  value: fastingState.progressPercentage,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    fastingState.appThemeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: fastingState.progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                fastingState.appThemeColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/fasting-timer');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fastingState.appThemeColor,
                    ),
                    child: const Text('View Timer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build main content with fasting awareness
  Widget _buildMainContent(FastingStateProvider fastingState) {
    // Filter content based on fasting state
    final stories = _getFilteredStories(fastingState);
    final recommendations = _getFilteredRecommendations(fastingState);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Demo showcases for investor presentations
        FutureBuilder<bool>(
          future: AuthService().isCurrentUserDemo(),
          builder: (context, snapshot) {
            final isDemo = snapshot.data ?? false;
            if (!isDemo) return const SizedBox.shrink();

            return Column(
              children: [
                // Fasting demo showcase
                const DemoFastingShowcase(),
                const SizedBox(height: 20),

                // Meal logging demo showcase
                const DemoMealShowcase(),
                const SizedBox(height: 20),

                // Health dashboard demo showcase
                const DemoHealthDashboardShowcase(),
                const SizedBox(height: 20),

                // AI advice demo showcase
                const DemoAIAdviceShowcase(),
                const SizedBox(height: 20),

                // Social features demo showcase
                const DemoSocialShowcase(),
                const SizedBox(height: 20),

                // Story sharing demo showcase
                const DemoStoryShowcase(),
                const SizedBox(height: 20),

                // Friend matching demo showcase
                const DemoFriendMatchingShowcase(),
                const SizedBox(height: 20),

                // Story permanence demo showcase
                const DemoStoryPermanenceShowcase(),
                const SizedBox(height: 20),

                // Performance demo showcase
                const DemoPerformanceShowcase(),
                const SizedBox(height: 20),

                // AI sophistication demo showcase
                const DemoAISophisticationShowcase(),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
        // Stories section
        if (stories.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              fastingState.fastingModeEnabled
                  ? 'Motivation Stories'
                  : 'Recent Stories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: fastingState.fastingModeEnabled
                    ? fastingState.appThemeColor
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: stories.length,
              itemBuilder: (context, index) =>
                  _buildStoryItem(stories[index], fastingState),
            ),
          ),
        ],

        // Milestone Stories section
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Milestone Stories',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: fastingState.fastingModeEnabled
                      ? fastingState.appThemeColor
                      : null,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MilestoneStoriesPage(),
                    ),
                  );
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: fastingState.fastingModeEnabled
                        ? fastingState.appThemeColor
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        _buildMilestoneStoriesPreview(fastingState),

        // Recommendations section
        if (recommendations.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              fastingState.fastingModeEnabled
                  ? 'Health Recommendations'
                  : 'For You',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: fastingState.fastingModeEnabled
                    ? fastingState.appThemeColor
                    : null,
              ),
            ),
          ),
          ...recommendations.map(
            (item) => _buildRecommendationItem(item, fastingState),
          ),
        ],

        // Fasting mode empty state
        if (fastingState.fastingModeEnabled &&
            stories.isEmpty &&
            recommendations.isEmpty)
          _buildFastingEmptyState(fastingState),
      ],
    );
  }

  /// Build fasting insights section
  Widget _buildFastingInsights(FastingStateProvider fastingState) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: fastingState.appThemeColor),
                SizedBox(width: 8),
                Text(
                  'Your Fasting Journey',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total Sessions',
                    '${fastingState.totalSessionsCount}',
                    Icons.timer,
                    fastingState.appThemeColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    '${fastingState.completedSessionsCount}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Current Streak',
                    '${fastingState.currentStreak}',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 44),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/fasting-stats');
              },
              child: Text('View Detailed Stats'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build stat item widget
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Build milestone stories preview
  Widget _buildMilestoneStoriesPreview(FastingStateProvider fastingState) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: _storyService.getMilestoneStories(
        FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: 3,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 120,
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: CircularProgressIndicator(
                color: fastingState.fastingModeEnabled
                    ? fastingState.appThemeColor
                    : Theme.of(context).primaryColor,
              ),
            ),
          );
        }

        final milestoneStories = snapshot.data ?? [];

        if (milestoneStories.isEmpty) {
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: fastingState.fastingModeEnabled
                  ? fastingState.appThemeColor.withValues(alpha: 0.05)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: fastingState.fastingModeEnabled
                    ? fastingState.appThemeColor.withValues(alpha: 0.2)
                    : Colors.grey[300]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: fastingState.fastingModeEnabled
                      ? fastingState.appThemeColor
                      : Colors.grey[600],
                  size: 32,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No milestone stories yet',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: fastingState.fastingModeEnabled
                              ? fastingState.appThemeColor
                              : Colors.grey[800],
                        ),
                      ),
                      Text(
                        'Stories with high engagement become milestones',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: milestoneStories.length,
            itemBuilder: (context, index) {
              final story = milestoneStories[index];
              final data = story.data() as Map<String, dynamic>;
              final permanence = data['permanence'] as Map<String, dynamic>?;
              final tier = permanence?['tier'] ?? 'standard';
              final mediaUrl = data['mediaUrl'] as String?;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MilestoneStoriesPage(
                        userId: FirebaseAuth.instance.currentUser?.uid,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 80,
                  margin: EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getMilestoneTierColor(tier),
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: mediaUrl != null
                              ? Image.network(
                                  mediaUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: Icon(
                                        Icons.broken_image,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: _getMilestoneTierColor(
                                    tier,
                                  ).withValues(alpha: 0.2),
                                  child: Icon(
                                    _getMilestoneTierIcon(tier),
                                    color: _getMilestoneTierColor(tier),
                                    size: 24,
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        tier.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getMilestoneTierColor(tier),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Get milestone tier color
  Color _getMilestoneTierColor(String tier) {
    switch (tier) {
      case 'weekly':
        return Colors.amber;
      case 'monthly':
        return Colors.purple;
      case 'milestone':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get milestone tier icon
  IconData _getMilestoneTierIcon(String tier) {
    switch (tier) {
      case 'weekly':
        return Icons.star;
      case 'monthly':
        return Icons.auto_awesome;
      case 'milestone':
        return Icons.emoji_events;
      default:
        return Icons.circle;
    }
  }

  /// Build fasting empty state
  Widget _buildFastingEmptyState(FastingStateProvider fastingState) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: fastingState.appThemeColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: fastingState.appThemeColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.shield, size: 64, color: fastingState.appThemeColor),
          SizedBox(height: 16),
          Text(
            'Fasting Mode Active',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: fastingState.appThemeColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Content is being filtered to support your fasting goals. Stay strong!',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/meditation-guide');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: fastingState.appThemeColor,
            ),
            child: Text('Try Meditation'),
          ),
        ],
      ),
    );
  }

  /// Get filtered stories based on fasting state
  List<dynamic> _getFilteredStories(FastingStateProvider fastingState) {
    // In a real implementation, you would filter stories based on content
    // For now, return appropriate content based on fasting state
    if (fastingState.fastingModeEnabled) {
      // Return motivation/health-focused stories
      return _getMotivationalStories();
    }

    return _getAllStories();
  }

  /// Get filtered recommendations based on fasting state
  List<dynamic> _getFilteredRecommendations(FastingStateProvider fastingState) {
    if (fastingState.fastingModeEnabled) {
      return _getHealthRecommendations();
    }

    return _getAllRecommendations();
  }

  /// Get motivational stories for fasting mode
  List<dynamic> _getMotivationalStories() {
    return [
      {
        'title': 'Fasting Success Story',
        'description': 'How intermittent fasting changed my life',
        'type': 'motivation',
      },
      {
        'title': 'Health Benefits',
        'description': 'The science behind fasting',
        'type': 'education',
      },
    ];
  }

  /// Get all stories for normal mode
  List<dynamic> _getAllStories() {
    return [
      {
        'title': 'Delicious Recipe',
        'description': 'Try this amazing pasta dish',
        'type': 'recipe',
      },
      {
        'title': 'Food Adventure',
        'description': 'Exploring local cuisine',
        'type': 'adventure',
      },
    ];
  }

  /// Get health recommendations for fasting mode
  List<dynamic> _getHealthRecommendations() {
    return [
      {
        'title': 'Stay Hydrated',
        'description': 'Drink plenty of water during your fast',
        'type': 'health',
      },
      {
        'title': 'Gentle Exercise',
        'description': 'Light walking can help during fasting',
        'type': 'fitness',
      },
    ];
  }

  /// Get all recommendations for normal mode
  List<dynamic> _getAllRecommendations() {
    return [
      {
        'title': 'New Restaurant',
        'description': 'Check out this trendy spot',
        'type': 'restaurant',
      },
      {
        'title': 'Cooking Tip',
        'description': 'Master this cooking technique',
        'type': 'tip',
      },
    ];
  }

  /// Build story item widget
  Widget _buildStoryItem(dynamic story, FastingStateProvider fastingState) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: fastingState.fastingModeEnabled
                  ? fastingState.appThemeColor.withValues(alpha: 0.1)
                  : SnapUIColors.greyLight,
              border: Border.all(
                color: fastingState.fastingModeEnabled
                    ? fastingState.appThemeColor
                    : SnapUIColors.grey,
              ),
            ),
            child: Icon(
              story['type'] == 'motivation'
                  ? Icons.favorite
                  : story['type'] == 'education'
                  ? Icons.school
                  : story['type'] == 'recipe'
                  ? Icons.restaurant
                  : Icons.camera_alt,
              color: fastingState.fastingModeEnabled
                  ? fastingState.appThemeColor
                  : SnapUIColors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            story['title'] ?? '',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: fastingState.fastingModeEnabled
                  ? fastingState.appThemeColor
                  : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build recommendation item widget
  Widget _buildRecommendationItem(
    dynamic item,
    FastingStateProvider fastingState,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: fastingState.fastingModeEnabled
              ? fastingState.appThemeColor.withValues(alpha: 0.1)
              : SnapUIColors.primaryYellow.withValues(alpha: 0.1),
          child: Icon(
            item['type'] == 'health'
                ? Icons.health_and_safety
                : item['type'] == 'fitness'
                ? Icons.fitness_center
                : item['type'] == 'restaurant'
                ? Icons.restaurant
                : Icons.lightbulb,
            color: fastingState.fastingModeEnabled
                ? fastingState.appThemeColor
                : SnapUIColors.primaryYellow,
          ),
        ),
        title: Text(
          item['title'] ?? '',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: fastingState.fastingModeEnabled
                ? fastingState.appThemeColor
                : null,
          ),
        ),
        subtitle: Text(item['description'] ?? ''),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: fastingState.fastingModeEnabled
              ? fastingState.appThemeColor
              : null,
        ),
        onTap: () {
          // Handle recommendation tap
        },
      ),
    );
  }

  /// Build floating action button with fasting context
  Widget? _buildFloatingActionButton(FastingStateProvider fastingState) {
    if (fastingState.fastingModeEnabled) {
      // Show fasting-specific FAB
      return FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/camera');
        },
        backgroundColor: fastingState.appThemeColor,
        child: Icon(Icons.camera_alt),
      );
    }

    // Normal FAB
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushNamed(context, '/camera');
      },
      child: Icon(Icons.camera_alt),
    );
  }

  /// Get navigation items for bottom navigation
  List<BottomNavigationBarItem> _getNavigationItems() {
    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Camera'),
      BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
      BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Friends'),
    ];
  }
}
