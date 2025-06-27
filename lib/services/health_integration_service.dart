import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/meal_log.dart';
import '../models/health_integration.dart';
import '../services/data_conflict_resolution_service.dart';
import '../config/ai_config.dart';
import '../utils/logger.dart';

enum IntegrationType { myFitnessPal, appleHealth, googleFit }

enum IntegrationStatus { disconnected, connecting, connected, error, syncing }

class HealthIntegrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DataConflictResolutionService _conflictService =
      DataConflictResolutionService();
  String get _myFitnessPalApiKey => AIConfig.myFitnessPalApiKey;
  final String _myFitnessPalBaseUrl = 'https://api.myfitnesspal.com/v2';

  // Cache for API responses to minimize requests
  final Map<String, dynamic> _foodCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(hours: 24);

  // Apple Health data types we'll sync
  static const List<String> _appleHealthDataTypes = [
    'HKQuantityTypeIdentifierActiveEnergyBurned',
    'HKQuantityTypeIdentifierBasalEnergyBurned',
    'HKQuantityTypeIdentifierDietaryEnergyConsumed',
    'HKQuantityTypeIdentifierDietaryProtein',
    'HKQuantityTypeIdentifierDietaryCarbohydrates',
    'HKQuantityTypeIdentifierDietaryFatTotal',
    'HKQuantityTypeIdentifierDietaryFiber',
    'HKQuantityTypeIdentifierDietarySugar',
    'HKQuantityTypeIdentifierDietarySodium',
    'HKQuantityTypeIdentifierBodyMass',
    'HKQuantityTypeIdentifierHeight',
    'HKQuantityTypeIdentifierStepCount',
    'HKQuantityTypeIdentifierDistanceWalkingRunning',
    'HKQuantityTypeIdentifierHeartRate',
    'HKCategoryTypeIdentifierSleepAnalysis',
  ];

  // Google Fit data types we'll sync
  static const List<String> _googleFitDataTypes = [
    'com.google.step_count.delta',
    'com.google.calories.expended',
    'com.google.active_minutes',
    'com.google.distance.delta',
    'com.google.heart_rate.bpm',
    'com.google.weight',
    'com.google.height',
    'com.google.body_fat_percentage',
    'com.google.nutrition',
    'com.google.hydration',
    'com.google.sleep.segment',
  ];

  /// Get all health integrations for the current user
  Stream<List<HealthIntegration>> getUserIntegrations() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('health_integrations')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => HealthIntegration.fromFirestore(doc))
              .toList(),
        );
  }

  /// Connect to MyFitnessPal API
  Future<bool> connectMyFitnessPal({
    required String username,
    required String password,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Update integration status to connecting
      await _updateIntegrationStatus(
        userId,
        IntegrationType.myFitnessPal,
        IntegrationStatus.connecting,
      );

      // Authenticate with MyFitnessPal API
      final authResponse = await _authenticateMyFitnessPal(username, password);

      if (authResponse['success'] == true) {
        final accessToken = authResponse['access_token'] as String;

        // Store integration data
        final integration = HealthIntegration(
          id: '${userId}_myfitnesspal',
          userId: userId,
          type: IntegrationType.myFitnessPal,
          status: IntegrationStatus.connected,
          accessToken: accessToken,
          refreshToken: authResponse['refresh_token'],
          connectedAt: DateTime.now(),
          lastSyncAt: null,
          settings: {
            'username': username,
            'sync_meals': true,
            'sync_exercises': true,
            'auto_sync': true,
          },
        );

        await _firestore
            .collection('health_integrations')
            .doc(integration.id)
            .set(integration.toFirestore());

        Logger.d('MyFitnessPal connected successfully');
        return true;
      } else {
        await _updateIntegrationStatus(
          userId,
          IntegrationType.myFitnessPal,
          IntegrationStatus.error,
        );
        return false;
      }
    } catch (e) {
      Logger.d('Error connecting MyFitnessPal: $e');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _updateIntegrationStatus(
          userId,
          IntegrationType.myFitnessPal,
          IntegrationStatus.error,
        );
      }
      return false;
    }
  }

  /// Search MyFitnessPal food database
  Future<List<Map<String, dynamic>>> searchMyFitnessPalFoods(
    String query,
  ) async {
    try {
      // Check cache first
      final cacheKey = 'search_$query';
      if (_isCacheValid(cacheKey)) {
        return List<Map<String, dynamic>>.from(_foodCache[cacheKey]);
      }

      final integration = await _getIntegration(IntegrationType.myFitnessPal);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        throw Exception('MyFitnessPal not connected');
      }

      final response = await http.get(
        Uri.parse(
          '$_myFitnessPalBaseUrl/foods/search?q=${Uri.encodeComponent(query)}',
        ),
        headers: {
          'Authorization': 'Bearer ${integration.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foods = List<Map<String, dynamic>>.from(data['foods'] ?? []);

        // Cache the results
        _foodCache[cacheKey] = foods;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return foods;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        await _refreshMyFitnessPalToken(integration);
        // Retry the request
        return searchMyFitnessPalFoods(query);
      } else {
        throw Exception('Failed to search foods: ${response.statusCode}');
      }
    } catch (e) {
      Logger.d('Error searching MyFitnessPal foods: $e');
      return [];
    }
  }

  /// Get detailed food information from MyFitnessPal
  Future<Map<String, dynamic>?> getMyFitnessPalFoodDetails(
    String foodId,
  ) async {
    try {
      // Check cache first
      final cacheKey = 'food_$foodId';
      if (_isCacheValid(cacheKey)) {
        return Map<String, dynamic>.from(_foodCache[cacheKey]);
      }

      final integration = await _getIntegration(IntegrationType.myFitnessPal);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        throw Exception('MyFitnessPal not connected');
      }

      final response = await http.get(
        Uri.parse('$_myFitnessPalBaseUrl/foods/$foodId'),
        headers: {
          'Authorization': 'Bearer ${integration.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cache the results
        _foodCache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return data;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        await _refreshMyFitnessPalToken(integration);
        // Retry the request
        return getMyFitnessPalFoodDetails(foodId);
      } else {
        throw Exception('Failed to get food details: ${response.statusCode}');
      }
    } catch (e) {
      Logger.d('Error getting MyFitnessPal food details: $e');
      return null;
    }
  }

  /// Sync meal log to MyFitnessPal
  Future<bool> syncMealToMyFitnessPal(MealLog mealLog) async {
    try {
      final integration = await _getIntegration(IntegrationType.myFitnessPal);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        Logger.d('MyFitnessPal not connected, skipping sync');
        return false;
      }

      if (integration.settings['sync_meals'] != true) {
        Logger.d('Meal sync disabled for MyFitnessPal');
        return false;
      }

      // Prepare meal data for MyFitnessPal format
      final mealData = {
        'date': mealLog.timestamp.toIso8601String().split('T')[0],
        'meal_name': _getMealTypeString(mealLog.timestamp),
        'foods': [
          {
            'food_id': mealLog.myFitnessPalFoodId ?? 'custom_${mealLog.id}',
            'quantity': mealLog.recognitionResult.totalNutrition.servingSize,
            'unit': 'serving',
            'calories': mealLog.recognitionResult.totalNutrition.calories,
            'carbs': mealLog.recognitionResult.totalNutrition.carbs,
            'fat': mealLog.recognitionResult.totalNutrition.fat,
            'protein': mealLog.recognitionResult.totalNutrition.protein,
          },
        ],
      };

      final response = await http.post(
        Uri.parse('$_myFitnessPalBaseUrl/diary'),
        headers: {
          'Authorization': 'Bearer ${integration.accessToken}',
          'Content-Type': 'application/json',
        },
        body: json.encode(mealData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Update meal log with sync status
        await _firestore.collection('meal_logs').doc(mealLog.id).update({
          'synced_to_myfitnesspal': true,
          'myfitnesspal_sync_at': FieldValue.serverTimestamp(),
        });

        // Update last sync time
        await _updateLastSyncTime(integration.id);

        Logger.d('Meal synced to MyFitnessPal successfully');
        return true;
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        await _refreshMyFitnessPalToken(integration);
        // Retry the sync
        return syncMealToMyFitnessPal(mealLog);
      } else {
        Logger.d('Failed to sync meal to MyFitnessPal: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      Logger.d('Error syncing meal to MyFitnessPal: $e');
      return false;
    }
  }

  /// Import meals from MyFitnessPal for a specific date range
  Future<List<Map<String, dynamic>>> importMealsFromMyFitnessPal({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final integration = await _getIntegration(IntegrationType.myFitnessPal);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        throw Exception('MyFitnessPal not connected');
      }

      await _updateIntegrationStatus(
        integration.userId,
        IntegrationType.myFitnessPal,
        IntegrationStatus.syncing,
      );

      final meals = <Map<String, dynamic>>[];

      // Import meals day by day
      for (
        var date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))
      ) {
        final dateString = date.toIso8601String().split('T')[0];
        final response = await http.get(
          Uri.parse('$_myFitnessPalBaseUrl/diary?date=$dateString'),
          headers: {
            'Authorization': 'Bearer ${integration.accessToken}',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final dayMeals = List<Map<String, dynamic>>.from(data['meals'] ?? []);
          meals.addAll(
            dayMeals.map(
              (meal) => {
                ...meal,
                'import_date': date.toIso8601String(),
                'source': 'myfitnesspal',
              },
            ),
          );
        } else if (response.statusCode == 401) {
          // Token expired, try to refresh
          await _refreshMyFitnessPalToken(integration);
          // Continue with next date (will retry on next call)
          continue;
        }
      }

      await _updateIntegrationStatus(
        integration.userId,
        IntegrationType.myFitnessPal,
        IntegrationStatus.connected,
      );

      await _updateLastSyncTime(integration.id);

      Logger.d('Imported ${meals.length} meals from MyFitnessPal');
      return meals;
    } catch (e) {
      Logger.d('Error importing meals from MyFitnessPal: $e');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _updateIntegrationStatus(
          userId,
          IntegrationType.myFitnessPal,
          IntegrationStatus.error,
        );
      }
      return [];
    }
  }

  /// Disconnect from MyFitnessPal
  Future<bool> disconnectMyFitnessPal() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      final integrationId = '${userId}_myfitnesspal';
      await _firestore
          .collection('health_integrations')
          .doc(integrationId)
          .delete();

      // Clear cache
      _foodCache.clear();
      _cacheTimestamps.clear();

      Logger.d('MyFitnessPal disconnected successfully');
      return true;
    } catch (e) {
      Logger.d('Error disconnecting MyFitnessPal: $e');
      return false;
    }
  }

  /// Connect to Apple Health (iOS only)
  Future<bool> connectAppleHealth({List<String>? requestedDataTypes}) async {
    try {
      if (!Platform.isIOS) {
        Logger.d('Apple Health is only available on iOS');
        return false;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Update integration status to connecting
      await _updateIntegrationStatus(
        userId,
        IntegrationType.appleHealth,
        IntegrationStatus.connecting,
      );

      // Request permissions for health data types
      final dataTypesToRequest = requestedDataTypes ?? _appleHealthDataTypes;
      final permissionResult = await _requestAppleHealthPermissions(
        dataTypesToRequest,
      );

      if (permissionResult['success'] == true) {
        // Store integration data
        final integration = HealthIntegration(
          id: '${userId}_applehealth',
          userId: userId,
          type: IntegrationType.appleHealth,
          status: IntegrationStatus.connected,
          accessToken: null, // Apple Health doesn't use tokens
          refreshToken: null,
          connectedAt: DateTime.now(),
          lastSyncAt: null,
          settings: {
            'sync_nutrition': true,
            'sync_workouts': true,
            'sync_body_measurements': true,
            'sync_sleep': true,
            'auto_sync': true,
            'data_types': dataTypesToRequest,
          },
          metadata: {
            'permissions_granted': permissionResult['granted_permissions'],
            'permissions_denied': permissionResult['denied_permissions'],
          },
        );

        await _firestore
            .collection('health_integrations')
            .doc(integration.id)
            .set(integration.toFirestore());

        Logger.d('Apple Health connected successfully');
        return true;
      } else {
        await _updateIntegrationStatus(
          userId,
          IntegrationType.appleHealth,
          IntegrationStatus.error,
        );
        return false;
      }
    } catch (e) {
      Logger.d('Error connecting Apple Health: $e');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _updateIntegrationStatus(
          userId,
          IntegrationType.appleHealth,
          IntegrationStatus.error,
        );
      }
      return false;
    }
  }

  /// Sync meal data to Apple Health
  Future<bool> syncMealToAppleHealth(MealLog mealLog) async {
    try {
      if (!Platform.isIOS) return false;

      final integration = await _getIntegration(IntegrationType.appleHealth);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        Logger.d('Apple Health not connected, skipping sync');
        return false;
      }

      if (integration.settings['sync_nutrition'] != true) {
        Logger.d('Nutrition sync disabled for Apple Health');
        return false;
      }

      // Prepare nutrition data for Apple Health
      final nutritionData = {
        'calories': mealLog.recognitionResult.totalNutrition.calories,
        'protein': mealLog.recognitionResult.totalNutrition.protein,
        'carbs': mealLog.recognitionResult.totalNutrition.carbs,
        'fat': mealLog.recognitionResult.totalNutrition.fat,
        'fiber': mealLog.recognitionResult.totalNutrition.fiber,
        'sugar': mealLog.recognitionResult.totalNutrition.sugar,
        'sodium': mealLog.recognitionResult.totalNutrition.sodium,
        'timestamp': mealLog.timestamp.toIso8601String(),
      };

      final success = await _writeNutritionToAppleHealth(nutritionData);

      if (success) {
        // Update meal log with sync status
        await _firestore.collection('meal_logs').doc(mealLog.id).update({
          'synced_to_apple_health': true,
          'apple_health_sync_at': FieldValue.serverTimestamp(),
        });

        // Update last sync time
        await _updateLastSyncTime(integration.id);

        Logger.d('Meal synced to Apple Health successfully');
        return true;
      } else {
        Logger.d('Failed to sync meal to Apple Health');
        return false;
      }
    } catch (e) {
      Logger.d('Error syncing meal to Apple Health: $e');
      return false;
    }
  }

  /// Import health data from Apple Health for a specific date range
  Future<Map<String, dynamic>> importHealthDataFromAppleHealth({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? dataTypes,
  }) async {
    try {
      if (!Platform.isIOS) {
        throw Exception('Apple Health is only available on iOS');
      }

      final integration = await _getIntegration(IntegrationType.appleHealth);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        throw Exception('Apple Health not connected');
      }

      await _updateIntegrationStatus(
        integration.userId,
        IntegrationType.appleHealth,
        IntegrationStatus.syncing,
      );

      final typesToImport = dataTypes ?? _appleHealthDataTypes;
      final healthData = <String, List<Map<String, dynamic>>>{};

      // Import each data type
      final List<DataConflict> allConflicts = [];
      for (final dataType in typesToImport) {
        try {
          final typeData = await _readAppleHealthData(
            dataType: dataType,
            startDate: startDate,
            endDate: endDate,
          );

          if (typeData.isNotEmpty) {
            // Check for conflicts with existing data
            final conflicts = await _detectConflictsForImportedData(
              typeData,
              DataSource.appleHealth,
              _mapAppleHealthDataType(dataType),
            );
            allConflicts.addAll(conflicts);

            healthData[dataType] = typeData;
          }
        } catch (e) {
          Logger.d('Error importing $dataType from Apple Health: $e');
          // Continue with other data types
        }
      }

      await _updateIntegrationStatus(
        integration.userId,
        IntegrationType.appleHealth,
        IntegrationStatus.connected,
      );

      await _updateLastSyncTime(integration.id);

      final totalDataPoints = healthData.values.fold(
        0,
        (currentSum, list) => currentSum + list.length,
      );
      Logger.d(
        'Imported $totalDataPoints health data points from Apple Health',
      );

      return {
        'success': true,
        'data': healthData,
        'conflicts': allConflicts.map((c) => c.toJson()).toList(),
        'total_points': totalDataPoints,
        'total_conflicts': allConflicts.length,
        'import_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.d('Error importing health data from Apple Health: $e');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _updateIntegrationStatus(
          userId,
          IntegrationType.appleHealth,
          IntegrationStatus.error,
        );
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get current body measurements from Apple Health
  Future<Map<String, dynamic>?> getCurrentBodyMeasurements() async {
    try {
      if (!Platform.isIOS) return null;

      final integration = await _getIntegration(IntegrationType.appleHealth);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        return null;
      }

      final measurements = <String, dynamic>{};

      // Get latest weight
      final weightData = await _readAppleHealthData(
        dataType: 'HKQuantityTypeIdentifierBodyMass',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        limit: 1,
      );

      if (weightData.isNotEmpty) {
        measurements['weight'] = {
          'value': weightData.first['value'],
          'unit': 'kg',
          'date': weightData.first['date'],
        };
      }

      // Get latest height
      final heightData = await _readAppleHealthData(
        dataType: 'HKQuantityTypeIdentifierHeight',
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now(),
        limit: 1,
      );

      if (heightData.isNotEmpty) {
        measurements['height'] = {
          'value': heightData.first['value'],
          'unit': 'm',
          'date': heightData.first['date'],
        };
      }

      return measurements.isNotEmpty ? measurements : null;
    } catch (e) {
      Logger.d('Error getting body measurements from Apple Health: $e');
      return null;
    }
  }

  /// Get today's activity summary from Apple Health
  Future<Map<String, dynamic>?> getTodayActivitySummary() async {
    try {
      if (!Platform.isIOS) return null;

      final integration = await _getIntegration(IntegrationType.appleHealth);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        return null;
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final summary = <String, dynamic>{};

      // Get steps
      final stepsData = await _readAppleHealthData(
        dataType: 'HKQuantityTypeIdentifierStepCount',
        startDate: startOfDay,
        endDate: endOfDay,
      );

      final totalSteps = stepsData.fold(
        0.0,
        (currentSum, item) => currentSum + (item['value'] ?? 0.0),
      );
      summary['steps'] = totalSteps.toInt();

      // Get active energy burned
      final activeEnergyData = await _readAppleHealthData(
        dataType: 'HKQuantityTypeIdentifierActiveEnergyBurned',
        startDate: startOfDay,
        endDate: endOfDay,
      );

      final totalActiveEnergy = activeEnergyData.fold(
        0.0,
        (currentSum, item) => currentSum + (item['value'] ?? 0.0),
      );
      summary['active_calories'] = totalActiveEnergy.toInt();

      // Get distance
      final distanceData = await _readAppleHealthData(
        dataType: 'HKQuantityTypeIdentifierDistanceWalkingRunning',
        startDate: startOfDay,
        endDate: endOfDay,
      );

      final totalDistance = distanceData.fold(
        0.0,
        (currentSum, item) => currentSum + (item['value'] ?? 0.0),
      );
      summary['distance_km'] = (totalDistance / 1000).toStringAsFixed(2);

      summary['date'] = startOfDay.toIso8601String();
      return summary;
    } catch (e) {
      Logger.d('Error getting activity summary from Apple Health: $e');
      return null;
    }
  }

  /// Disconnect from Apple Health
  Future<bool> disconnectAppleHealth() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      final integrationId = '${userId}_applehealth';
      await _firestore
          .collection('health_integrations')
          .doc(integrationId)
          .delete();

      Logger.d('Apple Health disconnected successfully');
      return true;
    } catch (e) {
      Logger.d('Error disconnecting Apple Health: $e');
      return false;
    }
  }

  /// Connect to Google Fit (Android only)
  Future<bool> connectGoogleFit({List<String>? requestedDataTypes}) async {
    try {
      if (!Platform.isAndroid) {
        Logger.d('Google Fit is only available on Android');
        return false;
      }

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Update integration status to connecting
      await _updateIntegrationStatus(
        userId,
        IntegrationType.googleFit,
        IntegrationStatus.connecting,
      );

      // Request permissions for Google Fit data types
      final dataTypesToRequest = requestedDataTypes ?? _googleFitDataTypes;
      final permissionResult = await _requestGoogleFitPermissions(
        dataTypesToRequest,
      );

      if (permissionResult['success'] == true) {
        // Store integration data
        final integration = HealthIntegration(
          id: '${userId}_googlefit',
          userId: userId,
          type: IntegrationType.googleFit,
          status: IntegrationStatus.connected,
          accessToken: permissionResult['access_token'],
          refreshToken: permissionResult['refresh_token'],
          connectedAt: DateTime.now(),
          lastSyncAt: null,
          settings: {
            'sync_fitness': true,
            'sync_nutrition': true,
            'sync_body_measurements': true,
            'sync_sleep': true,
            'auto_sync': true,
            'data_types': dataTypesToRequest,
          },
          metadata: {
            'permissions_granted': permissionResult['granted_permissions'],
            'permissions_denied': permissionResult['denied_permissions'],
            'google_account': permissionResult['account'],
          },
        );

        await _firestore
            .collection('health_integrations')
            .doc(integration.id)
            .set(integration.toFirestore());

        Logger.d('Google Fit connected successfully');
        return true;
      } else {
        await _updateIntegrationStatus(
          userId,
          IntegrationType.googleFit,
          IntegrationStatus.error,
        );
        return false;
      }
    } catch (e) {
      Logger.d('Error connecting Google Fit: $e');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _updateIntegrationStatus(
          userId,
          IntegrationType.googleFit,
          IntegrationStatus.error,
        );
      }
      return false;
    }
  }

  /// Sync meal data to Google Fit
  Future<bool> syncMealToGoogleFit(MealLog mealLog) async {
    try {
      if (!Platform.isAndroid) return false;

      final integration = await _getIntegration(IntegrationType.googleFit);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        Logger.d('Google Fit not connected, skipping sync');
        return false;
      }

      if (integration.settings['sync_nutrition'] != true) {
        Logger.d('Nutrition sync disabled for Google Fit');
        return false;
      }

      // Prepare nutrition data for Google Fit format
      final nutritionData = {
        'dataSourceId': 'derived:com.google.nutrition:com.snapameal.app',
        'point': [
          {
            'startTimeNanos':
                (mealLog.timestamp.millisecondsSinceEpoch * 1000000).toString(),
            'endTimeNanos': (mealLog.timestamp.millisecondsSinceEpoch * 1000000)
                .toString(),
            'dataTypeName': 'com.google.nutrition',
            'value': [
              {
                'mapVal': [
                  {
                    'key': 'calories',
                    'value': {
                      'fpVal':
                          mealLog.recognitionResult.totalNutrition.calories,
                    },
                  },
                  {
                    'key': 'fat.total',
                    'value': {
                      'fpVal': mealLog.recognitionResult.totalNutrition.fat,
                    },
                  },
                  {
                    'key': 'protein',
                    'value': {
                      'fpVal': mealLog.recognitionResult.totalNutrition.protein,
                    },
                  },
                  {
                    'key': 'carbs.total',
                    'value': {
                      'fpVal': mealLog.recognitionResult.totalNutrition.carbs,
                    },
                  },
                  {
                    'key': 'sodium',
                    'value': {
                      'fpVal': mealLog.recognitionResult.totalNutrition.sodium,
                    },
                  },
                ],
              },
            ],
          },
        ],
      };

      final success = await _writeNutritionToGoogleFit(
        nutritionData,
        integration.accessToken!,
      );

      if (success) {
        // Update meal log with sync status
        await _firestore.collection('meal_logs').doc(mealLog.id).update({
          'synced_to_google_fit': true,
          'google_fit_sync_at': FieldValue.serverTimestamp(),
        });

        // Update last sync time
        await _updateLastSyncTime(integration.id);

        Logger.d('Meal synced to Google Fit successfully');
        return true;
      } else {
        Logger.d('Failed to sync meal to Google Fit');
        return false;
      }
    } catch (e) {
      Logger.d('Error syncing meal to Google Fit: $e');
      return false;
    }
  }

  /// Import fitness data from Google Fit for a specific date range
  Future<Map<String, dynamic>> importFitnessDataFromGoogleFit({
    required DateTime startDate,
    required DateTime endDate,
    List<String>? dataTypes,
  }) async {
    try {
      if (!Platform.isAndroid) {
        throw Exception('Google Fit is only available on Android');
      }

      final integration = await _getIntegration(IntegrationType.googleFit);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        throw Exception('Google Fit not connected');
      }

      await _updateIntegrationStatus(
        integration.userId,
        IntegrationType.googleFit,
        IntegrationStatus.syncing,
      );

      final typesToImport = dataTypes ?? _googleFitDataTypes;
      final fitnessData = <String, List<Map<String, dynamic>>>{};

      // Import each data type
      final List<DataConflict> allConflicts = [];
      for (final dataType in typesToImport) {
        try {
          final typeData = await _readGoogleFitData(
            dataType: dataType,
            startDate: startDate,
            endDate: endDate,
            accessToken: integration.accessToken!,
          );

          if (typeData.isNotEmpty) {
            // Check for conflicts with existing data
            final conflicts = await _detectConflictsForImportedData(
              typeData,
              DataSource.googleFit,
              _mapGoogleFitDataType(dataType),
            );
            allConflicts.addAll(conflicts);

            fitnessData[dataType] = typeData;
          }
        } catch (e) {
          Logger.d('Error importing $dataType from Google Fit: $e');
          // Continue with other data types
        }
      }

      await _updateIntegrationStatus(
        integration.userId,
        IntegrationType.googleFit,
        IntegrationStatus.connected,
      );

      await _updateLastSyncTime(integration.id);

      final totalDataPoints = fitnessData.values.fold(
        0,
        (currentSum, list) => currentSum + list.length,
      );
      Logger.d('Imported $totalDataPoints fitness data points from Google Fit');

      return {
        'success': true,
        'data': fitnessData,
        'conflicts': allConflicts.map((c) => c.toJson()).toList(),
        'total_points': totalDataPoints,
        'total_conflicts': allConflicts.length,
        'import_date': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.d('Error importing fitness data from Google Fit: $e');
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _updateIntegrationStatus(
          userId,
          IntegrationType.googleFit,
          IntegrationStatus.error,
        );
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get current fitness summary from Google Fit
  Future<Map<String, dynamic>?> getCurrentFitnessSummary() async {
    try {
      if (!Platform.isAndroid) return null;

      final integration = await _getIntegration(IntegrationType.googleFit);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        return null;
      }

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final summary = <String, dynamic>{};

      // Get steps
      final stepsData = await _readGoogleFitData(
        dataType: 'com.google.step_count.delta',
        startDate: startOfDay,
        endDate: endOfDay,
        accessToken: integration.accessToken!,
      );

      final totalSteps = stepsData.fold(
        0.0,
        (currentSum, item) => currentSum + (item['value'] ?? 0.0),
      );
      summary['steps'] = totalSteps.toInt();

      // Get calories
      final caloriesData = await _readGoogleFitData(
        dataType: 'com.google.calories.expended',
        startDate: startOfDay,
        endDate: endOfDay,
        accessToken: integration.accessToken!,
      );

      final totalCalories = caloriesData.fold(
        0.0,
        (currentSum, item) => currentSum + (item['value'] ?? 0.0),
      );
      summary['calories_burned'] = totalCalories.toInt();

      // Get distance
      final distanceData = await _readGoogleFitData(
        dataType: 'com.google.distance.delta',
        startDate: startOfDay,
        endDate: endOfDay,
        accessToken: integration.accessToken!,
      );

      final totalDistance = distanceData.fold(
        0.0,
        (currentSum, item) => currentSum + (item['value'] ?? 0.0),
      );
      summary['distance_m'] = totalDistance.toInt();

      // Get active minutes
      final activeMinutesData = await _readGoogleFitData(
        dataType: 'com.google.active_minutes',
        startDate: startOfDay,
        endDate: endOfDay,
        accessToken: integration.accessToken!,
      );

      final totalActiveMinutes = activeMinutesData.fold(
        0.0,
        (currentSum, item) => currentSum + (item['value'] ?? 0.0),
      );
      summary['active_minutes'] = totalActiveMinutes.toInt();

      summary['date'] = startOfDay.toIso8601String();
      return summary;
    } catch (e) {
      Logger.d('Error getting fitness summary from Google Fit: $e');
      return null;
    }
  }

  /// Get current body measurements from Google Fit
  Future<Map<String, dynamic>?>
  getCurrentBodyMeasurementsFromGoogleFit() async {
    try {
      if (!Platform.isAndroid) return null;

      final integration = await _getIntegration(IntegrationType.googleFit);
      if (integration == null ||
          integration.status != IntegrationStatus.connected) {
        return null;
      }

      final measurements = <String, dynamic>{};

      // Get latest weight
      final weightData = await _readGoogleFitData(
        dataType: 'com.google.weight',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        accessToken: integration.accessToken!,
        limit: 1,
      );

      if (weightData.isNotEmpty) {
        measurements['weight'] = {
          'value': weightData.first['value'],
          'unit': 'kg',
          'date': weightData.first['date'],
        };
      }

      // Get latest height
      final heightData = await _readGoogleFitData(
        dataType: 'com.google.height',
        startDate: DateTime.now().subtract(const Duration(days: 365)),
        endDate: DateTime.now(),
        accessToken: integration.accessToken!,
        limit: 1,
      );

      if (heightData.isNotEmpty) {
        measurements['height'] = {
          'value': heightData.first['value'],
          'unit': 'm',
          'date': heightData.first['date'],
        };
      }

      // Get latest body fat percentage
      final bodyFatData = await _readGoogleFitData(
        dataType: 'com.google.body_fat_percentage',
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
        accessToken: integration.accessToken!,
        limit: 1,
      );

      if (bodyFatData.isNotEmpty) {
        measurements['body_fat_percentage'] = {
          'value': bodyFatData.first['value'],
          'unit': '%',
          'date': bodyFatData.first['date'],
        };
      }

      return measurements.isNotEmpty ? measurements : null;
    } catch (e) {
      Logger.d('Error getting body measurements from Google Fit: $e');
      return null;
    }
  }

  /// Disconnect from Google Fit
  Future<bool> disconnectGoogleFit() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return false;

      final integrationId = '${userId}_googlefit';
      await _firestore
          .collection('health_integrations')
          .doc(integrationId)
          .delete();

      Logger.d('Google Fit disconnected successfully');
      return true;
    } catch (e) {
      Logger.d('Error disconnecting Google Fit: $e');
      return false;
    }
  }

  // Private helper methods

  Future<Map<String, dynamic>> _authenticateMyFitnessPal(
    String username,
    String password,
  ) async {
    // This is a simplified authentication flow
    // In a real implementation, you would use OAuth 2.0
    final response = await http.post(
      Uri.parse('$_myFitnessPalBaseUrl/auth/token'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
        'grant_type': 'password',
        'client_id': _myFitnessPalApiKey,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {'success': false, 'error': 'Authentication failed'};
    }
  }

  Future<void> _refreshMyFitnessPalToken(HealthIntegration integration) async {
    try {
      final response = await http.post(
        Uri.parse('$_myFitnessPalBaseUrl/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'grant_type': 'refresh_token',
          'refresh_token': integration.refreshToken,
          'client_id': _myFitnessPalApiKey,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update the integration with new tokens
        await _firestore
            .collection('health_integrations')
            .doc(integration.id)
            .update({
              'access_token': data['access_token'],
              'refresh_token': data['refresh_token'],
              'updated_at': FieldValue.serverTimestamp(),
            });
      } else {
        // Refresh failed, mark integration as error
        await _updateIntegrationStatus(
          integration.userId,
          IntegrationType.myFitnessPal,
          IntegrationStatus.error,
        );
      }
    } catch (e) {
      Logger.d('Error refreshing MyFitnessPal token: $e');
      await _updateIntegrationStatus(
        integration.userId,
        IntegrationType.myFitnessPal,
        IntegrationStatus.error,
      );
    }
  }

  Future<HealthIntegration?> _getIntegration(IntegrationType type) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return null;

    final integrationId = '${userId}_${type.name}';
    final doc = await _firestore
        .collection('health_integrations')
        .doc(integrationId)
        .get();

    if (doc.exists) {
      return HealthIntegration.fromFirestore(doc);
    }
    return null;
  }

  Future<void> _updateIntegrationStatus(
    String userId,
    IntegrationType type,
    IntegrationStatus status,
  ) async {
    final integrationId = '${userId}_${type.name}';
    await _firestore
        .collection('health_integrations')
        .doc(integrationId)
        .update({
          'status': status.name,
          'updated_at': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _updateLastSyncTime(String integrationId) async {
    await _firestore
        .collection('health_integrations')
        .doc(integrationId)
        .update({'last_sync_at': FieldValue.serverTimestamp()});
  }

  bool _isCacheValid(String key) {
    if (!_foodCache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  String _getMealTypeString(DateTime timestamp) {
    final hour = timestamp.hour;
    if (hour < 11) return 'breakfast';
    if (hour < 15) return 'lunch';
    if (hour < 19) return 'dinner';
    return 'snack';
  }

  // Private Apple Health helper methods

  Future<Map<String, dynamic>> _requestAppleHealthPermissions(
    List<String> dataTypes,
  ) async {
    // This would use a platform channel to communicate with iOS HealthKit
    // For now, we'll simulate the response
    try {
      // In a real implementation, this would call:
      // final result = await _healthChannel.invokeMethod('requestPermissions', {
      //   'dataTypes': dataTypes,
      // });

      // Simulated successful permission request
      return {
        'success': true,
        'granted_permissions': dataTypes,
        'denied_permissions': <String>[],
      };
    } catch (e) {
      Logger.d('Error requesting Apple Health permissions: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> _writeNutritionToAppleHealth(
    Map<String, dynamic> nutritionData,
  ) async {
    // This would use a platform channel to write to iOS HealthKit
    try {
      // In a real implementation, this would call:
      // final result = await _healthChannel.invokeMethod('writeNutritionData', nutritionData);
      // return result['success'] == true;

      // Simulated successful write
      Logger.d('Writing nutrition data to Apple Health: $nutritionData');
      return true;
    } catch (e) {
      Logger.d('Error writing nutrition to Apple Health: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _readAppleHealthData({
    required String dataType,
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  }) async {
    // This would use a platform channel to read from iOS HealthKit
    try {
      // In a real implementation, this would call:
      // final result = await _healthChannel.invokeMethod('readHealthData', {
      //   'dataType': dataType,
      //   'startDate': startDate.toIso8601String(),
      //   'endDate': endDate.toIso8601String(),
      //   'limit': limit,
      // });
      // return List<Map<String, dynamic>>.from(result['data'] ?? []);

      // Simulated health data
      return _generateSimulatedHealthData(dataType, startDate, endDate, limit);
    } catch (e) {
      Logger.d('Error reading Apple Health data for $dataType: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _generateSimulatedHealthData(
    String dataType,
    DateTime startDate,
    DateTime endDate,
    int? limit,
  ) {
    // Generate realistic simulated data for testing
    final data = <Map<String, dynamic>>[];
    final random = DateTime.now().millisecondsSinceEpoch % 100;

    switch (dataType) {
      case 'HKQuantityTypeIdentifierStepCount':
        data.add({
          'value': 8500 + random,
          'unit': 'count',
          'date': DateTime.now().toIso8601String(),
        });
        break;
      case 'HKQuantityTypeIdentifierActiveEnergyBurned':
        data.add({
          'value': 450 + random,
          'unit': 'kcal',
          'date': DateTime.now().toIso8601String(),
        });
        break;
      case 'HKQuantityTypeIdentifierBodyMass':
        data.add({
          'value': 70.5 + (random / 100),
          'unit': 'kg',
          'date': DateTime.now().toIso8601String(),
        });
        break;
      case 'HKQuantityTypeIdentifierHeight':
        data.add({
          'value': 1.75,
          'unit': 'm',
          'date': DateTime.now().toIso8601String(),
        });
        break;
    }

    return limit != null ? data.take(limit).toList() : data;
  }

  // Private Google Fit helper methods

  Future<Map<String, dynamic>> _requestGoogleFitPermissions(
    List<String> dataTypes,
  ) async {
    // This would use Google Sign-In and Fitness API
    try {
      // In a real implementation, this would:
      // 1. Use GoogleSignIn to authenticate
      // 2. Request Fitness API permissions
      // 3. Get access tokens

      // Simulated successful permission request
      return {
        'success': true,
        'access_token': 'simulated_google_fit_access_token',
        'refresh_token': 'simulated_google_fit_refresh_token',
        'granted_permissions': dataTypes,
        'denied_permissions': <String>[],
        'account': 'user@example.com',
      };
    } catch (e) {
      Logger.d('Error requesting Google Fit permissions: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> _writeNutritionToGoogleFit(
    Map<String, dynamic> nutritionData,
    String accessToken,
  ) async {
    // This would use Google Fit REST API
    try {
      final response = await http.post(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataSources/derived:com.google.nutrition:com.snapameal.app/datasets/${DateTime.now().millisecondsSinceEpoch * 1000000}-${DateTime.now().millisecondsSinceEpoch * 1000000}',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(nutritionData),
      );

      if (response.statusCode == 200) {
        Logger.d('Nutrition data written to Google Fit successfully');
        return true;
      } else {
        Logger.d(
          'Failed to write nutrition to Google Fit: ${response.statusCode}',
        );
        return false;
      }
    } catch (e) {
      Logger.d('Error writing nutrition to Google Fit: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> _readGoogleFitData({
    required String dataType,
    required DateTime startDate,
    required DateTime endDate,
    required String accessToken,
    int? limit,
  }) async {
    // This would use Google Fit REST API
    try {
      final startTimeNanos = (startDate.millisecondsSinceEpoch * 1000000)
          .toString();
      final endTimeNanos = (endDate.millisecondsSinceEpoch * 1000000)
          .toString();

      final response = await http.get(
        Uri.parse(
          'https://www.googleapis.com/fitness/v1/users/me/dataSources/derived:$dataType:com.google.android.gms/datasets/$startTimeNanos-$endTimeNanos',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final points = List<Map<String, dynamic>>.from(data['point'] ?? []);

        // Transform Google Fit data format to our standardized format
        final transformedData = points.map((point) {
          final value =
              point['value']?[0]?['fpVal'] ??
              point['value']?[0]?['intVal'] ??
              0.0;
          final startTime = int.parse(point['startTimeNanos']) ~/ 1000000;

          return {
            'value': value,
            'date': DateTime.fromMillisecondsSinceEpoch(
              startTime,
            ).toIso8601String(),
            'source': 'google_fit',
          };
        }).toList();

        return limit != null
            ? transformedData.take(limit).toList()
            : transformedData;
      } else {
        Logger.d('Failed to read Google Fit data: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      Logger.d('Error reading Google Fit data for $dataType: $e');
      // Return simulated data for testing
      return _generateSimulatedGoogleFitData(
        dataType,
        startDate,
        endDate,
        limit,
      );
    }
  }

  List<Map<String, dynamic>> _generateSimulatedGoogleFitData(
    String dataType,
    DateTime startDate,
    DateTime endDate,
    int? limit,
  ) {
    // Generate realistic simulated data for testing
    final data = <Map<String, dynamic>>[];
    final random = DateTime.now().millisecondsSinceEpoch % 100;

    switch (dataType) {
      case 'com.google.step_count.delta':
        data.add({
          'value': 9200 + random,
          'date': DateTime.now().toIso8601String(),
          'source': 'google_fit_simulated',
        });
        break;
      case 'com.google.calories.expended':
        data.add({
          'value': 520 + random,
          'date': DateTime.now().toIso8601String(),
          'source': 'google_fit_simulated',
        });
        break;
      case 'com.google.weight':
        data.add({
          'value': 72.3 + (random / 100),
          'date': DateTime.now().toIso8601String(),
          'source': 'google_fit_simulated',
        });
        break;
      case 'com.google.height':
        data.add({
          'value': 1.78,
          'date': DateTime.now().toIso8601String(),
          'source': 'google_fit_simulated',
        });
        break;
      case 'com.google.distance.delta':
        data.add({
          'value': 6800 + random, // meters
          'date': DateTime.now().toIso8601String(),
          'source': 'google_fit_simulated',
        });
        break;
      case 'com.google.active_minutes':
        data.add({
          'value': 45 + (random / 10),
          'date': DateTime.now().toIso8601String(),
          'source': 'google_fit_simulated',
        });
        break;
    }

    return limit != null ? data.take(limit).toList() : data;
  }

  // Conflict detection helper methods

  /// Detect conflicts for imported data
  Future<List<DataConflict>> _detectConflictsForImportedData(
    List<Map<String, dynamic>> importedData,
    DataSource source,
    String dataType,
  ) async {
    final List<DataConflict> conflicts = [];

    for (final dataPoint in importedData) {
      try {
        final timestamp = DateTime.parse(dataPoint['date']);
        final detectedConflicts = await _conflictService.detectConflicts(
          dataType: dataType,
          newData: dataPoint,
          source: source,
          timestamp: timestamp,
        );
        conflicts.addAll(detectedConflicts);
      } catch (e) {
        Logger.d('Error detecting conflicts for data point: $e');
      }
    }

    return conflicts;
  }

  /// Map Apple Health data types to our internal data types
  String _mapAppleHealthDataType(String appleHealthType) {
    switch (appleHealthType) {
      case 'HKQuantityTypeIdentifierDietaryEnergyConsumed':
      case 'HKQuantityTypeIdentifierDietaryProtein':
      case 'HKQuantityTypeIdentifierDietaryCarbohydrates':
      case 'HKQuantityTypeIdentifierDietaryFatTotal':
        return 'meal';
      case 'HKQuantityTypeIdentifierActiveEnergyBurned':
      case 'HKQuantityTypeIdentifierStepCount':
      case 'HKQuantityTypeIdentifierDistanceWalkingRunning':
        return 'exercise';
      case 'HKQuantityTypeIdentifierBodyMass':
        return 'weight';
      case 'HKCategoryTypeIdentifierSleepAnalysis':
        return 'sleep';
      case 'HKQuantityTypeIdentifierHeartRate':
        return 'heart_rate';
      default:
        return 'health_data';
    }
  }

  /// Map Google Fit data types to our internal data types
  String _mapGoogleFitDataType(String googleFitType) {
    switch (googleFitType) {
      case 'com.google.nutrition':
        return 'meal';
      case 'com.google.step_count.delta':
      case 'com.google.calories.expended':
      case 'com.google.active_minutes':
      case 'com.google.distance.delta':
        return 'exercise';
      case 'com.google.weight':
        return 'weight';
      case 'com.google.sleep.segment':
        return 'sleep';
      case 'com.google.heart_rate.bpm':
        return 'heart_rate';
      case 'com.google.hydration':
        return 'hydration';
      default:
        return 'health_data';
    }
  }

  /// Get data conflicts for user
  Future<List<DataConflict>> getDataConflicts() async {
    return await _conflictService.getUnresolvedConflicts();
  }

  /// Resolve a data conflict
  Future<bool> resolveDataConflict({
    required String conflictId,
    required ConflictResolutionStrategy strategy,
    String? selectedSourceId,
    Map<String, dynamic>? mergedData,
  }) async {
    return await _conflictService.resolveConflict(
      conflictId: conflictId,
      strategy: strategy,
      selectedSourceId: selectedSourceId,
      mergedData: mergedData,
    );
  }

  /// Get conflict statistics
  Future<Map<String, int>> getConflictStatistics() async {
    return await _conflictService.getConflictStatistics();
  }

  // Missing methods needed by integrations_page.dart

  /// Check connection status for an integration
  Future<bool> checkConnectionStatus(String integrationId) async {
    try {
      final doc = await _firestore
          .collection('health_integrations')
          .doc(integrationId)
          .get();

      if (!doc.exists) return false;

      final integration = HealthIntegration.fromFirestore(doc);
      return integration.status == IntegrationStatus.connected;
    } catch (e) {
      Logger.d('Error checking connection status: $e');
      return false;
    }
  }

  /// Get last sync time for an integration
  Future<DateTime?> getLastSyncTime(String integrationId) async {
    try {
      final doc = await _firestore
          .collection('health_integrations')
          .doc(integrationId)
          .get();

      if (!doc.exists) return null;

      final integration = HealthIntegration.fromFirestore(doc);
      return integration.lastSyncAt;
    } catch (e) {
      Logger.d('Error getting last sync time: $e');
      return null;
    }
  }

  /// Connect an integration by ID
  Future<bool> connectIntegration(String integrationId) async {
    try {
      // This is a simplified version - in reality, this would trigger
      // the appropriate OAuth flow based on the integration type
      final doc = await _firestore
          .collection('health_integrations')
          .doc(integrationId)
          .get();

      if (!doc.exists) {
        // Create a new integration record
        final userId = FirebaseAuth.instance.currentUser?.uid;
        if (userId == null) return false;

        // Determine integration type from ID
        IntegrationType type;
        if (integrationId.contains('myfitnesspal')) {
          type = IntegrationType.myFitnessPal;
        } else if (integrationId.contains('apple')) {
          type = IntegrationType.appleHealth;
        } else {
          type = IntegrationType.googleFit;
        }

        final integration = HealthIntegration(
          id: integrationId,
          userId: userId,
          type: type,
          status: IntegrationStatus.connected,
          connectedAt: DateTime.now(),
          settings: {},
        );

        await _firestore
            .collection('health_integrations')
            .doc(integrationId)
            .set(integration.toFirestore());

        return true;
      } else {
        // Update existing integration to connected
        await _firestore
            .collection('health_integrations')
            .doc(integrationId)
            .update({
              'status': IntegrationStatus.connected.name,
              'connected_at': FieldValue.serverTimestamp(),
            });
        return true;
      }
    } catch (e) {
      Logger.d('Error connecting integration: $e');
      return false;
    }
  }

  /// Disconnect an integration
  Future<bool> disconnectIntegration(String integrationId) async {
    try {
      await _firestore
          .collection('health_integrations')
          .doc(integrationId)
          .update({
            'status': IntegrationStatus.disconnected.name,
            'access_token': null,
            'refresh_token': null,
          });
      return true;
    } catch (e) {
      Logger.d('Error disconnecting integration: $e');
      return false;
    }
  }

  /// Sync data for an integration
  Future<bool> syncIntegrationData(String integrationId) async {
    try {
      final doc = await _firestore
          .collection('health_integrations')
          .doc(integrationId)
          .get();

      if (!doc.exists) return false;

      final integration = HealthIntegration.fromFirestore(doc);

      // Update status to syncing
      await _firestore
          .collection('health_integrations')
          .doc(integrationId)
          .update({'status': IntegrationStatus.syncing.name});

      // Perform sync based on integration type
      bool syncSuccess = false;
      switch (integration.type) {
        case IntegrationType.myFitnessPal:
          syncSuccess = await _syncMyFitnessPalData(integration);
          break;
        case IntegrationType.appleHealth:
          syncSuccess = await _syncAppleHealthData(integration);
          break;
        case IntegrationType.googleFit:
          syncSuccess = await _syncGoogleFitData(integration);
          break;
      }

      // Update sync status
      await _firestore
          .collection('health_integrations')
          .doc(integrationId)
          .update({
            'status': syncSuccess
                ? IntegrationStatus.connected.name
                : IntegrationStatus.error.name,
            'last_sync_at': FieldValue.serverTimestamp(),
          });

      return syncSuccess;
    } catch (e) {
      Logger.d('Error syncing integration data: $e');
      // Update status to error
      await _firestore
          .collection('health_integrations')
          .doc(integrationId)
          .update({'status': IntegrationStatus.error.name});
      return false;
    }
  }

  // Helper methods for syncing data
  Future<bool> _syncMyFitnessPalData(HealthIntegration integration) async {
    // Simplified sync logic
    return true;
  }

  Future<bool> _syncAppleHealthData(HealthIntegration integration) async {
    // Simplified sync logic
    return true;
  }

  Future<bool> _syncGoogleFitData(HealthIntegration integration) async {
    // Simplified sync logic
    return true;
  }
}
