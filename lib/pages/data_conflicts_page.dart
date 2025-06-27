import 'package:flutter/material.dart';
import '../design_system/snap_ui.dart';
import '../services/data_conflict_resolution_service.dart';
import '../services/health_integration_service.dart';
// Removed unnecessary import - already provided by snap_ui.dart

class DataConflictsPage extends StatefulWidget {
  const DataConflictsPage({super.key});

  @override
  State<DataConflictsPage> createState() => _DataConflictsPageState();
}

class _DataConflictsPageState extends State<DataConflictsPage>
    with TickerProviderStateMixin {
  final HealthIntegrationService _healthService = HealthIntegrationService();
  late TabController _tabController;

  List<DataConflict> _conflicts = [];
  Map<String, int> _statistics = {};
  bool _isLoading = true;
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conflicts = await _healthService.getDataConflicts();
      final stats = await _healthService.getConflictStatistics();

      setState(() {
        _conflicts = conflicts;
        _statistics = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading conflicts: $e');
    }
  }

  Future<void> _resolveConflict(
    DataConflict conflict,
    ConflictResolutionStrategy strategy, {
    String? selectedSourceId,
    Map<String, dynamic>? mergedData,
  }) async {
    setState(() {
      _isResolving = true;
    });

    try {
      final success = await _healthService.resolveDataConflict(
        conflictId: conflict.id,
        strategy: strategy,
        selectedSourceId: selectedSourceId,
        mergedData: mergedData,
      );

      if (success) {
        _showSuccessSnackBar('Conflict resolved successfully');
        await _loadData(); // Refresh data
      } else {
        _showErrorSnackBar('Failed to resolve conflict');
      }
    } catch (e) {
      _showErrorSnackBar('Error resolving conflict: $e');
    } finally {
      setState(() {
        _isResolving = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: SnapColors.backgroundPrimary,
        elevation: 0,
        title: Text(
          'Data Conflicts',
          style: SnapTypography.heading2.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: SnapColors.textPrimary),
            onPressed: _isLoading ? null : _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: SnapColors.primaryYellow,
          unselectedLabelColor: SnapColors.textSecondary,
          indicatorColor: SnapColors.primaryYellow,
          tabs: const [
            Tab(text: 'Conflicts'),
            Tab(text: 'Statistics'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConflictsTab(),
                _buildStatisticsTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildConflictsTab() {
    if (_conflicts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: SnapColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No Data Conflicts',
              style: SnapTypography.heading3.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All your health data is synchronized without conflicts.',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _conflicts.length,
      itemBuilder: (context, index) {
        final conflict = _conflicts[index];
        return _buildConflictCard(conflict);
      },
    );
  }

  Widget _buildConflictCard(DataConflict conflict) {
    return Card(
      color: SnapColors.backgroundSecondary,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildConflictTypeIcon(conflict.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getConflictTitle(conflict),
                        style: SnapTypography.heading4.copyWith(
                          color: SnapColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDateTime(conflict.timestamp),
                        style: SnapTypography.caption.copyWith(
                          color: SnapColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildConflictPriorityBadge(conflict),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _getConflictDescription(conflict),
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _buildConflictingDataSection(conflict),
            const SizedBox(height: 16),
            if (conflict.suggestedResolution != null)
              _buildSuggestedResolution(conflict),
            const SizedBox(height: 16),
            _buildResolutionActions(conflict),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictTypeIcon(ConflictType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case ConflictType.duplicateEntry:
        iconData = Icons.content_copy;
        iconColor = Colors.orange;
        break;
      case ConflictType.valueDiscrepancy:
        iconData = Icons.compare_arrows;
        iconColor = Colors.red;
        break;
      case ConflictType.timestampOverlap:
        iconData = Icons.schedule;
        iconColor = Colors.blue;
        break;
      case ConflictType.sourceConflict:
        iconData = Icons.source;
        iconColor = Colors.purple;
        break;
      case ConflictType.dataTypeConflict:
        iconData = Icons.category;
        iconColor = Colors.teal;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildConflictPriorityBadge(DataConflict conflict) {
    final priority = _getConflictPriority(conflict);
    Color badgeColor;
    String priorityText;

    switch (priority) {
      case 'High':
        badgeColor = Colors.red;
        priorityText = 'HIGH';
        break;
      case 'Medium':
        badgeColor = Colors.orange;
        priorityText = 'MED';
        break;
      case 'Low':
        badgeColor = Colors.green;
        priorityText = 'LOW';
        break;
      default:
        badgeColor = Colors.grey;
        priorityText = 'N/A';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        priorityText,
        style: SnapTypography.caption.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildConflictingDataSection(DataConflict conflict) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conflicting Data Sources:',
          style: SnapTypography.body.copyWith(
            color: SnapColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...conflict.conflictingData.map((data) => _buildDataSourceCard(data)),
      ],
    );
  }

  Widget _buildDataSourceCard(ConflictingData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SnapColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDataSourceIcon(data.source),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getDataSourceName(data.source),
                  style: SnapTypography.body.copyWith(
                    color: SnapColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _buildConfidenceIndicator(data.confidence),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last Updated: ${_formatDateTime(data.lastUpdated)}',
            style: SnapTypography.caption.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Priority: ${data.priority}',
            style: SnapTypography.caption.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSourceIcon(DataSource source) {
    IconData iconData;
    Color iconColor;

    switch (source) {
      case DataSource.manual:
        iconData = Icons.edit;
        iconColor = SnapColors.primaryYellow;
        break;
      case DataSource.snapAMeal:
        iconData = Icons.camera_alt;
        iconColor = SnapColors.primaryYellow;
        break;
      case DataSource.myFitnessPal:
        iconData = Icons.restaurant;
        iconColor = Colors.blue;
        break;
      case DataSource.appleHealth:
        iconData = Icons.favorite;
        iconColor = Colors.red;
        break;
      case DataSource.googleFit:
        iconData = Icons.fitness_center;
        iconColor = Colors.green;
        break;
    }

    return Icon(iconData, color: iconColor, size: 20);
  }

  Widget _buildConfidenceIndicator(double confidence) {
    final percentage = (confidence * 100).round();
    Color indicatorColor;

    if (percentage >= 80) {
      indicatorColor = Colors.green;
    } else if (percentage >= 60) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$percentage%',
        style: SnapTypography.caption.copyWith(
          color: indicatorColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSuggestedResolution(DataConflict conflict) {
    final suggestion = conflict.suggestedResolution!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SnapColors.primaryYellow.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: SnapColors.primaryYellow.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: SnapColors.primaryYellow,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Suggested Resolution',
                  style: SnapTypography.body.copyWith(
                    color: SnapColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getResolutionDescription(suggestion),
                  style: SnapTypography.caption.copyWith(
                    color: SnapColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionActions(DataConflict conflict) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (conflict.suggestedResolution != null)
          SnapButton(
            text: 'Accept Suggestion',
            onTap: _isResolving
                ? null
                : () =>
                      _resolveConflict(conflict, conflict.suggestedResolution!),
          ),
        SnapButton(
          text: 'Keep Highest Priority',
          onTap: _isResolving
              ? null
              : () => _resolveConflict(
                  conflict,
                  ConflictResolutionStrategy.highestPriority,
                ),
        ),
        SnapButton(
          text: 'Keep Most Recent',
          onTap: _isResolving
              ? null
              : () => _resolveConflict(
                  conflict,
                  ConflictResolutionStrategy.mostRecent,
                ),
        ),
        SnapButton(
          text: 'Manual Choice',
          onTap: _isResolving
              ? null
              : () => _showManualResolutionDialog(conflict),
        ),
      ],
    );
  }

  void _showManualResolutionDialog(DataConflict conflict) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SnapColors.backgroundSecondary,
        title: Text(
          'Choose Data Source',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: conflict.conflictingData.map((data) {
            return ListTile(
              leading: _buildDataSourceIcon(data.source),
              title: Text(
                _getDataSourceName(data.source),
                style: SnapTypography.body.copyWith(
                  color: SnapColors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Confidence: ${(data.confidence * 100).round()}%',
                style: SnapTypography.caption.copyWith(
                  color: SnapColors.textSecondary,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _resolveConflict(
                  conflict,
                  ConflictResolutionStrategy.userChoice,
                  selectedSourceId: data.sourceId,
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: SnapColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_statistics.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard(
          'Total Conflicts',
          _statistics['total']?.toString() ?? '0',
          Icons.warning,
          Colors.orange,
        ),
        _buildStatCard(
          'Resolved',
          _statistics['resolved']?.toString() ?? '0',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Unresolved',
          _statistics['unresolved']?.toString() ?? '0',
          Icons.pending,
          Colors.red,
        ),
        const SizedBox(height: 24),
        Text(
          'Conflict Types',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          'Duplicate Entries',
          _statistics['duplicateEntry']?.toString() ?? '0',
          Icons.content_copy,
          Colors.orange,
        ),
        _buildStatCard(
          'Value Discrepancies',
          _statistics['valueDiscrepancy']?.toString() ?? '0',
          Icons.compare_arrows,
          Colors.red,
        ),
        _buildStatCard(
          'Timestamp Overlaps',
          _statistics['timestampOverlap']?.toString() ?? '0',
          Icons.schedule,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      color: SnapColors.backgroundSecondary,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SnapTypography.body.copyWith(
                      color: SnapColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: SnapTypography.heading2.copyWith(
                      color: SnapColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Conflict Resolution Settings',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: SnapColors.backgroundSecondary,
          child: Column(
            children: [
              SwitchListTile(
                title: Text(
                  'Auto-resolve duplicates',
                  style: SnapTypography.body.copyWith(
                    color: SnapColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Automatically resolve duplicate entries using highest priority source',
                  style: SnapTypography.caption.copyWith(
                    color: SnapColors.textSecondary,
                  ),
                ),
                value: true, // TODO: Connect to user settings
                onChanged: (value) {
                  // TODO: Update user settings
                },
                activeThumbColor: SnapColors.primaryYellow,
              ),
              const Divider(),
              SwitchListTile(
                title: Text(
                  'Notify on conflicts',
                  style: SnapTypography.body.copyWith(
                    color: SnapColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Get notified when data conflicts are detected',
                  style: SnapTypography.caption.copyWith(
                    color: SnapColors.textSecondary,
                  ),
                ),
                value: true, // TODO: Connect to user settings
                onChanged: (value) {
                  // TODO: Update user settings
                },
                activeThumbColor: SnapColors.primaryYellow,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Data Source Priorities',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: SnapColors.backgroundSecondary,
          child: Column(
            children: [
              _buildPriorityItem('Manual Entry', DataSource.manual, 100),
              _buildPriorityItem('SnapAMeal', DataSource.snapAMeal, 90),
              _buildPriorityItem('MyFitnessPal', DataSource.myFitnessPal, 80),
              _buildPriorityItem('Apple Health', DataSource.appleHealth, 70),
              _buildPriorityItem('Google Fit', DataSource.googleFit, 60),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityItem(String name, DataSource source, int priority) {
    return ListTile(
      leading: _buildDataSourceIcon(source),
      title: Text(
        name,
        style: SnapTypography.body.copyWith(color: SnapColors.textPrimary),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: SnapColors.primaryYellow.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Priority: $priority',
          style: SnapTypography.caption.copyWith(
            color: SnapColors.primaryYellow,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Helper methods

  String _getConflictTitle(DataConflict conflict) {
    switch (conflict.type) {
      case ConflictType.duplicateEntry:
        return 'Duplicate ${conflict.dataType.toUpperCase()} Entry';
      case ConflictType.valueDiscrepancy:
        return '${conflict.dataType.toUpperCase()} Value Mismatch';
      case ConflictType.timestampOverlap:
        return '${conflict.dataType.toUpperCase()} Time Overlap';
      case ConflictType.sourceConflict:
        return '${conflict.dataType.toUpperCase()} Source Conflict';
      case ConflictType.dataTypeConflict:
        return 'Data Type Conflict';
    }
  }

  String _getConflictDescription(DataConflict conflict) {
    switch (conflict.type) {
      case ConflictType.duplicateEntry:
        return 'Multiple sources have recorded similar ${conflict.dataType} data for the same time period.';
      case ConflictType.valueDiscrepancy:
        return 'Different sources show significantly different values for the same ${conflict.dataType} measurement.';
      case ConflictType.timestampOverlap:
        return 'Multiple ${conflict.dataType} entries exist for overlapping time periods.';
      case ConflictType.sourceConflict:
        return 'Conflicting information from different data sources.';
      case ConflictType.dataTypeConflict:
        return 'Data type mismatch between sources.';
    }
  }

  String _getConflictPriority(DataConflict conflict) {
    switch (conflict.type) {
      case ConflictType.valueDiscrepancy:
        return 'High';
      case ConflictType.duplicateEntry:
        return 'Medium';
      case ConflictType.timestampOverlap:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String _getDataSourceName(DataSource source) {
    switch (source) {
      case DataSource.manual:
        return 'Manual Entry';
      case DataSource.snapAMeal:
        return 'SnapAMeal';
      case DataSource.myFitnessPal:
        return 'MyFitnessPal';
      case DataSource.appleHealth:
        return 'Apple Health';
      case DataSource.googleFit:
        return 'Google Fit';
    }
  }

  String _getResolutionDescription(ConflictResolutionStrategy strategy) {
    switch (strategy) {
      case ConflictResolutionStrategy.mostRecent:
        return 'Keep the most recently updated data';
      case ConflictResolutionStrategy.highestPriority:
        return 'Keep data from the highest priority source';
      case ConflictResolutionStrategy.mostAccurate:
        return 'Keep the most accurate/confident data';
      case ConflictResolutionStrategy.userChoice:
        return 'Let you choose which data to keep';
      case ConflictResolutionStrategy.merge:
        return 'Combine data from multiple sources';
      case ConflictResolutionStrategy.keepAll:
        return 'Keep all conflicting data';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
