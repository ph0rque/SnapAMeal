import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../providers/fasting_state_provider.dart';

/// Comprehensive visual indicator system for fasting status
class FastingStatusIndicators {
  /// Get status color based on fasting progress
  static Color getStatusColor(double progress, {bool isActive = true}) {
    if (!isActive) return Colors.grey;
    
    if (progress < 0.25) {
      return Colors.red.shade400; // Early stage - challenging
    } else if (progress < 0.5) {
      return Colors.orange.shade400; // Getting stronger
    } else if (progress < 0.75) {
      return Colors.green.shade400; // Making good progress
    } else {
      return Colors.blue.shade600; // Nearly complete - calm confidence
    }
  }

  /// Get status icon based on fasting state
  static IconData getStatusIcon(FastingStateProvider fastingState) {
    if (!fastingState.isActiveFasting) {
      return Icons.restaurant_menu_outlined;
    }
    
    final progress = fastingState.progressPercentage;
    if (progress < 0.25) {
      return Icons.psychology; // Mental strength
    } else if (progress < 0.5) {
      return Icons.trending_up; // Progress
    } else if (progress < 0.75) {
      return Icons.fitness_center; // Strength
    } else {
      return Icons.star; // Achievement
    }
  }

  /// Get motivational text based on progress
  static String getMotivationalText(double progress) {
    if (progress < 0.25) {
      return "Stay Strong!";
    } else if (progress < 0.5) {
      return "You're Doing Great!";
    } else if (progress < 0.75) {
      return "Almost There!";
    } else {
      return "Final Stretch!";
    }
  }
}

/// Animated fasting badge widget
class FastingBadge extends StatefulWidget {
  final FastingStateProvider fastingState;
  final double size;
  final bool showProgress;
  final bool animate;

  const FastingBadge({
    super.key,
    required this.fastingState,
    this.size = 32,
    this.showProgress = true,
    this.animate = true,
  });

  @override
  State<FastingBadge> createState() => _FastingBadgeState();
}

