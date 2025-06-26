import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

enum ExportFormat { csv, json }

enum ExportDataType {
  mealLogs,
  fastingSessions,
  healthProfile,
  aiAdvice,
  integrations,
  all,
}

class ExportOptions {
  final ExportFormat format;
  final List<ExportDataType> dataTypes;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includePersonalInfo;
  final bool includeImages;
  final bool anonymizeData;

  const ExportOptions({
    required this.format,
    required this.dataTypes,
    this.startDate,
    this.endDate,
    this.includePersonalInfo = true,
    this.includeImages = false,
    this.anonymizeData = false,
  });
}

class ExportResult {
  final String filePath;
  final String fileName;
  final int recordCount;
  final double fileSizeKB;
  final DateTime exportedAt;

  const ExportResult({
    required this.filePath,
    required this.fileName,
    required this.recordCount,
    required this.fileSizeKB,
    required this.exportedAt,
  });
}

class DataExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  /// Export user data based on the provided options
  Future<ExportResult> exportData(ExportOptions options) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) {
        throw Exception('User not authenticated');
      }
      final userId = user.uid;

      debugPrint('Starting data export for user: $userId');
      debugPrint('Export options: ${options.format}, ${options.dataTypes}');

      final data = await _collectData(userId, options);
      final result = await _writeDataToFile(data, options);

      debugPrint('Export completed: ${result.fileName} (${result.recordCount} records)');
      return result;
    } catch (e) {
      debugPrint('Export failed: $e');
      rethrow;
    }
  }

  /// Collect data from Firestore based on export options
  Future<Map<String, dynamic>> _collectData(String userId, ExportOptions options) async {
    final Map<String, dynamic> exportData = {
      'exportInfo': {
        'userId': options.anonymizeData ? _anonymizeUserId(userId) : userId,
        'exportedAt': DateTime.now().toIso8601String(),
        'format': options.format.name,
        'dataTypes': options.dataTypes.map((e) => e.name).toList(),
        'dateRange': {
          'start': options.startDate?.toIso8601String(),
          'end': options.endDate?.toIso8601String(),
        },
        'includePersonalInfo': options.includePersonalInfo,
        'includeImages': options.includeImages,
        'anonymized': options.anonymizeData,
      },
    };

    int totalRecords = 0;

    for (final dataType in options.dataTypes) {
      switch (dataType) {
        case ExportDataType.mealLogs:
          final mealLogs = await _exportMealLogs(userId, options);
          exportData['mealLogs'] = mealLogs;
          totalRecords += mealLogs.length;
          break;

        case ExportDataType.fastingSessions:
          final fastingSessions = await _exportFastingSessions(userId, options);
          exportData['fastingSessions'] = fastingSessions;
          totalRecords += fastingSessions.length;
          break;

        case ExportDataType.healthProfile:
          final healthProfile = await _exportHealthProfile(userId, options);
          exportData['healthProfile'] = healthProfile;
          totalRecords += healthProfile != null ? 1 : 0;
          break;

        case ExportDataType.aiAdvice:
          final aiAdvice = await _exportAiAdvice(userId, options);
          exportData['aiAdvice'] = aiAdvice;
          totalRecords += aiAdvice.length;
          break;

        case ExportDataType.integrations:
          final integrations = await _exportIntegrations(userId, options);
          exportData['integrations'] = integrations;
          totalRecords += integrations.length;
          break;

        case ExportDataType.all:
          // Handle 'all' case by recursively calling with individual types
          final allTypes = [
            ExportDataType.mealLogs,
            ExportDataType.fastingSessions,
            ExportDataType.healthProfile,
            ExportDataType.aiAdvice,
            ExportDataType.integrations,
          ];
          final allOptions = ExportOptions(
            format: options.format,
            dataTypes: allTypes,
            startDate: options.startDate,
            endDate: options.endDate,
            includePersonalInfo: options.includePersonalInfo,
            includeImages: options.includeImages,
            anonymizeData: options.anonymizeData,
          );
          return _collectData(userId, allOptions);
      }
    }

    exportData['exportInfo']['totalRecords'] = totalRecords;
    return exportData;
  }

  /// Export meal logs
  Future<List<Map<String, dynamic>>> _exportMealLogs(String userId, ExportOptions options) async {
    try {
      Query query = _firestore
          .collection('meal_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      if (options.startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(options.startDate!));
      }
      if (options.endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(options.endDate!));
      }

      final snapshot = await query.get();
      final List<Map<String, dynamic>> mealLogs = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Process meal log data
        final mealLog = {
          'id': doc.id,
          'timestamp': (data['timestamp'] as Timestamp).toDate().toIso8601String(),
          'mealType': data['meal_type'],
          'foods': data['foods'] ?? [],
          'totalCalories': data['total_calories'],
          'totalProtein': data['total_protein'],
          'totalCarbs': data['total_carbs'],
          'totalFat': data['total_fat'],
          'mood': data['mood'],
          'notes': data['notes'],
          'confidenceScore': data['confidence_score'],
        };

        // Handle image data based on options
        if (options.includeImages && data['image_url'] != null) {
          mealLog['imageUrl'] = data['image_url'];
        }

        // Anonymize if requested
        if (options.anonymizeData) {
          mealLog['userId'] = _anonymizeUserId(userId);
          mealLog.remove('notes'); // Remove personal notes
        } else if (options.includePersonalInfo) {
          mealLog['userId'] = userId;
        }

        mealLogs.add(mealLog);
      }

      return mealLogs;
    } catch (e) {
      debugPrint('Error exporting meal logs: $e');
      return [];
    }
  }

  /// Export fasting sessions
  Future<List<Map<String, dynamic>>> _exportFastingSessions(String userId, ExportOptions options) async {
    try {
      Query query = _firestore
          .collection('fasting_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true);

      if (options.startDate != null) {
        query = query.where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(options.startDate!));
      }
      if (options.endDate != null) {
        query = query.where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(options.endDate!));
      }

      final snapshot = await query.get();
      final List<Map<String, dynamic>> sessions = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        final session = {
          'id': doc.id,
          'startTime': (data['startTime'] as Timestamp).toDate().toIso8601String(),
          'endTime': data['endTime'] != null 
              ? (data['endTime'] as Timestamp).toDate().toIso8601String() 
              : null,
          'duration': data['duration'],
          'targetDuration': data['target_duration'],
          'fastingType': data['fasting_type'],
          'status': data['status'],
          'mood': data['mood'],
          'notes': data['notes'],
          'difficulty': data['difficulty'],
        };

        // Anonymize if requested
        if (options.anonymizeData) {
          session['userId'] = _anonymizeUserId(userId);
          session.remove('notes');
        } else if (options.includePersonalInfo) {
          session['userId'] = userId;
        }

        sessions.add(session);
      }

      return sessions;
    } catch (e) {
      debugPrint('Error exporting fasting sessions: $e');
      return [];
    }
  }

  /// Export health profile
  Future<Map<String, dynamic>?> _exportHealthProfile(String userId, ExportOptions options) async {
    try {
      final doc = await _firestore.collection('health_profiles').doc(userId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      
      final profile = {
        'id': doc.id,
        'age': data['age'],
        'gender': data['gender'],
        'height': data['height'],
        'weight': data['weight'],
        'activityLevel': data['activity_level'],
        'healthGoals': data['health_goals'],
        'dietaryPreferences': data['dietary_preferences'],
        'healthConditions': data['health_conditions'],
        'createdAt': (data['created_at'] as Timestamp).toDate().toIso8601String(),
        'updatedAt': (data['updated_at'] as Timestamp).toDate().toIso8601String(),
      };

      // Handle personal info based on options
      if (!options.includePersonalInfo || options.anonymizeData) {
        profile.remove('age');
        profile.remove('gender');
        profile.remove('height');
        profile.remove('weight');
        profile.remove('health_conditions');
      }

      if (options.anonymizeData) {
        profile['userId'] = _anonymizeUserId(userId);
      } else {
        profile['userId'] = userId;
      }

      return profile;
    } catch (e) {
      debugPrint('Error exporting health profile: $e');
      return null;
    }
  }

  /// Export AI advice
  Future<List<Map<String, dynamic>>> _exportAiAdvice(String userId, ExportOptions options) async {
    try {
      Query query = _firestore
          .collection('ai_advice')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true);

      if (options.startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(options.startDate!));
      }
      if (options.endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(options.endDate!));
      }

      final snapshot = await query.get();
      final List<Map<String, dynamic>> advice = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        final adviceItem = {
          'id': doc.id,
          'title': data['title'],
          'content': data['content'],
          'category': data['category'],
          'type': data['type'],
          'priority': data['priority'],
          'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
          'rating': data['rating'],
          'isRead': data['is_read'],
        };

        // Anonymize if requested
        if (options.anonymizeData) {
          adviceItem['userId'] = _anonymizeUserId(userId);
        } else if (options.includePersonalInfo) {
          adviceItem['userId'] = userId;
        }

        advice.add(adviceItem);
      }

      return advice;
    } catch (e) {
      debugPrint('Error exporting AI advice: $e');
      return [];
    }
  }

  /// Export integrations
  Future<List<Map<String, dynamic>>> _exportIntegrations(String userId, ExportOptions options) async {
    try {
      final snapshot = await _firestore
          .collection('health_integrations')
          .where('userId', isEqualTo: userId)
          .get();

      final List<Map<String, dynamic>> integrations = [];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        final integration = {
          'id': doc.id,
          'name': data['name'],
          'type': data['type'],
          'isEnabled': data['is_enabled'],
          'connectedAt': (data['connected_at'] as Timestamp?)?.toDate().toIso8601String(),
          'lastSyncAt': (data['last_sync_at'] as Timestamp?)?.toDate().toIso8601String(),
          'permissions': data['permissions'],
        };

        // Handle sensitive data
        if (!options.includePersonalInfo || options.anonymizeData) {
          integration.remove('settings'); // Remove API keys and tokens
        }

        if (options.anonymizeData) {
          integration['userId'] = _anonymizeUserId(userId);
        } else if (options.includePersonalInfo) {
          integration['userId'] = userId;
        }

        integrations.add(integration);
      }

      return integrations;
    } catch (e) {
      debugPrint('Error exporting integrations: $e');
      return [];
    }
  }

  /// Write collected data to file
  Future<ExportResult> _writeDataToFile(Map<String, dynamic> data, ExportOptions options) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'snapameal_export_$timestamp.${options.format.name}';
    final filePath = '${directory.path}/$fileName';

    late File file;
    late int recordCount;

    switch (options.format) {
      case ExportFormat.json:
        file = await _writeJsonFile(filePath, data);
        recordCount = data['exportInfo']['totalRecords'] ?? 0;
        break;

      case ExportFormat.csv:
        file = await _writeCsvFile(filePath, data);
        recordCount = data['exportInfo']['totalRecords'] ?? 0;
        break;
    }

    final fileSize = await file.length();
    final fileSizeKB = fileSize / 1024;

    return ExportResult(
      filePath: filePath,
      fileName: fileName,
      recordCount: recordCount,
      fileSizeKB: fileSizeKB,
      exportedAt: DateTime.now(),
    );
  }

  /// Write data as JSON file
  Future<File> _writeJsonFile(String filePath, Map<String, dynamic> data) async {
    final file = File(filePath);
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(jsonString);
    return file;
  }

  /// Write data as CSV file
  Future<File> _writeCsvFile(String filePath, Map<String, dynamic> data) async {
    final file = File(filePath);
    final List<List<dynamic>> csvData = [];

    // Add export info header
    csvData.add(['Export Information']);
    csvData.add(['Exported At', data['exportInfo']['exportedAt']]);
    csvData.add(['Total Records', data['exportInfo']['totalRecords']]);
    csvData.add(['Data Types', data['exportInfo']['dataTypes'].join(', ')]);
    csvData.add([]); // Empty row

    // Process each data type
    for (final entry in data.entries) {
      if (entry.key == 'exportInfo') continue;

      csvData.add([entry.key.toUpperCase()]);
      
      if (entry.value is List) {
        final list = entry.value as List;
        if (list.isNotEmpty && list.first is Map) {
          // Add headers
          final headers = (list.first as Map<String, dynamic>).keys.toList();
          csvData.add(headers);
          
          // Add data rows
          for (final item in list) {
            final row = headers.map((header) => (item as Map)[header]?.toString() ?? '').toList();
            csvData.add(row);
          }
        }
      } else if (entry.value is Map) {
        final map = entry.value as Map<String, dynamic>;
        for (final mapEntry in map.entries) {
          csvData.add([mapEntry.key, mapEntry.value?.toString() ?? '']);
        }
      }
      
      csvData.add([]); // Empty row between sections
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    await file.writeAsString(csvString);
    return file;
  }

  /// Share exported file
  Future<void> shareExportedFile(ExportResult result) async {
    try {
      final xFile = XFile(result.filePath);
      await Share.shareXFiles(
        [xFile],
        text: 'SnapAMeal Health Data Export - ${result.recordCount} records',
        subject: 'Health Data Export',
      );
    } catch (e) {
      debugPrint('Error sharing file: $e');
      rethrow;
    }
  }

  /// Get export statistics
  Future<Map<String, int>> getExportStatistics(String userId) async {
    try {
      final stats = <String, int>{};
      
      // Use aggregation queries for better performance - these are more efficient than downloading all docs
      // For now, we'll limit the queries to avoid performance issues
      
      // Count meal logs (limit to recent data for performance)
      final mealLogsSnapshot = await _firestore
          .collection('meal_logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(1000) // Limit to avoid large downloads
          .get();
      stats['mealLogs'] = mealLogsSnapshot.docs.length;

      // Count fasting sessions (limit to recent data)
      final fastingSnapshot = await _firestore
          .collection('fasting_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(500) // Limit to avoid large downloads
          .get();
      stats['fastingSessions'] = fastingSnapshot.docs.length;

      // Count AI advice (limit to recent data)
      final adviceSnapshot = await _firestore
          .collection('ai_advice')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(500) // Limit to avoid large downloads
          .get();
      stats['aiAdvice'] = adviceSnapshot.docs.length;

      // Count integrations (this should be small, so no limit needed)
      final integrationsSnapshot = await _firestore
          .collection('health_integrations')
          .where('userId', isEqualTo: userId)
          .get();
      stats['integrations'] = integrationsSnapshot.docs.length;

      // Check health profile
      final profileDoc = await _firestore
          .collection('health_profiles')
          .doc(userId)
          .get();
      stats['healthProfile'] = profileDoc.exists ? 1 : 0;

      return stats;
    } catch (e) {
      debugPrint('Error getting export statistics: $e');
      return {};
    }
  }

  /// Anonymize user ID for privacy
  String _anonymizeUserId(String userId) {
    return 'user_${userId.hashCode.abs()}';
  }

  /// Get date range suggestions
  List<Map<String, dynamic>> getDateRangePresets() {
    final now = DateTime.now();
    return [
      {
        'label': 'Last 7 days',
        'startDate': now.subtract(const Duration(days: 7)),
        'endDate': now,
      },
      {
        'label': 'Last 30 days',
        'startDate': now.subtract(const Duration(days: 30)),
        'endDate': now,
      },
      {
        'label': 'Last 90 days',
        'startDate': now.subtract(const Duration(days: 90)),
        'endDate': now,
      },
      {
        'label': 'This year',
        'startDate': DateTime(now.year, 1, 1),
        'endDate': now,
      },
      {
        'label': 'All time',
        'startDate': null,
        'endDate': null,
      },
    ];
  }
} 