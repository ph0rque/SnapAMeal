import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/fasting_session.dart';
import '../services/rag_service.dart';

/// Types of AR filters available for fasting mode
enum FastingARFilterType {
  motivationalText,      // Floating motivational quotes
  progressRing,          // Animated progress rings around face
  achievement,           // Achievement celebration effects
  strengthAura,          // Glowing strength aura
  timeCounter,           // Floating time counter
  willpowerBoost,        // Power-up style effects
  zenMode,               // Calming, meditative effects
  challengeMode,         // Intense, focused effects
}

/// Configuration for an AR filter
class ARFilterConfig {
  final FastingARFilterType type;
  final String name;
  final String description;
  final Color primaryColor;
  final Color accentColor;
  final Duration animationDuration;
  final List<String> motivationalTexts;
  final Map<String, dynamic> customParams;

  ARFilterConfig({
    required this.type,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
    this.animationDuration = const Duration(seconds: 3),
    this.motivationalTexts = const [],
    this.customParams = const {},
  });
}

/// A rendered AR filter overlay
class ARFilterOverlay {
  final FastingARFilterType type;
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

/// Service for managing AR filters and effects during fasting
class ARFilterService {
  final RAGService _ragService;
  
  // Animation controllers and state
  final Map<FastingARFilterType, AnimationController> _animationControllers = {};
  final List<ARFilterOverlay> _activeOverlays = [];
  
  // Filter configurations
  late final Map<FastingARFilterType, ARFilterConfig> _filterConfigs;
  
  // Motivational content cache
  final Map<String, List<String>> _motivationalCache = {};

  ARFilterService(this._ragService) {
    _initializeFilterConfigs();
  }

  /// Initialize predefined filter configurations
  void _initializeFilterConfigs() {
    _filterConfigs = {
      FastingARFilterType.motivationalText: ARFilterConfig(
        type: FastingARFilterType.motivationalText,
        name: 'Motivational Quotes',
        description: 'Floating inspirational messages',
        primaryColor: Colors.blue,
        accentColor: Colors.lightBlue,
        motivationalTexts: [
          'Stay Strong! 💪',
          'You\'ve Got This! 🔥',
          'Building Discipline 🧠',
          'Every Hour Counts ⏰',
          'Mind Over Matter 🎯',
          'Strength in Progress 📈',
          'Focused & Determined 🎯',
          'Growing Stronger 🌱',
        ],
      ),
      
      FastingARFilterType.progressRing: ARFilterConfig(
        type: FastingARFilterType.progressRing,
        name: 'Progress Ring',
        description: 'Animated progress visualization',
        primaryColor: Colors.green,
        accentColor: Colors.lightGreen,
        animationDuration: Duration(seconds: 2),
      ),
      
      FastingARFilterType.achievement: ARFilterConfig(
        type: FastingARFilterType.achievement,
        name: 'Achievement Burst',
        description: 'Celebration effects for milestones',
        primaryColor: Colors.gold,
        accentColor: Colors.yellow,
        animationDuration: Duration(seconds: 4),
      ),
      
      FastingARFilterType.strengthAura: ARFilterConfig(
        type: FastingARFilterType.strengthAura,
        name: 'Strength Aura',
        description: 'Glowing aura of inner strength',
        primaryColor: Colors.purple,
        accentColor: Colors.deepPurple,
        animationDuration: Duration(seconds: 3),
      ),
      
      FastingARFilterType.timeCounter: ARFilterConfig(
        type: FastingARFilterType.timeCounter,
        name: 'Time Counter',
        description: 'Floating elapsed time display',
        primaryColor: Colors.cyan,
        accentColor: Colors.teal,
      ),
      
      FastingARFilterType.willpowerBoost: ARFilterConfig(
        type: FastingARFilterType.willpowerBoost,
        name: 'Willpower Boost',
        description: 'Power-up style energy effects',
        primaryColor: Colors.red,
        accentColor: Colors.orange,
        animationDuration: Duration(seconds: 2),
      ),
      
      FastingARFilterType.zenMode: ARFilterConfig(
        type: FastingARFilterType.zenMode,
        name: 'Zen Mode',
        description: 'Calming, meditative ambiance',
        primaryColor: Colors.indigo,
        accentColor: Colors.blue,
        animationDuration: Duration(seconds: 5),
      ),
      
      FastingARFilterType.challengeMode: ARFilterConfig(
        type: FastingARFilterType.challengeMode,
        name: 'Challenge Mode',
        description: 'Intense focus enhancement',
        primaryColor: Colors.deepOrange,
        accentColor: Colors.red,
        animationDuration: Duration(seconds: 1),
      ),
    };
  }

