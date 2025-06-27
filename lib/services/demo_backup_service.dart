import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/logger.dart';

/// Service for backing up and restoring demo data
class DemoBackupService {
  static final DemoBackupService _instance = DemoBackupService._internal();
  factory DemoBackupService() => _instance;
  DemoBackupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections to backup for demo data
  static const List<String> demoCollections = [
    'demo_users',
    'demo_meal_logs',
    'demo_fasting_sessions',
    'demo_health_groups',
    'demo_ai_advice',
    'demo_stories',
    'demo_chat_rooms',
    'demo_session_data',
  ];

  /// Create a comprehensive backup of all demo data
  Future<DemoBackupResult> createFullBackup() async {
    try {
      Logger.d('Starting full demo data backup...');

      final backup = DemoBackup(
        backupId: _generateBackupId(),
        timestamp: DateTime.now(),
        version: '1.0',
        collections: {},
      );

      int totalDocuments = 0;

      for (final collection in demoCollections) {
        Logger.d('Backing up collection: $collection');

        final snapshot = await _firestore.collection(collection).get();
        final documents = <String, Map<String, dynamic>>{};

        for (final doc in snapshot.docs) {
          // ignore: unnecessary_cast
          documents[doc.id] = _sanitizeDocumentData(
            doc.data() as Map<String, dynamic>,
          );
        }

        backup.collections[collection] = documents;
        totalDocuments += documents.length;

        Logger.d('Backed up ${documents.length} documents from $collection');
      }

      // Add metadata
      backup.metadata = {
        'totalCollections': demoCollections.length,
        'totalDocuments': totalDocuments,
        'backupSize': _calculateBackupSize(backup),
        'createdBy': _auth.currentUser?.email ?? 'unknown',
        'appVersion': '2.1.0',
      };

      Logger.d(
        'Backup completed: $totalDocuments documents across ${demoCollections.length} collections',
      );

      return DemoBackupResult(
        success: true,
        backup: backup,
        message: 'Backup created successfully',
      );
    } catch (e) {
      Logger.d('Error creating backup: $e');
      return DemoBackupResult(
        success: false,
        message: 'Failed to create backup: $e',
      );
    }
  }

  /// Create a backup for a specific demo user
  Future<DemoBackupResult> createUserBackup(String userId) async {
    try {
      Logger.d('Starting user backup for: $userId');

      final backup = DemoBackup(
        backupId: _generateBackupId(),
        timestamp: DateTime.now(),
        version: '1.0',
        collections: {},
        userId: userId,
      );

      int totalDocuments = 0;

      for (final collection in demoCollections) {
        Logger.d('Backing up user data from collection: $collection');

        Query query = _firestore.collection(collection);

        // Add user-specific filters based on collection structure
        if (collection == 'demo_users') {
          query = query.where(FieldPath.documentId, isEqualTo: userId);
        } else if (collection == 'demo_session_data') {
          query = query.where('userId', isEqualTo: userId);
        } else if ([
          'demo_meal_logs',
          'demo_fasting_sessions',
          'demo_ai_advice',
        ].contains(collection)) {
          query = query.where('user_id', isEqualTo: userId);
        } else if ([
          'demo_stories',
          'demo_health_groups',
        ].contains(collection)) {
          query = query.where('userId', isEqualTo: userId);
        } else if (collection == 'demo_chat_rooms') {
          query = query.where('members', arrayContains: userId);
        }

        final snapshot = await query.get();
        final documents = <String, Map<String, dynamic>>{};

        for (final doc in snapshot.docs) {
          // ignore: unnecessary_cast
          documents[doc.id] = _sanitizeDocumentData(
            doc.data() as Map<String, dynamic>,
          );
        }

        backup.collections[collection] = documents;
        totalDocuments += documents.length;

        Logger.d(
          'Backed up ${documents.length} user documents from $collection',
        );
      }

      // Add metadata
      backup.metadata = {
        'totalCollections': demoCollections.length,
        'totalDocuments': totalDocuments,
        'backupSize': _calculateBackupSize(backup),
        'userId': userId,
        'createdBy': _auth.currentUser?.email ?? 'unknown',
        'appVersion': '2.1.0',
      };

      Logger.d('User backup completed: $totalDocuments documents');

      return DemoBackupResult(
        success: true,
        backup: backup,
        message: 'User backup created successfully',
      );
    } catch (e) {
      Logger.d('Error creating user backup: $e');
      return DemoBackupResult(
        success: false,
        message: 'Failed to create user backup: $e',
      );
    }
  }

