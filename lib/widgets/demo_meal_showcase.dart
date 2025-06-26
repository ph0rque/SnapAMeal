import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meal_log.dart';
import '../services/meal_recognition_service.dart';
import '../services/auth_service.dart';
import '../design_system/snap_ui.dart';

/// Enhanced meal logging showcase for investor demos
/// Highlights AI recognition, nutrition analysis, and smart tracking
class DemoMealShowcase extends StatefulWidget {
  const DemoMealShowcase({super.key});

  @override
  State<DemoMealShowcase> createState() => _DemoMealShowcaseState();
}

class _DemoMealShowcaseState extends State<DemoMealShowcase>
    with TickerProviderStateMixin {
  late AnimationController _recognitionController;
  late AnimationController _nutritionController;
  late Animation<double> _recognitionAnimation;
  late Animation<double> _nutritionAnimation;
  
  bool _showingRecognitionDemo = false;
  bool _showingNutritionDemo = false;
  MealLog? _demoMeal;
  
  @override
  void initState() {
    super.initState();
    
    _recognitionController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _nutritionController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _recognitionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _recognitionController,
      curve: Curves.easeOutCubic,
    ));
    
    _nutritionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _nutritionController,
      curve: Curves.elasticOut,
    ));
    
    _initializeDemoMeal();
  }

  @override
  void dispose() {
    _recognitionController.dispose();
    _nutritionController.dispose();
    super.dispose();
  }

  void _initializeDemoMeal() {
    _demoMeal = MealLog(
      id: 'demo_meal_001',
      userId: 'demo_user',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      mealType: MealType.lunch,
      foods: [
        Food(
          name: 'Grilled Salmon Fillet',
          quantity: 6.0,
          unit: 'oz',
          calories: 367,
          protein: 51.0,
          carbs: 0.0,
          fat: 16.0,
          fiber: 0.0,
          sugar: 0.0,
          sodium: 89.0,
        ),
        Food(
          name: 'Quinoa Salad',
          quantity: 1.0,
          unit: 'cup',
          calories: 222,
          protein: 8.0,
          carbs: 39.0,
          fat: 4.0,
          fiber: 5.0,
          sugar: 3.0,
          sodium: 372.0,
        ),
        Food(
          name: 'Steamed Broccoli',
          quantity: 1.0,
          unit: 'cup',
          calories: 27,
          protein: 3.0,
          carbs: 5.0,
          fat: 0.3,
          fiber: 2.0,
          sugar: 1.5,
          sodium: 32.0,
        ),
      ],
      aiCaption: 'Healthy balanced lunch with lean protein, complex carbs, and vegetables',
      aiConfidence: 0.94,
      nutritionAnalysis: NutritionAnalysis(
        totalCalories: 616,
        macroBreakdown: {
          'protein': 62.0,
          'carbs': 44.0,
          'fat': 20.3,
        },
        healthScore: 0.92,
        recommendations: [
          'Excellent protein content for muscle maintenance',
          'Great balance of complex carbohydrates',
          'Rich in omega-3 fatty acids from salmon',
          'High fiber content supports digestive health',
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isCurrentUserDemo(),
      builder: (context, snapshot) {
        final isDemo = snapshot.data ?? false;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                SnapColors.success.withValues(alpha: 0.1),
                SnapColors.accent.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: SnapColors.success.withValues(alpha: 0.2),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Demo indicator for investors
              if (isDemo) _buildDemoIndicator(),
              
              const SizedBox(height: 16),
              
              // AI Recognition showcase
              _buildAIRecognitionShowcase(isDemo),
              
              const SizedBox(height: 20),
              
              // Nutrition analysis showcase
              if (isDemo) _buildNutritionAnalysisShowcase(),
              
              const SizedBox(height: 20),
              
              // Smart insights preview
              if (isDemo) _buildSmartInsightsPreview(),
              
              const SizedBox(height: 16),
              
              // Quick action buttons
              if (isDemo) _buildQuickActions(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDemoIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SnapColors.success,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            'AI Meal Recognition Demo',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRecognitionShowcase(bool isDemo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_enhance,
                color: SnapColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Food Recognition',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.text,
                ),
              ),
              const Spacer(),
              if (_showingRecognitionDemo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SnapColors.success.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'ANALYZING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: SnapColors.success,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'GPT-4 Vision instantly recognizes food items and estimates portions',
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // Mock camera preview with recognition overlay
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: SnapColors.border.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: SnapColors.border),
            ),
            child: Stack(
              children: [
                // Mock food image background
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withValues(alpha: 0.3),
                        Colors.green.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 60,
                      color: SnapColors.textSecondary,
                    ),
                  ),
                ),
                
                // Recognition overlays
                if (_showingRecognitionDemo) _buildRecognitionOverlays(),
                
                // Camera controls
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    onPressed: _toggleRecognitionDemo,
                    backgroundColor: SnapColors.primary,
                    child: Icon(
                      _showingRecognitionDemo ? Icons.stop : Icons.camera_alt,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Recognition results
          if (_showingRecognitionDemo && _demoMeal != null)
            _buildRecognitionResults(),
        ],
      ),
    );
  }

  Widget _buildRecognitionOverlays() {
    return AnimatedBuilder(
      animation: _recognitionAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Scanning effect
            Positioned(
              top: 20 + (_recognitionAnimation.value * 160),
              left: 20,
              right: 20,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      SnapColors.primary.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            
            // Food detection boxes
            if (_recognitionAnimation.value > 0.3) ...[
              _buildDetectionBox('Salmon', 40, 60, 120, 80),
              _buildDetectionBox('Quinoa', 140, 100, 100, 60),
              _buildDetectionBox('Broccoli', 80, 140, 90, 70),
            ],
          ],
        );
      },
    );
  }

  Widget _buildDetectionBox(String label, double left, double top, double width, double height) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: Border.all(
            color: SnapColors.success,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: SnapColors.success,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecognitionResults() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SnapColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SnapColors.success.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: SnapColors.success, size: 16),
              const SizedBox(width: 6),
              Text(
                'Recognition Complete',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: SnapColors.text,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              Text(
                '${(_demoMeal!.aiConfidence * 100).toInt()}% confidence',
                style: TextStyle(
                  color: SnapColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _demoMeal!.aiCaption,
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Detected: ${_demoMeal!.foods.map((f) => f.name).join(', ')}',
            style: TextStyle(
              color: SnapColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionAnalysisShowcase() {
    if (_demoMeal?.nutritionAnalysis == null) return const SizedBox.shrink();
    
    final nutrition = _demoMeal!.nutritionAnalysis!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: SnapColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Nutrition Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.text,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SnapColors.success.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Health Score: ${(nutrition.healthScore * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: SnapColors.success,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Calorie and macro breakdown
          _buildNutritionStats(nutrition),
          
          const SizedBox(height: 16),
          
          // Macro distribution chart
          _buildMacroChart(nutrition),
          
          const SizedBox(height: 16),
          
          // AI recommendations
          _buildNutritionRecommendations(nutrition),
        ],
      ),
    );
  }

  Widget _buildNutritionStats(NutritionAnalysis nutrition) {
    return Row(
      children: [
        Expanded(
          child: _buildNutritionStatCard(
            'Calories',
            '${nutrition.totalCalories}',
            'kcal',
            Icons.local_fire_department,
            SnapColors.accent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildNutritionStatCard(
            'Protein',
            '${nutrition.macroBreakdown['protein']?.toInt()}g',
            '${((nutrition.macroBreakdown['protein']! / nutrition.totalCalories) * 100).toInt()}%',
            Icons.fitness_center,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildNutritionStatCard(
            'Carbs',
            '${nutrition.macroBreakdown['carbs']?.toInt()}g',
            '${((nutrition.macroBreakdown['carbs']! / nutrition.totalCalories) * 100).toInt()}%',
            Icons.grain,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildNutritionStatCard(
            'Fat',
            '${nutrition.macroBreakdown['fat']?.toInt()}g',
            '${((nutrition.macroBreakdown['fat']! / nutrition.totalCalories) * 100).toInt()}%',
            Icons.opacity,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionStatCard(String label, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SnapColors.text,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: SnapColors.textSecondary,
              fontSize: 10,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroChart(NutritionAnalysis nutrition) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SnapColors.border),
      ),
      child: Row(
        children: [
          Flexible(
            flex: (nutrition.macroBreakdown['protein']! * 4).toInt(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.8),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(7),
                  bottomLeft: Radius.circular(7),
                ),
              ),
              child: Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            flex: (nutrition.macroBreakdown['carbs']! * 4).toInt(),
            child: Container(
              color: Colors.orange.withValues(alpha: 0.8),
              child: Center(
                child: Text(
                  'C',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            flex: (nutrition.macroBreakdown['fat']! * 9).toInt(),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.8),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(7),
                ),
              ),
              child: Center(
                child: Text(
                  'F',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRecommendations(NutritionAnalysis nutrition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Insights',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: SnapColors.text,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...nutrition.recommendations.take(2).map((recommendation) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: SnapColors.accent,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  recommendation,
                  style: TextStyle(
                    color: SnapColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildSmartInsightsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: SnapColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Smart Meal Insights',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SnapColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            'Perfect Protein Timing',
            'This meal provides optimal protein for your 2pm workout. Consider eating 1-2 hours before training.',
            Icons.schedule,
            SnapColors.info,
          ),
          const SizedBox(height: 8),
          _buildInsightCard(
            'Macro Balance Achievement',
            'You\'re 85% toward your daily protein goal. This meal keeps you on track for muscle maintenance.',
            Icons.track_changes,
            SnapColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: SnapColors.text,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: SnapColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleRecognitionDemo,
            icon: Icon(Icons.camera_alt, size: 16),
            label: Text('Scan Food'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SnapColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleNutritionDemo,
            icon: Icon(Icons.analytics, size: 16),
            label: Text('Analyze'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SnapColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _toggleRecognitionDemo() {
    setState(() {
      _showingRecognitionDemo = !_showingRecognitionDemo;
      if (_showingRecognitionDemo) {
        _recognitionController.forward();
      } else {
        _recognitionController.reset();
      }
    });
  }

  void _toggleNutritionDemo() {
    setState(() {
      _showingNutritionDemo = !_showingNutritionDemo;
      if (_showingNutritionDemo) {
        _nutritionController.forward();
      } else {
        _nutritionController.reset();
      }
    });
  }
} 