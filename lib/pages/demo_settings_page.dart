import 'package:flutter/material.dart';
import '../services/demo_reset_service.dart';
import '../services/demo_session_service.dart';
import '../services/demo_tour_service.dart';
import '../widgets/demo_mode_indicator.dart';
import '../models/demo_config.dart';
import '../utils/logger.dart';

/// Demo settings page for managing demo features and reset functionality
class DemoSettingsPage extends StatefulWidget {
  const DemoSettingsPage({super.key});

  @override
  State<DemoSettingsPage> createState() => _DemoSettingsPageState();
}

class _DemoSettingsPageState extends State<DemoSettingsPage> {
  bool _isLoading = false;
  Map<String, int>? _dataStats;
  Map<String, dynamic>? _sessionStats;
  Map<String, dynamic>? _analyticsStats;
  DemoConfig? _currentConfig;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);

    try {
      final stats = await DemoResetService.getDemoDataStats();
      final sessionStats = DemoSessionService.instance.getSessionStats();
      final analyticsStats = DemoSessionService.instance.getAnalyticsSummary();
      final config = DemoSessionService.instance.currentConfig;

      setState(() {
        _dataStats = stats;
        _sessionStats = sessionStats;
        _analyticsStats = analyticsStats;
        _currentConfig = config;
      });
    } catch (e) {
      Logger.d('Error loading demo stats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetDemoData() async {
    final confirmed = await _showConfirmationDialog(
      'Reset Demo Data',
      'This will reset all demo data to its original state. Your demo session will be restarted. Continue?',
    );

    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      // Reset demo data
      final success = await DemoResetService.resetCurrentUserDemoData();

      if (success) {
        // Reset session
        await DemoSessionService.instance.resetSession();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Demo data reset successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reload stats
        await _loadStats();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Failed to reset demo data'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showDemoTour() async {
    await DemoTourService.showMainTour(context);
  }

  Future<void> _exportAnalytics() async {
    final analytics = DemoSessionService.instance.exportAnalytics();

    // In a real app, you would export this data to a file or send it somewhere
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics Export'),
        content: Text(
          'Exported ${analytics.length} analytics events.\n\nIn a production app, this would save to a file or send to analytics service.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Settings'),
        actions: const [CompactDemoIndicator(), SizedBox(width: 16)],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Demo status section
                _buildDemoStatusSection(),
                const SizedBox(height: 24),

                // Session info section
                _buildSessionInfoSection(),
                const SizedBox(height: 24),

                // Data statistics section
                _buildDataStatsSection(),
                const SizedBox(height: 24),

                // Analytics section
                _buildAnalyticsSection(),
                const SizedBox(height: 24),

                // Actions section
                _buildActionsSection(),
              ],
            ),
    );
  }

  Widget _buildDemoStatusSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Demo Status',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            const DemoBannerIndicator(
              message: 'Demo mode is active - All features are available',
            ),
            const SizedBox(height: 12),
            if (_currentConfig != null) ...[
              Text(
                'Configuration: ${_getConfigName(_currentConfig!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_currentConfig!.enableTours)
                    const Chip(label: Text('Tours')),
                  if (_currentConfig!.enableTooltips)
                    const Chip(label: Text('Tooltips')),
                  if (_currentConfig!.enableAnalytics)
                    const Chip(label: Text('Analytics')),
                  if (_currentConfig!.enableReset)
                    const Chip(label: Text('Reset')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoSection() {
    if (_sessionStats == null || _sessionStats!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Session',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Session ID', _sessionStats!['sessionId'] ?? 'N/A'),
            _buildInfoRow('Persona', _sessionStats!['personaId'] ?? 'N/A'),
            _buildInfoRow(
              'Duration',
              '${_sessionStats!['duration'] ?? 0} minutes',
            ),
            _buildInfoRow(
              'Status',
              _sessionStats!['isActive'] == true ? 'Active' : 'Ended',
            ),
            _buildInfoRow(
              'Events Tracked',
              '${_sessionStats!['analyticsEvents'] ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStatsSection() {
    if (_dataStats == null || _dataStats!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Demo Data', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              const Text(
                'No demo data found. This is normal if you haven\'t seeded data yet.',
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Demo Data Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ..._dataStats!.entries.map((entry) {
              return _buildInfoRow(entry.key, entry.value.toString());
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    if (_analyticsStats == null || _analyticsStats!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Total Events',
              '${_analyticsStats!['totalEvents'] ?? 0}',
            ),
            _buildInfoRow(
              'Sessions',
              '${_analyticsStats!['sessionCount'] ?? 0}',
            ),
            const SizedBox(height: 8),
            if (_analyticsStats!['featureInteractions'] != null) ...[
              Text(
                'Feature Interactions:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              ...(_analyticsStats!['featureInteractions']
                      as Map<String, dynamic>)
                  .entries
                  .map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: _buildInfoRow(entry.key, '${entry.value}'),
                    );
                  }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Show demo tour
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showDemoTour,
                icon: const Icon(Icons.tour_outlined),
                label: const Text('Show Demo Tour'),
              ),
            ),
            const SizedBox(height: 8),

            // Export analytics
            if (_currentConfig?.enableAnalytics == true) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _exportAnalytics,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('Export Analytics'),
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Reset demo data
            if (_currentConfig?.enableReset == true) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resetDemoData,
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Reset Demo Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  String _getConfigName(DemoConfig config) {
    if (config == DemoConfig.investor) return 'Investor Demo';
    if (config == DemoConfig.userTesting) return 'User Testing';
    if (config == DemoConfig.development) return 'Development';
    if (config == DemoConfig.disabled) return 'Disabled';
    return 'Custom';
  }
}
