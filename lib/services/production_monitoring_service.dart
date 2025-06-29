/// Production Monitoring Service for SnapAMeal Enhanced Meal Analysis
/// Comprehensive monitoring, alerting, and health checking for production deployment
library;

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import '../utils/performance_monitor.dart';
import '../config/feature_flags.dart';

/// Health check status levels
enum HealthStatus {
  healthy,
  degraded,
  unhealthy,
  critical,
}

/// Alert severity levels
enum AlertSeverity {
  info,
  warning,
  error,
  critical,
}

/// System health check result
class HealthCheckResult {
  final String service;
  final HealthStatus status;
  final String message;
  final Map<String, dynamic> metrics;
  final DateTime timestamp;
  final Duration responseTime;

  HealthCheckResult({
    required this.service,
    required this.status,
    required this.message,
    this.metrics = const {},
    required this.timestamp,
    required this.responseTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'service': service,
      'status': status.name,
      'message': message,
      'metrics': metrics,
      'timestamp': timestamp.toIso8601String(),
      'response_time_ms': responseTime.inMilliseconds,
    };
  }
}

/// Production alert
class ProductionAlert {
  final String id;
  final AlertSeverity severity;
  final String title;
  final String description;
  final Map<String, dynamic> context;
  final DateTime timestamp;
  final bool acknowledged;

  ProductionAlert({
    required this.id,
    required this.severity,
    required this.title,
    required this.description,
    this.context = const {},
    required this.timestamp,
    this.acknowledged = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'severity': severity.name,
      'title': title,
      'description': description,
      'context': context,
      'timestamp': timestamp.toIso8601String(),
      'acknowledged': acknowledged,
    };
  }
}

/// Production monitoring and health check service
class ProductionMonitoringService {
  static final ProductionMonitoringService _instance = ProductionMonitoringService._internal();
  factory ProductionMonitoringService() => _instance;
  ProductionMonitoringService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Timer? _healthCheckTimer;
  Timer? _metricsCollectionTimer;

  static const Duration _healthCheckInterval = Duration(minutes: 2);
  static const Duration _metricsInterval = Duration(minutes: 5);

  /// Initialize production monitoring
  Future<void> initialize() async {
    await _startHealthChecks();
    await _startMetricsCollection();
    Logger.d('🔍 Production monitoring initialized');
  }

  /// Perform comprehensive system health check
  Future<Map<String, HealthCheckResult>> performHealthCheck() async {
    final results = <String, HealthCheckResult>{};

    results['firebase'] = await _checkFirebaseHealth();
    results['openai'] = await _checkOpenAIHealth();
    results['tensorflow'] = await _checkTensorFlowHealth();
    results['performance'] = await _checkPerformanceHealth();
    results['feature_flags'] = await _checkFeatureFlagsHealth();

    return results;
  }

