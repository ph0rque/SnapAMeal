import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../design_system/snap_ui.dart';
import '../design_system/widgets/meal_card_widget.dart';
import '../models/meal_log.dart';
import '../utils/logger.dart';
import '../services/demo_account_management_service.dart';

class MyMealsPage extends StatefulWidget {
  const MyMealsPage({super.key});

  @override
  State<MyMealsPage> createState() => _MyMealsPageState();
}

class _MyMealsPageState extends State<MyMealsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<MealLog> _meals = [];

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Check if user is a demo user to determine which collection to use
      final demoService = DemoAccountManagementService();
      final isDemo = await demoService.isCurrentUserDemo();
      final collectionName = 'meal_logs'; // All users now use production meal_logs
      final userIdField = isDemo ? 'userId' : 'userId'; // Both use same field name

      QuerySnapshot? querySnapshot;
      
      // Try to load meals, handle permission errors gracefully
      try {
        querySnapshot = await _firestore
            .collection(collectionName)
            .where(userIdField, isEqualTo: user.uid)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();
      } catch (e) {
        if (e.toString().contains('permission-denied')) {
          Logger.d('Permission denied for meal logs, showing empty state');
          setState(() {
            _meals = [];
            _isLoading = false;
          });
          return;
        } else {
          rethrow;
        }
      }

      final meals = <MealLog>[];
      for (final doc in querySnapshot.docs) {
        try {
          // Get document data
          final data = doc.data() as Map<String, dynamic>;
          
          Logger.d('🔍 Raw document data for ${doc.id}:');
          Logger.d('  image_url: ${data['image_url']}');
          Logger.d('  image_path: ${data['image_path']}');
          Logger.d('  user_id: ${data['user_id']}');
          Logger.d('  timestamp: ${data['timestamp']}');
          
          // Ensure consistent field names for MealLog.fromFirestore
          final processedData = Map<String, dynamic>.from(data);
          
          // Handle user_id vs userId inconsistency
          if (data.containsKey('userId') && !data.containsKey('user_id')) {
            processedData['user_id'] = data['userId'];
          }
          
          // Handle timestamp format inconsistencies
          if (data['timestamp'] is Timestamp) {
            processedData['timestamp'] = (data['timestamp'] as Timestamp).millisecondsSinceEpoch;
          } else if (data['timestamp'] == null) {
            // Fallback to document creation time or current time
            processedData['timestamp'] = DateTime.now().millisecondsSinceEpoch;
          }
          
          // Provide fallbacks for required fields that might be missing
          processedData['user_id'] ??= user.uid;
          processedData['image_path'] ??= '';
          processedData['tags'] ??= <String>[];
          processedData['metadata'] ??= <String, dynamic>{};
          
          // Provide minimal recognition result if missing
          if (processedData['recognition_result'] == null) {
            processedData['recognition_result'] = {
              'detected_foods': [],
              'total_nutrition': {
                'calories': 0.0,
                'protein': 0.0,
                'carbs': 0.0,
                'fat': 0.0,
                'fiber': 0.0,
                'sugar': 0.0,
                'sodium': 0.0,
                'serving_size': 100.0,
                'vitamins': {},
                'minerals': {},
              },
              'confidence_score': 0.0,
              'primary_food_category': 'Unknown',
              'allergen_warnings': [],
              'analysis_timestamp': DateTime.now().millisecondsSinceEpoch,
            };
          }
          
          // Create meal with processed data
          final meal = MealLog.fromJson({
            'id': doc.id,
            ...processedData,
          });
          
          Logger.d('Loaded meal: ${meal.id}, imageUrl: ${meal.imageUrl.isNotEmpty ? 'present' : 'empty'}, timestamp: ${meal.timestamp}');
          meals.add(meal);
        } catch (e) {
          Logger.d('Error parsing meal log ${doc.id}: $e');
          // Skip this meal and continue with others
        }
      }

      // Sort meals by timestamp if we couldn't do it in the query
      meals.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _meals = meals;
        _isLoading = false;
      });
      
      Logger.d('Successfully loaded ${meals.length} meals from $collectionName');
      
      // Show helpful message for first-time users
      if (meals.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No meals found. Start by logging your first meal!'),
            backgroundColor: SnapColors.primaryYellow,
            action: SnackBarAction(
              label: 'Log Meal',
              textColor: SnapColors.secondaryDark,
              onPressed: () => Navigator.pushNamed(context, '/meal-logging'),
            ),
          ),
        );
      }
      
    } catch (e) {
      Logger.d('Error loading meals: $e');
      setState(() => _isLoading = false);
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to load meals. ${e.toString().contains('permission') ? 'Check permissions.' : 'Please try again.'}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadMeals,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure proper system UI colors
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: SnapColors.backgroundLight,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    
    return Scaffold(
      backgroundColor: SnapColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'My Meals',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        backgroundColor: SnapColors.backgroundLight,
        foregroundColor: SnapColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: SnapColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: SnapColors.primaryYellow),
            onPressed: () => Navigator.pushNamed(context, '/meal-logging'),
            tooltip: 'Log New Meal',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: SnapColors.primaryYellow,
        ),
      );
    }

    if (_meals.isEmpty) {
      return _buildEmptyState();
    }

    return _buildMealsList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: SnapColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No meals logged yet',
            style: SnapTypography.heading3.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging your meals to track your nutrition!',
            style: SnapTypography.caption.copyWith(
              color: SnapColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/meal-logging'),
            icon: const Icon(Icons.add),
            label: const Text('Log Your First Meal'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SnapColors.primaryYellow,
              foregroundColor: SnapColors.secondaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealsList() {
    return RefreshIndicator(
      onRefresh: _loadMeals,
      color: SnapColors.primaryYellow,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _meals.length,
        itemBuilder: (context, index) {
          final meal = _meals[index];
          return MealCardWidget(
            mealLog: meal,
            onTap: () => _showMealDetails(meal),
          );
        },
      ),
    );
  }

  void _showMealDetails(MealLog meal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SnapColors.backgroundLight,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: SnapColors.backgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button and drag handle
              Row(
                children: [
                  // Drag handle
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: SnapColors.textSecondary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // Close button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: SnapColors.textPrimary,
                    ),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Meal Details',
                style: SnapTypography.heading2.copyWith(
                  color: SnapColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: MealCardWidget(
                    mealLog: meal,
                    showActions: false,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
