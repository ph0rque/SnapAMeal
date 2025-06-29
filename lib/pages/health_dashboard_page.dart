import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design_system/snap_ui.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

import '../providers/fasting_state_provider.dart';
import '../models/fasting_session.dart';
import '../models/health_profile.dart';
import '../models/ai_advice.dart';
import '../widgets/fasting_aware_navigation.dart';
import '../design_system/widgets/fasting_timer_widget.dart';
import '../widgets/insight_of_the_day_card.dart';
import '../widgets/mission_card.dart';
import '../widgets/notification_bell_widget.dart';
import '../services/in_app_notification_service.dart';

import 'ai_advice_page.dart';
import 'ai_settings_page.dart';
import 'data_conflicts_page.dart';
import 'data_export_page.dart';
import 'demo_settings_page.dart';
import 'health_groups_page.dart';
import 'health_onboarding_page.dart';
import 'integrations_page.dart';
import 'meal_logging_page.dart';
import 'weekly_review_page.dart';
import 'ar_camera_page.dart';

class HealthDashboardPage extends StatefulWidget {
  const HealthDashboardPage({super.key});

  @override
  State<HealthDashboardPage> createState() => _HealthDashboardPageState();
}

class _HealthDashboardPageState extends State<HealthDashboardPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final InAppNotificationService _notificationService = InAppNotificationService();

  HealthProfile? _healthProfile;
  List<FastingSession> _recentSessions = [];
  List<AIAdvice> _todaysAdvice = [];
  Map<String, dynamic> _healthMetrics = {};
  bool _isLoading = true;
  bool _isDemoUser = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if user is a demo user
      _isDemoUser = await _authService.isCurrentUserDemo();

      // Create test notifications for demo users if needed
      if (_isDemoUser) {
        await _notificationService.createTestNotifications();
      }

      // Load health profile
      await _loadHealthProfile(user.uid);

      // Load recent fasting sessions
      await _loadRecentFastingSessions(user.uid);

      // Load today's AI advice
      await _loadTodaysAdvice(user.uid);

      // Load health metrics
      await _loadHealthMetrics(user.uid);
    } catch (e) {
      Logger.d('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHealthProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('health_profiles')
          .doc(userId)
          .get();

      if (doc.exists) {
        setState(() {
          _healthProfile = HealthProfile.fromFirestore(doc);
        });
      }
    } catch (e) {
      Logger.d('Error loading health profile: $e');
    }
  }

  Future<void> _loadRecentFastingSessions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('fasting_sessions')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(5)
          .get();

      setState(() {
        _recentSessions = snapshot.docs
            .map((doc) => FastingSession.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      Logger.d('Error loading recent sessions: $e');
    }
  }

  Future<void> _loadTodaysAdvice(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final snapshot = await _firestore
          .collection('ai_advice')
          .where('user_id', isEqualTo: userId)
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .orderBy('created_at', descending: true)
          .limit(3)
          .get();

      setState(() {
        _todaysAdvice = snapshot.docs
            .map((doc) => AIAdvice.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      Logger.d('Error loading today\'s advice: $e');
    }
  }

  Future<void> _loadHealthMetrics(String userId) async {
    try {
      // Calculate health metrics from various sources
      final metrics = <String, dynamic>{};

      // Fasting metrics
      final fastingStats = await _calculateFastingStats(userId);
      metrics.addAll(fastingStats);

      // Weight and health metrics from health profile
      if (_healthProfile != null) {
        metrics['current_weight'] = _healthProfile!.currentWeight;
        metrics['target_weight'] = _healthProfile!.targetWeight;
        metrics['bmr'] = _healthProfile!.bmr;
        metrics['tdee'] = _healthProfile!.tdee;
      }

      // Weekly goals progress
      metrics['weekly_goals_completed'] = await _calculateWeeklyGoalsProgress(
        userId,
      );

      setState(() {
        _healthMetrics = metrics;
      });
    } catch (e) {
      Logger.d('Error loading health metrics: $e');
    }
  }

  Future<Map<String, dynamic>> _calculateFastingStats(String userId) async {
    try {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('fasting_sessions')
          .where('user_id', isEqualTo: userId)
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo),
          )
          .get();

      final sessions = snapshot.docs
          .map((doc) => FastingSession.fromFirestore(doc))
          .toList();

      final completedSessions = sessions
          .where((s) => s.state == FastingState.completed)
          .length;
      final totalHours = sessions.fold<double>(
        0,
        (totalHoursSum, session) =>
            totalHoursSum + (session.actualDuration?.inMinutes ?? 0) / 60.0,
      );
      final averageHours = sessions.isNotEmpty
          ? totalHours / sessions.length
          : 0.0;

      return {
        'weekly_fasting_sessions': completedSessions,
        'total_fasting_hours': totalHours,
        'average_session_hours': averageHours,
        'fasting_streak': await _calculateCurrentStreak(userId),
      };
    } catch (e) {
      Logger.d('Error calculating fasting stats: $e');
      return {};
    }
  }

  Future<int> _calculateCurrentStreak(String userId) async {
    // Simplified streak calculation - count consecutive days with completed fasts
    try {
      final sessions = await _firestore
          .collection('fasting_sessions')
          .where('user_id', isEqualTo: userId)
          .where('state', isEqualTo: FastingState.completed.name)
          .orderBy('created_at', descending: true)
          .limit(30)
          .get();

      if (sessions.docs.isEmpty) return 0;

      int streak = 0;
      DateTime? lastDate;

      for (final doc in sessions.docs) {
        final session = FastingSession.fromFirestore(doc);
        final sessionDate = DateTime(
          session.createdAt.year,
          session.createdAt.month,
          session.createdAt.day,
        );

        if (lastDate == null) {
          lastDate = sessionDate;
          streak = 1;
        } else {
          final daysDiff = lastDate.difference(sessionDate).inDays;
          if (daysDiff == 1) {
            streak++;
            lastDate = sessionDate;
          } else {
            break;
          }
        }
      }

      return streak;
    } catch (e) {
      Logger.d('Error calculating streak: $e');
      return 0;
    }
  }

  Future<int> _calculateWeeklyGoalsProgress(String userId) async {
    // Simplified goals progress calculation
    try {
      if (_healthProfile == null) return 0;

      int completed = 0;
      final goals = _healthProfile!.primaryGoals;

      // Check each goal type for completion this week
      if (goals.contains(HealthGoalType.weightLoss)) {
        // Check if user logged meals this week
        final mealsThisWeek = await _checkMealsThisWeek(userId);
        if (mealsThisWeek >= 14) completed++; // 2 meals per day
      }

      if (goals.contains(HealthGoalType.intermittentFasting)) {
        final fastingStats = _healthMetrics['weekly_fasting_sessions'] ?? 0;
        if (fastingStats >= 3) completed++; // 3 fasting sessions per week
      }

      return completed;
    } catch (e) {
      Logger.d('Error calculating weekly goals: $e');
      return 0;
    }
  }

  Future<int> _checkMealsThisWeek(String userId) async {
    try {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('meal_logs')
          .where('user_id', isEqualTo: userId)
          .where(
            'created_at',
            isGreaterThanOrEqualTo: Timestamp.fromDate(oneWeekAgo),
          )
          .get();

      return snapshot.docs.length;
    } catch (e) {
      Logger.d('Error checking meals this week: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FastingStateProvider>(
      builder: (context, fastingState, _) {
        return Scaffold(
          appBar: FastingAwareAppBar(
            title: 'Health Dashboard',
            actions: [
              const NotificationBellWidget(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle_outlined),
                onSelected: (value) {
                  switch (value) {
                    case 'health_profile':
                      _navigateToHealthProfile();
                      break;
                    case 'my_meals':
                      _navigateToMyMeals();
                      break;
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
                    case 'integrations':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IntegrationsPage(),
                        ),
                      );
                      break;
                    case 'data_export':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataExportPage(),
                        ),
                      );
                      break;
                    case 'data_conflicts':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DataConflictsPage(),
                        ),
                      );
                      break;
                    case 'demo_settings':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DemoSettingsPage(),
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
                    value: 'health_profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, color: SnapColors.primaryYellow),
                        SizedBox(width: 8),
                        Text('Health Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'my_meals',
                    child: Row(
                      children: [
                        Icon(Icons.restaurant, color: SnapColors.accentGreen),
                        SizedBox(width: 8),
                        Text('My Meals'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'reviews',
                    child: Row(
                      children: [
                        Icon(Icons.assessment, color: SnapColors.accentGreen),
                        SizedBox(width: 8),
                        Text('My Reviews'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'ai_settings',
                    child: Row(
                      children: [
                        Icon(Icons.smart_toy, color: SnapColors.accentPurple),
                        SizedBox(width: 8),
                        Text('AI Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'integrations',
                    child: Row(
                      children: [
                        Icon(Icons.sync, color: SnapColors.textSecondary),
                        SizedBox(width: 8),
                        Text('Integrations'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'data_export',
                    child: Row(
                      children: [
                        Icon(Icons.download, color: SnapColors.textSecondary),
                        SizedBox(width: 8),
                        Text('Export Data'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'data_conflicts',
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Data Conflicts'),
                      ],
                    ),
                  ),
                  // Demo settings - only show for demo users
                  if (_isDemoUser) const PopupMenuItem(
                    value: 'demo_settings',
                    child: Row(
                      children: [
                        Icon(Icons.science, color: SnapColors.primaryYellow),
                        SizedBox(width: 8),
                        Text('Demo Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: SnapColors.error),
                        SizedBox(width: 8),
                        Text(
                          'Logout',
                          style: TextStyle(color: SnapColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome header with personalization
                        _buildWelcomeHeader(),
                        const SizedBox(height: 24),

                        // Insight of the Day
                        const InsightOfTheDayCard(),

                        // Current Mission
                        const MissionCard(),

                        // Quick actions
                        _buildQuickActions(fastingState),
                        const SizedBox(height: 24),

                        // Current fasting status (if active)
                        if (fastingState.isActiveFasting) ...[
                          _buildCurrentFastingCard(fastingState),
                          const SizedBox(height: 24),
                        ],

                        // Health metrics overview
                        _buildHealthMetricsSection(),
                        const SizedBox(height: 24),

                        // Today's AI advice
                        _buildTodaysAdviceSection(),
                        const SizedBox(height: 24),

                        // Recent activity
                        _buildRecentActivitySection(),
                        const SizedBox(height: 24),

                        // Health goals progress
                        _buildHealthGoalsSection(),
                      ],
                    ),
                  ),
                ),
          bottomNavigationBar: FastingAwareBottomNavigation(
            currentIndex: 0, // Dashboard is the home tab
            onTap: _onNavigationTap,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt),
                label: 'Capture',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Community',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.psychology),
                label: 'AI Advice',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    final timeOfDay = DateTime.now().hour;
    String greeting;
    if (timeOfDay < 12) {
      greeting = 'Good Morning';
    } else if (timeOfDay < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return FutureBuilder<String>(
      future: _getUserDisplayName(),
      builder: (context, snapshot) {
        final userName = snapshot.data ?? 'there';
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting, $userName! 👋',
              style: SnapTypography.heading2.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getMotivationalMessage(),
              style: SnapTypography.body.copyWith(color: SnapColors.textSecondary),
            ),
          ],
        );
      },
    );
  }

  Future<String> _getUserDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'there';

    try {
      // First try to get name from Firestore user document
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final displayName = userData['displayName'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          return displayName.split(' ').first; // Use first name only
        }
      }

      // Fallback to Firebase Auth display name
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        return user.displayName!.split(' ').first;
      }

      // Last resort: extract from email
      if (user.email != null) {
        final emailName = user.email!.split('@').first.split('.').first;
        return emailName[0].toUpperCase() + emailName.substring(1);
      }
    } catch (e) {
      Logger.d('Error getting user display name: $e');
    }

    return 'there';
  }

  String _getMotivationalMessage() {
    if (_healthMetrics['fasting_streak'] != null &&
        _healthMetrics['fasting_streak'] > 0) {
      return 'You\'re on a ${_healthMetrics['fasting_streak']}-day fasting streak! 🔥';
    }

    if (_todaysAdvice.isNotEmpty) {
      return 'Your AI coach has new insights for you today.';
    }

    return 'Ready to continue your health journey?';
  }

  Widget _buildQuickActions(FastingStateProvider fastingState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: fastingState.isActiveFasting
                    ? Icons.pause_circle
                    : Icons.play_circle,
                title: fastingState.isActiveFasting
                    ? 'Pause Fast'
                    : 'Start Fast',
                subtitle: fastingState.isActiveFasting
                    ? 'Take a break'
                    : 'Begin your journey',
                color: SnapColors.primaryYellow,
                onTap: () => fastingState.isActiveFasting
                    ? fastingState.pauseFasting()
                    : _showStartFastingDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.restaurant,
                title: 'Log Meal',
                subtitle: 'AI recognition',
                color: SnapColors.accentGreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealLoggingPage(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: SnapTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: SnapColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: SnapTypography.caption.copyWith(
                  color: SnapColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentFastingCard(FastingStateProvider fastingState) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              fastingState.appThemeColor.withValues(alpha: 0.1),
              fastingState.appThemeColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timer, color: fastingState.appThemeColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Current Fast',
                  style: SnapTypography.heading3.copyWith(
                    color: fastingState.appThemeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (fastingState.currentSession != null)
              FastingTimerWidget(
                // Remove invalid parameters - check widget constructor
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetricsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Overview',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              'Fasting Streak',
              '${_healthMetrics['fasting_streak'] ?? 0} days',
              Icons.local_fire_department,
              SnapColors.accentRed,
            ),
            _buildMetricCard(
              'This Week',
              '${_healthMetrics['weekly_fasting_sessions'] ?? 0} sessions',
              Icons.calendar_today,
              SnapColors.primaryYellow,
            ),
            _buildMetricCard(
              'BMR',
              _healthProfile?.bmr?.toStringAsFixed(0) ?? '--',
              Icons.local_fire_department,
              SnapColors.accentGreen,
            ),
            _buildMetricCard(
              'Goals Progress',
              '${_healthMetrics['weekly_goals_completed'] ?? 0}/3',
              Icons.track_changes,
              SnapColors.accentPurple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: SnapTypography.heading3.copyWith(
                  color: SnapColors.textPrimary,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: SnapTypography.caption.copyWith(
                  color: SnapColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysAdviceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s AI Insights',
              style: SnapTypography.heading3.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AIAdvicePage()),
              ),
              child: Text(
                'View All',
                style: SnapTypography.body.copyWith(
                  color: SnapColors.primaryYellow,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_todaysAdvice.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No new insights today. Keep logging your meals and fasting sessions for personalized advice!',
                style: SnapTypography.body.copyWith(
                  color: SnapColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todaysAdvice.length,
            itemBuilder: (context, index) {
              final advice = _todaysAdvice[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    _getAdviceIcon(advice.type),
                    color: SnapColors.primaryYellow,
                  ),
                  title: Text(
                    advice.title,
                    style: SnapTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    advice.summary ?? advice.content,
                    style: SnapTypography.caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIAdvicePage(),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  IconData _getAdviceIcon(AdviceType type) {
    switch (type) {
      case AdviceType.nutritionTip:
        return Icons.restaurant;
      case AdviceType.fastingGuidance:
        return Icons.timer;
      case AdviceType.exerciseRecommendation:
        return Icons.fitness_center;
      case AdviceType.motivationalMessage:
        return Icons.favorite;
      default:
        return Icons.lightbulb;
    }
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_recentSessions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No recent fasting sessions. Start your first fast to see your progress here!',
                style: SnapTypography.body.copyWith(
                  color: SnapColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentSessions.take(3).length,
            itemBuilder: (context, index) {
              final session = _recentSessions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    session.state == FastingState.completed
                        ? Icons.check_circle
                        : Icons.pause_circle,
                    color: session.state == FastingState.completed
                        ? SnapColors.accentGreen
                        : SnapColors.accentPurple,
                  ),
                  title: Text(
                    session.typeDescription,
                    style: SnapTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${session.actualDuration?.inHours ?? 0}h ${(session.actualDuration?.inMinutes ?? 0) % 60}m - ${_formatDate(session.createdAt)}',
                    style: SnapTypography.caption,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: session.state == FastingState.completed
                          ? SnapColors.accentGreen.withValues(alpha: 0.1)
                          : SnapColors.accentPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.state == FastingState.completed
                          ? 'Completed'
                          : 'Paused',
                      style: SnapTypography.caption.copyWith(
                        color: session.state == FastingState.completed
                            ? SnapColors.accentGreen
                            : SnapColors.accentPurple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildHealthGoalsSection() {
    if (_healthProfile == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Goals',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _healthProfile!.primaryGoals.map((goal) {
            return Chip(
              label: Text(
                _getGoalDisplayName(goal),
                style: SnapTypography.caption,
              ),
              backgroundColor: SnapColors.primaryYellow.withValues(alpha: 0.1),
              labelStyle: TextStyle(color: SnapColors.primaryYellow),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getGoalDisplayName(HealthGoalType goal) {
    switch (goal) {
      case HealthGoalType.weightLoss:
        return 'Weight Loss';
      case HealthGoalType.weightGain:
        return 'Weight Gain';
      case HealthGoalType.muscleGain:
        return 'Muscle Gain';
      case HealthGoalType.fatLoss:
        return 'Fat Loss';
      case HealthGoalType.intermittentFasting:
        return 'Intermittent Fasting';
      case HealthGoalType.improveMetabolism:
        return 'Improve Metabolism';
      case HealthGoalType.betterSleep:
        return 'Better Sleep';
      case HealthGoalType.stressReduction:
        return 'Stress Reduction';
      case HealthGoalType.increaseEnergy:
        return 'Increase Energy';
      case HealthGoalType.improveDigestion:
        return 'Improve Digestion';
      case HealthGoalType.longevity:
        return 'Longevity';
      case HealthGoalType.mentalClarity:
        return 'Mental Clarity';
      case HealthGoalType.enduranceImprovement:
        return 'Endurance Improvement';
      case HealthGoalType.generalFitness:
        return 'General Fitness';
      case HealthGoalType.chronicDiseaseManagement:
        return 'Chronic Disease Management';
      case HealthGoalType.mentalWellness:
        return 'Mental Wellness';
      case HealthGoalType.nutritionImprovement:
        return 'Nutrition Improvement';
      case HealthGoalType.sleepImprovement:
        return 'Sleep Improvement';
      case HealthGoalType.habitBuilding:
        return 'Habit Building';
      case HealthGoalType.custom:
        return 'Custom Goal';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _showStartFastingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Fasting'),
        content: const Text('Choose your fasting duration:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Start 16:8 fast
              Provider.of<FastingStateProvider>(
                context,
                listen: false,
              ).startFasting(FastingType.sixteenEight);
            },
            child: const Text('16:8 Fast'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Start 24h fast
              Provider.of<FastingStateProvider>(
                context,
                listen: false,
              ).startFasting(FastingType.twentyFourHour);
            },
            child: const Text('24h Fast'),
          ),
        ],
      ),
    );
  }

  void _onNavigationTap(int index) {
    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        // Show camera options
        _showCameraOptions();
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HealthGroupsPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AIAdvicePage()),
        );
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
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('AR Camera'),
              subtitle: const Text('Capture moments with fitness AR filters'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ARCameraPage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToMyMeals() {
    Navigator.pushNamed(context, '/my_meals');
  }

  void _navigateToHealthProfile() {
    if (_healthProfile != null) {
      // If profile exists, show profile options
      showModalBottomSheet(
        context: context,
        backgroundColor: SnapColors.backgroundLight,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.8,
          minChildSize: 0.4,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: SnapColors.textSecondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Health Profile',
                  style: SnapTypography.heading2.copyWith(
                    color: SnapColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProfileSummaryCard(),
                        const SizedBox(height: 16),
                        _buildProfileActionsCard(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // No profile exists, navigate to onboarding
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HealthOnboardingPage(),
        ),
      );
    }
  }

  Widget _buildProfileSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Summary',
              style: SnapTypography.heading3.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            if (_healthProfile != null) ...[
              _buildProfileItem('Age', '${_healthProfile!.age ?? 'Not set'}'),
              _buildProfileItem('Gender', _healthProfile!.gender ?? 'Not set'),
              _buildProfileItem('Height', 
                _healthProfile!.heightCm != null 
                  ? '${_healthProfile!.heightCm!.toStringAsFixed(1)} cm'
                  : 'Not set'),
              _buildProfileItem('Weight', 
                _healthProfile!.weightKg != null 
                  ? '${_healthProfile!.weightKg!.toStringAsFixed(1)} kg'
                  : 'Not set'),
              _buildProfileItem('Activity Level', _healthProfile!.activityLevelDisplayName),
              _buildProfileItem('Goals', _healthProfile!.primaryGoalsDisplayNames.join(', ')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: SnapTypography.body.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HealthOnboardingPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Update Health Profile'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SnapColors.primaryYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DataExportPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Export Health Data'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
            style: TextButton.styleFrom(foregroundColor: SnapColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
