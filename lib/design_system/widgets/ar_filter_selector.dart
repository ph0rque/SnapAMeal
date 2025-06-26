import 'package:flutter/material.dart';
import '../../services/ar_filter_service.dart';
import '../../models/fasting_session.dart';

/// Widget for selecting and previewing AR filters
class ARFilterSelector extends StatefulWidget {
  final FastingSession? fastingSession;
  final ARFilterService arFilterService;
  final Function(FastingARFilterType) onFilterSelected;
  final FastingARFilterType? selectedFilter;
  final bool isVisible;

  const ARFilterSelector({
    super.key,
    required this.fastingSession,
    required this.arFilterService,
    required this.onFilterSelected,
    this.selectedFilter,
    this.isVisible = true,
  });

  @override
  State<ARFilterSelector> createState() => _ARFilterSelectorState();
}

class _ARFilterSelectorState extends State<ARFilterSelector>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    if (widget.isVisible) {
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(ARFilterSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fastingSession == null) {
      return SizedBox.shrink();
    }

    final availableFilters = widget.arFilterService.getAvailableFilters(widget.fastingSession);
    
    if (availableFilters.isEmpty) {
      return SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.9),
            ],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Motivational Filters',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  if (widget.selectedFilter != null)
                    GestureDetector(
                      onTap: () => widget.onFilterSelected(widget.selectedFilter!),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: availableFilters.length,
                itemBuilder: (context, index) {
                  final filter = availableFilters[index];
                  final isSelected = widget.selectedFilter == filter.type;
                  
                  return _buildFilterItem(filter, isSelected);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterItem(ARFilterConfig filter, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.onFilterSelected(filter.type),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        width: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
                          color: isSelected ? filter.primaryColor : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 3 : 1,
          ),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    filter.primaryColor.withValues(alpha: 0.8),
                    filter.accentColor.withValues(alpha: 0.6),
                  ],
                )
              : LinearGradient(
                              colors: [
              Colors.grey.withValues(alpha: 0.3),
              Colors.grey.withValues(alpha: 0.2),
            ],
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: filter.primaryColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getFilterIcon(filter.type),
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
              size: isSelected ? 28 : 24,
            ),
            SizedBox(height: 4),
            Text(
              filter.name.split(' ').first, // Show first word only
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected)
              Container(
                margin: EdgeInsets.only(top: 2),
                height: 2,
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getFilterIcon(FastingARFilterType type) {
    switch (type) {
      case FastingARFilterType.motivationalText:
        return Icons.format_quote;
      case FastingARFilterType.progressRing:
        return Icons.radio_button_unchecked;
      case FastingARFilterType.achievement:
        return Icons.celebration;
      case FastingARFilterType.strengthAura:
        return Icons.blur_circular;
      case FastingARFilterType.timeCounter:
        return Icons.timer;
      case FastingARFilterType.willpowerBoost:
        return Icons.flash_on;
      case FastingARFilterType.zenMode:
        return Icons.self_improvement;
      case FastingARFilterType.challengeMode:
        return Icons.fitness_center;
    }
  }
}

/// Overlay widget that displays active AR filters
class ARFilterOverlayWidget extends StatefulWidget {
  final List<ARFilterOverlay> activeOverlays;
  final Size screenSize;

  const ARFilterOverlayWidget({
    super.key,
    required this.activeOverlays,
    required this.screenSize,
  });

  @override
  State<ARFilterOverlayWidget> createState() => _ARFilterOverlayWidgetState();
}

class _ARFilterOverlayWidgetState extends State<ARFilterOverlayWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.activeOverlays.isEmpty) {
      return SizedBox.shrink();
    }

    return Stack(
      children: widget.activeOverlays.map((overlay) {
        return Positioned(
          top: _getOverlayPosition(overlay.type).dy,
          left: _getOverlayPosition(overlay.type).dx,
          child: overlay.widget,
        );
      }).toList(),
    );
  }

  /// Get position for different types of overlays
  Offset _getOverlayPosition(FastingARFilterType type) {
    final size = widget.screenSize;
    
    switch (type) {
      case FastingARFilterType.motivationalText:
        return Offset(size.width * 0.1, size.height * 0.15);
        
      case FastingARFilterType.progressRing:
        return Offset(size.width * 0.5 - 75, size.height * 0.3);
        
      case FastingARFilterType.achievement:
        return Offset(size.width * 0.5 - 100, size.height * 0.4);
        
      case FastingARFilterType.strengthAura:
        return Offset(size.width * 0.5 - 150, size.height * 0.35);
        
      case FastingARFilterType.timeCounter:
        return Offset(size.width * 0.5 - 50, size.height * 0.1);
        
      case FastingARFilterType.willpowerBoost:
        return Offset(size.width * 0.5 - 75, size.height * 0.45);
        
      case FastingARFilterType.zenMode:
        return Offset(size.width * 0.5 - 125, size.height * 0.4);
        
      case FastingARFilterType.challengeMode:
        return Offset(size.width * 0.5 - 150, size.height * 0.3);
    }
  }
}

/// Progress indicator for fasting session within AR overlay
class FastingProgressOverlay extends StatefulWidget {
  final FastingSession fastingSession;
  final Color primaryColor;
  final Color accentColor;

  const FastingProgressOverlay({
    super.key,
    required this.fastingSession,
    this.primaryColor = Colors.blue,
    this.accentColor = Colors.lightBlue,
  });

  @override
  State<FastingProgressOverlay> createState() => _FastingProgressOverlayState();
}

class _FastingProgressOverlayState extends State<FastingProgressOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  widget.primaryColor.withValues(alpha: 0.3),
                  widget.accentColor.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  child: Stack(
                    children: [
                      // Background circle
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 3,
                          ),
                        ),
                      ),
                      // Progress arc
                      CustomPaint(
                        size: Size(80, 80),
                        painter: ProgressArcPainter(
                          progress: widget.fastingSession.progressPercentage,
                          primaryColor: widget.primaryColor,
                          accentColor: widget.accentColor,
                        ),
                      ),
                      // Center content
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(widget.fastingSession.progressPercentage * 100).toInt()}%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Complete',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  widget.fastingSession.typeDescription,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

/// Custom painter for progress arc
class ProgressArcPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color accentColor;

  ProgressArcPainter({
    required this.progress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: [primaryColor, accentColor],
          stops: [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..strokeWidth = 4.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      
      final sweepAngle = 2 * 3.14159 * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2, // Start from top
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ProgressArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.accentColor != accentColor;
  }
}
