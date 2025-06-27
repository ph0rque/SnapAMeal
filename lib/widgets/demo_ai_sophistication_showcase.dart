import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../design_system/snap_ui.dart';

import 'dart:async';

/// AI sophistication showcase for investor demos
/// Highlights advanced AI capabilities and intelligent scenarios
class DemoAISophisticationShowcase extends StatefulWidget {
  const DemoAISophisticationShowcase({super.key});

  @override
  State<DemoAISophisticationShowcase> createState() =>
      _DemoAISophisticationShowcaseState();
}

class _DemoAISophisticationShowcaseState
    extends State<DemoAISophisticationShowcase>
    with TickerProviderStateMixin {
  late AnimationController _scenarioController;
  late AnimationController _insightController;
  late Animation<double> _scenarioAnimation;
  late Animation<double> _insightAnimation;

  Timer? _scenarioTimer;
  int _currentScenario = 0;
  int _currentInsight = 0;
  bool _showAdvancedFeatures = false;

  final List<Map<String, dynamic>> _aiScenarios = [
    {
      'title': 'Predictive Health Intervention',
      'scenario': 'Alice\'s fasting pattern analysis',
      'description':
          'AI detected 73% probability of breaking fast early based on stress indicators, sleep quality (6.2h), and historical patterns. Proactively suggested mindfulness session.',
      'outcome': 'Successfully completed 16-hour fast with 94% confidence',
      'aiCapabilities': [
        'Pattern Recognition',
        'Predictive Analytics',
        'Behavioral Modeling',
      ],
      'dataPoints': [
        'Heart Rate Variability',
        'Sleep Quality',
        'Stress Biomarkers',
        'Historical Behavior',
      ],
      'accuracy': 94,
      'confidence': 89,
      'icon': Icons.psychology,
      'color': SnapColors.accentBlue,
      'impact': 'Prevented early fast break, maintained health goal',
    },
    {
      'title': 'Contextual Meal Recognition',
      'scenario': 'Bob\'s restaurant dining analysis',
      'description':
          'Computer vision identified Mediterranean bowl with 97% accuracy. Cross-referenced with restaurant menu, dietary restrictions, and macro targets. Suggested portion adjustment.',
      'outcome': 'Optimized meal choice aligned with fitness goals',
      'aiCapabilities': [
        'Computer Vision',
        'Contextual Analysis',
        'Nutritional Intelligence',
      ],
      'dataPoints': [
        'Visual Recognition',
        'Menu Database',
        'Dietary Preferences',
        'Macro Targets',
      ],
      'accuracy': 97,
      'confidence': 92,
      'icon': Icons.camera_alt,
      'color': SnapColors.accentGreen,
      'impact': 'Achieved daily macro targets with 98% precision',
    },
    {
      'title': 'Social Health Optimization',
      'scenario': 'Charlie\'s community engagement',
      'description':
          'NLP analysis of group conversations identified declining motivation. AI matched with mentor Sarah (94% compatibility) and suggested participation in weekend hiking challenge.',
      'outcome': 'Increased engagement by 156% in following week',
      'aiCapabilities': [
        'Natural Language Processing',
        'Social Matching',
        'Motivation Analysis',
      ],
      'dataPoints': [
        'Conversation Sentiment',
        'Engagement Patterns',
        'Goal Alignment',
        'Personality Traits',
      ],
      'accuracy': 91,
      'confidence': 87,
      'icon': Icons.people,
      'color': SnapColors.accentPurple,
      'impact': 'Rebuilt motivation and strengthened social connections',
    },
    {
      'title': 'Adaptive Learning Evolution',
      'scenario': 'Multi-user pattern synthesis',
      'description':
          'AI synthesized learnings from 10K+ users to identify optimal fasting windows for different chronotypes. Personalized recommendations improved success rates by 34%.',
      'outcome': 'Enhanced algorithm performance across user base',
      'aiCapabilities': [
        'Machine Learning',
        'Pattern Synthesis',
        'Personalization Engine',
      ],
      'dataPoints': [
        'Chronotype Analysis',
        'Success Patterns',
        'Circadian Rhythms',
        'Lifestyle Factors',
      ],
      'accuracy': 89,
      'confidence': 95,
      'icon': Icons.auto_awesome,
      'color': SnapColors.primaryYellow,
      'impact': 'Improved success rates by 34% platform-wide',
    },
  ];

  final List<Map<String, dynamic>> _advancedInsights = [
    {
      'insight': 'Circadian Rhythm Optimization',
      'description':
          'AI identified optimal meal timing based on individual circadian patterns, improving metabolic efficiency by 23%',
      'technology': 'Temporal Pattern Analysis + Metabolic Modeling',
      'impact': '23% efficiency improvement',
      'users': '2.1K users optimized',
      'icon': Icons.schedule,
      'color': SnapColors.accentBlue,
    },
    {
      'insight': 'Micro-Nutrient Gap Analysis',
      'description':
          'Computer vision + nutritional database analysis identifies subtle nutrient deficiencies before symptoms appear',
      'technology': 'Multi-Modal AI + Predictive Health Analytics',
      'impact': '67% reduction in deficiencies',
      'users': '5.3K users monitored',
      'icon': Icons.biotech,
      'color': SnapColors.accentGreen,
    },
    {
      'insight': 'Behavioral Intervention Triggers',
      'description':
          'NLP sentiment analysis of user communications predicts motivation drops 3-5 days before they occur',
      'technology': 'Advanced NLP + Behavioral Psychology AI',
      'impact': '78% prevention rate',
      'users': '8.7K interventions delivered',
      'icon': Icons.trending_up,
      'color': SnapColors.accentPurple,
    },
    {
      'insight': 'Social Network Health Effects',
      'description':
          'Graph neural networks analyze social connections to predict health outcome improvements through friend matching',
      'technology': 'Graph Neural Networks + Social Psychology',
      'impact': '45% better outcomes',
      'users': '12.4K connections optimized',
      'icon': Icons.hub,
      'color': SnapColors.accentRed,
    },
  ];

  final List<Map<String, dynamic>> _aiCapabilities = [
    {
      'capability': 'Computer Vision Excellence',
      'description':
          'State-of-the-art food recognition with 97.3% accuracy across 50K+ food items',
      'metrics': ['97.3% accuracy', '0.8s processing', '50K+ items'],
      'icon': Icons.visibility,
      'color': SnapColors.accentBlue,
    },
    {
      'capability': 'Predictive Health Analytics',
      'description':
          'Machine learning models predict health outcomes 3-7 days in advance with 89% accuracy',
      'metrics': [
        '89% prediction accuracy',
        '3-7 day horizon',
        '15+ biomarkers',
      ],
      'icon': Icons.analytics,
      'color': SnapColors.accentGreen,
    },
    {
      'capability': 'Natural Language Understanding',
      'description':
          'Advanced NLP processes health conversations with medical-grade understanding',
      'metrics': ['94% intent accuracy', '12 languages', 'Medical context'],
      'icon': Icons.psychology,
      'color': SnapColors.accentPurple,
    },
    {
      'capability': 'Behavioral Intelligence',
      'description':
          'AI models human behavior patterns to optimize health interventions and timing',
      'metrics': [
        '78% intervention success',
        'Real-time adaptation',
        'Personal patterns',
      ],
      'icon': Icons.psychology_alt,
      'color': SnapColors.primaryYellow,
    },
  ];

  @override
  void initState() {
    super.initState();

    _scenarioController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _insightController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scenarioAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scenarioController, curve: Curves.easeInOut),
    );

    _insightAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _insightController, curve: Curves.elasticOut),
    );

    _startScenarioRotation();
  }

  @override
  void dispose() {
    _scenarioController.dispose();
    _insightController.dispose();
    _scenarioTimer?.cancel();
    super.dispose();
  }

  void _startScenarioRotation() {
    _scenarioTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          _currentScenario = (_currentScenario + 1) % _aiScenarios.length;
          _currentInsight = (_currentInsight + 1) % _advancedInsights.length;
        });
        _scenarioController.forward(from: 0);
        _insightController.forward(from: 0);
      }
    });

    // Start initial animations
    _scenarioController.forward();
    _insightController.forward();
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
                SnapColors.primaryYellow.withValues(alpha: 0.15),
                SnapColors.accentPurple.withValues(alpha: 0.1),
                SnapColors.accentBlue.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SnapColors.primaryYellow.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo indicator
              _buildDemoIndicator(),

              const SizedBox(height: 20),

              // AI sophistication overview
              _buildAIOverview(),

              const SizedBox(height: 20),

              // Featured AI scenario
              _buildFeaturedScenario(),

              const SizedBox(height: 20),

              // Advanced insights
              _buildAdvancedInsights(),

              const SizedBox(height: 20),

              // AI capabilities matrix
              _buildAICapabilities(),

              const SizedBox(height: 20),

              // Competitive differentiation
              _buildCompetitiveDifferentiation(),
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
        gradient: LinearGradient(
          colors: [SnapColors.primaryYellow, SnapColors.accentGreen],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: Colors.black),
          const SizedBox(width: 6),
          const Text(
            'AI Sophistication Showcase',
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

  Widget _buildAIOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next-Generation AI Health Intelligence',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Advanced AI capabilities that go beyond basic tracking to provide predictive, contextual, and personalized health intelligence.',
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
                'AI Models',
                '15+',
                'Specialized algorithms',
                Icons.memory,
                SnapColors.accentBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Prediction Accuracy',
                '91.3%',
                'Health outcomes',
                Icons.gps_fixed,
                SnapColors.accentGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Data Points',
                '150+',
                'Per user analysis',
                Icons.analytics,
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

  Widget _buildFeaturedScenario() {
    final scenario = _aiScenarios[_currentScenario];

    return AnimatedBuilder(
      animation: _scenarioAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.95 + (0.05 * _scenarioAnimation.value),
          child: Opacity(
            opacity: _scenarioAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    (scenario['color'] as Color).withValues(alpha: 0.15),
                    (scenario['color'] as Color).withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (scenario['color'] as Color).withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Scenario header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (scenario['color'] as Color).withValues(
                            alpha: 0.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          scenario['icon'] as IconData,
                          color: scenario['color'] as Color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scenario['title'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: SnapColors.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              scenario['scenario'] as String,
                              style: TextStyle(
                                color: SnapColors.textSecondary,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Accuracy indicators
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: SnapColors.accentGreen.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${scenario['accuracy']}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: SnapColors.accentGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Accuracy',
                            style: TextStyle(
                              fontSize: 8,
                              color: SnapColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Scenario description
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SnapColors.backgroundLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      scenario['description'] as String,
                      style: TextStyle(
                        color: SnapColors.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // AI capabilities used
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (scenario['aiCapabilities'] as List<String>)
                        .map(
                          (capability) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (scenario['color'] as Color).withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              capability,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: scenario['color'] as Color,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 12),

                  // Outcome and impact
                  Row(
                    children: [
                      Expanded(
                        child: Container(
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: SnapColors.accentGreen,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Outcome',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: SnapColors.textPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scenario['outcome'] as String,
                                style: TextStyle(
                                  color: SnapColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (scenario['color'] as Color).withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (scenario['color'] as Color).withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: scenario['color'] as Color,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Impact',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: SnapColors.textPrimary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                scenario['impact'] as String,
                                style: TextStyle(
                                  color: SnapColors.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdvancedInsights() {
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
              Icon(Icons.lightbulb, color: SnapColors.primaryYellow, size: 20),
              const SizedBox(width: 8),
              Text(
                'Advanced AI Insights',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  _showAdvancedFeatures ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _showAdvancedFeatures = !_showAdvancedFeatures;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Current insight highlight
          AnimatedBuilder(
            animation: _insightAnimation,
            builder: (context, child) {
              final insight = _advancedInsights[_currentInsight];

              return Transform.scale(
                scale: 0.98 + (0.02 * _insightAnimation.value),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        (insight['color'] as Color).withValues(alpha: 0.15),
                        (insight['color'] as Color).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (insight['color'] as Color).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        insight['icon'] as IconData,
                        color: insight['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight['insight'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: SnapColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              insight['description'] as String,
                              style: TextStyle(
                                color: SnapColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (insight['color'] as Color)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    insight['impact'] as String,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: insight['color'] as Color,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  insight['users'] as String,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: SnapColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          if (_showAdvancedFeatures) ...[
            const SizedBox(height: 16),
            // All insights grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: _advancedInsights
                  .map((insight) => _buildInsightCard(insight))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightCard(Map<String, dynamic> insight) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: (insight['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (insight['color'] as Color).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            insight['icon'] as IconData,
            color: insight['color'] as Color,
            size: 18,
          ),
          const SizedBox(height: 6),
          Text(
            insight['insight'] as String,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SnapColors.textPrimary,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            insight['impact'] as String,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: insight['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAICapabilities() {
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
                Icons.precision_manufacturing,
                color: SnapColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Core AI Capabilities',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Column(
            children: _aiCapabilities
                .map((capability) => _buildCapabilityTile(capability))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityTile(Map<String, dynamic> capability) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (capability['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (capability['color'] as Color).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            capability['icon'] as IconData,
            color: capability['color'] as Color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  capability['capability'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: SnapColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  capability['description'] as String,
                  style: TextStyle(
                    color: SnapColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: (capability['metrics'] as List<String>)
                      .map(
                        (metric) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (capability['color'] as Color).withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            metric,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: capability['color'] as Color,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompetitiveDifferentiation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SnapColors.primaryYellow.withValues(alpha: 0.15),
            SnapColors.accentGreen.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SnapColors.primaryYellow.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: SnapColors.primaryYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Competitive Advantage',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Our AI sophistication creates defensible moats through advanced health intelligence that competitors cannot easily replicate.',
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 14,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildDifferentiatorCard(
                  'Predictive vs Reactive',
                  'Prevents issues before they occur',
                  Icons.preview,
                  SnapColors.accentBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDifferentiatorCard(
                  'Contextual vs Generic',
                  'Understands individual patterns',
                  Icons.person,
                  SnapColors.accentGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildDifferentiatorCard(
                  'Adaptive vs Static',
                  'Learns and improves continuously',
                  Icons.auto_awesome,
                  SnapColors.accentPurple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SnapColors.primaryYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: SnapColors.primaryYellow,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Key Insight: Our AI doesn\'t just track health - it predicts, prevents, and optimizes for better outcomes.',
                    style: TextStyle(
                      color: SnapColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget _buildDifferentiatorCard(
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
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SnapColors.textPrimary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
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
