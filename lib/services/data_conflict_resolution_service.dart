import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

enum ConflictType {
  duplicateEntry,
  valueDiscrepancy,
  timestampOverlap,
  sourceConflict,
  dataTypeConflict,
}

enum ConflictResolutionStrategy {
  mostRecent,
  highestPriority,
  mostAccurate,
  userChoice,
  merge,
  keepAll,
}

enum DataSource { manual, myFitnessPal, appleHealth, googleFit, snapAMeal }

class DataConflict {
  final String id;
  final ConflictType type;
  final String dataType; // 'meal', 'exercise', 'weight', etc.
  final DateTime timestamp;
  final List<ConflictingData> conflictingData;
  final ConflictResolutionStrategy? suggestedResolution;
  final bool isResolved;
  final String? userId;

  const DataConflict({
    required this.id,
    required this.type,
    required this.dataType,
    required this.timestamp,
    required this.conflictingData,
    this.suggestedResolution,
    this.isResolved = false,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'dataType': dataType,
      'timestamp': Timestamp.fromDate(timestamp),
      'conflictingData': conflictingData.map((e) => e.toJson()).toList(),
      'suggestedResolution': suggestedResolution?.name,
      'isResolved': isResolved,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory DataConflict.fromJson(Map<String, dynamic> json, String id) {
    return DataConflict(
      id: id,
      type: ConflictType.values.firstWhere((e) => e.name == json['type']),
      dataType: json['dataType'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      conflictingData: (json['conflictingData'] as List)
          .map((e) => ConflictingData.fromJson(e))
          .toList(),
      suggestedResolution: json['suggestedResolution'] != null
          ? ConflictResolutionStrategy.values.firstWhere(
              (e) => e.name == json['suggestedResolution'],
            )
          : null,
      isResolved: json['isResolved'] ?? false,
      userId: json['userId'],
    );
  }
}

class ConflictingData {
  final String sourceId;
  final DataSource source;
  final Map<String, dynamic> data;
  final double confidence;
  final DateTime lastUpdated;
  final int priority; // Higher number = higher priority

  const ConflictingData({
    required this.sourceId,
    required this.source,
    required this.data,
    required this.confidence,
    required this.lastUpdated,
    required this.priority,
  });

  Map<String, dynamic> toJson() {
    return {
      'sourceId': sourceId,
      'source': source.name,
      'data': data,
      'confidence': confidence,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'priority': priority,
    };
  }

  factory ConflictingData.fromJson(Map<String, dynamic> json) {
    return ConflictingData(
      sourceId: json['sourceId'],
      source: DataSource.values.firstWhere((e) => e.name == json['source']),
      data: json['data'],
      confidence: json['confidence']?.toDouble() ?? 0.0,
      lastUpdated: (json['lastUpdated'] as Timestamp).toDate(),
      priority: json['priority'] ?? 0,
    );
  }
}

class ConflictResolution {
  final String conflictId;
  final ConflictResolutionStrategy strategy;
  final String? selectedSourceId;
  final Map<String, dynamic>? mergedData;
  final DateTime resolvedAt;
  final String resolvedBy;

  const ConflictResolution({
    required this.conflictId,
    required this.strategy,
    this.selectedSourceId,
    this.mergedData,
    required this.resolvedAt,
    required this.resolvedBy,
  });

  Map<String, dynamic> toJson() {
    return {
      'conflictId': conflictId,
      'strategy': strategy.name,
      'selectedSourceId': selectedSourceId,
      'mergedData': mergedData,
      'resolvedAt': Timestamp.fromDate(resolvedAt),
      'resolvedBy': resolvedBy,
    };
  }
}

class DataConflictResolutionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Data source priorities (higher = more trusted)
  static const Map<DataSource, int> _sourcePriorities = {
    DataSource.manual: 100, // User input is highest priority
    DataSource.snapAMeal: 90, // Our app's data
    DataSource.myFitnessPal: 80, // Dedicated nutrition app
    DataSource.appleHealth: 70, // Health platform
    DataSource.googleFit: 60, // Fitness platform
  };

  /// Detect conflicts when new data is added
  Future<List<DataConflict>> detectConflicts({
    required String dataType,
    required Map<String, dynamic> newData,
    required DataSource source,
    required DateTime timestamp,
    Duration? timeWindow,
  }) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return [];

      timeWindow ??= const Duration(minutes: 30); // Default 30-minute window
      final startTime = timestamp.subtract(timeWindow);
      final endTime = timestamp.add(timeWindow);

      // Query existing data in the time window
      final existingData = await _getExistingDataInTimeWindow(
        userId: user.uid,
        dataType: dataType,
        startTime: startTime,
        endTime: endTime,
      );

      final List<DataConflict> conflicts = [];

      for (final existing in existingData) {
        final conflict = _analyzeDataForConflicts(
          newData: newData,
          newSource: source,
          newTimestamp: timestamp,
          existingData: existing,
          dataType: dataType,
        );

        if (conflict != null) {
          conflicts.add(conflict);
        }
      }

      // Save detected conflicts
      for (final conflict in conflicts) {
        await _saveConflict(conflict);
      }

      return conflicts;
    } catch (e) {
      Logger.d('Error detecting conflicts: $e');
      return [];
    }
  }