  /// Get available filters for the current fasting session
  List<ARFilterConfig> getAvailableFilters(FastingSession? session) {
    if (session == null) return [];
    
    final filters = <ARFilterConfig>[];
    
    // Always available filters
    filters.addAll([
      _filterConfigs[FastingARFilterType.motivationalText]!,
      _filterConfigs[FastingARFilterType.progressRing]!,
      _filterConfigs[FastingARFilterType.timeCounter]!,
    ]);
    
    // Progress-based filters
    if (session.progressPercentage > 0.25) {
      filters.add(_filterConfigs[FastingARFilterType.strengthAura]!);
    }
    
    if (session.progressPercentage > 0.5) {
      filters.add(_filterConfigs[FastingARFilterType.willpowerBoost]!);
    }
    
    if (session.progressPercentage > 0.75) {
      filters.add(_filterConfigs[FastingARFilterType.achievement]!);
    }
    
    // Session type specific filters
    if (session.type == FastingType.extended24 || 
        session.type == FastingType.extended36 || 
        session.type == FastingType.extended48) {
      filters.add(_filterConfigs[FastingARFilterType.challengeMode]!);
    } else {
      filters.add(_filterConfigs[FastingARFilterType.zenMode]!);
    }
    
    return filters;
  }

  /// Apply an AR filter to the camera view
  Future<ARFilterOverlay?> applyFilter(
    FastingARFilterType type,
    FastingSession session,
    TickerProvider tickerProvider,
  ) async {
    final config = _filterConfigs[type];
    if (config == null) return null;

    try {
      Widget filterWidget;
      
      switch (type) {
        case FastingARFilterType.motivationalText:
          filterWidget = await _buildMotivationalTextFilter(config, session, tickerProvider);
          break;
          
        case FastingARFilterType.progressRing:
          filterWidget = _buildProgressRingFilter(config, session, tickerProvider);
          break;
          
        case FastingARFilterType.achievement:
          filterWidget = _buildAchievementFilter(config, session, tickerProvider);
          break;
          
        case FastingARFilterType.strengthAura:
          filterWidget = _buildStrengthAuraFilter(config, session, tickerProvider);
          break;
          
        case FastingARFilterType.timeCounter:
          filterWidget = _buildTimeCounterFilter(config, session, tickerProvider);
          break;
          
        case FastingARFilterType.willpowerBoost:
          filterWidget = _buildWillpowerBoostFilter(config, session, tickerProvider);
          break;
          
        case FastingARFilterType.zenMode:
          filterWidget = _buildZenModeFilter(config, session, tickerProvider);
          break;
          
        case FastingARFilterType.challengeMode:
          filterWidget = _buildChallengeModeFilter(config, session, tickerProvider);
          break;
      }

      final overlay = ARFilterOverlay(
        type: type,
        widget: filterWidget,
        duration: config.animationDuration,
        isAnimated: true,
      );

      _activeOverlays.add(overlay);
      return overlay;
    } catch (e) {
      print('Error applying AR filter: $e');
      return null;
    }
  }

  /// Build motivational text filter with AI-generated content
  Future<Widget> _buildMotivationalTextFilter(
    ARFilterConfig config,
    FastingSession session,
    TickerProvider tickerProvider,
  ) async {
    // Get AI-generated motivational text
    String motivationalText = await _getAIMotivationalText(session);
    
    final controller = AnimationController(
      duration: config.animationDuration,
      vsync: tickerProvider,
    );
    
    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    
    final slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutBack));
    
    controller.forward();
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    config.primaryColor.withOpacity(0.8),
                    config.accentColor.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: config.primaryColor.withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                motivationalText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build animated progress ring filter
  Widget _buildProgressRingFilter(
    ARFilterConfig config,
    FastingSession session,
    TickerProvider tickerProvider,
  ) {
    final controller = AnimationController(
      duration: config.animationDuration,
      vsync: tickerProvider,
    );
    
    final progressAnimation = Tween<double>(
      begin: 0.0,
      end: session.progressPercentage,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOutCubic));
    
