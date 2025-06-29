import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_log.dart';
import '../design_system/snap_ui.dart';
import '../services/meal_recognition_service.dart';

class FoodCorrectionDialog extends StatefulWidget {
  final FoodItem originalFood;
  final MealRecognitionService mealService;
  final Function(FoodItem correctedFood) onFoodCorrected;

  const FoodCorrectionDialog({
    super.key,
    required this.originalFood,
    required this.mealService,
    required this.onFoodCorrected,
  });

  @override
  State<FoodCorrectionDialog> createState() => _FoodCorrectionDialogState();
}

class _FoodCorrectionDialogState extends State<FoodCorrectionDialog> {
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final FocusNode _foodNameFocus = FocusNode();
  
  List<String> _searchSuggestions = [];
  bool _isSearching = false;
  bool _isCalculatingNutrition = false;
  FoodItem? _previewFood;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _foodNameController.text = widget.originalFood.name;
    _weightController.text = widget.originalFood.estimatedWeight.toInt().toString();
    _previewFood = widget.originalFood;
    
    // Add listener for real-time search
    _foodNameController.addListener(_onFoodNameChanged);
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _weightController.dispose();
    _foodNameFocus.dispose();
    super.dispose();
  }

  void _onFoodNameChanged() {
    final query = _foodNameController.text.trim();
    if (query.length >= 2 && query != _searchQuery) {
      _searchQuery = query;
      _searchFirebaseFoods(query);
    } else if (query.length < 2) {
      setState(() {
        _searchSuggestions.clear();
      });
    }
  }

  Future<void> _searchFirebaseFoods(String query) async {
    if (_isSearching) return;
    
    setState(() {
      _isSearching = true;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final keywords = _generateSearchKeywords(query);
      
      // Search Firebase foods collection
      final querySnapshot = await firestore
          .collection('foods')
          .where('searchableKeywords', arrayContainsAny: keywords)
          .limit(10)
          .get();
      
      final suggestions = <String>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final foodName = data['foodName'] as String? ?? '';
        if (foodName.isNotEmpty && !suggestions.contains(foodName)) {
          suggestions.add(foodName);
        }
      }
      
      // Sort by similarity to query
      suggestions.sort((a, b) {
        final scoreA = _calculateSimilarity(query.toLowerCase(), a.toLowerCase());
        final scoreB = _calculateSimilarity(query.toLowerCase(), b.toLowerCase());
        return scoreB.compareTo(scoreA);
      });
      
      setState(() {
        _searchSuggestions = suggestions.take(5).toList();
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchSuggestions.clear();
        _isSearching = false;
      });
    }
  }

  List<String> _generateSearchKeywords(String query) {
    final keywords = <String>{};
    final cleanQuery = query.toLowerCase().trim();
    
    keywords.add(cleanQuery);
    
    // Add individual words
    final words = cleanQuery.split(RegExp(r'[,\s]+'))
        .where((word) => word.length > 2)
        .toList();
    keywords.addAll(words);
    
    return keywords.toList();
  }

  double _calculateSimilarity(String query, String target) {
    if (query == target) return 1.0;
    if (target.contains(query) || query.contains(target)) return 0.8;
    
    final queryWords = query.split(' ').where((w) => w.length > 2).toSet();
    final targetWords = target.split(' ').where((w) => w.length > 2).toSet();
    
    if (queryWords.isEmpty || targetWords.isEmpty) return 0.0;
    
    final intersection = queryWords.intersection(targetWords);
    final union = queryWords.union(targetWords);
    
    return intersection.length / union.length;
  }

  Future<void> _updateNutritionPreview() async {
    final foodName = _foodNameController.text.trim();
    final weightText = _weightController.text.trim();
    
    if (foodName.isEmpty || weightText.isEmpty) return;
    
    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) return;

    setState(() {
      _isCalculatingNutrition = true;
    });

    try {
      final nutrition = await widget.mealService.estimateNutrition(foodName, weight);
      
      setState(() {
        _previewFood = FoodItem(
          name: foodName,
          category: _categorizeFoodItem(foodName),
          confidence: 0.9, // High confidence for user corrections
          nutrition: nutrition,
          estimatedWeight: weight,
          alternativeNames: [],
        );
        _isCalculatingNutrition = false;
      });
    } catch (e) {
      setState(() {
        _isCalculatingNutrition = false;
      });
    }
  }

  String _categorizeFoodItem(String foodName) {
    final name = foodName.toLowerCase();
    
    if (name.contains('chicken') || name.contains('beef') || 
        name.contains('fish') || name.contains('egg')) {
      return 'protein';
    } else if (name.contains('rice') || name.contains('bread') || 
               name.contains('pasta')) {
      return 'carbohydrates';
    } else if (name.contains('apple') || name.contains('banana') || 
               name.contains('berry')) {
      return 'fruits';
    } else if (name.contains('broccoli') || name.contains('spinach') || 
               name.contains('carrot')) {
      return 'vegetables';
    }
    
    return 'other';
  }

  void _selectSuggestion(String suggestion) {
    _foodNameController.text = suggestion;
    setState(() {
      _searchSuggestions.clear();
    });
    _updateNutritionPreview();
    _foodNameFocus.unfocus();
  }

  void _saveCorrection() async {
    final foodName = _foodNameController.text.trim();
    final weightText = _weightController.text.trim();
    
    if (foodName.isEmpty || weightText.isEmpty) {
      _showError('Please enter both food name and weight');
      return;
    }
    
    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      _showError('Please enter a valid weight');
      return;
    }

    if (_previewFood != null) {
      // Save correction to Firebase for learning
      _saveCorrectionToFirebase(
        widget.originalFood.name, 
        foodName, 
        widget.originalFood.estimatedWeight, 
        weight
      );
      
      // Provide haptic feedback
      HapticFeedback.lightImpact();
      
      // Return the corrected food
      widget.onFoodCorrected(_previewFood!);
      Navigator.of(context).pop();
    }
  }

  void _saveCorrectionToFirebase(
    String originalName, 
    String correctedName, 
    double originalWeight, 
    double correctedWeight
  ) {
    // Save in background to avoid blocking UI
    Future(() async {
      try {
        final firestore = FirebaseFirestore.instance;
        await firestore.collection('feedback_corrections').add({
          'originalFoodName': originalName,
          'correctedFoodName': correctedName,
          'originalWeight': originalWeight,
          'correctedWeight': correctedWeight,
          'correctionType': 'inline_edit',
          'timestamp': FieldValue.serverTimestamp(),
          'userId': 'current_user', // Should come from auth
        });
      } catch (e) {
        // Silently fail - correction feedback is non-critical
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: SnapUI.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Header
            Row(
              children: [
                Icon(Icons.edit, color: SnapUI.primaryColor, size: 24),
                SnapUI.horizontalSpaceSmall,
                Expanded(
                  child: Text(
                    'Edit Food Item',
                    style: SnapUI.headingStyle.copyWith(fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            SnapUI.verticalSpaceMedium,
            
            // Food name input with autocomplete
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Food Name', style: SnapUI.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                SnapUI.verticalSpaceXSmall,
                TextField(
                  controller: _foodNameController,
                  focusNode: _foodNameFocus,
                  decoration: SnapUI.inputDecoration.copyWith(
                    hintText: 'Search or enter food name...',
                    suffixIcon: _isSearching 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.search),
                  ),
                  onChanged: (_) => _updateNutritionPreview(),
                ),
                
                // Search suggestions
                if (_searchSuggestions.isNotEmpty) ...[
                  SnapUI.verticalSpaceXSmall,
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: SnapUI.borderRadius,
                    ),
                    child: Column(
                      children: _searchSuggestions.map((suggestion) => 
                        ListTile(
                          dense: true,
                          title: Text(suggestion, style: SnapUI.bodyStyle),
                          onTap: () => _selectSuggestion(suggestion),
                        ),
                      ).toList(),
                    ),
                  ),
                ],
              ],
            ),
            
            SnapUI.verticalSpaceMedium,
            
            // Weight input
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weight (grams)', style: SnapUI.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                )),
                SnapUI.verticalSpaceXSmall,
                TextField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: SnapUI.inputDecoration.copyWith(
                    hintText: 'Enter weight in grams',
                    suffixText: 'g',
                  ),
                  onChanged: (_) => _updateNutritionPreview(),
                ),
              ],
            ),
            
            SnapUI.verticalSpaceMedium,
            
            // Nutrition comparison
            if (_previewFood != null) ...[
              Text('Nutritional Impact', style: SnapUI.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
              )),
              SnapUI.verticalSpaceSmall,
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SnapUI.backgroundColor,
                  borderRadius: SnapUI.borderRadius,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: _isCalculatingNutrition
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _buildNutritionComparison(),
              ),
            ],
            
            SnapUI.verticalSpaceLarge,
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.5)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                                 SnapUI.horizontalSpaceSmall,
                Expanded(
                  child: ElevatedButton(
                    onPressed: _previewFood != null ? _saveCorrection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SnapUI.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildNutritionComparison() {
    final original = widget.originalFood.nutrition;
    final preview = _previewFood!.nutrition;
    
    return Column(
      children: [
        _buildComparisonRow('Calories', original.calories, preview.calories, 'cal'),
        _buildComparisonRow('Protein', original.protein, preview.protein, 'g'),
        _buildComparisonRow('Carbs', original.carbs, preview.carbs, 'g'),
        _buildComparisonRow('Fat', original.fat, preview.fat, 'g'),
      ],
    );
  }

  Widget _buildComparisonRow(String label, double original, double updated, String unit) {
    final difference = updated - original;
    final isIncrease = difference > 0;
    final changeColor = difference.abs() < 0.1 
        ? Colors.grey 
        : isIncrease 
            ? Colors.red 
            : Colors.green;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: SnapUI.captionStyle),
          ),
          Expanded(
            child: Text(
              '${original.toStringAsFixed(1)}$unit',
              style: SnapUI.captionStyle.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
          const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
          Expanded(
            child: Text(
              '${updated.toStringAsFixed(1)}$unit',
              style: SnapUI.captionStyle.copyWith(
                color: changeColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (difference.abs() >= 0.1)
            Text(
              '${isIncrease ? '+' : ''}${difference.toStringAsFixed(1)}',
              style: SnapUI.captionStyle.copyWith(
                color: changeColor,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
} 