import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../design_system/snap_ui.dart';
import 'dart:math' as math;

/// Enhanced story permanence showcase for investor demos
/// Highlights logarithmic decay algorithm and milestone archiving system
class DemoStoryPermanenceShowcase extends StatefulWidget {
  const DemoStoryPermanenceShowcase({super.key});

  @override
  State<DemoStoryPermanenceShowcase> createState() =>
      _DemoStoryPermanenceShowcaseState();
}

class _DemoStoryPermanenceShowcaseState
    extends State<DemoStoryPermanenceShowcase>
    with TickerProviderStateMixin {
  late AnimationController _algorithmController;
  late AnimationController _archiveController;
  late Animation<double> _algorithmAnimation;
  late Animation<double> _archiveAnimation;

  bool _showAlgorithm = false;
  bool _showArchive = false;
  int _selectedTimeframe = 0; // 0: 7 days, 1: 30 days, 2: 90 days

  final List<String> _timeframes = ['7 Days', '30 Days', '90 Days'];

  final List<Map<String, dynamic>> _storyExamples = [
    {
      'type': 'daily',
      'title': 'Morning Workout',
      'daysAgo': 1,
      'engagement': 45,
      'permanence': 85,
      'decayRate': 0.15,
      'color': SnapColors.accentBlue,
      'icon': Icons.fitness_center,
      'description': 'Regular daily activity with moderate engagement',
    },
    {
      'type': 'achievement',
      'title': 'First 5K Run',
      'daysAgo': 15,
      'engagement': 89,
      'permanence': 95,
      'decayRate': 0.05,
      'color': SnapColors.accentGreen,
      'icon': Icons.emoji_events,
      'description': 'Significant milestone with high engagement',
    },
    {
      'type': 'milestone',
      'title': '50 Pound Weight Loss',
      'daysAgo': 45,
      'engagement': 96,
      'permanence': 100,
      'decayRate': 0.0,
      'color': SnapColors.primaryYellow,
      'icon': Icons.star,
      'description': 'Major life achievement - permanently archived',
    },
    {
      'type': 'tip',
      'title': 'Healthy Recipe Share',
      'daysAgo': 3,
      'engagement': 32,
      'permanence': 65,
      'decayRate': 0.25,
      'color': SnapColors.accentPurple,
      'icon': Icons.restaurant_menu,
      'description': 'Helpful content with standard decay pattern',
    },
  ];

  final List<Map<String, dynamic>> _algorithmFactors = [
    {
      'factor': 'Initial Engagement',
      'weight': 40,
      'description': 'Likes, comments, shares, and view duration',
      'icon': Icons.favorite,
      'color': SnapColors.accentRed,
    },
    {
      'factor': 'Content Significance',
      'weight': 30,
      'description': 'Milestone detection and achievement classification',
      'icon': Icons.flag,
      'color': SnapColors.accentGreen,
    },
    {
      'factor': 'User Interaction',
      'weight': 20,
      'description': 'Ongoing engagement and reference frequency',
      'icon': Icons.chat,
      'color': SnapColors.accentBlue,
    },
    {
      'factor': 'Temporal Relevance',
      'weight': 10,
      'description': 'Seasonal patterns and contextual importance',
      'icon': Icons.schedule,
      'color': SnapColors.accentPurple,
    },
  ];

  @override
  void initState() {
    super.initState();

    _algorithmController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _archiveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _algorithmAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _algorithmController, curve: Curves.easeInOut),
    );

    _archiveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _archiveController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _algorithmController.dispose();
    _archiveController.dispose();
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
                SnapColors.primaryYellow.withValues(alpha: 0.1),
                SnapColors.accentGreen.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SnapColors.primaryYellow.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo indicator
              _buildDemoIndicator(),

              const SizedBox(height: 20),

              // Permanence overview
              _buildPermanenceOverview(),

              const SizedBox(height: 20),

              // Story lifecycle visualization
              _buildStoryLifecycleSection(),

              const SizedBox(height: 20),

              // Algorithm explanation
              _buildAlgorithmSection(),

              const SizedBox(height: 20),

              // Milestone archive showcase
              _buildMilestoneArchiveSection(),

              const SizedBox(height: 20),

              // Competitive advantage
              _buildCompetitiveAdvantage(),
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
        color: SnapColors.primaryYellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_graph, size: 16, color: Colors.black),
          const SizedBox(width: 6),
          const Text(
            'Story Permanence Algorithm Demo',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermanenceOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logarithmic Story Permanence System',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unlike traditional 24-hour story deletion, our AI-powered system preserves meaningful content based on engagement and significance.',
          style: TextStyle(
            fontSize: 14,
            color: SnapColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildOverviewCard(
                'Smart Retention',
                '89%',
                'User satisfaction',
                Icons.psychology,
                SnapColors.accentBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Milestone Archive',
                '1.2K',
                'Permanent stories',
                Icons.bookmark,
                SnapColors.accentGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Avg. Lifespan',
                '12.3d',
                'vs 1 day standard',
                Icons.timeline,
                SnapColors.primaryYellow,
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

  Widget _buildStoryLifecycleSection() {
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
              Icon(Icons.timeline, color: SnapColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Story Lifecycle Visualization',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Timeframe selector
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: SnapColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _timeframes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final timeframe = entry.value;
                    final isSelected = _selectedTimeframe == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTimeframe = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SnapColors.accentBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          timeframe,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : SnapColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Story examples with decay visualization
          Column(
            children: _storyExamples
                .map((story) => _buildStoryDecayVisualization(story))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryDecayVisualization(Map<String, dynamic> story) {
    final daysAgo = story['daysAgo'] as int;
    final permanence = story['permanence'] as int;

    // Calculate current permanence based on timeframe
    double currentPermanence = permanence / 100.0;
    if (story['type'] != 'milestone') {
      final decayRate = story['decayRate'] as double;
      currentPermanence = math.max(
        0.1,
        permanence / 100.0 - (daysAgo * decayRate),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (story['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (story['color'] as Color).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Story header
          Row(
            children: [
              Icon(
                story['icon'] as IconData,
                color: story['color'] as Color,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  story['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: SnapColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (story['color'] as Color).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(currentPermanence * 100).round()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: story['color'] as Color,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Decay visualization bar
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  '${daysAgo}d ago',
                  style: TextStyle(
                    fontSize: 10,
                    color: SnapColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: SnapColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: currentPermanence,
                    child: Container(
                      decoration: BoxDecoration(
                        color: story['color'] as Color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (story['type'] == 'milestone')
                Icon(Icons.lock, size: 12, color: SnapColors.accentGreen),
            ],
          ),

          const SizedBox(height: 4),

          Text(
            story['description'] as String,
            style: TextStyle(
              fontSize: 10,
              color: SnapColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlgorithmSection() {
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
                'Permanence Algorithm Factors',
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
                  children: _algorithmFactors.asMap().entries.map((entry) {
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
                                    const SizedBox(height: 4),
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

  Widget _buildMilestoneArchiveSection() {
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
              Icon(Icons.archive, color: SnapColors.accentGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Milestone Archive System',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showArchive ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showArchive = !_showArchive;
                  });
                  if (_showArchive) {
                    _archiveController.forward();
                  } else {
                    _archiveController.reverse();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'AI automatically identifies and permanently preserves significant life achievements and milestones.',
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 14,
              height: 1.3,
            ),
          ),

          if (_showArchive) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _archiveAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    // Archive categories
                    Row(
                      children: [
                        Expanded(
                          child: _buildArchiveCategory(
                            'Health Milestones',
                            '156',
                            'Weight loss, fitness goals',
                            Icons.favorite,
                            SnapColors.accentRed,
                            _archiveAnimation.value,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildArchiveCategory(
                            'Personal Records',
                            '89',
                            'First achievements',
                            Icons.emoji_events,
                            SnapColors.primaryYellow,
                            _archiveAnimation.value * 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildArchiveCategory(
                            'Life Events',
                            '43',
                            'Major life changes',
                            Icons.celebration,
                            SnapColors.accentPurple,
                            _archiveAnimation.value * 0.6,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildArchiveCategory(
                            'Knowledge Sharing',
                            '78',
                            'Valuable insights',
                            Icons.lightbulb,
                            SnapColors.accentBlue,
                            _archiveAnimation.value * 0.4,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArchiveCategory(
    String title,
    String count,
    String description,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Transform.scale(
      scale: 0.8 + (0.2 * progress),
      child: Opacity(
        opacity: progress,
        child: Container(
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
                count,
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
                description,
                style: TextStyle(
                  color: color,
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompetitiveAdvantage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SnapColors.accentGreen.withValues(alpha: 0.1),
            SnapColors.primaryYellow.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SnapColors.accentGreen.withValues(alpha: 0.3),
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
                'Competitive Advantage',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Our logarithmic permanence system creates lasting value for users while differentiating from ephemeral social media.',
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 14,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildAdvantagePoint(
                  'vs Snapchat',
                  'Meaningful preservation',
                  Icons.compare,
                  SnapColors.accentBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdvantagePoint(
                  'vs Instagram',
                  'Smart lifecycle',
                  Icons.auto_awesome,
                  SnapColors.accentPurple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdvantagePoint(
                  'User Value',
                  'Digital legacy',
                  Icons.bookmark,
                  SnapColors.accentGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvantagePoint(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SnapColors.textPrimary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            description,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
