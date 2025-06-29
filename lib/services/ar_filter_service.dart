import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Types of AR filters available for fitness motivation
enum FitnessARFilterType {
  fastingChampion,   // Crown with "16-Hour Fasting Champ!"
  calorieCrusher,    // Superhero with calorie count
  workoutGuide,      // Yoga pose with tips
  progressParty,     // Fireworks with milestone
  groupStreakSparkler, // Sparkles with group streak
}

/// Configuration for an AR fitness filter
class ARFilterConfig {
  final FitnessARFilterType type;
  final String name;
  final String description;
  final Color primaryColor;
  final Color accentColor;
  final Duration animationDuration;
  final Map<String, dynamic> customParams;

  ARFilterConfig({
    required this.type,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
    this.animationDuration = const Duration(seconds: 3),
    this.customParams = const {},
  });
}

/// A rendered AR filter overlay
class ARFilterOverlay {
  final FitnessARFilterType type;
  final Widget widget;
  final Duration duration;
  final bool isAnimated;
  final VoidCallback? onComplete;

  ARFilterOverlay({
    required this.type,
    required this.widget,
    this.duration = const Duration(seconds: 5),
    this.isAnimated = true,
    this.onComplete,
  });
}

/// Service for managing fitness-based AR filters
class ARFilterService {
  // Filter configurations
  late final Map<FitnessARFilterType, ARFilterConfig> _filterConfigs;

  ARFilterService() {
    _initializeFilterConfigs();
  }

  /// Initialize fitness filter configurations
  void _initializeFilterConfigs() {
    _filterConfigs = {
      FitnessARFilterType.fastingChampion: ARFilterConfig(
        type: FitnessARFilterType.fastingChampion,
        name: 'Fasting Champion',
        description: 'Celebrate fasting milestones',
        primaryColor: Color(0xFFFFD700), // Gold
        accentColor: Color(0xFFFFA500), // Orange
        animationDuration: Duration(seconds: 2),
      ),

      FitnessARFilterType.calorieCrusher: ARFilterConfig(
        type: FitnessARFilterType.calorieCrusher,
        name: 'Calorie Crusher',
        description: 'Superhero calorie feedback',
        primaryColor: Color(0xFF1E90FF), // DodgerBlue
        accentColor: Color(0xFF00CED1), // DarkTurquoise
        animationDuration: Duration(seconds: 2),
      ),

      FitnessARFilterType.workoutGuide: ARFilterConfig(
        type: FitnessARFilterType.workoutGuide,
        name: 'Workout Guide',
        description: 'Visual workout coaching',
        primaryColor: Color(0xFFFF7F50), // Coral
        accentColor: Color(0xFFFF6347), // Tomato
        animationDuration: Duration(seconds: 3),
      ),

      FitnessARFilterType.progressParty: ARFilterConfig(
        type: FitnessARFilterType.progressParty,
        name: 'Progress Party',
        description: 'Celebrate achievements',
        primaryColor: Color(0xFF9370DB), // MediumPurple
        accentColor: Color(0xFFBA55D3), // MediumOrchid
        animationDuration: Duration(seconds: 4),
      ),

      FitnessARFilterType.groupStreakSparkler: ARFilterConfig(
        type: FitnessARFilterType.groupStreakSparkler,
        name: 'Group Streak Sparkler',
        description: 'Group engagement sparkles',
        primaryColor: Color(0xFFFFD700), // Gold
        accentColor: Color(0xFFFFFACD), // LemonChiffon
        animationDuration: Duration(seconds: 3),
      ),
    };
  }

  /// Get all available fitness filters
  List<ARFilterConfig> getAvailableFilters() {
    return _filterConfigs.values.toList();
  }

  /// Get filter configuration by type
  ARFilterConfig? getFilterConfig(FitnessARFilterType type) {
    return _filterConfigs[type];
  }

  /// Generate overlay widget for a specific filter type
  Widget generateFilterOverlay(FitnessARFilterType type, {Size? size}) {
    final config = _filterConfigs[type];
    if (config == null) return SizedBox.shrink();

    switch (type) {
      case FitnessARFilterType.fastingChampion:
        return FastingChampionOverlay(size: size ?? Size(300, 200));
      case FitnessARFilterType.calorieCrusher:
        return CalorieCrusherOverlay(size: size ?? Size(300, 200));
      case FitnessARFilterType.workoutGuide:
        return WorkoutGuideOverlay(size: size ?? Size(300, 200));
      case FitnessARFilterType.progressParty:
        return ProgressPartyOverlay(size: size ?? Size(300, 200));
      case FitnessARFilterType.groupStreakSparkler:
        return GroupStreakSparklerOverlay(size: size ?? Size(300, 200));
    }
  }



}