class _FastingBadgeState extends State<FastingBadge>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));

    if (widget.animate && widget.fastingState.isActiveFasting) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(FastingBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.animate && widget.fastingState.isActiveFasting) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat(reverse: true);
      }
      if (!_rotationController.isAnimating) {
        _rotationController.repeat();
      }
    } else {
      _pulseController.stop();
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fastingState.fastingModeEnabled) {
      return SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.animate ? _pulseAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.animate && widget.showProgress 
                ? _rotationAnimation.value 
                : 0,
            child: _buildBadgeContent(),
          ),
        );
      },
    );
  }

  Widget _buildBadgeContent() {
    final color = FastingStatusIndicators.getStatusColor(
      widget.fastingState.progressPercentage,
      isActive: widget.fastingState.isActiveFasting,
    );

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Progress ring
          if (widget.showProgress && widget.fastingState.isActiveFasting)
            Positioned.fill(
              child: CircularProgressIndicator(
                value: widget.fastingState.progressPercentage,
                strokeWidth: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          
          // Center icon
          Center(
            child: Icon(
              FastingStatusIndicators.getStatusIcon(widget.fastingState),
              color: Colors.white,
              size: widget.size * 0.5,
            ),
          ),
          
          // Progress percentage text (for larger badges)
          if (widget.size > 40 && widget.fastingState.isActiveFasting)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(widget.fastingState.progressPercentage * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: widget.size * 0.15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Color shift container that changes based on fasting status
class FastingColorShift extends StatefulWidget {
  final Widget child;
  final FastingStateProvider fastingState;
  final Duration animationDuration;
  final bool applyToBackground;
  final bool applyToBorder;
  final double borderWidth;

  const FastingColorShift({
    super.key,
    required this.child,
    required this.fastingState,
    this.animationDuration = const Duration(milliseconds: 500),
    this.applyToBackground = false,
    this.applyToBorder = true,
    this.borderWidth = 2,
  });

  @override
  State<FastingColorShift> createState() => _FastingColorShiftState();
}

class _FastingColorShiftState extends State<FastingColorShift>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;
  Color _currentColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _updateColor();
  }

  @override
  void didUpdateWidget(FastingColorShift oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.fastingState.progressPercentage != 
        widget.fastingState.progressPercentage ||
        oldWidget.fastingState.fastingModeEnabled != 
        widget.fastingState.fastingModeEnabled) {
      _updateColor();
    }
  }

  void _updateColor() {
    final newColor = widget.fastingState.fastingModeEnabled
        ? FastingStatusIndicators.getStatusColor(
            widget.fastingState.progressPercentage,
            isActive: widget.fastingState.isActiveFasting,
          )
        : Colors.transparent;

    if (newColor != _currentColor) {
      _colorAnimation = ColorTween(
        begin: _currentColor,
        end: newColor,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ));

      _controller.forward(from: 0);
      _currentColor = newColor;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, _) {
        final animatedColor = _colorAnimation.value ?? _currentColor;
        
        return Container(
          decoration: BoxDecoration(
            color: widget.applyToBackground 
                ? animatedColor.withValues(alpha: 0.1)
                : null,
            border: widget.applyToBorder && animatedColor != Colors.transparent
                ? Border.all(
                    color: animatedColor.withValues(alpha: 0.5),
                    width: widget.borderWidth,
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// Progress ring overlay for any widget
class FastingProgressRing extends StatefulWidget {
  final Widget child;
  final FastingStateProvider fastingState;
  final double strokeWidth;
  final bool showPercentage;

  const FastingProgressRing({
    super.key,
    required this.child,
    required this.fastingState,
    this.strokeWidth = 4,
    this.showPercentage = false,
  });

  @override
  State<FastingProgressRing> createState() => _FastingProgressRingState();
}

class _FastingProgressRingState extends State<FastingProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _progressAnimation = AlwaysStoppedAnimation<double>(0.0);
    _updateProgress();
  }

  @override
  void didUpdateWidget(FastingProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.fastingState.progressPercentage != 
        widget.fastingState.progressPercentage) {
      _updateProgress();
    }
  }

  void _updateProgress() {
    _progressAnimation = Tween<double>(
      begin: _progressAnimation.value,
      end: widget.fastingState.progressPercentage,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.fastingState.isActiveFasting) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, _) {
        return Stack(
          children: [
            widget.child,
            
            // Progress ring overlay
            Positioned.fill(
              child: CustomPaint(
                painter: ProgressRingPainter(
                  progress: _progressAnimation.value,
                  color: FastingStatusIndicators.getStatusColor(
                    widget.fastingState.progressPercentage,
                  ),
                  strokeWidth: widget.strokeWidth,
                ),
              ),
            ),
            
            // Percentage text overlay
            if (widget.showPercentage)
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(_progressAnimation.value * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: FastingStatusIndicators.getStatusColor(
                          widget.fastingState.progressPercentage,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Custom painter for progress ring
class ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.color != color ||
           oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Motivational status banner
class FastingStatusBanner extends StatefulWidget {
  final FastingStateProvider fastingState;
  final bool showDismiss;
  final VoidCallback? onDismiss;

  const FastingStatusBanner({
    super.key,
    required this.fastingState,
    this.showDismiss = false,
    this.onDismiss,
  });

  @override
  State<FastingStatusBanner> createState() => _FastingStatusBannerState();
}

class _FastingStatusBannerState extends State<FastingStatusBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: -1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    if (widget.fastingState.isActiveFasting) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(FastingStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.fastingState.isActiveFasting && !oldWidget.fastingState.isActiveFasting) {
      _isVisible = true;
      _controller.forward();
    } else if (!widget.fastingState.isActiveFasting && oldWidget.fastingState.isActiveFasting) {
      _dismiss();
    }
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || !widget.fastingState.isActiveFasting) {
      return SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.fastingState.appThemeColor,
                  widget.fastingState.appThemeColor.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.fastingState.appThemeColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                FastingBadge(
                  fastingState: widget.fastingState,
                  size: 40,
                  animate: true,
                ),
                
                SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          FastingStatusIndicators.getMotivationalText(
                            widget.fastingState.progressPercentage,
                          ),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${widget.fastingState.elapsedTime.inHours}h ${widget.fastingState.elapsedTime.inMinutes.remainder(60)}m elapsed',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (widget.showDismiss)
                  IconButton(
                    onPressed: _dismiss,
                    icon: Icon(
                      Icons.close,
                      color: Colors.white.withValues(alpha: 0.8),
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
