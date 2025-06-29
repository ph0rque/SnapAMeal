/// Performance Monitoring Utility for SnapAMeal
/// Tracks performance metrics for all AI and database operations
library;

import 'dart:collection';
import '../utils/logger.dart';

/// Performance metric data structure
class PerformanceMetric {
  final String operation;
  final String service;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  PerformanceMetric({
    required this.operation,
    required this.service,
    required this.startTime,
    required this.endTime,
    required this.success,
    this.errorMessage,
    this.metadata = const {},
  }) : duration = endTime.difference(startTime);

  Map<String, dynamic> toJson() {
    return {
      'operation': operation,
      'service': service,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_ms': duration.inMilliseconds,
      'success': success,
      'error_message': errorMessage,
      'metadata': metadata,
    };
  }
}

/// Service-specific performance statistics
class ServiceStats {
  final String serviceName;
  int totalOperations = 0;
  int successfulOperations = 0;
  int failedOperations = 0;
  double totalDurationMs = 0.0;
  double averageDurationMs = 0.0;
  double minDurationMs = double.infinity;
  double maxDurationMs = 0.0;
  final Map<String, int> operationCounts = {};

  ServiceStats(this.serviceName);

  void addMetric(PerformanceMetric metric) {
    totalOperations++;
    
    if (metric.success) {
      successfulOperations++;
    } else {
      failedOperations++;
    }

    final durationMs = metric.duration.inMilliseconds.toDouble();
    totalDurationMs += durationMs;
    averageDurationMs = totalDurationMs / totalOperations;
    
    if (durationMs < minDurationMs) {
      minDurationMs = durationMs;
    }
    
    if (durationMs > maxDurationMs) {
      maxDurationMs = durationMs;
    }

    operationCounts[metric.operation] = (operationCounts[metric.operation] ?? 0) + 1;
  }

  double get successRate => totalOperations > 0 ? successfulOperations / totalOperations : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'service_name': serviceName,
      'total_operations': totalOperations,
      'successful_operations': successfulOperations,
      'failed_operations': failedOperations,
      'success_rate': successRate,
      'average_duration_ms': averageDurationMs,
      'min_duration_ms': minDurationMs == double.infinity ? 0.0 : minDurationMs,
      'max_duration_ms': maxDurationMs,
      'operation_counts': operationCounts,
    };
  }
}

/// Cost tracking for external APIs
class CostTracker {
  final Map<String, double> _costs = {};
  final Map<String, int> _usageCounts = {};
  
  static const Map<String, double> _costPerOperation = {
    'openai_completion': 0.002,
    'openai_embedding': 0.0001,
    'tensorflow_inference': 0.0, // Local processing
    'firebase_query': 0.0, // Free tier
  };

  void trackUsage(String operation, {int count = 1}) {
    _usageCounts[operation] = (_usageCounts[operation] ?? 0) + count;
    final cost = (_costPerOperation[operation] ?? 0.0) * count;
    _costs[operation] = (_costs[operation] ?? 0.0) + cost;
  }

  double getTotalCost() => _costs.values.fold(0.0, (sum, cost) => sum + cost);
  Map<String, double> getCostBreakdown() => Map.from(_costs);
  Map<String, int> getUsageBreakdown() => Map.from(_usageCounts);

  void reset() {
    _costs.clear();
    _usageCounts.clear();
  }
}

/// Circuit breaker for external service failures
class CircuitBreaker {
  final String serviceName;
  final int failureThreshold;
  final Duration recoveryTimeout;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;

  CircuitBreaker({
    required this.serviceName,
    this.failureThreshold = 5,
    this.recoveryTimeout = const Duration(minutes: 5),
  });

  bool get isOpen => _isOpen;
  
  bool canExecute() {
    if (!_isOpen) return true;
    
    if (_lastFailureTime != null && 
        DateTime.now().difference(_lastFailureTime!) > recoveryTimeout) {
      _reset();
      return true;
    }
    
    return false;
  }

  void recordSuccess() => _reset();

  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _isOpen = true;
      Logger.d('🔴 Circuit breaker opened for $serviceName');
    }
  }

  void _reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _isOpen = false;
  }

  /// Manually reset the circuit breaker (for external use)
  void reset() => _reset();

  Map<String, dynamic> getStatus() {
    return {
      'service_name': serviceName,
      'is_open': _isOpen,
      'failure_count': _failureCount,
      'last_failure_time': _lastFailureTime?.toIso8601String(),
    };
  }
}

