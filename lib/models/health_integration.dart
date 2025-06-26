import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/health_integration_service.dart';

class HealthIntegration {
  final String id;
  final String userId;
  final IntegrationType type;
  final IntegrationStatus status;
  final String? accessToken;
  final String? refreshToken;
  final DateTime connectedAt;
  final DateTime? lastSyncAt;
  final Map<String, dynamic> settings;
  final Map<String, dynamic>? metadata;

  const HealthIntegration({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    this.accessToken,
    this.refreshToken,
    required this.connectedAt,
    this.lastSyncAt,
    required this.settings,
    this.metadata,
  });

  /// Create HealthIntegration from Firestore document
  factory HealthIntegration.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return HealthIntegration(
      id: doc.id,
      userId: data['user_id'] ?? '',
      type: IntegrationType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => IntegrationType.myFitnessPal,
      ),
      status: IntegrationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => IntegrationStatus.disconnected,
      ),
      accessToken: data['access_token'],
      refreshToken: data['refresh_token'],
      connectedAt: (data['connected_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSyncAt: (data['last_sync_at'] as Timestamp?)?.toDate(),
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
      metadata: data['metadata'] != null 
          ? Map<String, dynamic>.from(data['metadata']) 
          : null,
    );
  }

  /// Convert HealthIntegration to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'type': type.name,
      'status': status.name,
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'connected_at': Timestamp.fromDate(connectedAt),
      'last_sync_at': lastSyncAt != null ? Timestamp.fromDate(lastSyncAt!) : null,
      'settings': settings,
      'metadata': metadata,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  HealthIntegration copyWith({
    String? id,
    String? userId,
    IntegrationType? type,
    IntegrationStatus? status,
    String? accessToken,
    String? refreshToken,
    DateTime? connectedAt,
    DateTime? lastSyncAt,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? metadata,
  }) {
    return HealthIntegration(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      connectedAt: connectedAt ?? this.connectedAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      settings: settings ?? this.settings,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if the integration is connected and functional
  bool get isConnected => status == IntegrationStatus.connected;

  /// Check if the integration is currently syncing
  bool get isSyncing => status == IntegrationStatus.syncing;

  /// Check if the integration has an error
  bool get hasError => status == IntegrationStatus.error;

  /// Get human-readable integration type name
  String get typeName {
    switch (type) {
      case IntegrationType.myFitnessPal:
        return 'MyFitnessPal';
      case IntegrationType.appleHealth:
        return 'Apple Health';
      case IntegrationType.googleFit:
        return 'Google Fit';
    }
  }

  /// Get integration type icon
  String get typeIcon {
    switch (type) {
      case IntegrationType.myFitnessPal:
        return '🍎'; // MyFitnessPal logo would be better
      case IntegrationType.appleHealth:
        return '❤️'; // Apple Health icon
      case IntegrationType.googleFit:
        return '🏃'; // Google Fit icon
    }
  }

  /// Get status color for UI
  String get statusColor {
    switch (status) {
      case IntegrationStatus.connected:
        return '#4CAF50'; // Green
      case IntegrationStatus.connecting:
      case IntegrationStatus.syncing:
        return '#FF9800'; // Orange
      case IntegrationStatus.error:
        return '#F44336'; // Red
      case IntegrationStatus.disconnected:
        return '#9E9E9E'; // Grey
    }
  }

  /// Get human-readable status text
  String get statusText {
    switch (status) {
      case IntegrationStatus.connected:
        return 'Connected';
      case IntegrationStatus.connecting:
        return 'Connecting...';
      case IntegrationStatus.syncing:
        return 'Syncing...';
      case IntegrationStatus.error:
        return 'Error';
      case IntegrationStatus.disconnected:
        return 'Disconnected';
    }
  }

  /// Get sync status text
  String get syncStatusText {
    if (lastSyncAt == null) {
      return 'Never synced';
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastSyncAt!);
    
    if (difference.inMinutes < 1) {
      return 'Just synced';
    } else if (difference.inHours < 1) {
      return 'Synced ${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return 'Synced ${difference.inHours}h ago';
    } else {
      return 'Synced ${difference.inDays}d ago';
    }
  }

  /// Check if auto-sync is enabled
  bool get autoSyncEnabled => settings['auto_sync'] == true;

  /// Check if meal sync is enabled
  bool get mealSyncEnabled => settings['sync_meals'] == true;

  /// Check if exercise sync is enabled
  bool get exerciseSyncEnabled => settings['sync_exercises'] == true;

  /// Get sync frequency in minutes (default 60)
  int get syncFrequencyMinutes => settings['sync_frequency'] ?? 60;

  @override
  String toString() {
    return 'HealthIntegration(id: $id, type: $type, status: $status, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is HealthIntegration &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        status.hashCode;
  }
} 