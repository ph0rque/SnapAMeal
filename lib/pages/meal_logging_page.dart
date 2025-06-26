import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design_system/snap_ui.dart';

import '../models/meal_log.dart';
import '../services/meal_recognition_service.dart';
import '../services/openai_service.dart';
import '../services/rag_service.dart';


/// AI-Powered Meal Logging Page
/// Allows users to snap meals for instant calorie estimates and AI captions
class MealLoggingPage extends StatefulWidget {
  const MealLoggingPage({super.key});

  @override
  State<MealLoggingPage> createState() => _MealLoggingPageState();
}

class _MealLoggingPageState extends State<MealLoggingPage>
    with TickerProviderStateMixin {
  
  // Services
  late MealRecognitionService _mealRecognitionService;
  late OpenAIService _openAIService;
  late RAGService _ragService;
  
  // UI State
  bool _isAnalyzing = false;
  bool _isInitialized = false;
  String? _selectedImagePath;
  MealRecognitionResult? _analysisResult;
  String _selectedCaptionType = 'motivational';
  String? _generatedCaption;
  List<RecipeSuggestion>? _recipeSuggestions;
  
  // Form controllers
  final TextEditingController _userCaptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  // Mood and hunger tracking
  int _selectedMoodRating = 3;
  int _selectedHungerLevel = 3;
  
  // Animation controllers
  late AnimationController _pulseAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimationController.repeat(reverse: true);
  }

  Future<void> _initializeServices() async {
    try {
              _openAIService = OpenAIService();
        await _openAIService.initialize();
          _ragService = RAGService(_openAIService);
    _mealRecognitionService = MealRecognitionService(_openAIService, _ragService);
      
      final initialized = await _mealRecognitionService.initialize();
      setState(() {
        _isInitialized = initialized;
      });
      
      if (initialized) {
        developer.log('Meal recognition services initialized successfully');
      } else {
        throw Exception('Failed to initialize meal recognition services');
      }
    } catch (e) {
      developer.log('Error initializing services: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnapUI.errorSnackBar('Failed to initialize AI services'),
      );
    }
  }

  Future<void> _captureImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
          _analysisResult = null;
          _generatedCaption = null;
          _recipeSuggestions = null;
        });
        
        _slideAnimationController.forward();
        await _analyzeMeal(image.path);
      }
    } catch (e) {
      developer.log('Error capturing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnapUI.errorSnackBar('Failed to capture image'),
      );
    }
  }

  Future<void> _analyzeMeal(String imagePath) async {
    if (!_isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnapUI.errorSnackBar('AI services not ready'),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Analyze the meal image
      final result = await _mealRecognitionService.analyzeMealImage(imagePath);
      
      // Generate caption
      final caption = await _mealRecognitionService.generateMealCaption(
        result, 
        _selectedCaptionType,
      );
      
      // Generate recipe suggestions
      final recipes = await _mealRecognitionService.generateRecipeSuggestions(result);
      
      setState(() {
        _analysisResult = result;
        _generatedCaption = caption;
        _recipeSuggestions = recipes;
        _isAnalyzing = false;
      });
      
      // Provide haptic feedback
      HapticFeedback.lightImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnapUI.successSnackBar('Meal analyzed successfully!'),
      );
      
    } catch (e) {
      developer.log('Error analyzing meal: $e');
      setState(() {
        _isAnalyzing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnapUI.errorSnackBar('Failed to analyze meal'),
      );
    }
  }

  Future<void> _regenerateCaption(String captionType) async {
    if (_analysisResult == null) return;
    
    try {
      final caption = await _mealRecognitionService.generateMealCaption(
        _analysisResult!,
        captionType,
      );
      
      setState(() {
        _selectedCaptionType = captionType;
        _generatedCaption = caption;
      });
      
      HapticFeedback.selectionClick();
    } catch (e) {
      developer.log('Error regenerating caption: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnapUI.errorSnackBar('Failed to generate caption'),
      );
    }
  }

  Future<void> _saveMealLog() async {
    if (_selectedImagePath == null || _analysisResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnapUI.errorSnackBar('Please capture and analyze a meal first'),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Upload image to Firebase Storage
      final imageFile = File(_selectedImagePath!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'meals/${user.uid}/$timestamp.jpg';
      
      final uploadTask = FirebaseStorage.instance
          .ref()
          .child(fileName)
          .putFile(imageFile);
      
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      // Create meal log
      final mealLog = MealLog(
        id: '', // Firestore will generate
        userId: user.uid,
        imagePath: _selectedImagePath!,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        recognitionResult: _analysisResult!,
        userCaption: _userCaptionController.text.isNotEmpty 
            ? _userCaptionController.text 
            : null,
        aiCaption: _generatedCaption,
        tags: _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList(),
        moodRating: MoodRating(
          rating: _selectedMoodRating,
          description: _getMoodDescription(_selectedMoodRating),
          timestamp: DateTime.now(),
        ),
        hungerLevel: HungerLevel(
          level: _selectedHungerLevel,
          description: _getHungerDescription(_selectedHungerLevel),
          timestamp: DateTime.now(),
        ),
        recipeSuggestions: _recipeSuggestions,
        metadata: {
          'caption_type': _selectedCaptionType,
          'analysis_confidence': _analysisResult!.confidenceScore,
          'primary_category': _analysisResult!.primaryFoodCategory,
        },
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('meal_logs')
          .add(mealLog.toJson());

      // Reset form
      setState(() {
        _selectedImagePath = null;
        _analysisResult = null;
        _generatedCaption = null;
        _recipeSuggestions = null;
        _userCaptionController.clear();
        _tagsController.clear();
        _selectedMoodRating = 3;
        _selectedHungerLevel = 3;
      });

      _slideAnimationController.reset();

      ScaffoldMessenger.of(context).showSnackBar(
        SnapUI.successSnackBar('Meal logged successfully!'),
      );

    } catch (e) {
      developer.log('Error saving meal log: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnapUI.errorSnackBar('Failed to save meal log'),
      );
    }
  }

  String _getMoodDescription(int rating) {
    switch (rating) {
      case 1: return 'Very unhappy';
      case 2: return 'Unhappy';
      case 3: return 'Neutral';
      case 4: return 'Happy';
      case 5: return 'Very happy';
      default: return 'Neutral';
    }
  }

  String _getHungerDescription(int level) {
    switch (level) {
      case 1: return 'Very hungry';
      case 2: return 'Hungry';
      case 3: return 'Neutral';
      case 4: return 'Satisfied';
      case 5: return 'Very full';
      default: return 'Neutral';
    }
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _slideAnimationController.dispose();
    _userCaptionController.dispose();
    _tagsController.dispose();
    _mealRecognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapUI.backgroundColor,
      appBar: SnapUI.appBar(
        title: 'AI Meal Logger',
      ),
      body: SingleChildScrollView(
        padding: SnapUI.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Capture Controls
            _buildCaptureSection(),
            
            if (_selectedImagePath != null) ...[
              SnapUI.verticalSpaceMedium,
              
              // Image Preview & Analysis
              SlideTransition(
                position: _slideAnimation,
                child: _buildImageAnalysisSection(),
              ),
            ],
            
            if (_analysisResult != null) ...[
              SnapUI.verticalSpaceMedium,
              
              // Nutrition Information
              _buildNutritionSection(),
              
              SnapUI.verticalSpaceMedium,
              
              // Caption Generation
              _buildCaptionSection(),
              
              SnapUI.verticalSpaceMedium,
              
              // Mood and Hunger Tracking
              _buildMoodHungerSection(),
              
              SnapUI.verticalSpaceMedium,
              
              // Tags and Notes
              _buildTagsNotesSection(),
              
              if (_recipeSuggestions?.isNotEmpty == true) ...[
                SnapUI.verticalSpaceMedium,
                _buildRecipeSuggestionsSection(),
              ],
              
              SnapUI.verticalSpaceLarge,
              
              // Save Button
              _buildSaveButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureSection() {
    return Container(
      padding: SnapUI.cardPadding,
      decoration: SnapUI.cardDecorationWithBorder,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt,
                color: SnapUI.primaryColor,
                size: 24,
              ),
              SnapUI.horizontalSpaceSmall,
              Text(
                'Capture Your Meal',
                style: SnapUI.headingStyle,
              ),
            ],
          ),
          SnapUI.verticalSpaceMedium,
          Row(
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: SnapUI.primaryButton(
                        'Take Photo',
                        () => _captureImage(ImageSource.camera),
                        icon: Icons.camera_alt,
                      ),
                    );
                  },
                ),
              ),
              SnapUI.horizontalSpaceSmall,
              Expanded(
                child: SnapUI.secondaryButton(
                  'From Gallery',
                  () => _captureImage(ImageSource.gallery),
                  icon: Icons.photo_library,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageAnalysisSection() {
    return Container(
      padding: SnapUI.cardPadding,
      decoration: SnapUI.cardDecorationWithBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview
          ClipRRect(
            borderRadius: SnapUI.borderRadius,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.file(
                File(_selectedImagePath!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SnapUI.verticalSpaceSmall,
          
          // Analysis Status
          if (_isAnalyzing)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: SnapUI.primaryColor,
                  ),
                ),
                SnapUI.horizontalSpaceSmall,
                Text(
                  'Analyzing meal...',
                  style: SnapUI.bodyStyle.copyWith(
                    color: SnapUI.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else if (_analysisResult != null)
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 16,
                ),
                SnapUI.horizontalSpaceSmall,
                Text(
                  'Analysis complete!',
                  style: SnapUI.bodyStyle.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNutritionSection() {
    final nutrition = _analysisResult!.totalNutrition;
    final foods = _analysisResult!.detectedFoods;
    
    return Container(
      padding: SnapUI.cardPadding,
      decoration: SnapUI.cardDecorationWithBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_dining,
                color: SnapUI.primaryColor,
                size: 24,
              ),
              SnapUI.horizontalSpaceSmall,
              Text(
                'Nutrition Analysis',
                style: SnapUI.headingStyle,
              ),
            ],
          ),
          
          SnapUI.verticalSpaceMedium,
          
          // Detected Foods
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: foods.map((food) => Chip(
              label: Text(
                '${food.name} (${food.confidence.toStringAsFixed(1)}%)',
                style: SnapUI.captionStyle,
              ),
              backgroundColor: SnapUI.primaryColor.withValues(alpha: 0.1),
              side: BorderSide(color: SnapUI.primaryColor),
            )).toList(),
          ),
          
          SnapUI.verticalSpaceMedium,
          
          // Macro Overview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SnapUI.primaryColor.withValues(alpha: 0.05),
              borderRadius: SnapUI.borderRadius,
              border: Border.all(color: SnapUI.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionItem('Calories', '${nutrition.calories.round()}', 'kcal'),
                _buildNutritionItem('Protein', '${nutrition.protein.round()}', 'g'),
                _buildNutritionItem('Carbs', '${nutrition.carbs.round()}', 'g'),
                _buildNutritionItem('Fat', '${nutrition.fat.round()}', 'g'),
              ],
            ),
          ),
          
          // Allergen Warnings
          if (_analysisResult!.allergenWarnings.isNotEmpty) ...[
            SnapUI.verticalSpaceSmall,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: SnapUI.borderRadius,
                border: Border.all(color: Colors.orange),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  SnapUI.horizontalSpaceSmall,
                  Expanded(
                    child: Text(
                      'Contains: ${_analysisResult!.allergenWarnings.join(', ')}',
                      style: SnapUI.captionStyle.copyWith(color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: SnapUI.headingStyle.copyWith(
            color: SnapUI.primaryColor,
            fontSize: 20,
          ),
        ),
        Text(
          unit,
          style: SnapUI.captionStyle.copyWith(
            color: SnapUI.primaryColor,
          ),
        ),
        Text(
          label,
          style: SnapUI.captionStyle,
        ),
      ],
    );
  }

  Widget _buildCaptionSection() {
    return Container(
      padding: SnapUI.cardPadding,
      decoration: SnapUI.cardDecorationWithBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: SnapUI.primaryColor,
                size: 24,
              ),
              SnapUI.horizontalSpaceSmall,
              Text(
                'AI Caption',
                style: SnapUI.headingStyle,
              ),
            ],
          ),
          
          SnapUI.verticalSpaceSmall,
          
          // Caption Type Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['motivational', 'witty', 'health_tip', 'descriptive']
                  .map((type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type.replaceAll('_', ' ').toUpperCase()),
                      selected: _selectedCaptionType == type,
                      onSelected: (selected) {
                        if (selected) {
                          _regenerateCaption(type);
                        }
                      },
                      selectedColor: SnapUI.primaryColor.withValues(alpha: 0.2),
                      checkmarkColor: SnapUI.primaryColor,
                    ),
                  ))
                  .toList(),
            ),
          ),
          
          SnapUI.verticalSpaceSmall,
          
          // Generated Caption
          if (_generatedCaption != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SnapUI.backgroundColor,
                borderRadius: SnapUI.borderRadius,
                border: Border.all(color: SnapUI.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                _generatedCaption!,
                style: SnapUI.bodyStyle.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoodHungerSection() {
    return Container(
      padding: SnapUI.cardPadding,
      decoration: SnapUI.cardDecorationWithBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you feeling?',
            style: SnapUI.headingStyle,
          ),
          
          SnapUI.verticalSpaceSmall,
          
          // Mood Rating
          Row(
            children: [
              Text('Mood:', style: SnapUI.bodyStyle),
              SnapUI.horizontalSpaceSmall,
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final rating = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedMoodRating = rating),
                      child: Icon(
                        rating <= _selectedMoodRating ? Icons.sentiment_very_satisfied : Icons.sentiment_neutral,
                        color: rating <= _selectedMoodRating ? SnapUI.primaryColor : Colors.grey,
                        size: 28,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          
          SnapUI.verticalSpaceSmall,
          
          // Hunger Level
          Row(
            children: [
              Text('Hunger:', style: SnapUI.bodyStyle),
              SnapUI.horizontalSpaceSmall,
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(5, (index) {
                    final level = index + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedHungerLevel = level),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: level <= _selectedHungerLevel ? SnapUI.primaryColor : Colors.transparent,
                          border: Border.all(color: SnapUI.primaryColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: level <= _selectedHungerLevel
                            ? Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTagsNotesSection() {
    return Container(
      padding: SnapUI.cardPadding,
      decoration: SnapUI.cardDecorationWithBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Additional Details',
            style: SnapUI.headingStyle,
          ),
          
          SnapUI.verticalSpaceSmall,
          
          // User Caption
          TextField(
            controller: _userCaptionController,
            decoration: SnapUI.inputDecoration.copyWith(
              labelText: 'Your caption (optional)',
              hintText: 'Add your own thoughts about this meal...',
            ),
            maxLines: 2,
          ),
          
          SnapUI.verticalSpaceSmall,
          
          // Tags
          TextField(
            controller: _tagsController,
            decoration: SnapUI.inputDecoration.copyWith(
              labelText: 'Tags (optional)',
              hintText: 'healthy, homemade, breakfast, etc.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeSuggestionsSection() {
    return Container(
      padding: SnapUI.cardPadding,
      decoration: SnapUI.cardDecorationWithBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: SnapUI.primaryColor,
                size: 24,
              ),
              SnapUI.horizontalSpaceSmall,
              Text(
                'Recipe Suggestions',
                style: SnapUI.headingStyle,
              ),
            ],
          ),
          
          SnapUI.verticalSpaceSmall,
          
          ...(_recipeSuggestions!.map((recipe) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SnapUI.primaryColor.withValues(alpha: 0.05),
              borderRadius: SnapUI.borderRadius,
              border: Border.all(color: SnapUI.primaryColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: SnapUI.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                ),
                SnapUI.verticalSpaceXSmall,
                Text(
                  recipe.description,
                  style: SnapUI.captionStyle,
                ),
                SnapUI.verticalSpaceXSmall,
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min',
                      style: SnapUI.captionStyle,
                    ),
                    SnapUI.horizontalSpaceSmall,
                    Icon(Icons.favorite, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.healthScore.round()}% healthy',
                      style: SnapUI.captionStyle,
                    ),
                  ],
                ),
              ],
            ),
          ))),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SnapUI.primaryButton(
      'Save Meal Log',
      _saveMealLog,
      icon: Icons.save,
    );
  }
} 