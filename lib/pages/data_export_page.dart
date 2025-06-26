import 'package:flutter/material.dart';
import '../design_system/snap_ui.dart';
import '../services/data_export_service.dart';
import '../services/auth_service.dart';

class DataExportPage extends StatefulWidget {
  const DataExportPage({super.key});

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  final DataExportService _exportService = DataExportService();
  final AuthService _authService = AuthService();
  
  // Export options
  ExportFormat _selectedFormat = ExportFormat.json;
  Set<ExportDataType> _selectedDataTypes = {ExportDataType.all};
  DateTime? _startDate;
  DateTime? _endDate;
  bool _includePersonalInfo = true;
  bool _includeImages = false;
  bool _anonymizeData = false;
  
  // UI state
  bool _isLoading = false;
  bool _isExporting = false;
  Map<String, int> _exportStats = {};
  String? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadExportStats();
  }

  Future<void> _loadExportStats() async {
    setState(() => _isLoading = true);
    
    try {
      final user = _authService.getCurrentUser();
      if (user != null) {
        final stats = await _exportService.getExportStatistics(user.uid);
        setState(() {
          _exportStats = stats;
        });
      }
    } catch (e) {
      debugPrint('Error loading export stats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportData() async {
    if (_selectedDataTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one data type')),
      );
      return;
    }

    setState(() => _isExporting = true);

    try {
      final options = ExportOptions(
        format: _selectedFormat,
        dataTypes: _selectedDataTypes.toList(),
        startDate: _startDate,
        endDate: _endDate,
        includePersonalInfo: _includePersonalInfo,
        includeImages: _includeImages,
        anonymizeData: _anonymizeData,
      );

      final result = await _exportService.exportData(options);
      
      if (mounted) {
        await _showExportSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _showExportSuccessDialog(ExportResult result) async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File: ${result.fileName}'),
            const SizedBox(height: 8),
            Text('Records: ${result.recordCount}'),
            const SizedBox(height: 8),
            Text('Size: ${result.fileSizeKB.toStringAsFixed(1)} KB'),
            const SizedBox(height: 16),
            const Text('Would you like to share the file?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _exportService.shareExportedFile(result);
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _selectDateRange(Map<String, dynamic> preset) {
    setState(() {
      _selectedDateRange = preset['label'];
      _startDate = preset['startDate'];
      _endDate = preset['endDate'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
        backgroundColor: SnapColors.surface,
        foregroundColor: SnapColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildExportStats(),
                  const SizedBox(height: 24),
                  _buildFormatSelection(),
                  const SizedBox(height: 24),
                  _buildDataTypeSelection(),
                  const SizedBox(height: 24),
                  _buildDateRangeSelection(),
                  const SizedBox(height: 24),
                  _buildPrivacyOptions(),
                  const SizedBox(height: 32),
                  _buildExportButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildExportStats() {
    if (_exportStats.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: SnapColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Your Data Overview',
                  style: SnapTypography.heading.copyWith(fontSize: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatChip('Meals', _exportStats['mealLogs'] ?? 0, Icons.restaurant),
                _buildStatChip('Fasting', _exportStats['fastingSessions'] ?? 0, Icons.timer),
                _buildStatChip('AI Advice', _exportStats['aiAdvice'] ?? 0, Icons.psychology),
                _buildStatChip('Integrations', _exportStats['integrations'] ?? 0, Icons.link),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: SnapColors.primary),
      label: Text('$label: $count'),
      backgroundColor: SnapColors.primary.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: SnapColors.primary, fontSize: 12),
    );
  }

  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export Format',
          style: SnapTypography.heading.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildFormatCard(
                ExportFormat.json,
                'JSON',
                'Structured data format, best for developers',
                Icons.code,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormatCard(
                ExportFormat.csv,
                'CSV',
                'Spreadsheet format, best for analysis',
                Icons.table_chart,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormatCard(ExportFormat format, String title, String description, IconData icon) {
    final isSelected = _selectedFormat == format;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = format),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? SnapColors.primary : SnapColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? SnapColors.primary.withValues(alpha: 0.05) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? SnapColors.primary : SnapColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: SnapTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? SnapColors.primary : SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: SnapTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data to Export',
          style: SnapTypography.heading.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        _buildDataTypeCheckbox(
          ExportDataType.all,
          'All Data',
          'Export everything',
          Icons.select_all,
        ),
        const Divider(height: 24),
        _buildDataTypeCheckbox(
          ExportDataType.mealLogs,
          'Meal Logs',
          'Food photos, nutrition data, meal history',
          Icons.restaurant,
        ),
        _buildDataTypeCheckbox(
          ExportDataType.fastingSessions,
          'Fasting Sessions',
          'Fasting timers, goals, completion history',
          Icons.timer,
        ),
        _buildDataTypeCheckbox(
          ExportDataType.healthProfile,
          'Health Profile',
          'Personal health goals and preferences',
          Icons.person,
        ),
        _buildDataTypeCheckbox(
          ExportDataType.aiAdvice,
          'AI Advice',
          'Personalized recommendations and tips',
          Icons.psychology,
        ),
        _buildDataTypeCheckbox(
          ExportDataType.integrations,
          'Integrations',
          'Connected health apps and sync data',
          Icons.link,
        ),
      ],
    );
  }

  Widget _buildDataTypeCheckbox(ExportDataType dataType, String title, String description, IconData icon) {
    final isSelected = _selectedDataTypes.contains(dataType);
    final isAllSelected = _selectedDataTypes.contains(ExportDataType.all);
    
    return CheckboxListTile(
      value: isSelected || (dataType != ExportDataType.all && isAllSelected),
      onChanged: (value) {
        setState(() {
          if (dataType == ExportDataType.all) {
            if (value == true) {
              _selectedDataTypes = {ExportDataType.all};
            } else {
              _selectedDataTypes.remove(ExportDataType.all);
            }
          } else {
            _selectedDataTypes.remove(ExportDataType.all);
            if (value == true) {
              _selectedDataTypes.add(dataType);
            } else {
              _selectedDataTypes.remove(dataType);
            }
          }
        });
      },
      title: Row(
        children: [
          Icon(icon, size: 20, color: SnapColors.primary),
          const SizedBox(width: 8),
          Text(title, style: SnapTypography.body),
        ],
      ),
      subtitle: Text(description, style: SnapTypography.caption),
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildDateRangeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: SnapTypography.heading.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _exportService.getDateRangePresets().map((preset) {
            final isSelected = _selectedDateRange == preset['label'];
            return FilterChip(
              label: Text(preset['label']),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _selectDateRange(preset);
                }
              },
              backgroundColor: SnapColors.surface,
              selectedColor: SnapColors.primary.withValues(alpha: 0.2),
            );
          }).toList(),
        ),
        if (_startDate != null || _endDate != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SnapColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SnapColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, color: SnapColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatDateRange(),
                  style: SnapTypography.caption.copyWith(color: SnapColors.primary),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacyOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy Options',
          style: SnapTypography.heading.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Include Personal Information'),
          subtitle: const Text('Age, weight, health conditions, etc.'),
          value: _includePersonalInfo,
          onChanged: (value) => setState(() => _includePersonalInfo = value),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Include Images'),
          subtitle: const Text('Food photos and meal images'),
          value: _includeImages,
          onChanged: (value) => setState(() => _includeImages = value),
          contentPadding: EdgeInsets.zero,
        ),
        SwitchListTile(
          title: const Text('Anonymize Data'),
          subtitle: const Text('Remove identifying information'),
          value: _anonymizeData,
          onChanged: (value) => setState(() => _anonymizeData = value),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: SnapButton(
        text: _isExporting ? 'Exporting...' : 'Export Data',
        onTap: _isExporting ? null : _exportData,
      ),
    );
  }

  String _formatDateRange() {
    if (_startDate == null && _endDate == null) {
      return 'All time';
    } else if (_startDate != null && _endDate != null) {
      return '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}';
    } else if (_startDate != null) {
      return 'From ${_formatDate(_startDate!)}';
    } else {
      return 'Until ${_formatDate(_endDate!)}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 