import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../design_system/snap_ui.dart';


/// Enhanced story sharing showcase for investor demos
/// Highlights engagement metrics, retention features, and story permanence
class DemoStoryShowcase extends StatefulWidget {
  const DemoStoryShowcase({super.key});

  @override
  State<DemoStoryShowcase> createState() => _DemoStoryShowcaseState();
}

class _DemoStoryShowcaseState extends State<DemoStoryShowcase>
    with TickerProviderStateMixin {
  late AnimationController _storyController;
  late AnimationController _metricsController;
  late Animation<double> _storyAnimation;
  late Animation<double> _metricsAnimation;
  
  bool _showStoryDetails = false;
  bool _showEngagementMetrics = false;
  int _currentStoryIndex = 0;
  
  final List<Map<String, dynamic>> _demoStories = [
    {
      'user': 'Alice',
      'avatar': '👩‍⚕️',
      'title': '30-Day Transformation',
      'type': 'milestone',
      'content': 'Finally hit my goal weight! 15 lbs down with 16:8 fasting 🎉',
      'timestamp': '2h ago',
      'views': 234,
      'likes': 89,
      'comments': 23,
      'shares': 12,
      'retention': 85,
      'permanence': 'Milestone - Permanent',
      'engagement_rate': 38.0,
      'color': SnapColors.accentGreen,
      'icon': Icons.emoji_events,
    },
    {
      'user': 'Bob',
      'avatar': '🧑‍💼',
      'title': 'Morning Routine',
      'type': 'daily',
      'content': 'Day 12 of my new morning routine. Feeling more energized than ever! ☀️',
      'timestamp': '5h ago',
      'views': 156,
      'likes': 42,
      'comments': 8,
      'shares': 3,
      'retention': 72,
      'permanence': '7 days remaining',
      'engagement_rate': 34.0,
      'color': SnapColors.accentBlue,
      'icon': Icons.wb_sunny,
    },
    {
      'user': 'Charlie',
      'avatar': '👨‍🍳',
      'title': 'Recipe Discovery',
      'type': 'tip',
      'content': 'Found an amazing keto-friendly breakfast recipe! Game changer 🍳',
      'timestamp': '1d ago',
      'views': 312,
      'likes': 67,
      'comments': 15,
      'shares': 8,
      'retention': 68,
      'permanence': '13 days remaining',
      'engagement_rate': 29.0,
      'color': SnapColors.primaryYellow,
      'icon': Icons.restaurant_menu,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    
    _storyController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _metricsController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _storyAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _storyController,
      curve: Curves.easeInOut,
    ));
    
    _metricsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _metricsController,
      curve: Curves.elasticOut,
    ));
    
    // Auto-cycle through stories
    _startStoryCycle();
  }

  void _startStoryCycle() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _currentStoryIndex = (_currentStoryIndex + 1) % _demoStories.length;
        });
        _startStoryCycle();
      }
    });
  }

  @override
  void dispose() {
    _storyController.dispose();
    _metricsController.dispose();
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
                SnapColors.accentPurple.withValues(alpha: 0.1),
                SnapColors.primaryYellow.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SnapColors.accentPurple.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo indicator
              _buildDemoIndicator(),
              
              const SizedBox(height: 20),
              
              // Story overview
              _buildStoryOverview(),
              
              const SizedBox(height: 20),
              
              // Featured story showcase
              _buildFeaturedStory(),
              
              const SizedBox(height: 20),
              
              // Engagement metrics
              _buildEngagementMetricsSection(),
              
              const SizedBox(height: 20),
              
              // Logarithmic permanence explanation
              _buildPermanenceSection(),
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
        color: SnapColors.accentPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_stories,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          const Text(
            'Story Sharing & Engagement Demo',
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

  Widget _buildStoryOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Story Retention System',
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
                'Daily Stories',
                '2.3K',
                'Active today',
                Icons.today,
                SnapColors.accentBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Avg. Engagement',
                '32%',
                'Above industry',
                Icons.trending_up,
                SnapColors.accentGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Milestone Stories',
                '156',
                'Permanent archive',
                Icons.bookmark,
                SnapColors.primaryYellow,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewCard(String title, String value, String subtitle, IconData icon, Color color) {
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

  Widget _buildFeaturedStory() {
    final currentStory = _demoStories[_currentStoryIndex];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_stories,
                color: SnapColors.accentPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Featured Story',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showStoryDetails ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showStoryDetails = !_showStoryDetails;
                  });
                  if (_showStoryDetails) {
                    _storyController.forward();
                  } else {
                    _storyController.reverse();
                  }
                },
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Story card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (currentStory['color'] as Color).withValues(alpha: 0.1),
                  (currentStory['color'] as Color).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: (currentStory['color'] as Color).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Story header
                Row(
                  children: [
                    Text(
                      currentStory['avatar'] as String,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentStory['user'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: SnapColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            currentStory['title'] as String,
                            style: TextStyle(
                              color: currentStory['color'] as Color,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      currentStory['icon'] as IconData,
                      color: currentStory['color'] as Color,
                      size: 24,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Story content
                Text(
                  currentStory['content'] as String,
                  style: TextStyle(
                    color: SnapColors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Quick engagement metrics
                Row(
                  children: [
                    _buildQuickMetric(Icons.visibility, '${currentStory['views']}'),
                    const SizedBox(width: 16),
                    _buildQuickMetric(Icons.favorite, '${currentStory['likes']}'),
                    const SizedBox(width: 16),
                    _buildQuickMetric(Icons.comment, '${currentStory['comments']}'),
                    const SizedBox(width: 16),
                    _buildQuickMetric(Icons.share, '${currentStory['shares']}'),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (currentStory['color'] as Color).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${currentStory['engagement_rate']}% engaged',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: currentStory['color'] as Color,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (_showStoryDetails) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _storyAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _storyAnimation.value,
                  child: Column(
                    children: [
                      // Retention visualization
                      _buildRetentionVisualization(currentStory),
                      const SizedBox(height: 12),
                      
                      // Permanence indicator
                      _buildPermanenceIndicator(currentStory),
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

  Widget _buildQuickMetric(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: SnapColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: SnapColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRetentionVisualization(Map<String, dynamic> story) {
    final retention = story['retention'] as int;
    
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
              Icon(
                Icons.timeline,
                color: SnapColors.accentBlue,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Viewer Retention: $retention%',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: SnapColors.textPrimary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Retention bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: SnapColors.textSecondary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: retention / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: retention > 80 
                      ? SnapColors.accentGreen 
                      : retention > 60 
                          ? SnapColors.primaryYellow 
                          : SnapColors.accentRed,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermanenceIndicator(Map<String, dynamic> story) {
    final isPermanent = story['type'] == 'milestone';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPermanent 
            ? SnapColors.accentGreen.withValues(alpha: 0.1)
            : SnapColors.primaryYellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPermanent 
              ? SnapColors.accentGreen.withValues(alpha: 0.3)
              : SnapColors.primaryYellow.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isPermanent ? Icons.bookmark : Icons.schedule,
            color: isPermanent ? SnapColors.accentGreen : SnapColors.primaryYellow,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              story['permanence'] as String,
              style: TextStyle(
                color: SnapColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (isPermanent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: SnapColors.accentGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'MILESTONE',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: SnapColors.accentGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: SnapColors.accentGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Real-Time Engagement Analytics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showEngagementMetrics ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showEngagementMetrics = !_showEngagementMetrics;
                  });
                  if (_showEngagementMetrics) {
                    _metricsController.forward();
                  } else {
                    _metricsController.reverse();
                  }
                },
              ),
            ],
          ),
          
          if (_showEngagementMetrics) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _metricsAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildEngagementCard(
                            'Views/Story',
                            '234',
                            'Avg. last 7 days',
                            Icons.visibility,
                            SnapColors.accentBlue,
                            _metricsAnimation.value,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildEngagementCard(
                            'Completion Rate',
                            '78%',
                            'Full story views',
                            Icons.play_circle,
                            SnapColors.accentGreen,
                            _metricsAnimation.value * 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEngagementCard(
                            'Avg. Watch Time',
                            '12.3s',
                            'Out of 15s total',
                            Icons.timer,
                            SnapColors.primaryYellow,
                            _metricsAnimation.value * 0.6,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildEngagementCard(
                            'Share Rate',
                            '8.2%',
                            'Stories shared',
                            Icons.share,
                            SnapColors.accentPurple,
                            _metricsAnimation.value * 0.4,
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

  Widget _buildEngagementCard(String title, String value, String subtitle, IconData icon, Color color, double progress) {
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
        ),
      ),
    );
  }

  Widget _buildPermanenceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.textSecondary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_graph,
                color: SnapColors.accentPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Logarithmic Story Permanence',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Stories fade gradually based on engagement and importance. Milestone achievements become permanent, while daily updates follow a smart decay algorithm.',
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
                child: _buildPermanenceExample(
                  'Daily Stories',
                  '7 days',
                  'Standard fade',
                  Icons.today,
                  SnapColors.accentBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPermanenceExample(
                  'High Engagement',
                  '14 days',
                  'Extended life',
                  Icons.trending_up,
                  SnapColors.primaryYellow,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPermanenceExample(
                  'Milestones',
                  '∞',
                  'Permanent',
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

  Widget _buildPermanenceExample(String title, String duration, String description, IconData icon, Color color) {
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
            duration,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SnapColors.textPrimary,
              fontSize: 14,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 9,
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
    );
  }
} 