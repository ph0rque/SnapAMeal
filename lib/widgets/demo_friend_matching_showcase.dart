import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../design_system/snap_ui.dart';
import 'dart:math' as math;

/// Enhanced friend matching showcase for investor demos
/// Highlights AI-powered friend suggestions and compatibility algorithms
class DemoFriendMatchingShowcase extends StatefulWidget {
  const DemoFriendMatchingShowcase({super.key});

  @override
  State<DemoFriendMatchingShowcase> createState() =>
      _DemoFriendMatchingShowcaseState();
}

class _DemoFriendMatchingShowcaseState extends State<DemoFriendMatchingShowcase>
    with TickerProviderStateMixin {
  late AnimationController _matchingController;
  late AnimationController _algorithmController;
  late Animation<double> _matchingAnimation;
  late Animation<double> _algorithmAnimation;

  bool _showMatching = false;
  bool _showAlgorithm = false;
  int _currentSuggestionIndex = 0;

  final List<Map<String, dynamic>> _friendSuggestions = [
    {
      'name': 'Sarah Chen',
      'avatar': '👩‍⚕️',
      'age': 29,
      'location': 'San Francisco',
      'goals': ['Weight Loss', 'Muscle Gain'],
      'experience': 'Intermediate',
      'compatibility': 94,
      'mutualFriends': 3,
      'commonInterests': ['16:8 Fasting', 'Strength Training', 'Meal Prep'],
      'joinedDays': 45,
      'successStories': 2,
      'responseRate': 89,
      'timezone': 'PST',
      'preferredWorkout': 'Morning',
      'dietType': 'Keto',
      'color': SnapColors.accentGreen,
    },
    {
      'name': 'Mike Rodriguez',
      'avatar': '🧑‍💼',
      'age': 34,
      'location': 'Austin',
      'goals': ['Endurance', 'Health Optimization'],
      'experience': 'Advanced',
      'compatibility': 87,
      'mutualFriends': 1,
      'commonInterests': ['Intermittent Fasting', 'Running', 'Biohacking'],
      'joinedDays': 78,
      'successStories': 4,
      'responseRate': 92,
      'timezone': 'CST',
      'preferredWorkout': 'Evening',
      'dietType': 'Mediterranean',
      'color': SnapColors.accentBlue,
    },
    {
      'name': 'Emma Johnson',
      'avatar': '👩‍🎓',
      'age': 26,
      'location': 'New York',
      'goals': ['Stress Management', 'Energy'],
      'experience': 'Beginner',
      'compatibility': 91,
      'mutualFriends': 2,
      'commonInterests': ['Mindful Eating', 'Yoga', 'Sleep Optimization'],
      'joinedDays': 23,
      'successStories': 1,
      'responseRate': 95,
      'timezone': 'EST',
      'preferredWorkout': 'Flexible',
      'dietType': 'Plant-based',
      'color': SnapColors.accentPurple,
    },
  ];

  final List<Map<String, dynamic>> _matchingFactors = [
    {
      'factor': 'Goal Alignment',
      'weight': 35,
      'description': 'Shared health and fitness objectives',
      'icon': Icons.flag,
      'color': SnapColors.accentGreen,
    },
    {
      'factor': 'Experience Level',
      'weight': 25,
      'description': 'Similar knowledge and skill levels',
      'icon': Icons.school,
      'color': SnapColors.accentBlue,
    },
    {
      'factor': 'Lifestyle Compatibility',
      'weight': 20,
      'description': 'Schedule, timezone, and routine alignment',
      'icon': Icons.schedule,
      'color': SnapColors.primaryYellow,
    },
    {
      'factor': 'Communication Style',
      'weight': 20,
      'description': 'Response patterns and engagement preferences',
      'icon': Icons.chat,
      'color': SnapColors.accentPurple,
    },
  ];

  @override
  void initState() {
    super.initState();

    _matchingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _algorithmController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _matchingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _matchingController, curve: Curves.easeInOut),
    );

    _algorithmAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _algorithmController, curve: Curves.elasticOut),
    );

    // Auto-cycle through suggestions
    _startSuggestionCycle();
  }

  void _startSuggestionCycle() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _currentSuggestionIndex =
              (_currentSuggestionIndex + 1) % _friendSuggestions.length;
        });
        _startSuggestionCycle();
      }
    });
  }

  @override
  void dispose() {
    _matchingController.dispose();
    _algorithmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isCurrentUserDemo(),
      builder: (context, snapshot) {
        final isDemo = snapshot.data ?? false;
        if (!isDemo) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SnapColors.accentBlue.withValues(alpha: 0.1),
                SnapColors.accentPurple.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SnapColors.accentBlue.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo indicator
              _buildDemoIndicator(),

              const SizedBox(height: 20),

              // Matching overview
              _buildMatchingOverview(),

              const SizedBox(height: 20),

              // Featured friend suggestion
              _buildFeaturedSuggestion(),

              const SizedBox(height: 20),

              // AI matching algorithm
              _buildMatchingAlgorithmSection(),

              const SizedBox(height: 20),

              // Success metrics
              _buildSuccessMetrics(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SnapColors.accentBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_alt, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          const Text(
            'AI Friend Matching Demo',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Intelligent Social Connections',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Daily Matches',
                '12',
                'Personalized',
                Icons.auto_awesome,
                SnapColors.accentBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Success Rate',
                '78%',
                'Meaningful connections',
                Icons.handshake,
                SnapColors.accentGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Avg. Compatibility',
                '89%',
                'AI-calculated',
                Icons.psychology,
                SnapColors.accentPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SnapColors.textPrimary,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSuggestion() {
    final suggestion = _friendSuggestions[_currentSuggestionIndex];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SnapColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_add, color: SnapColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Suggested Connection',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showMatching ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showMatching = !_showMatching;
                  });
                  if (_showMatching) {
                    _matchingController.forward();
                  } else {
                    _matchingController.reverse();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Friend card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (suggestion['color'] as Color).withValues(alpha: 0.1),
                  (suggestion['color'] as Color).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (suggestion['color'] as Color).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile header
                Row(
                  children: [
                    Text(
                      suggestion['avatar'] as String,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            suggestion['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: SnapColors.textPrimary,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${suggestion['age']} • ${suggestion['location']}',
                            style: TextStyle(
                              color: SnapColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${suggestion['experience']} • ${suggestion['joinedDays']} days',
                            style: TextStyle(
                              color: suggestion['color'] as Color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: SnapColors.accentGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${suggestion['compatibility']}% Match',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: SnapColors.accentGreen,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Goals and interests
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...(suggestion['goals'] as List<String>).map(
                      (goal) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (suggestion['color'] as Color).withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          goal,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: suggestion['color'] as Color,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Quick stats
                Row(
                  children: [
                    _buildQuickStat(
                      Icons.group,
                      '${suggestion['mutualFriends']} mutual',
                    ),
                    const SizedBox(width: 16),
                    _buildQuickStat(
                      Icons.emoji_events,
                      '${suggestion['successStories']} stories',
                    ),
                    const SizedBox(width: 16),
                    _buildQuickStat(
                      Icons.reply,
                      '${suggestion['responseRate']}% response',
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (_showMatching) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _matchingAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _matchingAnimation.value,
                  child: Column(
                    children: [
                      // Common interests
                      _buildCommonInterests(suggestion),
                      const SizedBox(height: 12),

                      // Compatibility breakdown
                      _buildCompatibilityBreakdown(suggestion),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: SnapColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: SnapColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCommonInterests(Map<String, dynamic> suggestion) {
    final interests = suggestion['commonInterests'] as List<String>;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SnapColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite, color: SnapColors.accentRed, size: 16),
              const SizedBox(width: 6),
              Text(
                'Common Interests',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: SnapColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: interests
                .map(
                  (interest) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: SnapColors.accentRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: SnapColors.accentRed.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      interest,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: SnapColors.textPrimary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityBreakdown(Map<String, dynamic> suggestion) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SnapColors.accentGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SnapColors.accentGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: SnapColors.accentGreen, size: 16),
              const SizedBox(width: 6),
              Text(
                'Compatibility Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: SnapColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildCompatibilityItem(
                  'Goals',
                  96,
                  SnapColors.accentGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompatibilityItem(
                  'Schedule',
                  89,
                  SnapColors.accentBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompatibilityItem(
                  'Style',
                  92,
                  SnapColors.accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilityItem(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          '$score%',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: SnapColors.textPrimary,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchingAlgorithmSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SnapColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: SnapColors.accentPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Matching Algorithm',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showAlgorithm ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showAlgorithm = !_showAlgorithm;
                  });
                  if (_showAlgorithm) {
                    _algorithmController.forward();
                  } else {
                    _algorithmController.reverse();
                  }
                },
              ),
            ],
          ),

          if (_showAlgorithm) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _algorithmAnimation,
              builder: (context, child) {
                return Column(
                  children: _matchingFactors.asMap().entries.map((entry) {
                    final index = entry.key;
                    final factor = entry.value;
                    final delay = index * 0.2;
                    final progress = math.max(
                      0.0,
                      math.min(1.0, (_algorithmAnimation.value - delay) / 0.3),
                    );

                    return Transform.scale(
                      scale: 0.8 + (0.2 * progress),
                      child: Opacity(
                        opacity: progress,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (factor['color'] as Color).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (factor['color'] as Color).withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                factor['icon'] as IconData,
                                color: factor['color'] as Color,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          factor['factor'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: SnapColors.textPrimary,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (factor['color'] as Color)
                                                .withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            '${factor['weight']}%',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: factor['color'] as Color,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      factor['description'] as String,
                                      style: TextStyle(
                                        color: SnapColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessMetrics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SnapColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: SnapColors.accentGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Matching Success Metrics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Connection Rate',
                  '78%',
                  'Accept suggestions',
                  Icons.handshake,
                  SnapColors.accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Long-term Engagement',
                  '65%',
                  'Active after 30 days',
                  Icons.schedule,
                  SnapColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Goal Achievement',
                  '84%',
                  'With matched friends',
                  Icons.emoji_events,
                  SnapColors.primaryYellow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SnapColors.textPrimary,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