  /// Get existing data in a time window
  Future<List<Map<String, dynamic>>> _getExistingDataInTimeWindow({
    required String userId,
    required String dataType,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final collections = _getCollectionsForDataType(dataType);
    final List<Map<String, dynamic>> allData = [];

    for (final collection in collections) {
      final snapshot = await _firestore
          .collection(collection)
          .where('userId', isEqualTo: userId)
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startTime),
          )
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endTime))
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        data['docId'] = doc.id;
        data['collection'] = collection;
        allData.add(data);
      }
    }

    return allData;
  }

  /// Analyze data for conflicts
  DataConflict? _analyzeDataForConflicts({
    required Map<String, dynamic> newData,
    required DataSource newSource,
    required DateTime newTimestamp,
    required Map<String, dynamic> existingData,
    required String dataType,
  }) {
    final existingSource = _getDataSource(existingData);
    final existingTimestamp = (existingData['timestamp'] as Timestamp).toDate();

    // Check for duplicate entries
    if (_isDuplicateEntry(newData, existingData, dataType)) {
      return _createConflict(
        type: ConflictType.duplicateEntry,
        dataType: dataType,
        timestamp: newTimestamp,
        newData: newData,
        newSource: newSource,
        existingData: existingData,
        existingSource: existingSource,
      );
    }

    // Check for value discrepancies
    if (_hasValueDiscrepancy(newData, existingData, dataType)) {
      return _createConflict(
        type: ConflictType.valueDiscrepancy,
        dataType: dataType,
        timestamp: newTimestamp,
        newData: newData,
        newSource: newSource,
        existingData: existingData,
        existingSource: existingSource,
      );
    }

    // Check for timestamp overlaps
    if (_hasTimestampOverlap(newTimestamp, existingTimestamp, dataType)) {
      return _createConflict(
        type: ConflictType.timestampOverlap,
        dataType: dataType,
        timestamp: newTimestamp,
        newData: newData,
        newSource: newSource,
        existingData: existingData,
        existingSource: existingSource,
      );
    }

    return null;
  }

  /// Create a conflict object
  DataConflict _createConflict({
    required ConflictType type,
    required String dataType,
    required DateTime timestamp,
    required Map<String, dynamic> newData,
    required DataSource newSource,
    required Map<String, dynamic> existingData,
    required DataSource existingSource,
  }) {
    final user = _authService.getCurrentUser();
    final conflictId = _firestore.collection('data_conflicts').doc().id;

    final conflictingData = [
      ConflictingData(
        sourceId: 'new_${DateTime.now().millisecondsSinceEpoch}',
        source: newSource,
        data: newData,
        confidence: _calculateConfidence(newData, newSource),
        lastUpdated: timestamp,
        priority: _sourcePriorities[newSource] ?? 0,
      ),
      ConflictingData(
        sourceId: existingData['docId'] ?? 'existing',
        source: existingSource,
        data: existingData,
        confidence: _calculateConfidence(existingData, existingSource),
        lastUpdated: (existingData['timestamp'] as Timestamp).toDate(),
        priority: _sourcePriorities[existingSource] ?? 0,
      ),
    ];

    return DataConflict(
      id: conflictId,
      type: type,
      dataType: dataType,
      timestamp: timestamp,
      conflictingData: conflictingData,
      suggestedResolution: _suggestResolutionStrategy(type, conflictingData),
      userId: user?.uid,
    );
  }

  /// Check if entries are duplicates
  bool _isDuplicateEntry(
    Map<String, dynamic> data1,
    Map<String, dynamic> data2,
    String dataType,
  ) {
    switch (dataType) {
      case 'meal':
        return _compareMealData(data1, data2);
      case 'exercise':
        return _compareExerciseData(data1, data2);
      case 'weight':
        return _compareWeightData(data1, data2);
      default:
        return _compareGenericData(data1, data2);
    }
  }

  /// Check for value discrepancies
  bool _hasValueDiscrepancy(
    Map<String, dynamic> data1,
    Map<String, dynamic> data2,
    String dataType,
  ) {
    switch (dataType) {
      case 'meal':
        return _hasMealValueDiscrepancy(data1, data2);
      case 'exercise':
        return _hasExerciseValueDiscrepancy(data1, data2);
      case 'weight':
        return _hasWeightValueDiscrepancy(data1, data2);
      default:
        return false;
    }
  }

  /// Check for timestamp overlaps
  bool _hasTimestampOverlap(DateTime time1, DateTime time2, String dataType) {
    final difference = time1.difference(time2).abs();

    switch (dataType) {
      case 'meal':
        return difference.inMinutes < 15; // Meals within 15 minutes
      case 'exercise':
        return difference.inMinutes < 30; // Exercises within 30 minutes
      case 'weight':
        return difference.inHours < 1; // Weight measurements within 1 hour
      default:
        return difference.inMinutes < 10;
    }
  }

  /// Compare meal data for duplicates
  bool _compareMealData(
    Map<String, dynamic> meal1,
    Map<String, dynamic> meal2,
  ) {
    final calories1 = meal1['total_calories'] ?? meal1['calories'];
    final calories2 = meal2['total_calories'] ?? meal2['calories'];

    if (calories1 != null && calories2 != null) {
      final calorieDiff = (calories1 - calories2).abs();
      return calorieDiff < 50; // Within 50 calories
    }

    return false;
  }

  /// Compare exercise data for duplicates
  bool _compareExerciseData(
    Map<String, dynamic> ex1,
    Map<String, dynamic> ex2,
  ) {
    final duration1 = ex1['duration'];
    final duration2 = ex2['duration'];
    final type1 = ex1['type'] ?? ex1['exercise_type'];
    final type2 = ex2['type'] ?? ex2['exercise_type'];

    return type1 == type2 &&
        duration1 != null &&
        duration2 != null &&
        (duration1 - duration2).abs() < 300; // Within 5 minutes
  }

  /// Compare weight data for duplicates
  bool _compareWeightData(Map<String, dynamic> w1, Map<String, dynamic> w2) {
    final weight1 = w1['weight'];
    final weight2 = w2['weight'];

    if (weight1 != null && weight2 != null) {
      final weightDiff = (weight1 - weight2).abs();
      return weightDiff < 0.5; // Within 0.5 lbs
    }

    return false;
  }

  /// Compare generic data
  bool _compareGenericData(
    Map<String, dynamic> data1,
    Map<String, dynamic> data2,
  ) {
    // Basic comparison of key fields
    final keys = ['value', 'amount', 'count', 'duration'];

    for (final key in keys) {
      if (data1[key] != null && data2[key] != null) {
        return data1[key] == data2[key];
      }
    }

    return false;
  }

  /// Check meal value discrepancy
  bool _hasMealValueDiscrepancy(
    Map<String, dynamic> meal1,
    Map<String, dynamic> meal2,
  ) {
    final calories1 = meal1['total_calories'] ?? meal1['calories'];
    final calories2 = meal2['total_calories'] ?? meal2['calories'];

    if (calories1 != null && calories2 != null) {
      final calorieDiff = (calories1 - calories2).abs();
      return calorieDiff > 100; // More than 100 calories difference
    }

    return false;
  }

  /// Check exercise value discrepancy
  bool _hasExerciseValueDiscrepancy(
    Map<String, dynamic> ex1,
    Map<String, dynamic> ex2,
  ) {
    final calories1 = ex1['calories_burned'];
    final calories2 = ex2['calories_burned'];

    if (calories1 != null && calories2 != null) {
      final calorieDiff = (calories1 - calories2).abs();
      return calorieDiff > 50; // More than 50 calories difference
    }

    return false;
  }

  /// Check weight value discrepancy
  bool _hasWeightValueDiscrepancy(
    Map<String, dynamic> w1,
    Map<String, dynamic> w2,
  ) {
    final weight1 = w1['weight'];
    final weight2 = w2['weight'];

    if (weight1 != null && weight2 != null) {
      final weightDiff = (weight1 - weight2).abs();
      return weightDiff > 2.0; // More than 2 lbs difference
    }

    return false;
  }

  /// Get data source from data
  DataSource _getDataSource(Map<String, dynamic> data) {
    final source = data['source'] ?? data['data_source'];

    if (source is String) {
      try {
        return DataSource.values.firstWhere((e) => e.name == source);
      } catch (e) {
        return DataSource.manual;
      }
    }

    return DataSource.manual;
  }

  /// Calculate confidence score
  double _calculateConfidence(Map<String, dynamic> data, DataSource source) {
    double confidence = 0.5; // Base confidence

    // Adjust based on source reliability
    switch (source) {
      case DataSource.manual:
        confidence = 0.9; // High confidence for manual entry
        break;
      case DataSource.snapAMeal:
        confidence = 0.85; // High confidence for our app
        break;
      case DataSource.myFitnessPal:
        confidence = 0.8; // Good confidence for nutrition app
        break;
      case DataSource.appleHealth:
      case DataSource.googleFit:
        confidence = 0.7; // Moderate confidence for health platforms
        break;
    }

    // Adjust based on data completeness
    final completeness = _calculateDataCompleteness(data);
    confidence *= completeness;

    return confidence.clamp(0.0, 1.0);
  }

  /// Calculate data completeness
  double _calculateDataCompleteness(Map<String, dynamic> data) {
    final requiredFields = ['timestamp'];
    final optionalFields = ['calories', 'duration', 'type', 'notes'];

    int presentFields = 0;
    int totalFields = requiredFields.length + optionalFields.length;

    for (final field in requiredFields) {
      if (data[field] != null) presentFields++;
    }

    for (final field in optionalFields) {
      if (data[field] != null) presentFields++;
    }

    return presentFields / totalFields;
  }

  /// Suggest resolution strategy
  ConflictResolutionStrategy _suggestResolutionStrategy(
    ConflictType type,
    List<ConflictingData> conflictingData,
  ) {
    switch (type) {
      case ConflictType.duplicateEntry:
        // For duplicates, prefer highest priority source
        return ConflictResolutionStrategy.highestPriority;

      case ConflictType.valueDiscrepancy:
        // For value differences, prefer most accurate (highest confidence)
        return ConflictResolutionStrategy.mostAccurate;

      case ConflictType.timestampOverlap:
        // For time overlaps, prefer most recent
        return ConflictResolutionStrategy.mostRecent;

      default:
        return ConflictResolutionStrategy.userChoice;
    }
  }

  /// Get collections for data type
  List<String> _getCollectionsForDataType(String dataType) {
    switch (dataType) {
      case 'meal':
        return ['meal_logs'];
      case 'exercise':
        return ['exercises', 'workouts'];
      case 'weight':
        return ['weight_logs', 'health_metrics'];
      case 'fasting':
        return ['fasting_sessions'];
      default:
        return ['health_data'];
    }
  }

  /// Save conflict to Firestore
  Future<void> _saveConflict(DataConflict conflict) async {
    try {
      await _firestore
          .collection('data_conflicts')
          .doc(conflict.id)
          .set(conflict.toJson());
    } catch (e) {
      Logger.d('Error saving conflict: $e');
    }
  }

  /// Get unresolved conflicts for user
  Future<List<DataConflict>> getUnresolvedConflicts({String? userId}) async {
    try {
      final user = _authService.getCurrentUser();
      final targetUserId = userId ?? user?.uid;

      if (targetUserId == null) return [];

      final snapshot = await _firestore
          .collection('data_conflicts')
          .where('userId', isEqualTo: targetUserId)
          .where('isResolved', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => DataConflict.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      Logger.d('Error getting unresolved conflicts: $e');
      return [];
    }
  }

  /// Resolve conflict
  Future<bool> resolveConflict({
    required String conflictId,
    required ConflictResolutionStrategy strategy,
    String? selectedSourceId,
    Map<String, dynamic>? mergedData,
  }) async {
    try {
      final user = _authService.getCurrentUser();
      if (user == null) return false;

      final resolution = ConflictResolution(
        conflictId: conflictId,
        strategy: strategy,
        selectedSourceId: selectedSourceId,
        mergedData: mergedData,
        resolvedAt: DateTime.now(),
        resolvedBy: user.uid,
      );

      // Save resolution
      await _firestore
          .collection('conflict_resolutions')
          .add(resolution.toJson());

      // Mark conflict as resolved
      await _firestore.collection('data_conflicts').doc(conflictId).update({
        'isResolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedBy': user.uid,
      });

      // Apply resolution to actual data
      await _applyResolution(
        conflictId,
        strategy,
        selectedSourceId,
        mergedData,
      );

      return true;
    } catch (e) {
      Logger.d('Error resolving conflict: $e');
      return false;
    }
  }

  /// Apply resolution to actual data
  Future<void> _applyResolution(
    String conflictId,
    ConflictResolutionStrategy strategy,
    String? selectedSourceId,
    Map<String, dynamic>? mergedData,
  ) async {
    // Get conflict details
    final conflictDoc = await _firestore
        .collection('data_conflicts')
        .doc(conflictId)
        .get();

    if (!conflictDoc.exists) return;

    final conflict = DataConflict.fromJson(conflictDoc.data()!, conflictDoc.id);

    switch (strategy) {
      case ConflictResolutionStrategy.highestPriority:
        await _applyHighestPriorityResolution(conflict);
        break;
      case ConflictResolutionStrategy.mostRecent:
        await _applyMostRecentResolution(conflict);
        break;
      case ConflictResolutionStrategy.mostAccurate:
        await _applyMostAccurateResolution(conflict);
        break;
      case ConflictResolutionStrategy.merge:
        if (mergedData != null) {
          await _applyMergedDataResolution(conflict, mergedData);
        }
        break;
      case ConflictResolutionStrategy.userChoice:
        if (selectedSourceId != null) {
          await _applyUserChoiceResolution(conflict, selectedSourceId);
        }
        break;
      case ConflictResolutionStrategy.keepAll:
        // Keep all data, no action needed
        break;
    }
  }

  /// Apply highest priority resolution
  Future<void> _applyHighestPriorityResolution(DataConflict conflict) async {
    final highestPriority = conflict.conflictingData.reduce(
      (a, b) => a.priority > b.priority ? a : b,
    );

    await _keepDataAndRemoveOthers(conflict, highestPriority.sourceId);
  }

  /// Apply most recent resolution
  Future<void> _applyMostRecentResolution(DataConflict conflict) async {
    final mostRecent = conflict.conflictingData.reduce(
      (a, b) => a.lastUpdated.isAfter(b.lastUpdated) ? a : b,
    );

    await _keepDataAndRemoveOthers(conflict, mostRecent.sourceId);
  }

  /// Apply most accurate resolution
  Future<void> _applyMostAccurateResolution(DataConflict conflict) async {
    final mostAccurate = conflict.conflictingData.reduce(
      (a, b) => a.confidence > b.confidence ? a : b,
    );

    await _keepDataAndRemoveOthers(conflict, mostAccurate.sourceId);
  }

  /// Apply merged data resolution
  Future<void> _applyMergedDataResolution(
    DataConflict conflict,
    Map<String, dynamic> mergedData,
  ) async {
    // Remove all conflicting entries and add merged data
    await _removeAllConflictingData(conflict);

    // Add merged data to appropriate collection
    final collections = _getCollectionsForDataType(conflict.dataType);
    if (collections.isNotEmpty) {
      await _firestore.collection(collections.first).add(mergedData);
    }
  }

  /// Apply user choice resolution
  Future<void> _applyUserChoiceResolution(
    DataConflict conflict,
    String selectedSourceId,
  ) async {
    await _keepDataAndRemoveOthers(conflict, selectedSourceId);
  }

  /// Keep selected data and remove others
  Future<void> _keepDataAndRemoveOthers(
    DataConflict conflict,
    String keepSourceId,
  ) async {
    for (final data in conflict.conflictingData) {
      if (data.sourceId != keepSourceId) {
        await _removeDataEntry(data);
      }
    }
  }

  /// Remove all conflicting data
  Future<void> _removeAllConflictingData(DataConflict conflict) async {
    for (final data in conflict.conflictingData) {
      await _removeDataEntry(data);
    }
  }

  /// Remove a data entry
  Future<void> _removeDataEntry(ConflictingData data) async {
    try {
      // Extract collection and document ID from sourceId
      if (data.data['collection'] != null && data.data['docId'] != null) {
        await _firestore
            .collection(data.data['collection'])
            .doc(data.data['docId'])
            .delete();
      }
    } catch (e) {
      Logger.d('Error removing data entry: $e');
    }
  }

  /// Get conflict statistics
  Future<Map<String, int>> getConflictStatistics({String? userId}) async {
    try {
      final user = _authService.getCurrentUser();
      final targetUserId = userId ?? user?.uid;

      if (targetUserId == null) return {};

      final snapshot = await _firestore
          .collection('data_conflicts')
          .where('userId', isEqualTo: targetUserId)
          .get();

      final stats = <String, int>{
        'total': snapshot.docs.length,
        'resolved': 0,
        'unresolved': 0,
        'duplicateEntry': 0,
        'valueDiscrepancy': 0,
        'timestampOverlap': 0,
      };

      for (final doc in snapshot.docs) {
        final conflict = DataConflict.fromJson(doc.data(), doc.id);

        if (conflict.isResolved) {
          stats['resolved'] = (stats['resolved'] ?? 0) + 1;
        } else {
          stats['unresolved'] = (stats['unresolved'] ?? 0) + 1;
        }

        stats[conflict.type.name] = (stats[conflict.type.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      Logger.d('Error getting conflict statistics: $e');
      return {};
    }
  }
}
