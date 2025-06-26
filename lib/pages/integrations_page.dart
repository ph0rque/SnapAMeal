import 'package:flutter/material.dart';
import '../design_system/snap_ui.dart';
import '../services/health_integration_service.dart';
import '../models/health_integration.dart';
import '../services/auth_service.dart';
import 'data_export_page.dart';
import 'data_conflicts_page.dart';

class IntegrationsPage extends StatefulWidget {
  const IntegrationsPage({super.key});

  @override
  State<IntegrationsPage> createState() => _IntegrationsPageState();
}

class _IntegrationsPageState extends State<IntegrationsPage> with TickerProviderStateMixin {
  final HealthIntegrationService _integrationService = HealthIntegrationService();
  final AuthService _authService = AuthService();
  
  late TabController _tabController;
  bool _isLoading = false;
  String? _currentUserId;
  List<HealthIntegration> _integrations = [];
  Map<String, bool> _connectionStatus = {};
  Map<String, DateTime?> _lastSyncTimes = {};
  
  // Integration categories
  final List<String> _categories = ['All', 'Fitness', 'Nutrition', 'Wellness', 'Medical'];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    
    try {
      _currentUserId = _authService.getCurrentUser()?.uid;
      if (_currentUserId != null) {
        await _loadIntegrations();
        await _checkConnectionStatuses();
      }
    } catch (e) {
      debugPrint('Error initializing integrations data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadIntegrations() async {
    if (_currentUserId == null) return;
    
    try {
      // Get user's existing integrations
      final userIntegrations = await _integrationService.getUserIntegrations().first;
      
      // Get all available integrations (including ones not yet connected)
      final allAvailableIntegrations = _getAllAvailableIntegrations();
      
      // Merge existing with available ones
      final integrationsMap = <String, HealthIntegration>{};
      
      // Add existing integrations
      for (final integration in userIntegrations) {
        integrationsMap[integration.id] = integration;
      }
      
      // Add available integrations that user hasn't connected yet
      for (final availableIntegration in allAvailableIntegrations) {
        if (!integrationsMap.containsKey(availableIntegration.id)) {
          integrationsMap[availableIntegration.id] = availableIntegration;
        }
      }
      
      setState(() {
        _integrations = integrationsMap.values.toList();
      });
    } catch (e) {
      debugPrint('Error loading integrations: $e');
    }
  }

  /// Get all available integrations including ones not yet connected
  List<HealthIntegration> _getAllAvailableIntegrations() {
    if (_currentUserId == null) return [];
    
    return [
      // MyFitnessPal - Coming Soon
      HealthIntegration(
        id: '${_currentUserId}_myfitnesspal',
        userId: _currentUserId!,
        type: IntegrationType.myFitnessPal,
        status: IntegrationStatus.disconnected,
        connectedAt: DateTime.now(),
        settings: {'coming_soon': true},
      ),
      // Apple Health - Coming Soon  
      HealthIntegration(
        id: '${_currentUserId}_applehealth',
        userId: _currentUserId!,
        type: IntegrationType.appleHealth,
        status: IntegrationStatus.disconnected,
        connectedAt: DateTime.now(),
        settings: {'coming_soon': true},
      ),
      // Google Fit - Available for connection
      HealthIntegration(
        id: '${_currentUserId}_googlefit',
        userId: _currentUserId!,
        type: IntegrationType.googleFit,
        status: IntegrationStatus.disconnected,
        connectedAt: DateTime.now(),
        settings: {},
      ),
    ];
  }

  Future<void> _checkConnectionStatuses() async {
    final Map<String, bool> statuses = {};
    final Map<String, DateTime?> syncTimes = {};
    
    for (final integration in _integrations) {
      try {
        final isConnected = await _integrationService.checkConnectionStatus(integration.id);
        final lastSync = await _integrationService.getLastSyncTime(integration.id);
        
        statuses[integration.id] = isConnected;
        syncTimes[integration.id] = lastSync;
      } catch (e) {
        statuses[integration.id] = false;
        syncTimes[integration.id] = null;
      }
    }
    
    setState(() {
      _connectionStatus = statuses;
      _lastSyncTimes = syncTimes;
    });
  }

  Future<void> _connectIntegration(String integrationId) async {
    // Check if this is a "coming soon" integration
    final integration = _integrations.firstWhere(
      (i) => i.id == integrationId,
      orElse: () => HealthIntegration(
        id: integrationId,
        userId: _currentUserId ?? '',
        type: IntegrationType.googleFit,
        status: IntegrationStatus.disconnected,
        connectedAt: DateTime.now(),
        settings: {},
      ),
    );
    
    if (integration.settings['coming_soon'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapSnackBar.error('${integration.typeName} integration is coming soon! We\'re working on getting the necessary permissions.'),
        );
      }
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await _integrationService.connectIntegration(integrationId);
      await _checkConnectionStatuses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapSnackBar.success('Successfully connected to ${_getIntegrationName(integrationId)}'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapSnackBar.error('Failed to connect: ${e.toString()}'),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnectIntegration(String integrationId) async {
    final confirmed = await _showDisconnectDialog(integrationId);
    if (!confirmed) return;
    
    setState(() => _isLoading = true);
    
    try {
      await _integrationService.disconnectIntegration(integrationId);
      await _checkConnectionStatuses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapSnackBar.success('Disconnected from ${_getIntegrationName(integrationId)}'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapSnackBar.error('Failed to disconnect: ${e.toString()}'),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _syncIntegration(String integrationId) async {
    setState(() => _isLoading = true);
    
    try {
      await _integrationService.syncIntegrationData(integrationId);
      await _checkConnectionStatuses();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapSnackBar.success('${_getIntegrationName(integrationId)} synced successfully'),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnapSnackBar.error('Sync failed: ${e.toString()}'),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showDisconnectDialog(String integrationId) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect ${_getIntegrationName(integrationId)}?'),
        content: const Text(
          'This will stop syncing data and remove access permissions. You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: SnapColors.error),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    ) ?? false;
  }

  String _getIntegrationName(String integrationId) {
    final integration = _integrations.firstWhere(
      (i) => i.id == integrationId,
      orElse: () => HealthIntegration(
        id: integrationId,
        userId: _currentUserId ?? '',
        type: IntegrationType.myFitnessPal,
        status: IntegrationStatus.disconnected,
        connectedAt: DateTime.now(),
        settings: {},
      ),
    );
    return integration.typeName;
  }

  List<HealthIntegration> get _filteredIntegrations {
    if (_selectedCategory == 'All') return _integrations;
    
    return _integrations.where((integration) {
      switch (_selectedCategory) {
        case 'Fitness':
          return integration.type == IntegrationType.googleFit || 
                 integration.type == IntegrationType.appleHealth;
        case 'Nutrition':
          return integration.type == IntegrationType.myFitnessPal;
        case 'Wellness':
          return integration.type == IntegrationType.appleHealth;
        case 'Medical':
          return integration.type == IntegrationType.appleHealth;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Check if this page was accessed via settings route
    final route = ModalRoute.of(context);
    final isSettingsRoute = route?.settings.name == '/settings';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isSettingsRoute ? 'Settings' : 'Health Integrations'),
        backgroundColor: SnapColors.surface,
        foregroundColor: SnapColors.textPrimary,
        elevation: 0,
        automaticallyImplyLeading: true, // Ensure back button is shown
        leading: Navigator.canPop(context) 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back',
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.warning_amber),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DataConflictsPage(),
                ),
              );
            },
            tooltip: 'Data Conflicts',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Connected'),
            Tab(text: 'Available'),
            Tab(text: 'Settings'),
          ],
          labelColor: SnapColors.primary,
          unselectedLabelColor: SnapColors.textSecondary,
          indicatorColor: SnapColors.primary,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildConnectedTab(),
                _buildAvailableTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildConnectedTab() {
    final connectedIntegrations = _filteredIntegrations
        .where((integration) => _connectionStatus[integration.id] == true)
        .toList();

    if (connectedIntegrations.isEmpty) {
      return _buildEmptyState(
        icon: Icons.link_off,
        title: 'No Connected Apps',
        subtitle: 'Connect health apps to sync your data automatically',
        actionText: 'Browse Available Apps',
        onAction: () => _tabController.animateTo(1),
      );
    }

    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: connectedIntegrations.length,
            itemBuilder: (context, index) {
              final integration = connectedIntegrations[index];
              return _buildConnectedIntegrationCard(integration);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableTab() {
    final availableIntegrations = _filteredIntegrations
        .where((integration) => _connectionStatus[integration.id] != true)
        .toList();

    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: availableIntegrations.length,
            itemBuilder: (context, index) {
              final integration = availableIntegrations[index];
              return _buildAvailableIntegrationCard(integration);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSettingsSection(
          'Data Sync',
          [
            _buildSettingsTile(
              'Auto Sync',
              'Automatically sync data when app opens',
              Icons.sync,
              trailing: Switch(
                value: true,
                onChanged: (value) {
                  // TODO: Implement auto sync setting
                },
              ),
            ),
            _buildSettingsTile(
              'Sync Frequency',
              'Every 4 hours',
              Icons.schedule,
              onTap: () {
                // TODO: Show sync frequency dialog
              },
            ),
            _buildSettingsTile(
              'Background Sync',
              'Sync data in background',
              Icons.cloud_sync,
              trailing: Switch(
                value: false,
                onChanged: (value) {
                  // TODO: Implement background sync setting
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsSection(
          'Privacy & Permissions',
          [
            _buildSettingsTile(
              'Data Sharing',
              'Manage what data is shared',
              Icons.share,
              onTap: () {
                // TODO: Show data sharing settings
              },
            ),
            _buildSettingsTile(
              'Permission Manager',
              'Review app permissions',
              Icons.security,
              onTap: () {
                // TODO: Show permission manager
              },
            ),
            _buildSettingsTile(
              'Data Retention',
              'Control how long data is kept',
              Icons.history,
              onTap: () {
                // TODO: Show data retention settings
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildSettingsSection(
          'Advanced',
          [
            _buildSettingsTile(
              'Export Data',
              'Download your health data',
              Icons.download,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataExportPage(),
                  ),
                );
              },
            ),
            _buildSettingsTile(
              'Reset Connections',
              'Disconnect all integrations',
              Icons.restore,
              onTap: () {
                // TODO: Show reset confirmation
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: SnapColors.surface,
              selectedColor: SnapColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? SnapColors.primary : SnapColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectedIntegrationCard(HealthIntegration integration) {
    final lastSync = _lastSyncTimes[integration.id];
    final isConnected = _connectionStatus[integration.id] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildIntegrationIcon(integration.type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        integration.typeName,
                        style: SnapTypography.heading.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isConnected ? Icons.check_circle : Icons.error_outline,
                            size: 16,
                            color: isConnected ? SnapColors.success : SnapColors.error,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isConnected ? 'Connected' : 'Connection Error',
                            style: SnapTypography.body.copyWith(
                              color: isConnected ? SnapColors.success : SnapColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'sync':
                        _syncIntegration(integration.id);
                        break;
                      case 'settings':
                        // TODO: Show integration settings
                        break;
                      case 'disconnect':
                        _disconnectIntegration(integration.id);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'sync',
                      child: Row(
                        children: [
                          Icon(Icons.sync),
                          SizedBox(width: 8),
                          Text('Sync Now'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings),
                          SizedBox(width: 8),
                          Text('Settings'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'disconnect',
                      child: Row(
                        children: [
                          Icon(Icons.link_off, color: SnapColors.error),
                          SizedBox(width: 8),
                          Text('Disconnect', style: TextStyle(color: SnapColors.error)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (lastSync != null) ...[
              Text(
                'Last synced: ${_formatDateTime(lastSync)}',
                style: SnapTypography.caption,
              ),
              const SizedBox(height: 8),
            ],
            // _buildPermissionChips(integration.permissions), // Permissions not available in model
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableIntegrationCard(HealthIntegration integration) {
    final isComingSoon = integration.settings['coming_soon'] == true;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildIntegrationIcon(integration.type),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        integration.typeName,
                        style: SnapTypography.heading.copyWith(fontSize: 16),
                      ),
                      if (isComingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: SnapColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Coming Soon',
                            style: SnapTypography.caption.copyWith(
                              color: SnapColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isComingSoon 
                        ? _getComingSoonDescription(integration.type)
                        : _getIntegrationDescription(integration.type),
                    style: SnapTypography.body.copyWith(
                      color: SnapColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isComingSoon)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: SnapColors.textSecondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Coming Soon',
                  style: SnapTypography.body.copyWith(
                    color: SnapColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              )
            else
              SnapButton(
                text: 'Connect',
                onTap: () => _connectIntegration(integration.id),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationIcon(IntegrationType type) {
    IconData iconData;
    Color color;
    
    switch (type) {
      case IntegrationType.myFitnessPal:
        iconData = Icons.restaurant;
        color = SnapColors.success;
        break;
      case IntegrationType.appleHealth:
        iconData = Icons.favorite;
        color = SnapColors.error;
        break;
      case IntegrationType.googleFit:
        iconData = Icons.fitness_center;
        color = SnapColors.primary;
        break;
    }
    
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: color,
        size: 24,
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: SnapTypography.heading.copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildSettingsTile(
    String title,
    String subtitle,
    IconData icon, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: SnapColors.primary),
      title: Text(title, style: SnapTypography.body),
      subtitle: Text(subtitle, style: SnapTypography.caption),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: SnapColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: SnapTypography.heading,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: SnapTypography.body.copyWith(color: SnapColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              SnapButton(
                text: actionText,
                onTap: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getIntegrationDescription(IntegrationType type) {
    switch (type) {
      case IntegrationType.myFitnessPal:
        return 'Log meals, calories, and nutrition information';
      case IntegrationType.appleHealth:
        return 'Sync health data from Apple Health app';
      case IntegrationType.googleFit:
        return 'Track workouts, steps, and activity data';
    }
  }

  String _getComingSoonDescription(IntegrationType type) {
    switch (type) {
      case IntegrationType.myFitnessPal:
        return 'MyFitnessPal integration requires special API permissions. We\'re working on getting access!';
      case IntegrationType.appleHealth:
        return 'Apple Health integration requires special permissions and review. Coming soon!';
      case IntegrationType.googleFit:
        return 'Track workouts, steps, and activity data';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

// Extension for SnackBar convenience
extension SnapSnackBar on ScaffoldMessenger {
  static SnackBar success(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: SnapColors.success,
      behavior: SnackBarBehavior.floating,
    );
  }
  
  static SnackBar error(String message) {
    return SnackBar(
      content: Text(message),
      backgroundColor: SnapColors.error,
      behavior: SnackBarBehavior.floating,
    );
  }
} 