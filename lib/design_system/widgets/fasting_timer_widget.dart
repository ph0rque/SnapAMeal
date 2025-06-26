import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/fasting_session.dart';
import '../../services/fasting_service.dart';
import '../snap_ui.dart';

/// Circular fasting timer widget with progress visualization and interactive controls
class FastingTimerWidget extends StatefulWidget {
  final double size;
  final bool showControls;
  final VoidCallback? onTap;
  final Function(FastingSession?)? onSessionChanged;

  const FastingTimerWidget({
    super.key,
    this.size = 280.0,
    this.showControls = true,
    this.onTap,
    this.onSessionChanged,
  });

  @override
  State<FastingTimerWidget> createState() => _FastingTimerWidgetState();
}

class _FastingTimerWidgetState extends State<FastingTimerWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;
  
  FastingSession? _currentSession;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FastingService>(
      builder: (context, fastingService, child) {
        return StreamBuilder<FastingSession?>(
          stream: fastingService.sessionStream,
          builder: (context, snapshot) {
            final session = snapshot.data;
            
            // Update session and trigger animation if changed
            if (session != _currentSession) {
              _updateSession(session);
            }
            
            return GestureDetector(
              onTap: widget.onTap ?? () => _handleTimerTap(context, fastingService),
              child: Container(
                width: widget.size,
                height: widget.size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background circle
                    _buildBackgroundCircle(),
                    
                    // Progress circle
                    _buildProgressCircle(session),
                    
                    // Inner content
                    _buildInnerContent(session),
                    
                    // Pulse effect for active sessions
                    if (session?.isActive == true) _buildPulseEffect(),
                    
                    // Control buttons
                    if (widget.showControls && session != null)
                      _buildControlButtons(context, fastingService, session),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Update session and trigger animations
  void _updateSession(FastingSession? newSession) {
    final oldSession = _currentSession;
    _currentSession = newSession;
    
    // Trigger progress animation when session changes
    if (newSession != null && oldSession?.id != newSession.id) {
      _progressController.reset();
      _progressController.forward();
    }
    
    // Notify parent of session change
    widget.onSessionChanged?.call(newSession);
  }

  /// Build the background circle
  Widget _buildBackgroundCircle() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SnapColors.surface,
        boxShadow: [
          BoxShadow(
            color: SnapColors.shadow.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: SnapColors.border,
          width: 2,
        ),
      ),
    );
  }

  /// Build the progress circle
  Widget _buildProgressCircle(FastingSession? session) {
    final progress = session?.progressPercentage ?? 0.0;
    final isActive = session?.isActive == true;
    final isPaused = session?.isPaused == true;
    
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        final animatedProgress = progress * _progressAnimation.value;
        
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: CircularProgressPainter(
            progress: animatedProgress,
            strokeWidth: 8.0,
            backgroundColor: SnapColors.border,
            progressColor: _getProgressColor(session),
            isActive: isActive,
            isPaused: isPaused,
          ),
        );
      },
    );
  }

  /// Build the inner content (time display and status)
  Widget _buildInnerContent(FastingSession? session) {
    return Container(
      width: widget.size * 0.7,
      height: widget.size * 0.7,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Time display
          _buildTimeDisplay(session),
          
          SizedBox(height: 8),
          
          // Status text
          _buildStatusText(session),
          
          SizedBox(height: 4),
          
          // Progress percentage
          if (session != null) _buildProgressText(session),
        ],
      ),
    );
  }

  /// Build the time display
  Widget _buildTimeDisplay(FastingSession? session) {
    String timeText;
    String label;
    
    if (session == null) {
      timeText = '00:00';
      label = 'Ready to start';
    } else if (session.isActive || session.isPaused) {
      final remaining = session.remainingTime;
      timeText = _formatDuration(remaining);
      label = 'Remaining';
    } else if (session.isCompleted) {
      final duration = session.actualDuration ?? session.plannedDuration;
      timeText = _formatDuration(duration);
      label = 'Completed';
    } else {
      timeText = '00:00';
      label = 'Ended';
    }
    
    return Column(
      children: [
        Text(
          timeText,
          style: SnapTypography.heading1.copyWith(
            fontSize: widget.size * 0.12,
            fontWeight: FontWeight.bold,
            color: _getTimeColor(session),
          ),
        ),
        Text(
          label,
          style: SnapTypography.caption.copyWith(
            color: SnapColors.textSecondary,
            fontSize: widget.size * 0.04,
          ),
        ),
      ],
    );
  }

  /// Build the status text
  Widget _buildStatusText(FastingSession? session) {
    String statusText;
    Color statusColor;
    
    if (session == null) {
      statusText = 'Tap to start fasting';
      statusColor = SnapColors.textSecondary;
    } else {
      switch (session.state) {
        case FastingState.active:
          statusText = session.typeDescription;
          statusColor = SnapColors.primary;
          break;
        case FastingState.paused:
          statusText = 'Paused • ${session.typeDescription}';
          statusColor = SnapColors.warning;
          break;
        case FastingState.completed:
          statusText = 'Completed! 🎉';
          statusColor = SnapColors.success;
          break;
        case FastingState.broken:
          statusText = 'Session ended';
          statusColor = SnapColors.error;
          break;
        default:
          statusText = session.typeDescription;
          statusColor = SnapColors.textSecondary;
      }
    }
    
    return Text(
      statusText,
      style: SnapTypography.bodyMedium.copyWith(
        color: statusColor,
        fontSize: widget.size * 0.045,
        fontWeight: FontWeight.w600,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build the progress percentage text
  Widget _buildProgressText(FastingSession session) {
    final progress = (session.progressPercentage * 100).toInt();
    
    return Text(
      '$progress% complete',
      style: SnapTypography.caption.copyWith(
        color: SnapColors.textSecondary,
        fontSize: widget.size * 0.035,
      ),
    );
  }

  /// Build the pulse effect for active sessions
  Widget _buildPulseEffect() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: widget.size * 0.9,
            height: widget.size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: SnapColors.primary.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build control buttons
  Widget _buildControlButtons(
    BuildContext context,
    FastingService fastingService,
    FastingSession session,
  ) {
    return Positioned(
      bottom: widget.size * 0.15,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pause/Resume button
          if (session.isActive || session.isPaused)
            _buildControlButton(
              icon: session.isActive ? Icons.pause : Icons.play_arrow,
              onTap: () => session.isActive
                  ? fastingService.pauseFastingSession()
                  : fastingService.resumeFastingSession(),
              backgroundColor: session.isActive ? SnapColors.warning : SnapColors.success,
            ),
          
          SizedBox(width: 16),
          
          // Stop button
          if (session.isActive || session.isPaused)
            _buildControlButton(
              icon: Icons.stop,
              onTap: () => _showEndSessionDialog(context, fastingService),
              backgroundColor: SnapColors.error,
            ),
        ],
      ),
    );
  }

  /// Build a control button
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  /// Handle timer tap
  void _handleTimerTap(BuildContext context, FastingService fastingService) {
    if (_currentSession == null) {
      _showStartSessionDialog(context, fastingService);
    } else if (_currentSession!.isCompleted || _currentSession!.wasBroken) {
      _showStartSessionDialog(context, fastingService);
    }
  }

  /// Show start session dialog
  void _showStartSessionDialog(BuildContext context, FastingService fastingService) {
    showDialog(
      context: context,
      builder: (context) => FastingStartDialog(
        onStart: (type, goal) async {
          await fastingService.startFastingSession(
            type: type,
            personalGoal: goal,
          );
        },
      ),
    );
  }

  /// Show end session dialog
  void _showEndSessionDialog(BuildContext context, FastingService fastingService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Fasting Session?'),
        content: Text('Are you sure you want to end your current fasting session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await fastingService.endFastingSession(FastingEndReason.userBreak);
            },
            child: Text(
              'End Session',
              style: TextStyle(color: SnapColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Get progress color based on session state
  Color _getProgressColor(FastingSession? session) {
    if (session == null) return SnapColors.border;
    
    switch (session.state) {
      case FastingState.active:
        return SnapColors.primary;
      case FastingState.paused:
        return SnapColors.warning;
      case FastingState.completed:
        return SnapColors.success;
      case FastingState.broken:
        return SnapColors.error;
      default:
        return SnapColors.border;
    }
  }

  /// Get time color based on session state
  Color _getTimeColor(FastingSession? session) {
    if (session == null) return SnapColors.textSecondary;
    
    switch (session.state) {
      case FastingState.active:
        return SnapColors.textPrimary;
      case FastingState.paused:
        return SnapColors.warning;
      case FastingState.completed:
        return SnapColors.success;
      case FastingState.broken:
        return SnapColors.error;
      default:
        return SnapColors.textSecondary;
    }
  }

  /// Format duration to HH:MM format
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${duration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
    }
  }
}

/// Custom painter for circular progress
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final bool isActive;
  final bool isPaused;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
    this.isActive = false,
    this.isPaused = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      // Add gradient effect for active sessions
      if (isActive) {
        final gradient = SweepGradient(
          colors: [
            progressColor.withValues(alpha: 0.3),
            progressColor,
            progressColor,
          ],
          stops: [0.0, 0.5, 1.0],
        );
        
        progressPaint.shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        );
      }
      
      final startAngle = -math.pi / 2; // Start from top
      final sweepAngle = 2 * math.pi * progress;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
      
      // Add animated dots for paused state
      if (isPaused) {
        final dotPaint = Paint()
          ..color = progressColor
          ..style = PaintingStyle.fill;
        
        for (int i = 0; i < 3; i++) {
          final angle = startAngle + sweepAngle + (i * 0.1);
          final dotX = center.dx + radius * math.cos(angle);
          final dotY = center.dy + radius * math.sin(angle);
          
          canvas.drawCircle(
            Offset(dotX, dotY),
            strokeWidth / 4,
            dotPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.progressColor != progressColor ||
           oldDelegate.isActive != isActive ||
           oldDelegate.isPaused != isPaused;
  }
}

/// Dialog for starting a new fasting session
class FastingStartDialog extends StatefulWidget {
  final Function(FastingType type, String? goal) onStart;

  const FastingStartDialog({
    super.key,
    required this.onStart,
  });

  @override
  State<FastingStartDialog> createState() => _FastingStartDialogState();
}

class _FastingStartDialogState extends State<FastingStartDialog> {
  FastingType _selectedType = FastingType.intermittent16_8;
  final TextEditingController _goalController = TextEditingController();

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Start Fasting Session'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose your fasting type:',
              style: SnapTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            
            // Fasting type selection
            ...FastingType.values.map((type) => RadioListTile<FastingType>(
              title: Text(_getTypeDescription(type)),
              subtitle: Text(_getTypeDuration(type)),
              value: type,
              groupValue: _selectedType,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                  });
                }
              },
            )),
            
            SizedBox(height: 16),
            
            // Personal goal input
            Text(
              'Personal goal (optional):',
              style: SnapTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _goalController,
              decoration: InputDecoration(
                hintText: 'e.g., Build discipline, lose weight...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onStart(
              _selectedType,
              _goalController.text.isNotEmpty ? _goalController.text : null,
            );
          },
          child: Text('Start Fasting'),
        ),
      ],
    );
  }

  String _getTypeDescription(FastingType type) {
    switch (type) {
      case FastingType.intermittent16_8:
      case FastingType.sixteenEight:
        return '16:8 Intermittent Fasting';
      case FastingType.intermittent18_6:
        return '18:6 Intermittent Fasting';
      case FastingType.intermittent20_4:
        return '20:4 Intermittent Fasting';
      case FastingType.omad:
        return 'One Meal A Day (OMAD)';
      case FastingType.alternate:
        return 'Alternate Day Fasting';
      case FastingType.extended24:
      case FastingType.twentyFourHour:
        return '24-Hour Extended Fast';
      case FastingType.extended36:
        return '36-Hour Extended Fast';
      case FastingType.extended48:
        return '48-Hour Extended Fast';
      case FastingType.custom:
        return 'Custom Duration';
    }
  }

  String _getTypeDuration(FastingType type) {
    final duration = FastingSession.getStandardDuration(type);
    return '${duration.inHours} hours';
  }
} 