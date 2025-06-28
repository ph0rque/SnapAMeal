import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../design_system/snap_ui.dart';
import 'dart:math' as math;

/// Enhanced AI advice showcase for investor demos
/// Highlights RAG-powered personalized recommendations and AI sophistication
class DemoAIAdviceShowcase extends StatefulWidget {
  const DemoAIAdviceShowcase({super.key});

  @override
  State<DemoAIAdviceShowcase> createState() => _DemoAIAdviceShowcaseState();
}

class _DemoAIAdviceShowcaseState extends State<DemoAIAdviceShowcase>
    with TickerProviderStateMixin {
  late AnimationController _ragController;
  late AnimationController _personalizationController;
  late Animation<double> _ragAnimation;
  late Animation<double> _personalizationAnimation;

  int _currentAdviceIndex = 0;
  bool _showRAGProcess = false;
  bool _showPersonalization = false;

  final List<Map<String, dynamic>> _aiAdviceExamples = [
    {
      'title': 'Optimal Fasting Window',
      'advice':
          'Based on your sleep patterns and cortisol levels, extending your fast to 18 hours on Tuesdays and Thursdays could improve fat oxidation by 23%.',
      'confidence': 94,
      'ragSources': [
        'Sleep study data',
        'Metabolic research',
        'Personal patterns',
      ],
      'personalization': 'Tailored to your 11pm-7am sleep schedule',
      'category': 'Fasting Optimization',
      'icon': Icons.schedule,
      'color': SnapColors.accentBlue,
    },
    {
      'title': 'Meal Timing Strategy',
      'advice':
          'Your glucose response shows better insulin sensitivity between 12-2pm. Consider your largest meal during this window for optimal metabolic benefits.',
      'confidence': 89,
      'ragSources': [
        'CGM data analysis',
        'Circadian research',
        'User meal logs',
      ],
      'personalization': 'Based on 30 days of glucose monitoring',
      'category': 'Metabolic Health',
      'icon': Icons.restaurant,
      'color': SnapColors.accentGreen,
    },
    {
      'title': 'Exercise Timing',
      'advice':
          'Your energy levels peak at 4pm based on activity tracking. Scheduling workouts then could increase performance by 15% and improve sleep quality.',
      'confidence': 91,
      'ragSources': [
        'Activity tracker data',
        'Performance studies',
        'Sleep correlation',
      ],
      'personalization': 'Analyzed from 45 days of activity patterns',
      'category': 'Performance',
      'icon': Icons.fitness_center,
      'color': SnapColors.accentPurple,
    },
  ];

  @override
  void initState() {
    super.initState();

    _ragController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _personalizationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _ragAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ragController, curve: Curves.easeInOut));

    _personalizationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _personalizationController,
        curve: Curves.elasticOut,
      ),
    );

    // Auto-cycle through advice examples
    _startAdviceCycle();
  }

  void _startAdviceCycle() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _currentAdviceIndex =
              (_currentAdviceIndex + 1) % _aiAdviceExamples.length;
        });
        _startAdviceCycle();
      }
    });
  }

  @override
  void dispose() {
    _ragController.dispose();
    _personalizationController.dispose();
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
                SnapColors.accentBlue.withValues(alpha: 0.05),
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

              // Current AI advice showcase
              _buildCurrentAdviceCard(),

              const SizedBox(height: 20),

              // RAG process visualization
              _buildRAGProcessSection(),

              const SizedBox(height: 20),

              // Personalization showcase
              _buildPersonalizationSection(),

              const SizedBox(height: 20),

              // AI capabilities metrics
              _buildAICapabilitiesMetrics(),
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
          const Icon(Icons.psychology, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          const Text(
            'RAG-Powered AI Advice Demo',
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

  Widget _buildCurrentAdviceCard() {
    final currentAdvice = _aiAdviceExamples[_currentAdviceIndex];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (currentAdvice['color'] as Color).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (currentAdvice['color'] as Color).withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with category and confidence
          Row(
            children: [
              Icon(
                currentAdvice['icon'] as IconData,
                color: currentAdvice['color'] as Color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentAdvice['title'] as String,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: SnapColors.textPrimary,
                      ),
                    ),
                    Text(
                      currentAdvice['category'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: currentAdvice['color'] as Color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SnapColors.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${currentAdvice['confidence']}% Confidence',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: SnapColors.accentGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // AI advice content
          Text(
            currentAdvice['advice'] as String,
            style: TextStyle(
              fontSize: 16,
              color: SnapColors.textPrimary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          // Personalization note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SnapColors.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: SnapColors.accentBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.person, size: 16, color: SnapColors.accentBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentAdvice['personalization'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: SnapColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRAGProcessSection() {
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
              Icon(Icons.hub, color: SnapColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'RAG Process Visualization',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showRAGProcess ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showRAGProcess = !_showRAGProcess;
                  });
                  if (_showRAGProcess) {
                    _ragController.forward();
                  } else {
                    _ragController.reverse();
                  }
                },
              ),
            ],
          ),

          if (_showRAGProcess) ...[
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: _ragAnimation,
              builder: (context, child) {
                return Column(
                  children: [
                    // Knowledge sources
                    _buildRAGStep(
                      'Knowledge Retrieval',
                      'Accessing medical research, user data, and health patterns',
                      Icons.library_books,
                      SnapColors.accentBlue,
                      _ragAnimation.value >= 0.3
                          ? 1.0
                          : _ragAnimation.value / 0.3,
                    ),
                    const SizedBox(height: 8),

                    // Context analysis
                    _buildRAGStep(
                      'Context Analysis',
                      'Analyzing user-specific patterns and correlations',
                      Icons.analytics,
                      SnapColors.accentPurple,
                      _ragAnimation.value >= 0.6
                          ? 1.0
                          : math.max(0, (_ragAnimation.value - 0.3) / 0.3),
                    ),
                    const SizedBox(height: 8),

                    // Generation
                    _buildRAGStep(
                      'Advice Generation',
                      'Creating personalized, evidence-based recommendations',
                      Icons.auto_awesome,
                      SnapColors.accentGreen,
                      _ragAnimation.value >= 0.9
                          ? 1.0
                          : math.max(0, (_ragAnimation.value - 0.6) / 0.3),
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

  Widget _buildRAGStep(
    String title,
    String description,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset((1 - progress) * 50, 0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: SnapColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        color: SnapColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: progress,
                color: color,
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalizationSection() {
    final currentAdvice = _aiAdviceExamples[_currentAdviceIndex];
    final ragSources = currentAdvice['ragSources'] as List<String>;

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
              Icon(Icons.person_pin, color: SnapColors.accentGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Personalization Sources',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showPersonalization ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showPersonalization = !_showPersonalization;
                  });
                  if (_showPersonalization) {
                    _personalizationController.forward();
                  } else {
                    _personalizationController.reverse();
                  }
                },
              ),
            ],
          ),

          if (_showPersonalization) ...[
            const SizedBox(height: 12),
            AnimatedBuilder(
              animation: _personalizationAnimation,
              builder: (context, child) {
                return Column(
                  children: ragSources.asMap().entries.map((entry) {
                    final index = entry.key;
                    final source = entry.value;
                    final delay = index * 0.3;
                    final progress = math.max(
                      0.0,
                      math.min(
                        1.0,
                        (_personalizationAnimation.value - delay) / 0.3,
                      ),
                    );

                    return Transform.scale(
                      scale: 0.8 + (0.2 * progress),
                      child: Opacity(
                        opacity: progress,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SnapColors.accentGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: SnapColors.accentGreen.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.source,
                                color: SnapColors.accentGreen,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  source,
                                  style: TextStyle(
                                    color: SnapColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.check_circle,
                                color: SnapColors.accentGreen,
                                size: 14,
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

  Widget _buildAICapabilitiesMetrics() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Knowledge Base',
            '50K+',
            'Medical studies',
            Icons.library_books,
            SnapColors.accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Personalization',
            '99.2%',
            'Accuracy rate',
            Icons.gps_fixed,
            SnapColors.accentGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            'Response Time',
            '< 2s',
            'Average',
            Icons.speed,
            SnapColors.accentPurple,
          ),
        ),
      ],
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
          const SizedBox(height: 4),
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