/// Main performance monitoring service
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, ServiceStats> _serviceStats = {};
  final Queue<PerformanceMetric> _recentMetrics = Queue();
  final CostTracker _costTracker = CostTracker();
  final Map<String, CircuitBreaker> _circuitBreakers = {};
  
  static const int _maxRecentMetrics = 1000;
  bool _isEnabled = true;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  PerformanceTimer startTimer(String operation, String service, {Map<String, dynamic>? metadata}) {
    if (!_isEnabled) return PerformanceTimer._disabled();
    
    return PerformanceTimer._(
      operation: operation,
      service: service,
      startTime: DateTime.now(),
      metadata: metadata ?? {},
      monitor: this,
    );
  }

  void _recordMetric(PerformanceMetric metric) {
    if (!_isEnabled) return;

    if (_recentMetrics.length >= _maxRecentMetrics) {
      _recentMetrics.removeFirst();
    }
    _recentMetrics.addLast(metric);

    _serviceStats[metric.service] ??= ServiceStats(metric.service);
    _serviceStats[metric.service]!.addMetric(metric);

    final circuitBreaker = _getCircuitBreaker(metric.service);
    if (metric.success) {
      circuitBreaker.recordSuccess();
    } else {
      circuitBreaker.recordFailure();
    }

    _trackCostForMetric(metric);

    if (metric.duration.inMilliseconds > 5000 || !metric.success) {
      Logger.d('⚡ ${metric.service}.${metric.operation}: ${metric.duration.inMilliseconds}ms');
    }
  }

  CircuitBreaker _getCircuitBreaker(String service) {
    return _circuitBreakers[service] ??= CircuitBreaker(serviceName: service);
  }

  void _trackCostForMetric(PerformanceMetric metric) {
    switch (metric.service.toLowerCase()) {
      case 'openai':
        if (metric.operation.contains('completion')) {
          _costTracker.trackUsage('openai_completion');
        } else if (metric.operation.contains('embedding')) {
          _costTracker.trackUsage('openai_embedding');
        }
        break;
      case 'tensorflow':
        _costTracker.trackUsage('tensorflow_inference');
        break;
      case 'firebase':
        _costTracker.trackUsage('firebase_query');
        break;
    }
  }

  bool isServiceAvailable(String service) {
    if (!_isEnabled) return true;
    return _getCircuitBreaker(service).canExecute();
  }

  Map<String, dynamic> getDashboardData() {
    if (!_isEnabled) return {'monitoring_enabled': false};

    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final recentMetrics = _recentMetrics.where((m) => m.startTime.isAfter(last24Hours)).toList();

    return {
      'monitoring_enabled': true,
      'generated_at': now.toIso8601String(),
      'total_operations': recentMetrics.length,
      'successful_operations': recentMetrics.where((m) => m.success).length,
      'failed_operations': recentMetrics.where((m) => !m.success).length,
      'average_response_time_ms': recentMetrics.isNotEmpty
          ? recentMetrics.map((m) => m.duration.inMilliseconds).reduce((a, b) => a + b) / recentMetrics.length
          : 0.0,
      'service_stats': _serviceStats.map((key, value) => MapEntry(key, value.toJson())),
      'cost_tracking': _costTracker.getCostBreakdown(),
      'total_cost_usd': _costTracker.getTotalCost(),
      'circuit_breakers': _circuitBreakers.map((key, value) => MapEntry(key, value.getStatus())),
    };
  }

  Map<String, dynamic> getHealthCheck() {
    final openBreakers = _circuitBreakers.values.where((cb) => cb.isOpen).map((cb) => cb.serviceName).toList();
    final totalCost = _costTracker.getTotalCost();
    
    return {
      'status': openBreakers.isEmpty ? 'healthy' : 'degraded',
      'monitoring_enabled': _isEnabled,
      'open_circuit_breakers': openBreakers,
      'total_cost_24h_usd': totalCost,
      'cost_alert': totalCost > 10.0,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  void clearData() {
    _recentMetrics.clear();
    _serviceStats.clear();
    _costTracker.reset();
    _circuitBreakers.clear();
  }

  /// Reset circuit breaker for a specific service
  void resetCircuitBreaker(String service) {
    final circuitBreaker = _circuitBreakers[service];
    if (circuitBreaker != null) {
      circuitBreaker.reset();
      Logger.d('🟢 Circuit breaker reset for $service');
    }
  }

  /// Reset all circuit breakers
  void resetAllCircuitBreakers() {
    for (final circuitBreaker in _circuitBreakers.values) {
      circuitBreaker.reset();
    }
    Logger.d('🟢 All circuit breakers reset');
  }
}

/// Timer class for measuring operation performance
class PerformanceTimer {
  final String operation;
  final String service;
  final DateTime startTime;
  final Map<String, dynamic> metadata;
  final PerformanceMonitor? monitor;
  bool _completed = false;

  PerformanceTimer._({
    required this.operation,
    required this.service,
    required this.startTime,
    required this.metadata,
    required this.monitor,
  });

  PerformanceTimer._disabled()
      : operation = '',
        service = '',
        startTime = DateTime.now(),
        metadata = {},
        monitor = null;

  void complete({Map<String, dynamic>? additionalMetadata}) {
    if (_completed || monitor == null) return;
    
    _completed = true;
    final metric = PerformanceMetric(
      operation: operation,
      service: service,
      startTime: startTime,
      endTime: DateTime.now(),
      success: true,
      metadata: {...metadata, ...?additionalMetadata},
    );

    monitor!._recordMetric(metric);
  }

  void fail(String errorMessage, {Map<String, dynamic>? additionalMetadata}) {
    if (_completed || monitor == null) return;
    
    _completed = true;
    final metric = PerformanceMetric(
      operation: operation,
      service: service,
      startTime: startTime,
      endTime: DateTime.now(),
      success: false,
      errorMessage: errorMessage,
      metadata: {...metadata, ...?additionalMetadata},
    );

    monitor!._recordMetric(metric);
  }

  Duration get elapsed => DateTime.now().difference(startTime);
} 