/// Fasting Champion Filter - Crown with celebration text
class FastingChampionOverlay extends StatefulWidget {
  final Size size;

  const FastingChampionOverlay({super.key, required this.size});

  @override
  State<FastingChampionOverlay> createState() => _FastingChampionOverlayState();
}

class _FastingChampionOverlayState extends State<FastingChampionOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: widget.size.width,
              height: widget.size.height,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Crown SVG
                  Container(
                    width: 80,
                    height: 60,
                    child: CustomPaint(
                      painter: CrownPainter(),
                    ),
                  ),
                  SizedBox(height: 8),
                  // Celebration text
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '16-Hour\nFasting Champ!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Calorie Crusher Filter - Superhero with calorie count
class CalorieCrusherOverlay extends StatefulWidget {
  final Size size;

  const CalorieCrusherOverlay({super.key, required this.size});

  @override
  State<CalorieCrusherOverlay> createState() => _CalorieCrusherOverlayState();
}

class _CalorieCrusherOverlayState extends State<CalorieCrusherOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: Container(
            width: widget.size.width,
            height: widget.size.height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Superhero
                Container(
                  width: 60,
                  height: 80,
                  child: CustomPaint(
                    painter: SuperheroPainter(),
                  ),
                ),
                SizedBox(width: 12),
                // Calorie badge
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFA500),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    '300\nkcal',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Workout Guide Filter - Yoga pose with tips
class WorkoutGuideOverlay extends StatefulWidget {
  final Size size;

  const WorkoutGuideOverlay({super.key, required this.size});

  @override
  State<WorkoutGuideOverlay> createState() => _WorkoutGuideOverlayState();
}

