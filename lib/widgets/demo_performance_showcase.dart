import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../design_system/snap_ui.dart';
import 'dart:math' as math;
import 'dart:async';

/// Cross-platform performance and synchronization showcase for investor demos
/// Highlights technical excellence and real-time capabilities
class DemoPerformanceShowcase extends StatefulWidget {
  const DemoPerformanceShowcase({super.key});

  @override
  State<DemoPerformanceShowcase> createState() =>
      _DemoPerformanceShowcaseState();
}

class _DemoPerformanceShowcaseState extends State<DemoPerformanceShowcase>
    with TickerProviderStateMixin {
  late AnimationController _performanceController;
  late AnimationController _syncController;

  Timer? _performanceTimer;
  Timer? _syncTimer;

  int _selectedPlatform = 0; // 0: iOS, 1: Android, 2: Web

  final List<String> _platforms = ['iOS', 'Android', 'Web'];
  final List<IconData> _platformIcons = [
    Icons.phone_iphone,
    Icons.android,
    Icons.web,
  ];

  // Simulated real-time performance metrics
  double _cpuUsage = 12.5;
  double _memoryUsage = 156.8;
  double _networkLatency = 45.2;
  double _frameRate = 59.8;
  int _syncEvents = 0;
  DateTime _lastSync = DateTime.now();

  final List<Map<String, dynamic>> _performanceMetrics = [
    {
      'platform': 'iOS',
      'appSize': '24.8 MB',
      'startupTime': '1.2s',
      'avgFrameRate': '59.8 FPS',
      'memoryEfficiency': '94%',
      'batteryOptimization': '97%',
      'crashRate': '0.01%',
      'color': SnapColors.accentBlue,
      'icon': Icons.phone_iphone,
    },
    {
      'platform': 'Android',
      'appSize': '26.1 MB',
      'startupTime': '1.4s',
      'avgFrameRate': '59.2 FPS',
      'memoryEfficiency': '91%',
      'batteryOptimization': '93%',
      'crashRate': '0.02%',
      'color': SnapColors.accentGreen,
      'icon': Icons.android,
    },
    {
      'platform': 'Web',
      'appSize': '2.8 MB',
      'startupTime': '0.8s',
      'avgFrameRate': '60.0 FPS',
      'memoryEfficiency': '89%',
      'batteryOptimization': 'N/A',
      'crashRate': '0.01%',
      'color': SnapColors.accentPurple,
      'icon': Icons.web,
    },
  ];

  final List<Map<String, dynamic>> _syncFeatures = [
    {
      'feature': 'Real-time Chat',
      'latency': '< 100ms',
      'reliability': '99.9%',
      'description': 'Instant message delivery with conflict resolution',
      'icon': Icons.chat,
      'color': SnapColors.accentBlue,
      'isActive': true,
    },
    {
      'feature': 'Health Data Sync',
      'latency': '< 500ms',
      'reliability': '99.8%',
      'description': 'Cross-device health metrics synchronization',
      'icon': Icons.favorite,
      'color': SnapColors.accentRed,
      'isActive': true,
    },
    {
      'feature': 'Story Updates',
      'latency': '< 200ms',
      'reliability': '99.7%',
      'description': 'Live story engagement and view tracking',
      'icon': Icons.video_library,
      'color': SnapColors.accentGreen,
      'isActive': false,
    },
    {
      'feature': 'AI Insights',
      'latency': '< 2s',
      'reliability': '99.5%',
      'description': 'Personalized recommendations across devices',
      'icon': Icons.psychology,
      'color': SnapColors.accentPurple,
      'isActive': true,
    },
  ];

  @override
  void initState() {
    super.initState();

    _performanceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _syncController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _startPerformanceSimulation();
    _startSyncSimulation();
  }

  @override
  void dispose() {
    _performanceController.dispose();
    _syncController.dispose();
    _performanceTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  void _startPerformanceSimulation() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          // Simulate realistic performance fluctuations
          _cpuUsage = 8.0 + (math.Random().nextDouble() * 12.0);
          _memoryUsage = 140.0 + (math.Random().nextDouble() * 30.0);
          _networkLatency = 35.0 + (math.Random().nextDouble() * 20.0);
          _frameRate = 58.0 + (math.Random().nextDouble() * 2.0);
        });
      }
    });
  }

  void _startSyncSimulation() {
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _syncEvents++;
          _lastSync = DateTime.now();

          // Randomly activate/deactivate sync features for demo
          final random = math.Random();
          for (var feature in _syncFeatures) {
            if (random.nextDouble() > 0.7) {
              feature['isActive'] = !feature['isActive'];
            }
          }
        });
      }
    });
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
                SnapColors.accentBlue.withValues(alpha: 0.1),
                SnapColors.accentGreen.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SnapColors.accentBlue.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo indicator
              _buildDemoIndicator(),

              const SizedBox(height: 20),

              // Performance overview
              _buildPerformanceOverview(),

              const SizedBox(height: 20),

              // Platform metrics
              _buildPlatformMetricsSection(),

              const SizedBox(height: 20),

              // Real-time performance monitoring
              _buildRealTimeMonitoring(),

              const SizedBox(height: 20),

              // Synchronization showcase
              _buildSynchronizationSection(),

              const SizedBox(height: 20),

              // Technical architecture
              _buildTechnicalArchitecture(),
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
          const Icon(Icons.speed, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          const Text(
            'Performance & Sync Demo',
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

  Widget _buildPerformanceOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cross-Platform Performance Excellence',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Optimized for performance across iOS, Android, and Web with real-time synchronization capabilities.',
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
                'Avg Startup',
                '1.1s',
                'Across platforms',
                Icons.rocket_launch,
                SnapColors.accentGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Frame Rate',
                '59.7 FPS',
                '60 FPS target',
                Icons.videocam,
                SnapColors.accentBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewCard(
                'Sync Latency',
                '<200ms',
                'Real-time updates',
                Icons.sync,
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

  Widget _buildPlatformMetricsSection() {
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
              Icon(Icons.devices, color: SnapColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Platform-Specific Metrics',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              // Platform selector
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: SnapColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _platforms.asMap().entries.map((entry) {
                    final index = entry.key;
                    final platform = entry.value;
                    final isSelected = _selectedPlatform == index;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlatform = index;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? SnapColors.accentBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _platformIcons[index],
                              size: 12,
                              color: isSelected
                                  ? Colors.white
                                  : SnapColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              platform,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : SnapColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Selected platform metrics
          _buildPlatformMetricsCard(_performanceMetrics[_selectedPlatform]),
        ],
      ),
    );
  }

  Widget _buildPlatformMetricsCard(Map<String, dynamic> metrics) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (metrics['color'] as Color).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (metrics['color'] as Color).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Platform header
          Row(
            children: [
              Icon(
                metrics['icon'] as IconData,
                color: metrics['color'] as Color,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '${metrics['platform']} Performance',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                  fontSize: 16,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Metrics grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 1.2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _buildMetricTile('App Size', metrics['appSize'], Icons.storage),
              _buildMetricTile('Startup', metrics['startupTime'], Icons.timer),
              _buildMetricTile(
                'Frame Rate',
                metrics['avgFrameRate'],
                Icons.videocam,
              ),
              _buildMetricTile(
                'Memory',
                metrics['memoryEfficiency'],
                Icons.memory,
              ),
              _buildMetricTile(
                'Battery',
                metrics['batteryOptimization'],
                Icons.battery_full,
              ),
              _buildMetricTile(
                'Stability',
                '${100 - double.parse(metrics['crashRate'].toString().replaceAll('%', ''))}%',
                Icons.check_circle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SnapColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: SnapColors.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SnapColors.textPrimary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: TextStyle(color: SnapColors.textSecondary, fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeMonitoring() {
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
              Icon(Icons.monitor_heart, color: SnapColors.accentRed, size: 20),
              const SizedBox(width: 8),
              Text(
                'Real-Time Performance Monitoring',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SnapColors.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: SnapColors.accentGreen,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Live metrics
          Row(
            children: [
              Expanded(
                child: _buildLiveMetric(
                  'CPU Usage',
                  '${_cpuUsage.toStringAsFixed(1)}%',
                  _cpuUsage / 100,
                  Icons.memory,
                  SnapColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLiveMetric(
                  'Memory',
                  '${_memoryUsage.toStringAsFixed(1)} MB',
                  _memoryUsage / 200,
                  Icons.storage,
                  SnapColors.accentGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildLiveMetric(
                  'Network',
                  '${_networkLatency.toStringAsFixed(0)}ms',
                  1 - (_networkLatency / 100),
                  Icons.wifi,
                  SnapColors.accentPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildLiveMetric(
                  'Frame Rate',
                  '${_frameRate.toStringAsFixed(1)} FPS',
                  _frameRate / 60,
                  Icons.videocam,
                  SnapColors.accentRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMetric(
    String label,
    String value,
    double progress,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: SnapColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SnapColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: SnapColors.textSecondary.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildSynchronizationSection() {
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
              Icon(Icons.sync, color: SnapColors.accentGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Real-Time Synchronization',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Last sync: ${_formatTimeAgo(_lastSync)}',
                style: TextStyle(color: SnapColors.textSecondary, fontSize: 10),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Cross-device synchronization with conflict resolution and offline support.',
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 14,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 16),

          // Sync features
          Column(
            children: _syncFeatures
                .map((feature) => _buildSyncFeature(feature))
                .toList(),
          ),

          const SizedBox(height: 16),

          // Sync stats
          Row(
            children: [
              Expanded(
                child: _buildSyncStat(
                  'Sync Events',
                  '$_syncEvents',
                  'This session',
                  Icons.sync_alt,
                  SnapColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSyncStat(
                  'Success Rate',
                  '99.8%',
                  'Last 30 days',
                  Icons.check_circle,
                  SnapColors.accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSyncStat(
                  'Avg Latency',
                  '156ms',
                  'Global average',
                  Icons.speed,
                  SnapColors.accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncFeature(Map<String, dynamic> feature) {
    final isActive = feature['isActive'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive
            ? (feature['color'] as Color).withValues(alpha: 0.1)
            : SnapColors.textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? (feature['color'] as Color).withValues(alpha: 0.3)
              : SnapColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Icon(
                feature['icon'] as IconData,
                color: isActive
                    ? feature['color'] as Color
                    : SnapColors.textSecondary,
                size: 20,
              ),
              if (isActive)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: SnapColors.accentGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      feature['feature'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: SnapColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      feature['latency'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? feature['color'] as Color
                            : SnapColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  feature['description'] as String,
                  style: TextStyle(
                    color: SnapColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStat(
    String label,
    String value,
    String subtitle,
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
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SnapColors.textPrimary,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 9,
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

  Widget _buildTechnicalArchitecture() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SnapColors.accentBlue.withValues(alpha: 0.1),
            SnapColors.accentPurple.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.architecture, color: SnapColors.accentBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Technical Excellence',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            'Built with Flutter for native performance and Firebase for scalable real-time infrastructure.',
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 14,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildTechPoint(
                  'Flutter',
                  'Native performance',
                  Icons.flutter_dash,
                  SnapColors.accentBlue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTechPoint(
                  'Firebase',
                  'Real-time sync',
                  Icons.cloud,
                  SnapColors.accentGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTechPoint(
                  'AI/ML',
                  'Smart features',
                  Icons.psychology,
                  SnapColors.accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTechPoint(
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
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SnapColors.textPrimary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
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

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}
