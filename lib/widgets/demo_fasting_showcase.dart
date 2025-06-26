import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fasting_session.dart';
import '../services/fasting_service.dart';
import '../services/ar_filter_service.dart';

import '../services/auth_service.dart';
import '../design_system/widgets/fasting_timer_widget.dart';
import '../design_system/snap_ui.dart';

/// Enhanced fasting timer showcase for investor demos
/// Highlights AR filters, content blocking, and AI-powered features
class DemoFastingShowcase extends StatefulWidget {
  const DemoFastingShowcase({super.key});

  @override
  State<DemoFastingShowcase> createState() => _DemoFastingShowcaseState();
}

class _DemoFastingShowcaseState extends State<DemoFastingShowcase>
    with TickerProviderStateMixin {
  late AnimationController _highlightController;
  late AnimationController _filterDemoController;
  late Animation<double> _highlightAnimation;
  late Animation<double> _filterAnimation;
  
  bool _showingARDemo = false;
  bool _showingContentFilterDemo = false;
  FastingARFilterType? _activeFilter;
  
  @override
  void initState() {
    super.initState();
    
    _highlightController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _filterDemoController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _highlightAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _highlightController,
      curve: Curves.easeInOut,
    ));
    
    _filterAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _filterDemoController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _highlightController.dispose();
    _filterDemoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isCurrentUserDemo(),
      builder: (context, snapshot) {
        final isDemo = snapshot.data ?? false;
        
        return Consumer<FastingService>(
          builder: (context, fastingService, child) {
            return StreamBuilder<FastingSession?>(
              stream: fastingService.sessionStream,
              builder: (context, snapshot) {
                final session = snapshot.data;
                
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        SnapColors.primaryYellow.withValues(alpha: 0.1),
                        SnapColors.accentBlue.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: SnapColors.primaryYellow.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Demo indicator for investors
                      if (isDemo) _buildDemoIndicator(),
                      
                      // Enhanced fasting timer with demo features
                      _buildEnhancedTimer(session, isDemo),
                      
                      const SizedBox(height: 20),
                      
                      // AR Filter showcase
                      if (isDemo && session?.isActive == true)
                        _buildARFilterShowcase(session!),
                      
                      const SizedBox(height: 16),
                      
                      // Content filtering showcase
                      if (isDemo && session?.isActive == true)
                        _buildContentFilterShowcase(session!),
                      
                      const SizedBox(height: 16),
                      
                      // AI insights preview
                      if (isDemo) _buildAIInsightsPreview(session),
                    ],
                  ),
                );
              },
            );
          },
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
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            'AI-Powered Fasting Demo',
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

  Widget _buildEnhancedTimer(FastingSession? session, bool isDemo) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main timer widget
        FastingTimerWidget(
          size: 240,
          showControls: true,
          onSessionChanged: (newSession) {
            if (isDemo && newSession?.isActive == true) {
              _startDemoAnimations();
            }
          },
        ),
        
        // Demo highlight effect
        if (isDemo && _showingARDemo)
          AnimatedBuilder(
            animation: _highlightAnimation,
            builder: (context, child) {
              return Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SnapColors.accentBlue.withValues(
                      alpha: _highlightAnimation.value * 0.8,
                    ),
                    width: 4,
                  ),
                ),
              );
            },
          ),
        
        // AR filter overlay simulation
        if (isDemo && _activeFilter != null)
          _buildARFilterOverlay(_activeFilter!),
      ],
    );
  }

  Widget _buildARFilterShowcase(FastingSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: SnapColors.primaryYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AR Fasting Filters',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              if (_showingARDemo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SnapColors.accentGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ACTIVE',
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
            'AI-powered AR filters provide motivation and focus during fasting sessions',
            style: TextStyle(
              color: SnapColors.textSecondaryLight,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Motivational Quotes', FastingARFilterType.motivationalText),
              _buildFilterChip('Progress Ring', FastingARFilterType.progressRing),
              _buildFilterChip('Strength Aura', FastingARFilterType.strengthAura),
              _buildFilterChip('Zen Mode', FastingARFilterType.zenMode),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentFilterShowcase(FastingSession session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield,
                color: SnapColors.primaryYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Smart Content Filtering',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimaryLight,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleContentFilterDemo,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _showingContentFilterDemo 
                        ? SnapColors.accentBlue.withValues(alpha: 0.2)
                        : SnapColors.border.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _showingContentFilterDemo ? 'ON' : 'DEMO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _showingContentFilterDemo 
                          ? SnapColors.accentBlue 
                          : SnapColors.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'AI automatically blocks food content to maintain focus during fasting',
            style: TextStyle(
              color: SnapColors.textSecondaryLight,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildFilteringStatsRow(session),
        ],
      ),
    );
  }

  Widget _buildAIInsightsPreview(FastingSession? session) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: SnapColors.primaryYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Fasting Insights',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (session?.isActive == true) ...[
            _buildInsightCard(
              'Optimal Performance Window',
              'Your body is entering peak fat-burning mode. Mental clarity typically increases in the next 2 hours.',
              Icons.trending_up,
              SnapColors.accentGreen,
            ),
            const SizedBox(height: 8),
            _buildInsightCard(
              'Hydration Reminder',
              'AI recommends 16oz of water now to support your fasting goals and maintain energy levels.',
              Icons.water_drop,
              SnapColors.accentBlue,
            ),
          ] else ...[
            _buildInsightCard(
              'Ready to Fast',
              'Your last meal was logged 3 hours ago. Perfect timing to begin your 16:8 intermittent fast.',
              Icons.schedule,
              SnapColors.accentBlue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, FastingARFilterType filterType) {
    final isActive = _activeFilter == filterType;
    
    return GestureDetector(
      onTap: () => _toggleARFilter(filterType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? SnapColors.accentBlue.withValues(alpha: 0.2)
              : SnapColors.border.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? SnapColors.accentBlue : SnapColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? SnapColors.accentBlue : SnapColors.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildFilteringStatsRow(FastingSession session) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem('Content Blocked', '23', Icons.block),
        ),
        Expanded(
          child: _buildStatItem('Focus Score', '94%', Icons.psychology),
        ),
        Expanded(
          child: _buildStatItem('Filter Accuracy', '99%', Icons.verified),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: SnapColors.primaryYellow),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: SnapColors.textPrimaryLight,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: SnapColors.textSecondaryLight,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildInsightCard(String title, String description, IconData icon, Color color) {
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
                    color: SnapColors.textPrimaryLight,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: SnapColors.textSecondaryLight,
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

  Widget _buildARFilterOverlay(FastingARFilterType filterType) {
    return AnimatedBuilder(
      animation: _filterAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _filterAnimation.value,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _getFilterColor(filterType).withValues(alpha: 0.3),
                  _getFilterColor(filterType).withValues(alpha: 0.1),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Text(
                _getFilterText(filterType),
                style: TextStyle(
                  color: _getFilterColor(filterType),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getFilterColor(FastingARFilterType filterType) {
    switch (filterType) {
      case FastingARFilterType.motivationalText:
        return Colors.blue;
      case FastingARFilterType.progressRing:
        return Colors.green;
      case FastingARFilterType.strengthAura:
        return Colors.purple;
      case FastingARFilterType.zenMode:
        return Colors.indigo;
      default:
        return SnapColors.accentBlue;
    }
  }

  String _getFilterText(FastingARFilterType filterType) {
    switch (filterType) {
      case FastingARFilterType.motivationalText:
        return 'You\'ve Got This! 💪';
      case FastingARFilterType.progressRing:
        return 'Progress Ring Active';
      case FastingARFilterType.strengthAura:
        return 'Strength Aura ✨';
      case FastingARFilterType.zenMode:
        return 'Zen Mode 🧘‍♀️';
      default:
        return 'AR Filter Active';
    }
  }

  void _startDemoAnimations() {
    _highlightController.repeat(reverse: true);
  }

  void _toggleARFilter(FastingARFilterType filterType) {
    setState(() {
      if (_activeFilter == filterType) {
        _activeFilter = null;
        _showingARDemo = false;
        _filterDemoController.reset();
      } else {
        _activeFilter = filterType;
        _showingARDemo = true;
        _filterDemoController.forward();
      }
    });
  }

  void _toggleContentFilterDemo() {
    setState(() {
      _showingContentFilterDemo = !_showingContentFilterDemo;
    });
  }
} 