  /// Save backup to local storage
  Future<String?> saveBackupToFile(DemoBackup backup) async {
    try {
      if (kIsWeb) {
        // For web, return JSON string for download
        return jsonEncode(backup.toJson());
      }

      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/demo_backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final fileName = 'demo_backup_${backup.backupId}.json';
      final file = File('${backupDir.path}/$fileName');

      await file.writeAsString(jsonEncode(backup.toJson()));

      Logger.d('Backup saved to: ${file.path}');
      return file.path;
    } catch (e) {
      Logger.d('Error saving backup to file: $e');
      return null;
    }
  }

  /// Load backup from file
  Future<DemoBackup?> loadBackupFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        Logger.d('Backup file not found: $filePath');
        return null;
      }

      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      return DemoBackup.fromJson(jsonData);
    } catch (e) {
      Logger.d('Error loading backup from file: $e');
      return null;
    }
  }

  /// Restore demo data from backup
  Future<DemoRestoreResult> restoreFromBackup(
    DemoBackup backup, {
    bool overwrite = false,
  }) async {
    try {
      Logger.d('Starting restore from backup: ${backup.backupId}');

      int restoredDocuments = 0;
      int skippedDocuments = 0;
      final errors = <String>[];

      for (final collectionName in backup.collections.keys) {
        final documents = backup.collections[collectionName]!;

        Logger.d(
          'Restoring collection: $collectionName (${documents.length} documents)',
        );

        for (final docId in documents.keys) {
          try {
            final docData = documents[docId]!;
            final docRef = _firestore.collection(collectionName).doc(docId);

            if (!overwrite) {
              final existingDoc = await docRef.get();
              if (existingDoc.exists) {
                skippedDocuments++;
                continue;
              }
            }

            // Restore timestamps
            final sanitizedData = _restoreTimestamps(docData);

            await docRef.set(sanitizedData);
            restoredDocuments++;
          } catch (e) {
            errors.add(
              'Failed to restore document $docId in $collectionName: $e',
            );
            Logger.d('Error restoring document $docId: $e');
          }
        }
      }

      // Log restore operation
      await _logRestoreOperation(
        backup,
        restoredDocuments,
        skippedDocuments,
        errors,
      );

      Logger.d(
        'Restore completed: $restoredDocuments restored, $skippedDocuments skipped, ${errors.length} errors',
      );

      return DemoRestoreResult(
        success: errors.isEmpty || restoredDocuments > 0,
        restoredDocuments: restoredDocuments,
        skippedDocuments: skippedDocuments,
        errors: errors,
        message: errors.isEmpty
            ? 'Restore completed successfully'
            : 'Restore completed with ${errors.length} errors',
      );
    } catch (e) {
      Logger.d('Error restoring from backup: $e');
      return DemoRestoreResult(
        success: false,
        restoredDocuments: 0,
        skippedDocuments: 0,
        errors: ['Restore failed: $e'],
        message: 'Failed to restore from backup: $e',
      );
    }
  }

  /// Get list of available backup files
  Future<List<DemoBackupInfo>> getAvailableBackups() async {
    try {
      if (kIsWeb) {
        // Web doesn't have access to local files
        return [];
      }

      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/demo_backups');

      if (!await backupDir.exists()) {
        return [];
      }

      final files = await backupDir.list().toList();
      final backups = <DemoBackupInfo>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final jsonString = await file.readAsString();
            final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

            backups.add(
              DemoBackupInfo(
                filePath: file.path,
                fileName: file.path.split('/').last,
                backupId: jsonData['backupId'],
                timestamp: DateTime.parse(jsonData['timestamp']),
                version: jsonData['version'],
                totalDocuments: jsonData['metadata']?['totalDocuments'] ?? 0,
                userId: jsonData['userId'],
              ),
            );
          } catch (e) {
            Logger.d('Error reading backup file ${file.path}: $e');
          }
        }
      }

      // Sort by timestamp (newest first)
      backups.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return backups;
    } catch (e) {
      Logger.d('Error getting available backups: $e');
      return [];
    }
  }

  /// Delete backup file
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        Logger.d('Backup deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      Logger.d('Error deleting backup: $e');
      return false;
    }
  }

  /// Sanitize document data for JSON serialization
  Map<String, dynamic> _sanitizeDocumentData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};

    for (final key in data.keys) {
      final value = data[key];

      if (value is Timestamp) {
        sanitized[key] = {
          '_type': 'timestamp',
          '_value': value.millisecondsSinceEpoch,
        };
      } else if (value is GeoPoint) {
        sanitized[key] = {
          '_type': 'geopoint',
          '_latitude': value.latitude,
          '_longitude': value.longitude,
        };
      } else if (value is DocumentReference) {
        sanitized[key] = {'_type': 'reference', '_path': value.path};
      } else if (value is List) {
        sanitized[key] = value
            .map(
              (item) => item is Map<String, dynamic>
                  ? _sanitizeDocumentData(item)
                  : item,
            )
            .toList();
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeDocumentData(value);
      } else {
        sanitized[key] = value;
      }
    }

    return sanitized;
  }

  /// Restore special Firestore types from sanitized data
  Map<String, dynamic> _restoreTimestamps(Map<String, dynamic> data) {
    final restored = <String, dynamic>{};

    for (final key in data.keys) {
      final value = data[key];

      if (value is Map<String, dynamic> && value.containsKey('_type')) {
        switch (value['_type']) {
          case 'timestamp':
            restored[key] = Timestamp.fromMillisecondsSinceEpoch(
              value['_value'],
            );
            break;
          case 'geopoint':
            restored[key] = GeoPoint(value['_latitude'], value['_longitude']);
            break;
          case 'reference':
            restored[key] = _firestore.doc(value['_path']);
            break;
          default:
            restored[key] = value;
        }
      } else if (value is List) {
        restored[key] = value
            .map(
              (item) => item is Map<String, dynamic>
                  ? _restoreTimestamps(item)
                  : item,
            )
            .toList();
      } else if (value is Map<String, dynamic>) {
        restored[key] = _restoreTimestamps(value);
      } else {
        restored[key] = value;
      }
    }

    return restored;
  }

  /// Calculate approximate backup size in bytes
  int _calculateBackupSize(DemoBackup backup) {
    try {
      final jsonString = jsonEncode(backup.toJson());
      return jsonString.length;
    } catch (e) {
      return 0;
    }
  }

  /// Log restore operation for audit trail
  Future<void> _logRestoreOperation(
    DemoBackup backup,
    int restored,
    int skipped,
    List<String> errors,
  ) async {
    try {
      await _firestore.collection('demo_restore_history').add({
        'backupId': backup.backupId,
        'restoreTime': FieldValue.serverTimestamp(),
        'restoredBy': _auth.currentUser?.email ?? 'unknown',
        'restoredDocuments': restored,
        'skippedDocuments': skipped,
        'errorCount': errors.length,
        'errors': errors.take(10).toList(), // Limit errors stored
        'backupTimestamp': backup.timestamp.millisecondsSinceEpoch,
        'backupVersion': backup.version,
      });
    } catch (e) {
      Logger.d('Error logging restore operation: $e');
    }
  }

  String _generateBackupId() {
    return 'backup_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Demo backup data structure
class DemoBackup {
  final String backupId;
  final DateTime timestamp;
  final String version;
  final Map<String, Map<String, Map<String, dynamic>>> collections;
  final String? userId;
  Map<String, dynamic>? metadata;

  DemoBackup({
    required this.backupId,
    required this.timestamp,
    required this.version,
    required this.collections,
    this.userId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'backupId': backupId,
      'timestamp': timestamp.toIso8601String(),
      'version': version,
      'collections': collections,
      'userId': userId,
      'metadata': metadata,
    };
  }

  factory DemoBackup.fromJson(Map<String, dynamic> json) {
    return DemoBackup(
      backupId: json['backupId'],
      timestamp: DateTime.parse(json['timestamp']),
      version: json['version'],
      collections: Map<String, Map<String, Map<String, dynamic>>>.from(
        json['collections'].map(
          (key, value) =>
              MapEntry(key, Map<String, Map<String, dynamic>>.from(value)),
        ),
      ),
      userId: json['userId'],
      metadata: json['metadata'],
    );
  }
}

/// Backup operation result
class DemoBackupResult {
  final bool success;
  final DemoBackup? backup;
  final String message;

  DemoBackupResult({required this.success, this.backup, required this.message});
}

/// Restore operation result
class DemoRestoreResult {
  final bool success;
  final int restoredDocuments;
  final int skippedDocuments;
  final List<String> errors;
  final String message;

  DemoRestoreResult({
    required this.success,
    required this.restoredDocuments,
    required this.skippedDocuments,
    required this.errors,
    required this.message,
  });
}

/// Backup file information
class DemoBackupInfo {
  final String filePath;
  final String fileName;
  final String backupId;
  final DateTime timestamp;
  final String version;
  final int totalDocuments;
  final String? userId;

  DemoBackupInfo({
    required this.filePath,
    required this.fileName,
    required this.backupId,
    required this.timestamp,
    required this.version,
    required this.totalDocuments,
    this.userId,
  });
}