  /// Check Firebase connectivity and performance
  Future<HealthCheckResult> _checkFirebaseHealth() async {
    final startTime = DateTime.now();
    
    try {
      await _firestore
          .collection('health_check')
          .doc('test')
          .get()
          .timeout(Duration(seconds: 5));

      final responseTime = DateTime.now().difference(startTime);

      return HealthCheckResult(
        service: 'firebase',
        status: responseTime.inMilliseconds > 3000 ? HealthStatus.degraded : HealthStatus.healthy,
        message: responseTime.inMilliseconds > 3000 
            ? 'Firebase responding slowly (${responseTime.inMilliseconds}ms)'
            : 'Firebase operational',
        metrics: {'response_time_ms': responseTime.inMilliseconds},
        timestamp: DateTime.now(),
        responseTime: responseTime,
      );
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime);
      return HealthCheckResult(
        service: 'firebase',
        status: HealthStatus.critical,
        message: 'Firebase connection failed: $e',
        metrics: {'error': e.toString()},
        timestamp: DateTime.now(),
        responseTime: responseTime,
      );
    }
  }

  /// Check OpenAI API health
  Future<HealthCheckResult> _checkOpenAIHealth() async {
    final startTime = DateTime.now();
    
    try {
      final performanceData = PerformanceMonitor().getDashboardData();
      final openaiMetrics = performanceData['service_stats']?['openai_service'] ?? {};
      
      final responseTime = DateTime.now().difference(startTime);
      final successRate = openaiMetrics['success_rate'] ?? 1.0;

      HealthStatus status = HealthStatus.healthy;
      String message = 'OpenAI service operational';

      if (successRate < 0.8) {
        status = HealthStatus.unhealthy;
        message = 'OpenAI success rate below threshold (${(successRate * 100).toStringAsFixed(1)}%)';
      }

      return HealthCheckResult(
        service: 'openai',
        status: status,
        message: message,
        metrics: {'success_rate': successRate},
        timestamp: DateTime.now(),
        responseTime: responseTime,
      );
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime);
      return HealthCheckResult(
        service: 'openai',
        status: HealthStatus.critical,
        message: 'OpenAI health check failed: $e',
        metrics: {'error': e.toString()},
        timestamp: DateTime.now(),
        responseTime: responseTime,
      );
    }
  }

  /// Check TensorFlow Lite health
  Future<HealthCheckResult> _checkTensorFlowHealth() async {
    final startTime = DateTime.now();
    
    try {
      final performanceData = PerformanceMonitor().getDashboardData();
      final tfMetrics = performanceData['service_stats']?['tensorflow_lite'] ?? {};
      
      final responseTime = DateTime.now().difference(startTime);
      final successRate = tfMetrics['success_rate'] ?? 1.0;

      return HealthCheckResult(
        service: 'tensorflow',
        status: successRate < 0.9 ? HealthStatus.unhealthy : HealthStatus.healthy,
        message: successRate < 0.9 
            ? 'TensorFlow Lite success rate below threshold (${(successRate * 100).toStringAsFixed(1)}%)'
            : 'TensorFlow Lite operational',
        metrics: {'success_rate': successRate},
        timestamp: DateTime.now(),
        responseTime: responseTime,
      );
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime);
      return HealthCheckResult(
        service: 'tensorflow',
        status: HealthStatus.degraded,
        message: 'TensorFlow Lite metrics unavailable: $e',
        metrics: {'error': e.toString()},
        timestamp: DateTime.now(),
        responseTime: responseTime,
      );
    }
  }

  /// Check overall performance health
  Future<HealthCheckResult> _checkPerformanceHealth() async {
    final startTime = DateTime.now();
    
    try {
      final performanceData = PerformanceMonitor().getDashboardData();
      final healthCheck = PerformanceMonitor().getHealthCheck();
      
      final responseTime = DateTime.now().difference(startTime);
      final totalCost = performanceData['total_cost_usd'] ?? 0.0;

      HealthStatus status = HealthStatus.healthy;
      String message = 'Performance metrics normal';

      if (totalCost > 50.0) {
        status = HealthStatus.degraded;
        message = 'High API costs detected (\$${totalCost.toStringAsFixed(2)})';
      }

      final openCircuitBreakers = healthCheck['open_circuit_breakers'] as List? ?? [];
      if (openCircuitBreakers.isNotEmpty) {
        status = HealthStatus.unhealthy;
        message = 'Circuit breakers triggered: ${openCircuitBreakers.join(', ')}';
      }

      return HealthCheckResult(
        service: 'performance',
        status: status,
        message: message,
        metrics: {
          'total_cost_usd': totalCost,
          'circuit_breakers_open': openCircuitBreakers.length,
        },
        timestamp: DateTime.now(),
        responseTime: responseTime,
      );
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime);
      return HealthCheckResult(
        service: 'performance',
        status: HealthStatus.critical,
        message: 'Performance monitoring failed: $e',
        metrics: {'error': e.toString()},
        timestamp: DateTime.now(),
        responseTime: responseTime,
      );
    }
  }

  /// Check feature flags health
  Future<HealthCheckResult> _checkFeatureFlagsHealth() async {
    final startTime = DateTime.now();
    
    try {
      final featureFlagService = FeatureFlagService();
      final allFlags = await featureFlagService.getAllFlagStatuses(version: '4.0.0');
      
      final responseTime = DateTime.now().difference(startTime);
      final enabledFlags = allFlags.values.where((enabled) => enabled).length;
      final totalFlags = allFlags.length;

      return HealthCheckResult(
        service: 'feature_flags',
        status: HealthStatus.healthy,
        message: 'Feature flags operational ($enabledFlags/$totalFlags enabled)',
        metrics: {
          'enabled_flags': enabledFlags,
          'total_flags': totalFlags,
        },
        timestamp: DateTime.now(),
        responseTime: responseTime,
      );
    } catch (e) {
      final responseTime = DateTime.now().difference(startTime);
      return HealthCheckResult(
        service: 'feature_flags',
        status: HealthStatus.degraded,
        message: 'Feature flags check failed: $e',
        metrics: {'error': e.toString()},
        timestamp: DateTime.now(),
        responseTime: responseTime,
      );
    }
  }

  /// Start automated health checks
  Future<void> _startHealthChecks() async {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (timer) async {
      try {
        final healthResults = await performHealthCheck();
        await _storeHealthCheckResults(healthResults);
      } catch (e) {
        Logger.d('❌ Health check failed: $e');
      }
    });
  }

  /// Start metrics collection
  Future<void> _startMetricsCollection() async {
    _metricsCollectionTimer?.cancel();
    _metricsCollectionTimer = Timer.periodic(_metricsInterval, (timer) async {
      try {
        await _collectAndStoreMetrics();
      } catch (e) {
        Logger.d('❌ Metrics collection failed: $e');
      }
    });
  }

  /// Store health check results
  Future<void> _storeHealthCheckResults(Map<String, HealthCheckResult> results) async {
    try {
      final batch = _firestore.batch();
      
      for (final entry in results.entries) {
        final docRef = _firestore
            .collection('health_checks')
            .doc('${entry.key}_${DateTime.now().millisecondsSinceEpoch}');
        batch.set(docRef, entry.value.toJson());
      }

      await batch.commit();
    } catch (e) {
      Logger.d('❌ Failed to store health check results: $e');
    }
  }

  /// Collect and store production metrics
  Future<void> _collectAndStoreMetrics() async {
    try {
      final performanceData = PerformanceMonitor().getDashboardData();
      
      await _firestore
          .collection('production_metrics')
          .doc('metrics_${DateTime.now().millisecondsSinceEpoch}')
          .set({
            ...performanceData,
            'collected_at': DateTime.now().toIso8601String(),
            'version': '4.0.0',
          });
    } catch (e) {
      Logger.d('❌ Failed to store production metrics: $e');
    }
  }

  /// Get current system status
  Map<String, dynamic> getSystemStatus() {
    final performanceData = PerformanceMonitor().getDashboardData();
    final healthCheck = PerformanceMonitor().getHealthCheck();
    
    return {
      'overall_status': healthCheck['status'],
      'total_operations': performanceData['total_operations'],
      'success_rate': performanceData['successful_operations'] / (performanceData['total_operations'] + 1),
      'average_response_time_ms': performanceData['average_response_time_ms'],
      'total_cost_usd': performanceData['total_cost_usd'],
      'circuit_breakers_open': (healthCheck['open_circuit_breakers'] as List? ?? []).length,
      'last_health_check': DateTime.now().toIso8601String(),
    };
  }

  /// Emergency rollback procedure
  Future<bool> initiateEmergencyRollback(String reason) async {
    try {
      Logger.d('🚨 INITIATING EMERGENCY ROLLBACK: $reason');

      final featureFlagService = FeatureFlagService();
      
      // Disable advanced features
      await featureFlagService.updateFeatureFlag(FeatureFlagConfig(
        flag: FeatureFlag.nutritionalQueries,
        enabled: false,
        rolloutPercentage: 0.0,
      ));
      
      await featureFlagService.updateFeatureFlag(FeatureFlagConfig(
        flag: FeatureFlag.usdaKnowledgeBase,
        enabled: false,
        rolloutPercentage: 0.0,
      ));

      return true;
    } catch (e) {
      Logger.d('❌ Emergency rollback failed: $e');
      return false;
    }
  }

  /// Cleanup resources
  void dispose() {
    _healthCheckTimer?.cancel();
    _metricsCollectionTimer?.cancel();
  }
} 