class _WorkoutGuideOverlayState extends State<WorkoutGuideOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size.width,
            height: widget.size.height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Yoga pose
                Container(
                  width: 70,
                  height: 70,
                  child: CustomPaint(
                    painter: YogaPosePainter(),
                  ),
                ),
                SizedBox(height: 8),
                // Tip text
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Keep back straight!',
                    style: TextStyle(
                      color: Color(0xFFFF7F50),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Progress Party Filter - Fireworks with achievement
class ProgressPartyOverlay extends StatefulWidget {
  final Size size;

  const ProgressPartyOverlay({super.key, required this.size});

  @override
  State<ProgressPartyOverlay> createState() => _ProgressPartyOverlayState();
}

class _ProgressPartyOverlayState extends State<ProgressPartyOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: widget.size.width,
          height: widget.size.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Fireworks
              Positioned.fill(
                child: CustomPaint(
                  painter: FireworksPainter(_sparkleAnimation.value),
                ),
              ),
              // Achievement text
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(0xFF9370DB),
                    width: 2,
                  ),
                ),
                child: Text(
                  '-5 lbs!',
                  style: TextStyle(
                    color: Color(0xFF9370DB),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Group Streak Sparkler Filter - Sparkles with streak count
class GroupStreakSparklerOverlay extends StatefulWidget {
  final Size size;

  const GroupStreakSparklerOverlay({super.key, required this.size});

  @override
  State<GroupStreakSparklerOverlay> createState() => _GroupStreakSparklerOverlayState();
}

class _GroupStreakSparklerOverlayState extends State<GroupStreakSparklerOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _twinkleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    );

    _twinkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: widget.size.width,
          height: widget.size.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Sparkles
              Positioned.fill(
                child: CustomPaint(
                  painter: SparklesPainter(_twinkleAnimation.value),
                ),
              ),
              // Streak text
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Color(0xFFFFD700),
                    width: 2,
                  ),
                ),
                child: Text(
                  '3-Day Group\nStreak!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Custom Painters for SVG-like graphics

class CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Crown base
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.lineTo(size.width * 0.9, size.height * 0.8);
    path.lineTo(size.width * 0.85, size.height);
    path.lineTo(size.width * 0.15, size.height);
    path.close();

    // Crown peaks
    path.moveTo(size.width * 0.1, size.height * 0.8);
    path.lineTo(size.width * 0.2, size.height * 0.4);
    path.lineTo(size.width * 0.35, size.height * 0.6);
    path.lineTo(size.width * 0.5, size.height * 0.2);
    path.lineTo(size.width * 0.65, size.height * 0.6);
    path.lineTo(size.width * 0.8, size.height * 0.4);
    path.lineTo(size.width * 0.9, size.height * 0.8);

    canvas.drawPath(path, paint);

    // Add sparkles
    final sparklePaint = Paint()
      ..color = Color(0xFFFFFACD)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final x = size.width * (0.2 + i * 0.15);
      final y = size.height * 0.1;
      _drawSparkle(canvas, sparklePaint, Offset(x, y), 3);
    }
  }

  void _drawSparkle(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.3, center.dy - size * 0.3);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.3, center.dy - size * 0.3);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SuperheroPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Superhero body
    final bodyPaint = Paint()
      ..color = Color(0xFF00CED1)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.25),
      size.width * 0.15,
      bodyPaint..color = Color(0xFFFFDBAE),
    );

    // Body
    final bodyRect = Rect.fromLTWH(
      size.width * 0.3,
      size.height * 0.35,
      size.width * 0.4,
      size.height * 0.45,
    );
    canvas.drawRect(bodyRect, bodyPaint..color = Color(0xFF00CED1));

    // Cape
    final capePaint = Paint()
      ..color = Color(0xFFDC143C)
      ..style = PaintingStyle.fill;

    final capePath = Path();
    capePath.moveTo(size.width * 0.25, size.height * 0.4);
    capePath.lineTo(size.width * 0.15, size.height * 0.9);
    capePath.lineTo(size.width * 0.3, size.height * 0.75);
    capePath.close();
    canvas.drawPath(capePath, capePaint);

    // Arms (flexing)
    final armPaint = Paint()
      ..color = Color(0xFFFFDBAE)
      ..style = PaintingStyle.fill
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.5),
      size.width * 0.08,
      armPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.5),
      size.width * 0.08,
      armPaint,
    );

    // "S" logo on chest
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'S',
        style: TextStyle(
          fontSize: size.height * 0.2,
          fontWeight: FontWeight.bold,
          color: Colors.yellow,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width * 0.5 - textPainter.width / 2,
        size.height * 0.45,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class YogaPosePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFFFF7F50)
      ..style = PaintingStyle.fill;

    // Head
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.2),
      size.width * 0.1,
      paint..color = Color(0xFFFFDBAE),
    );

    // Body in warrior pose
    final bodyPaint = Paint()
      ..color = Color(0xFFFF7F50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Torso
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.3),
      Offset(size.width * 0.5, size.height * 0.6),
      bodyPaint,
    );

    // Arms extended
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.4),
      Offset(size.width * 0.8, size.height * 0.4),
      bodyPaint,
    );

    // Legs in lunge
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.6),
      Offset(size.width * 0.3, size.height * 0.9),
      bodyPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.6),
      Offset(size.width * 0.7, size.height * 0.9),
      bodyPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FireworksPainter extends CustomPainter {
  final double animationValue;

  FireworksPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    final colors = [
      Color(0xFFFF6347),
      Color(0xFF9370DB),
      Color(0xFFFFD700),
      Color(0xFF00CED1),
    ];

    // Draw multiple fireworks
    for (int i = 0; i < 3; i++) {
      final centerX = size.width * (0.2 + i * 0.3);
      final centerY = size.height * (0.2 + i * 0.2);
      final color = colors[i % colors.length];
      
      _drawFirework(canvas, paint, Offset(centerX, centerY), color, animationValue);
    }
  }

  void _drawFirework(Canvas canvas, Paint paint, Offset center, Color color, double progress) {
    paint.color = color.withValues(alpha: 1.0 - progress * 0.5);
    
    final radius = progress * 30;
    final sparkleCount = 8;
    
    for (int i = 0; i < sparkleCount; i++) {
      final angle = (i * 2 * math.pi) / sparkleCount;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      
      canvas.drawCircle(Offset(x, y), 3 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SparklesPainter extends CustomPainter {
  final double animationValue;

  SparklesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFFFFD700)
      ..style = PaintingStyle.fill;

    // Draw sparkles at various positions
    final sparklePositions = [
      Offset(size.width * 0.2, size.height * 0.2),
      Offset(size.width * 0.8, size.height * 0.3),
      Offset(size.width * 0.1, size.height * 0.6),
      Offset(size.width * 0.9, size.height * 0.7),
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.7, size.height * 0.9),
    ];

    for (int i = 0; i < sparklePositions.length; i++) {
      final position = sparklePositions[i];
      final phase = (animationValue + i * 0.2) % 1.0;
      final alpha = (math.sin(phase * 2 * math.pi) + 1) / 2;
      final size = 4 + 2 * alpha;
      
      paint.color = Color(0xFFFFD700).withValues(alpha: alpha);
      _drawSparkle(canvas, paint, position, size);
    }
  }

  void _drawSparkle(Canvas canvas, Paint paint, Offset center, double size) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size);
    path.lineTo(center.dx + size * 0.3, center.dy - size * 0.3);
    path.lineTo(center.dx + size, center.dy);
    path.lineTo(center.dx + size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx, center.dy + size);
    path.lineTo(center.dx - size * 0.3, center.dy + size * 0.3);
    path.lineTo(center.dx - size, center.dy);
    path.lineTo(center.dx - size * 0.3, center.dy - size * 0.3);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
