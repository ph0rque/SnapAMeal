import 'package:flutter/material.dart';
import '../providers/fasting_state_provider.dart';
import '../services/content_filter_service.dart';
import '../design_system/widgets/filtered_content_widget.dart';

/// Route guard that manages navigation during fasting
class FastingRouteGuard {
  static const List<String> _restrictedRoutes = [
    '/food-discovery',
    '/restaurant-finder',
    '/meal-planning',
    '/recipe-browser',
    '/food-ordering',
    '/cooking-tutorials',
  ];

  static const Map<String, String> _routeRedirects = {
    '/food-discovery': '/health-dashboard',
    '/restaurant-finder': '/workout-finder',
    '/meal-planning': '/fasting-timer',
    '/recipe-browser': '/health-tips',
    '/food-ordering': '/motivation-center',
    '/cooking-tutorials': '/meditation-guide',
  };

  /// Check if route should be blocked during fasting
  static bool shouldBlockRoute(
    String route,
    FastingStateProvider fastingState,
  ) {
    if (!fastingState.fastingModeEnabled || !fastingState.isActiveFasting) {
      return false;
    }

    return _restrictedRoutes.any(
      (restrictedRoute) =>
          route.toLowerCase().contains(restrictedRoute.toLowerCase()),
    );
  }

  /// Get alternative route for blocked route
  static String? getAlternativeRoute(String blockedRoute) {
    return _routeRedirects[blockedRoute.toLowerCase()];
  }

  /// Show route blocked dialog
  static Future<bool> showRouteBlockedDialog(
    BuildContext context,
    String blockedRoute,
    FastingStateProvider fastingState,
  ) async {
    final alternative = getAlternativeRoute(blockedRoute);

    return await showDialog<bool>(
          context: context,
          builder: (context) => FastingRouteBlockedDialog(
            blockedRoute: blockedRoute,
            alternativeRoute: alternative,
            fastingState: fastingState,
          ),
        ) ??
        false;
  }

  /// Create route-aware page wrapper
  static Widget wrapPage(
    Widget page,
    String route,
    FastingStateProvider fastingState,
  ) {
    if (shouldBlockRoute(route, fastingState)) {
      return FastingBlockedPage(
        blockedRoute: route,
        fastingState: fastingState,
      );
    }

    return page;
  }
}

/// Dialog shown when route is blocked during fasting
class FastingRouteBlockedDialog extends StatelessWidget {
  final String blockedRoute;
  final String? alternativeRoute;
  final FastingStateProvider fastingState;

  const FastingRouteBlockedDialog({
    super.key,
    required this.blockedRoute,
    this.alternativeRoute,
    required this.fastingState,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.shield, color: fastingState.appThemeColor, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Fasting Protection',
              style: TextStyle(
                color: fastingState.appThemeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This page contains content that might interfere with your fasting goals.',
            style: TextStyle(fontSize: 16, height: 1.4),
          ),

          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: fastingState.appThemeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.timer, color: fastingState.appThemeColor, size: 20),
                SizedBox(width: 8),
                Text(
                  'Fasting: ${fastingState.elapsedTime.inHours}h ${fastingState.elapsedTime.inMinutes.remainder(60)}m',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: fastingState.appThemeColor,
                  ),
                ),
              ],
            ),
          ),

          if (alternativeRoute != null) ...[
            SizedBox(height: 16),
            Text(
              'Would you like to visit a healthier alternative instead?',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Stay Here'),
        ),

        if (alternativeRoute != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(true);
              Navigator.of(context).pushReplacementNamed(alternativeRoute!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: fastingState.appThemeColor,
            ),
            child: Text('Go to Alternative'),
          ),

        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(false);
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/home', (route) => false);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600]),
          child: Text('Back to Home'),
        ),
      ],
    );
  }
}

/// Page shown when route is blocked
class FastingBlockedPage extends StatelessWidget {
  final String blockedRoute;
  final FastingStateProvider fastingState;

  const FastingBlockedPage({
    super.key,
    required this.blockedRoute,
    required this.fastingState,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fasting Protection'),
        backgroundColor: fastingState.appThemeColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: FilteredContentWidget(
                filterResult: ContentFilterResult(
                  shouldFilter: true,
                  confidence: 1.0,
                  category: FilterCategory.food,
                  reason: 'Page blocked to support your fasting goals',
                  replacementContent:
                      'This page is temporarily unavailable during your fasting session to help you stay focused on your health goals.',
                ),
                fastingSession: fastingState.currentSession!,
                onViewProgress: () {
                  Navigator.of(context).pushNamed('/fasting-timer');
                },
                onViewAlternatives: () {
                  _showAlternatives(context);
                },
              ),
            ),

            SizedBox(height: 20),

            // Alternative navigation options
            _buildAlternativeOptions(context),
          ],
        ),
      ),
    );
  }

  /// Build alternative navigation options
  Widget _buildAlternativeOptions(BuildContext context) {
    final alternatives = _getAlternativePages();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended alternatives:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: fastingState.appThemeColor,
          ),
        ),

        SizedBox(height: 12),

        ...alternatives.map(
          (alternative) => _buildAlternativeTile(
            context,
            alternative['title'],
            alternative['subtitle'],
            alternative['icon'],
            alternative['route'],
          ),
        ),
      ],
    );
  }

  /// Get alternative pages based on blocked route
  List<Map<String, dynamic>> _getAlternativePages() {
    switch (blockedRoute.toLowerCase()) {
      case '/food-discovery':
        return [
          {
            'title': 'Health Dashboard',
            'subtitle': 'Track your wellness progress',
            'icon': Icons.dashboard,
            'route': '/health-dashboard',
          },
          {
            'title': 'Meditation Guide',
            'subtitle': 'Stay mindful during fasting',
            'icon': Icons.self_improvement,
            'route': '/meditation-guide',
          },
        ];

      case '/restaurant-finder':
        return [
          {
            'title': 'Workout Finder',
            'subtitle': 'Find nearby fitness activities',
            'icon': Icons.fitness_center,
            'route': '/workout-finder',
          },
          {
            'title': 'Health Communities',
            'subtitle': 'Connect with fellow fasters',
            'icon': Icons.group,
            'route': '/health-communities',
          },
        ];

      default:
        return [
          {
            'title': 'Fasting Timer',
            'subtitle': 'Monitor your current session',
            'icon': Icons.timer,
            'route': '/fasting-timer',
          },
          {
            'title': 'Motivation Center',
            'subtitle': 'Stay inspired and focused',
            'icon': Icons.psychology,
            'route': '/motivation-center',
          },
        ];
    }
  }

  /// Build alternative tile
  Widget _buildAlternativeTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String route,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: fastingState.appThemeColor.withValues(alpha: 0.1),
          child: Icon(icon, color: fastingState.appThemeColor),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: () {
          Navigator.of(context).pushReplacementNamed(route);
        },
      ),
    );
  }

  /// Show alternatives bottom sheet
  void _showAlternatives(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Healthy Alternatives',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: fastingState.appThemeColor,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Stay focused on your fasting goals with these alternatives:',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),

              SizedBox(height: 20),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: _getAlternativePages()
                      .map(
                        (alternative) => _buildAlternativeTile(
                          context,
                          alternative['title'],
                          alternative['subtitle'],
                          alternative['icon'],
                          alternative['route'],
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
