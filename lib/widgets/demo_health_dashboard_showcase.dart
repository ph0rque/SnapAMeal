import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../design_system/snap_ui.dart';
import 'dart:math' as math;

/// Enhanced health dashboard showcase for investor demos
/// Highlights imperial units, progress visualization, and comprehensive metrics
class DemoHealthDashboardShowcase extends StatefulWidget {
  const DemoHealthDashboardShowcase({super.key});

  @override
  State<DemoHealthDashboardShowcase> createState() =>
      _DemoHealthDashboardShowcaseState();
}

class _DemoHealthDashboardShowcaseState
    extends State<DemoHealthDashboardShowcase>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  // Demo data - keeping for reference but not using to avoid unused field warning

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start animations
    _progressController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SnapColors.accentBlue.withValues(alpha: 0.1),
                SnapColors.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SnapColors.accentBlue.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo indicator
              _buildDemoIndicator(),

              const SizedBox(height: 20),

              // Health overview cards
              _buildHealthOverviewCards(),

              const SizedBox(height: 20),

              // Progress visualization
              _buildProgressVisualization(),

              const SizedBox(height: 20),

              // Imperial units showcase
              _buildImperialUnitsShowcase(),

              const SizedBox(height: 20),

              // AI insights and recommendations
              _buildAIInsightsSection(),
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
          Icon(Icons.dashboard, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'Health Dashboard Demo',
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

  Widget _buildHealthOverviewCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Health Overview',
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
              child: _buildMetricCard(
                'Current Weight',
                '150 lbs',
                '68.0 kg',
                Icons.monitor_weight,
                SnapColors.primary,
                progress: 0.75,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Target Weight',
                '140 lbs',
                '63.5 kg',
                Icons.flag,
                SnapColors.accentGreen,
                progress: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Height',
                '5\'5"',
                '165 cm',
                Icons.height,
                SnapColors.accentBlue,
                showProgress: false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'BMI',
                '25.2',
                'Normal',
                Icons.analytics,
                SnapColors.accentBlue,
                showProgress: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String primaryValue,
    String secondaryValue,
    IconData icon,
    Color color, {
    double? progress,
    bool showProgress = true,
  }) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: SnapColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                primaryValue,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              Text(
                secondaryValue,
                style: TextStyle(fontSize: 12, color: SnapColors.textSecondary),
              ),
              if (showProgress && progress != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress * _progressAnimation.value,
                  backgroundColor: color.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressVisualization() {
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
              Icon(Icons.trending_up, color: SnapColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Progress Visualization',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weight loss progress chart
          _buildWeightProgressChart(),

          const SizedBox(height: 16),

          // Weekly stats
          _buildWeeklyStats(),
        ],
      ),
    );
  }

  Widget _buildWeightProgressChart() {
    return SizedBox(
      height: 120,
      child: CustomPaint(
        painter: WeightProgressPainter(_progressAnimation),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildWeeklyStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Fasting Sessions',
            '5',
            'This week',
            Icons.timer,
            SnapColors.accentBlue,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Weight Lost',
            '2.2 lbs',
            'Last 30 days',
            Icons.trending_down,
            SnapColors.accentGreen,
          ),
        ),
        Expanded(
          child: _buildStatItem(
            'Streak',
            '12 days',
            'Current',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: title == 'Streak' ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 16),
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
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImperialUnitsShowcase() {
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
              Icon(Icons.straighten, color: SnapColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Imperial Units Display',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SnapColors.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'US STANDARD',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: SnapColors.accentGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Automatic conversion to familiar US imperial units for better user experience',
            style: TextStyle(color: SnapColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),

          // Imperial conversion examples
          _buildConversionExample('Height', '165 cm', '5 feet 5 inches'),
          const SizedBox(height: 8),
          _buildConversionExample('Weight', '68.0 kg', '150.0 pounds'),
          const SizedBox(height: 8),
          _buildConversionExample('Goal Weight', '63.5 kg', '140.0 pounds'),
          const SizedBox(height: 8),
          _buildConversionExample('Weight Loss', '2.3 kg', '5.1 pounds'),
        ],
      ),
    );
  }

  Widget _buildConversionExample(String label, String metric, String imperial) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SnapColors.textSecondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: SnapColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              imperial,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: SnapColors.primary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '($metric)',
            style: TextStyle(color: SnapColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsSection() {
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
              Icon(Icons.psychology, color: SnapColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Health Insights',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            'Weight Loss Trajectory',
            'You\'re on track to reach your goal weight of 140 lbs by March 2025. Current rate: 1.1 lbs/week.',
            Icons.trending_down,
            SnapColors.accentGreen,
          ),
          const SizedBox(height: 8),
          _buildInsightCard(
            'Optimal Fasting Window',
            'Your 16:8 fasting pattern shows 94% adherence. Consider extending to 18:6 twice weekly.',
            Icons.schedule,
            SnapColors.accentBlue,
          ),
          const SizedBox(height: 8),
          _buildInsightCard(
            'Energy Levels',
            'Fasting days show 23% higher energy scores. Your body has adapted well to intermittent fasting.',
            Icons.battery_charging_full,
            SnapColors.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String description,
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
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: SnapColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for weight progress chart
class WeightProgressPainter extends CustomPainter {
  final Animation<double> animation;

  WeightProgressPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = SnapColors.textSecondary.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = SnapColors.accentGreen
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = SnapColors.primary
      ..style = PaintingStyle.fill;

    // Draw background grid
    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), backgroundPaint);
    }

    // Sample weight data points (in descending order - weight loss)
    final dataPoints = [
      Offset(0, size.height * 0.8), // 155 lbs
      Offset(size.width * 0.2, size.height * 0.75), // 153 lbs
      Offset(size.width * 0.4, size.height * 0.7), // 152 lbs
      Offset(size.width * 0.6, size.height * 0.65), // 151 lbs
      Offset(size.width * 0.8, size.height * 0.6), // 150 lbs (current)
      Offset(size.width, size.height * 0.4), // 140 lbs (target)
    ];

    // Draw the weight loss line with animation
    final path = Path();
    for (int i = 0; i < dataPoints.length; i++) {
      final progress = math.min(animation.value * dataPoints.length, i + 1);
      if (progress > i) {
        final point = dataPoints[i];
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          // Interpolate between points based on animation progress
          final prevPoint = dataPoints[i - 1];
          final t = progress - i;
          final interpolatedPoint = Offset(
            prevPoint.dx + (point.dx - prevPoint.dx) * t,
            prevPoint.dy + (point.dy - prevPoint.dy) * t,
          );
          path.lineTo(interpolatedPoint.dx, interpolatedPoint.dy);
        }
      }
    }

    canvas.drawPath(path, progressPaint);

    // Draw data points
    for (int i = 0; i < dataPoints.length; i++) {
      final progress = math.min(animation.value * dataPoints.length, i + 1);
      if (progress > i) {
        final point = dataPoints[i];
        canvas.drawCircle(point, 4, pointPaint);

        // Draw current weight indicator
        if (i == 4) {
          // Current weight point
          canvas.drawCircle(
            point,
            6,
            Paint()
              ..color = SnapColors.accentBlue
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
