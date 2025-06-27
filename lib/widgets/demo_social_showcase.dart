import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../design_system/snap_ui.dart';
import 'dart:math' as math;

/// Enhanced social features showcase for investor demos
/// Highlights group chat interactions, community engagement, and social features
class DemoSocialShowcase extends StatefulWidget {
  const DemoSocialShowcase({super.key});

  @override
  State<DemoSocialShowcase> createState() => _DemoSocialShowcaseState();
}

class _DemoSocialShowcaseState extends State<DemoSocialShowcase>
    with TickerProviderStateMixin {
  late AnimationController _chatController;
  late AnimationController _engagementController;
  late Animation<double> _chatAnimation;
  late Animation<double> _engagementAnimation;

  bool _showGroupChat = false;
  bool _showEngagementMetrics = false;
  int _currentMessageIndex = 0;

  final List<Map<String, dynamic>> _demoMessages = [
    {
      'user': 'Alice',
      'avatar': '👩‍⚕️',
      'message':
          'Day 15 of my 16:8 fast! Energy levels are through the roof 🚀',
      'time': '2m ago',
      'reactions': ['💪', '🔥', '👏'],
      'reactionCount': 12,
      'type': 'achievement',
    },
    {
      'user': 'Bob',
      'avatar': '🧑‍💼',
      'message':
          'Alice that\'s amazing! I\'m on day 8. Any tips for the afternoon energy dip?',
      'time': '1m ago',
      'reactions': ['❤️'],
      'reactionCount': 3,
      'type': 'question',
    },
    {
      'user': 'Charlie',
      'avatar': '👨‍🍳',
      'message': 'Try green tea around 2pm @Bob! Works wonders for me 🍵',
      'time': '30s ago',
      'reactions': ['🙏', '💚'],
      'reactionCount': 5,
      'type': 'advice',
    },
  ];

  final List<Map<String, dynamic>> _socialFeatures = [
    {
      'title': 'Health Groups',
      'description': 'AI-matched communities based on goals and preferences',
      'metric': '156',
      'unit': 'Active Groups',
      'icon': Icons.groups,
      'color': SnapColors.accentBlue,
      'growth': '+23%',
    },
    {
      'title': 'Peer Support',
      'description': 'Real-time encouragement and accountability',
      'metric': '94%',
      'unit': 'Success Rate',
      'icon': Icons.favorite,
      'color': SnapColors.accentRed,
      'growth': '+15%',
    },
    {
      'title': 'Knowledge Sharing',
      'description': 'Community-driven tips and insights',
      'metric': '2.3K',
      'unit': 'Tips Shared',
      'icon': Icons.lightbulb,
      'color': SnapColors.primaryYellow,
      'growth': '+45%',
    },
  ];

  @override
  void initState() {
    super.initState();

    _chatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    _engagementController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _chatAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _chatController, curve: Curves.easeInOut),
    );

    _engagementAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _engagementController, curve: Curves.elasticOut),
    );

    // Auto-cycle through messages
    _startMessageCycle();
  }

  void _startMessageCycle() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _showGroupChat) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _demoMessages.length;
        });
        _startMessageCycle();
      }
    });
  }

  @override
  void dispose() {
    _chatController.dispose();
    _engagementController.dispose();
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
                SnapColors.accentGreen.withValues(alpha: 0.1),
                SnapColors.accentBlue.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SnapColors.accentGreen.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo indicator
              _buildDemoIndicator(),

              const SizedBox(height: 20),

              // Social features overview
              _buildSocialFeaturesOverview(),

              const SizedBox(height: 20),

              // Group chat showcase
              _buildGroupChatSection(),

              const SizedBox(height: 20),

              // Engagement metrics
              _buildEngagementMetrics(),

              const SizedBox(height: 20),

              // AI-powered matching showcase
              _buildAIMatchingSection(),
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
        color: SnapColors.accentGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          const Text(
            'Social Features Demo',
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

  Widget _buildSocialFeaturesOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Community-Driven Health Platform',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: _socialFeatures
              .map(
                (feature) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (feature['color'] as Color).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (feature['color'] as Color).withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          feature['icon'] as IconData,
                          color: feature['color'] as Color,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feature['metric'] as String,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: SnapColors.textPrimary,
                          ),
                        ),
                        Text(
                          feature['unit'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            color: SnapColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: SnapColors.accentGreen.withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            feature['growth'] as String,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: SnapColors.accentGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildGroupChatSection() {
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
              Icon(
                Icons.chat_bubble_outline,
                color: SnapColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Live Group Chat: "16:8 Fasting Masters"',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SnapColors.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '23 online',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: SnapColors.accentGreen,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _showGroupChat ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showGroupChat = !_showGroupChat;
                  });
                  if (_showGroupChat) {
                    _chatController.forward();
                    _startMessageCycle();
                  } else {
                    _chatController.reverse();
                  }
                },
              ),
            ],
          ),

          if (_showGroupChat) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _chatAnimation,
              builder: (context, child) {
                return SizedBox(
                  height: 200,
                  child: ListView.builder(
                    itemCount: _demoMessages.length,
                    itemBuilder: (context, index) {
                      final message = _demoMessages[index];
                      final delay = index * 0.3;
                      final progress = math.max(
                        0.0,
                        math.min(1.0, (_chatAnimation.value - delay) / 0.3),
                      );

                      return Transform.translate(
                        offset: Offset((1 - progress) * 100, 0),
                        child: Opacity(
                          opacity: progress,
                          child: _buildChatMessage(
                            message,
                            index == _currentMessageIndex,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // Chat input simulation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SnapColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_emotions_outlined,
                    color: SnapColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Type your message...',
                      style: TextStyle(
                        color: SnapColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Icon(Icons.send, color: SnapColors.accentBlue, size: 20),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatMessage(Map<String, dynamic> message, bool isHighlighted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted
            ? SnapColors.accentBlue.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isHighlighted
            ? Border.all(color: SnapColors.accentBlue.withValues(alpha: 0.3))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              Text(
                message['avatar'] as String,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Text(
                message['user'] as String,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                message['time'] as String,
                style: TextStyle(color: SnapColors.textSecondary, fontSize: 10),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Message content
          Text(
            message['message'] as String,
            style: TextStyle(
              color: SnapColors.textPrimary,
              fontSize: 13,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          // Reactions
          Row(
            children: [
              ...(message['reactions'] as List<String>).map(
                (reaction) => Container(
                  margin: const EdgeInsets.only(right: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: SnapColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(reaction, style: const TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${message['reactionCount']} reactions',
                style: TextStyle(color: SnapColors.textSecondary, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementMetrics() {
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
                'Community Engagement Metrics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showEngagementMetrics
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showEngagementMetrics = !_showEngagementMetrics;
                  });
                  if (_showEngagementMetrics) {
                    _engagementController.forward();
                  } else {
                    _engagementController.reverse();
                  }
                },
              ),
            ],
          ),

          if (_showEngagementMetrics) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _engagementAnimation,
              builder: (context, child) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildEngagementCard(
                        'Daily Active Users',
                        '12.5K',
                        '+18% vs last month',
                        Icons.people,
                        SnapColors.accentBlue,
                        _engagementAnimation.value,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEngagementCard(
                        'Messages/Day',
                        '8.2K',
                        '+34% engagement',
                        Icons.chat,
                        SnapColors.accentGreen,
                        _engagementAnimation.value * 0.8,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildEngagementCard(
                        'Goal Achievement',
                        '89%',
                        'With peer support',
                        Icons.emoji_events,
                        SnapColors.primaryYellow,
                        _engagementAnimation.value * 0.6,
                      ),
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

  Widget _buildEngagementCard(
    String title,
    String value,
    String subtitle,
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
              const SizedBox(height: 4),
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

  Widget _buildAIMatchingSection() {
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
                'AI-Powered Community Matching',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Smart algorithms match users based on health goals, experience levels, and personality compatibility for optimal peer support.',
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
                child: _buildMatchingFeature(
                  'Goal Alignment',
                  '97%',
                  Icons.flag,
                  SnapColors.accentBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMatchingFeature(
                  'Experience Match',
                  '92%',
                  Icons.school,
                  SnapColors.accentGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMatchingFeature(
                  'Compatibility',
                  '95%',
                  Icons.favorite,
                  SnapColors.accentRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingFeature(
    String title,
    String value,
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
            value,
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
        ],
      ),
    );
  }
}