    final pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.elasticOut));
    
    controller.forward();
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: pulseAnimation.value,
          child: Container(
            width: 150,
            height: 150,
            child: CustomPaint(
              painter: ProgressRingPainter(
                progress: progressAnimation.value,
                primaryColor: config.primaryColor,
                accentColor: config.accentColor,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build achievement celebration filter
  Widget _buildAchievementFilter(
    ARFilterConfig config,
    FastingSession session,
    TickerProvider tickerProvider,
  ) {
    final controller = AnimationController(
      duration: config.animationDuration,
      vsync: tickerProvider,
    );
    
    final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.elasticOut),
    );
    
    final rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    
    controller.forward();
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Transform.rotate(
            angle: rotationAnimation.value,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    config.primaryColor.withOpacity(0.8),
                    config.accentColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.celebration,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build strength aura filter
  Widget _buildStrengthAuraFilter(
    ARFilterConfig config,
    FastingSession session,
    TickerProvider tickerProvider,
  ) {
    final controller = AnimationController(
      duration: config.animationDuration,
      vsync: tickerProvider,
    );
    
    final pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    
    controller.repeat(reverse: true);
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.transparent,
                config.primaryColor.withOpacity(0.1 * pulseAnimation.value),
                config.accentColor.withOpacity(0.3 * pulseAnimation.value),
                Colors.transparent,
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }

  /// Build floating time counter filter
  Widget _buildTimeCounterFilter(
    ARFilterConfig config,
    FastingSession session,
    TickerProvider tickerProvider,
  ) {
    final controller = AnimationController(
      duration: Duration(seconds: 2),
      vsync: tickerProvider,
    );
    
    final floatAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    
    controller.repeat(reverse: true);
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, floatAnimation.value),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: config.primaryColor.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: config.accentColor, width: 2),
            ),
            child: Text(
              _formatDuration(session.elapsedTime),
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build willpower boost filter
  Widget _buildWillpowerBoostFilter(
    ARFilterConfig config,
    FastingSession session,
    TickerProvider tickerProvider,
  ) {
    final controller = AnimationController(
      duration: config.animationDuration,
      vsync: tickerProvider,
    );
    
    final burstAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutExpo),
    );
    
    controller.forward();
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(8, (index) {
            final angle = (index * math.pi * 2) / 8;
            final distance = 100 * burstAnimation.value;
            
            return Transform.translate(
              offset: Offset(
                math.cos(angle) * distance,
                math.sin(angle) * distance,
              ),
              child: Opacity(
                opacity: 1.0 - burstAnimation.value,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: config.primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: config.accentColor,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Build zen mode filter
  Widget _buildZenModeFilter(
    ARFilterConfig config,
    FastingSession session,
    TickerProvider tickerProvider,
  ) {
    final controller = AnimationController(
      duration: config.animationDuration,
      vsync: tickerProvider,
    );
    
    final breatheAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    
    controller.repeat(reverse: true);
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Transform.scale(
          scale: breatheAnimation.value,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  config.primaryColor.withOpacity(0.2),
                  config.accentColor.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Icon(
                Icons.self_improvement,
                size: 50,
                color: config.primaryColor.withOpacity(0.7),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build challenge mode filter
  Widget _buildChallengeModeFilter(
    ARFilterConfig config,
    FastingSession session,
    TickerProvider tickerProvider,
  ) {
    final controller = AnimationController(
      duration: config.animationDuration,
      vsync: tickerProvider,
    );
    
    final intensityAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
    
    controller.repeat(reverse: true);
    
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: config.primaryColor.withOpacity(intensityAnimation.value),
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: config.accentColor.withOpacity(intensityAnimation.value * 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.fitness_center,
              size: 60,
              color: config.primaryColor.withOpacity(intensityAnimation.value),
            ),
          ),
        );
      },
    );
  }

  /// Get AI-generated motivational text
  Future<String> _getAIMotivationalText(FastingSession session) async {
    try {
      // Check cache first
      final cacheKey = '${session.type.name}_${(session.progressPercentage * 10).floor()}';
      if (_motivationalCache.containsKey(cacheKey) && 
          _motivationalCache[cacheKey]!.isNotEmpty) {
        final cached = _motivationalCache[cacheKey]!;
        return cached[math.Random().nextInt(cached.length)];
      }

      // Generate new motivational content using RAG
      final healthContext = HealthQueryContext(
        userId: session.userId,
        queryType: 'motivation',
        userProfile: {
          'fasting_type': session.type.name,
          'session_progress': session.progressPercentage,
          'elapsed_time': session.elapsedTime.inHours,
        },
        currentGoals: ['fasting', 'motivation', 'discipline'],
        dietaryRestrictions: [],
        recentActivity: {
          'session_duration': session.elapsedTime.inMinutes,
          'personal_goal': session.personalGoal,
        },
        contextTimestamp: DateTime.now(),
      );

      final aiText = await _ragService.generateContextualizedResponse(
        userQuery: 'Give me a short, powerful motivational message for my ${session.typeDescription} session. I\'m ${(session.progressPercentage * 100).toInt()}% complete. Keep it under 10 words and make it inspiring.',
        healthContext: healthContext,
        maxContextLength: 500,
      );

      if (aiText != null && aiText.isNotEmpty) {
        // Cache the result
        _motivationalCache[cacheKey] = [aiText];
        return aiText;
      }
    } catch (e) {
      print('Error getting AI motivational text: $e');
    }

    // Fallback to predefined motivational texts
    final config = _filterConfigs[FastingARFilterType.motivationalText]!;
    return config.motivationalTexts[math.Random().nextInt(config.motivationalTexts.length)];
  }

  /// Remove an active overlay
  void removeOverlay(ARFilterOverlay overlay) {
    _activeOverlays.remove(overlay);
  }

  /// Clear all active overlays
  void clearAllOverlays() {
    _activeOverlays.clear();
  }

  /// Get list of active overlays
  List<ARFilterOverlay> get activeOverlays => List.unmodifiable(_activeOverlays);

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// Dispose of resources
  void dispose() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    _animationControllers.clear();
    _activeOverlays.clear();
  }
}

/// Custom painter for progress ring
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  ProgressRingPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Background ring
    final backgroundPaint = Paint()
      ..color = primaryColor.withOpacity(0.2)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress ring
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: [primaryColor, accentColor, primaryColor],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = 8.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.accentColor != accentColor;
  }
} 