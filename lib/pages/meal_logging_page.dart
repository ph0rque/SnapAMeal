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
import '../services/mission_service.dart';
import '../widgets/food_correction_dialog.dart';
import 'package:get_it/get_it.dart';

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
  bool _isSaving = false;
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
    print('🚨 BASIC INIT: MealLoggingPage initState() called - THIS SHOULD SHOW!');
    developer.log('🏁 INIT: MealLoggingPage initState() called');
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

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _slideAnimationController,
            curve: Curves.elasticOut,
          ),
        );

    _pulseAnimationController.repeat(reverse: true);
  }

  Future<void> _initializeServices() async {
    print('🚨 SERVICE INIT: Starting service initialization...');
    developer.log('🔧 SERVICE INIT: Starting service initialization...');
    
    try {
      print('🚨 SERVICE INIT: Creating OpenAIService...');
      developer.log('🔧 SERVICE INIT: Creating OpenAIService...');
      _openAIService = OpenAIService();
      
      print('🚨 SERVICE INIT: Initializing OpenAIService...');
      developer.log('🔧 SERVICE INIT: Initializing OpenAIService...');
      await _openAIService.initialize();
      print('🚨 SERVICE INIT: OpenAIService initialized successfully!');
      developer.log('✅ SERVICE INIT: OpenAIService initialized');
      
      print('🚨 SERVICE INIT: Creating RAGService...');
      developer.log('🔧 SERVICE INIT: Creating RAGService...');
      _ragService = RAGService(_openAIService);
      
      print('🚨 SERVICE INIT: Creating MealRecognitionService...');
      developer.log('🔧 SERVICE INIT: Creating MealRecognitionService...');
      _mealRecognitionService = MealRecognitionService(
        _openAIService,
        _ragService,
      );

      print('🚨 SERVICE INIT: Initializing MealRecognitionService...');
      developer.log('🔧 SERVICE INIT: Initializing MealRecognitionService...');
      final initialized = await _mealRecognitionService.initialize();
      print('🚨 SERVICE INIT: MealRecognitionService returned: $initialized');
      developer.log('🔧 SERVICE INIT: MealRecognitionService.initialize() returned: $initialized');
      
      setState(() {
        _isInitialized = initialized;
      });
      print('🚨 SERVICE INIT: _isInitialized set to: $_isInitialized');
      developer.log('🔧 SERVICE INIT: _isInitialized set to: $_isInitialized');

      if (initialized) {
        print('🚨 SERVICE INIT: ✅ ALL SERVICES READY!');
        developer.log('✅ SERVICE INIT: All meal recognition services initialized successfully');
      } else {
        throw Exception('Failed to initialize meal recognition services');
      }
    } catch (e) {
      print('🚨 SERVICE INIT: ❌ ERROR: $e');
      developer.log('❌ SERVICE INIT: Error initializing services: $e');
      developer.log('❌ SERVICE INIT: Error type: ${e.runtimeType}');
      
      setState(() {
        _isInitialized = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnapUI.errorSnackBar('Failed to initialize AI services'));
    }
  }

  Future<void> _captureImage(ImageSource source) async {
    print('🚨 IMAGE CAPTURE: Starting image capture from ${source == ImageSource.gallery ? 'GALLERY' : 'CAMERA'}');
    developer.log('📸 IMAGE CAPTURE: Starting image capture from ${source == ImageSource.gallery ? 'GALLERY' : 'CAMERA'}');
    
    try {
      final picker = ImagePicker();
      print('🚨 IMAGE CAPTURE: Created ImagePicker instance');
      developer.log('📸 IMAGE CAPTURE: Created ImagePicker instance');
      
      final image = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      print('🚨 IMAGE CAPTURE: pickImage returned: ${image != null ? 'SUCCESS' : 'NULL'}');
      developer.log('📸 IMAGE CAPTURE: pickImage returned: ${image != null ? 'SUCCESS' : 'NULL'}');
      if (image != null) {
        print('🚨 IMAGE CAPTURE: Image path: ${image.path}');
        print('🚨 IMAGE CAPTURE: Image file exists: ${File(image.path).existsSync()}');
        developer.log('📸 IMAGE CAPTURE: Image path: ${image.path}');
        developer.log('📸 IMAGE CAPTURE: Image file exists: ${File(image.path).existsSync()}');
        
        setState(() {
          _selectedImagePath = image.path;
          _analysisResult = null;
          _generatedCaption = null;
          _recipeSuggestions = null;
        });

        print('🚨 IMAGE CAPTURE: State updated, starting animation');
        developer.log('📸 IMAGE CAPTURE: State updated, starting animation');
        _slideAnimationController.forward();
        
        print('🚨 IMAGE CAPTURE: Starting meal analysis...');
        developer.log('📸 IMAGE CAPTURE: Starting meal analysis...');
        await _analyzeMeal(image.path);
        print('🚨 IMAGE CAPTURE: Meal analysis completed!');
        developer.log('📸 IMAGE CAPTURE: Meal analysis completed');
      } else {
        developer.log('❌ IMAGE CAPTURE: User cancelled image selection');
      }
    } catch (e) {
      developer.log('Error capturing image: $e');
      if (!mounted) return;
      
      // Provide more specific error messages based on the error type
      String errorMessage = 'Failed to capture image';
      if (e.toString().contains('photo_access_denied') || e.toString().contains('camera_access_denied')) {
        errorMessage = 'Permission denied. Please allow camera and photo library access in Settings > Privacy.';
      } else if (e.toString().contains('not_available')) {
        errorMessage = 'Camera or photo library not available on this device.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: e.toString().contains('access_denied') 
            ? SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () {
                  // Note: This would require adding url_launcher dependency and app_settings package
                  // For now, just show instruction
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Go to Settings > Privacy > Camera/Photos to enable access'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              )
            : null,
        ),
      );
    }
  }

  Future<void> _analyzeMeal(String imagePath) async {
    print('🚨 MEAL ANALYSIS: Starting analysis for image: $imagePath');
    print('🚨 MEAL ANALYSIS: _isInitialized = $_isInitialized');
    developer.log('🔍 MEAL ANALYSIS: Starting analysis for image: $imagePath');
    developer.log('🔍 MEAL ANALYSIS: _isInitialized = $_isInitialized');
    
    if (!_isInitialized) {
      print('🚨 MEAL ANALYSIS: ❌ Services not initialized!');
      developer.log('❌ MEAL ANALYSIS: Services not initialized');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnapUI.errorSnackBar('AI services not ready'));
      return;
    }

    print('🚨 MEAL ANALYSIS: Setting _isAnalyzing = true');
    developer.log('🔍 MEAL ANALYSIS: Setting _isAnalyzing = true');
    setState(() {
      _isAnalyzing = true;
    });

    try {
      print('🚨 MEAL ANALYSIS: Calling analyzeMealImage...');
      developer.log('🔍 MEAL ANALYSIS: Calling analyzeMealImage...');
      // Analyze the meal image (always performed)
      final result = await _mealRecognitionService.analyzeMealImage(imagePath);
      print('🚨 MEAL ANALYSIS: ✅ analyzeMealImage completed successfully!');
      print('🚨 MEAL ANALYSIS: Detected foods: ${result.detectedFoods.length}');
      print('🚨 MEAL ANALYSIS: Primary category: ${result.primaryFoodCategory}');
      developer.log('✅ MEAL ANALYSIS: analyzeMealImage completed successfully');
      developer.log('   Detected foods: ${result.detectedFoods.length}');
      developer.log('   Primary category: ${result.primaryFoodCategory}');

      print('🚨 MEAL ANALYSIS: Generating caption...');
      developer.log('🔍 MEAL ANALYSIS: Generating caption...');
      // Generate caption (always performed)
      final caption = await _mealRecognitionService.generateMealCaption(
        result,
        _selectedCaptionType,
      );
      print('🚨 MEAL ANALYSIS: ✅ Caption generated successfully!');
      developer.log('✅ MEAL ANALYSIS: Caption generated successfully');

      // Conditional recipe suggestions based on meal type
      List<RecipeSuggestion> recipes = [];
      if (result.shouldShowRecipeSuggestions) {
        developer.log('🔍 MEAL ANALYSIS: Generating recipe suggestions for ${result.mealType.value} meal');
        recipes = await _mealRecognitionService.generateRecipeSuggestions(result);
        developer.log('✅ MEAL ANALYSIS: Recipe suggestions generated: ${recipes.length}');
      } else {
        developer.log('🔍 MEAL ANALYSIS: Skipping recipe suggestions for ${result.mealType.value} meal');
      }

      print('🚨 MEAL ANALYSIS: Setting analysis results in state...');
      developer.log('🔍 MEAL ANALYSIS: Setting analysis results in state...');
      setState(() {
        _analysisResult = result;
        _generatedCaption = caption;
        _recipeSuggestions = recipes;
        _isAnalyzing = false;
      });
      print('🚨 MEAL ANALYSIS: ✅ State updated with results! Save button should now appear.');
      developer.log('✅ MEAL ANALYSIS: State updated with results');

      // Provide haptic feedback
      HapticFeedback.lightImpact();

      if (!mounted) return;
      
      // Show different success messages based on meal type
      final message = result.mealType == MealType.ingredients
        ? 'Ingredients analyzed! Recipe suggestions included.'
        : result.mealType == MealType.readyMade 
          ? 'Ready-made meal analyzed!'
          : 'Meal analyzed successfully!';
          
      developer.log('✅ MEAL ANALYSIS: Showing success message: $message');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnapUI.successSnackBar(message));
    } catch (e) {
      print('🚨 MEAL ANALYSIS: ❌ ERROR occurred: $e');
      print('🚨 MEAL ANALYSIS: ❌ Error type: ${e.runtimeType}');
      print('🚨 MEAL ANALYSIS: ❌ Full error: ${e.toString()}');
      developer.log('❌ MEAL ANALYSIS: Error analyzing meal: $e');
      developer.log('❌ MEAL ANALYSIS: Error type: ${e.runtimeType}');
      developer.log('❌ MEAL ANALYSIS: Full error: ${e.toString()}');
      
      print('🚨 MEAL ANALYSIS: Setting _isAnalyzing = false due to error');
      setState(() {
        _isAnalyzing = false;
      });

      if (!mounted) return;
      
      String errorMessage;
      if (e is NonFoodImageException) {
        developer.log('❌ MEAL ANALYSIS: NonFoodImageException detected');
        // Specific error for non-food images
        errorMessage = e.message;
      } else {
        developer.log('❌ MEAL ANALYSIS: Generic error occurred');
        // Generic error for other issues
        errorMessage = 'Failed to analyze meal';
      }
      
      developer.log('❌ MEAL ANALYSIS: Showing error message: $errorMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: e is NonFoodImageException ? Colors.orange : Colors.red,
          duration: const Duration(seconds: 4),
          action: e is NonFoodImageException
              ? SnackBarAction(
                  label: 'Try Again',
                  textColor: Colors.white,
                  onPressed: () {
                    // Clear the current image so user can take a new one
                    setState(() {
                      _selectedImagePath = null;
                      _analysisResult = null;
                    });
                  },
                )
              : null,
        ),
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
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnapUI.errorSnackBar('Failed to generate caption'));
    }
  }

  Future<void> _saveMealLog() async {
    developer.log('🎯 MEAL SAVE: Starting _saveMealLog() method');
    developer.log('🔍 MEAL SAVE: _selectedImagePath = $_selectedImagePath');
    developer.log('🔍 MEAL SAVE: _analysisResult = ${_analysisResult != null ? 'present' : 'null'}');
    
    if (_selectedImagePath == null || _analysisResult == null) {
      developer.log('❌ MEAL SAVE: Missing required data - imagePath: $_selectedImagePath, analysisResult: ${_analysisResult != null}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnapUI.errorSnackBar('Please capture and analyze a meal first'),
      );
      return;
    }

    // Prevent duplicate uploads
    if (_isSaving) {
      developer.log('🔵 MEAL SAVE: Already saving, ignoring duplicate call');
      return;
    }

    developer.log('🔵 MEAL SAVE: Setting _isSaving = true');
    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      developer.log('🔍 MEAL SAVE: User authentication check');
      developer.log('   User: ${user != null ? 'authenticated' : 'null'}');
      if (user != null) {
        developer.log('   User ID: ${user.uid}');
        developer.log('   User email: ${user.email}');
      }
      
      if (user == null) {
        developer.log('❌ MEAL SAVE: User not authenticated');
        throw Exception('User not authenticated');
      }

      // Upload image to Firebase Storage with unique filename to prevent conflicts
      final imageFile = File(_selectedImagePath!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final randomId = DateTime.now().microsecondsSinceEpoch; // Additional uniqueness
      final fileName = 'meals/${user.uid}/${timestamp}_$randomId.jpg';

      developer.log('🔄 Starting image upload...');
      developer.log('  File path: $_selectedImagePath');
      developer.log('  File exists: ${imageFile.existsSync()}');
      developer.log('  File size: ${imageFile.lengthSync()} bytes');
      developer.log('  Storage path: $fileName');
      developer.log('  User ID: $user.uid');

      String imageUrl = '';
      try {
        // Enhanced validation before upload
        if (!imageFile.existsSync()) {
          throw Exception('Image file does not exist at path: $_selectedImagePath');
        }
        
        final fileSize = imageFile.lengthSync();
        if (fileSize == 0) {
          throw Exception('Image file is empty (0 bytes)');
        }
        
        if (fileSize > 10 * 1024 * 1024) {
          throw Exception('Image file too large: $fileSize bytes (max 10MB)');
        }

        developer.log('🔄 Pre-upload validation passed');
        developer.log('  File exists: ${imageFile.existsSync()}');
        developer.log('  File size: $fileSize bytes');
        developer.log('  User authenticated: ${user.uid}');
        
        // Test Firebase Storage connectivity
        try {
          FirebaseStorage.instance.ref();
          developer.log('✅ Firebase Storage reference created successfully');
        } catch (storageError) {
          throw Exception('Failed to create Firebase Storage reference: $storageError');
        }

        final uploadTask = FirebaseStorage.instance
            .ref()
            .child(fileName)
            .putFile(imageFile);

        developer.log('📤 Upload task created, waiting for completion...');
        
        // Add upload progress monitoring
        uploadTask.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            final progressPercent = (progress * 100).clamp(0.0, 100.0).toInt();
            developer.log('📊 Upload progress: $progressPercent%');
          } else {
            developer.log('📊 Upload progress: preparing...');
          }
        });
        
        final snapshot = await uploadTask;
        developer.log('✅ Upload completed successfully');
        developer.log('  Bytes transferred: ${snapshot.totalBytes}');
        developer.log('  Upload state: ${snapshot.state}');
        
        imageUrl = await snapshot.ref.getDownloadURL();
        developer.log('🔗 Download URL obtained: $imageUrl');

        if (imageUrl.isEmpty) {
          throw Exception('Download URL is empty');
        }
        
        // Validate the download URL format
        if (!imageUrl.startsWith('https://')) {
          throw Exception('Invalid download URL format: $imageUrl');
        }
        
        developer.log('✅ Image upload and URL validation successful');
        
      } catch (uploadError) {
        developer.log('❌ CRITICAL: Image upload failed completely!');
        developer.log('❌ Upload error: $uploadError');
        developer.log('❌ Upload error type: ${uploadError.runtimeType}');
        developer.log('❌ Full error details: ${uploadError.toString()}');
        developer.log('❌ This is why all meals have null image_url in Firestore!');
        
        // STOP THE SAVE PROCESS - don't save corrupted data
        setState(() {
          _isSaving = false;
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: ${uploadError.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _saveMealLog(),
            ),
          ),
        );
        return; // EXIT - don't save to Firestore with null imageUrl
      }

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

      developer.log('📝 Created meal log with imageUrl: $imageUrl');
      developer.log('   Image path: $_selectedImagePath');
      developer.log('   User ID: $user.uid');

      // Validate meal log data before saving
      final mealLogJson = mealLog.toJson();
      developer.log('🔍 Meal log JSON data:');
      developer.log('   image_url: ${mealLogJson['image_url']}');
      developer.log('   image_path: ${mealLogJson['image_path']}');
      developer.log('   user_id: ${mealLogJson['user_id']}');
      developer.log('   timestamp: ${mealLogJson['timestamp']}');
      
      if (mealLogJson['image_url'] == null || mealLogJson['image_url'].toString().isEmpty) {
        throw Exception('Meal log has empty image_url before saving to Firestore');
      }

      // Always save to meal_logs collection for all users (demo and production)
      const collectionName = 'meal_logs';
      developer.log('💾 FORCE SAVE: All users saving to meal_logs collection');
      developer.log('💾 FORCE SAVE: Collection name = $collectionName');

      // Save to Firestore
      final docRef = await FirebaseFirestore.instance
          .collection(collectionName)
          .add(mealLogJson);

      developer.log('✅ Meal log saved with document ID: ${docRef.id}');
      developer.log('   Saved imageUrl: ${mealLog.imageUrl}');
      
      // Immediately read back the document to verify it was saved correctly
      try {
        final savedDoc = await docRef.get();
        final savedData = savedDoc.data() as Map<String, dynamic>;
        developer.log('✅ Verification read from Firestore:');
        developer.log('   Saved image_url: ${savedData['image_url']}');
        developer.log('   Saved image_path: ${savedData['image_path']}');
        
        if (savedData['image_url'] == null || savedData['image_url'].toString().isEmpty) {
          developer.log('❌ WARNING: image_url is null/empty in saved Firestore document!');
        }
      } catch (verificationError) {
        developer.log('❌ Failed to verify saved document: $verificationError');
      }

      // Check for mission auto-completions
      try {
        await MissionService().checkAutoCompletions(
          user.uid,
          'log_meal',
          {
            'meal_category': _analysisResult!.primaryFoodCategory,
            'meal_time': DateTime.now().hour,
          },
        );
      } catch (e) {
        developer.log('Error checking mission auto-completions: $e');
        // Don't fail the meal logging if mission check fails
      }

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

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnapUI.successSnackBar('Meal logged successfully!'));
    } catch (e) {
      developer.log('Error saving meal log: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnapUI.errorSnackBar('Failed to save meal log'));
    } finally {
      developer.log('🔵 MEAL SAVE: Finally block - resetting _isSaving to false');
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        developer.log('🔵 MEAL SAVE: _isSaving reset to false');
      } else {
        developer.log('❌ MEAL SAVE: Widget not mounted, cannot reset _isSaving');
      }
    }
  }

  String _getMoodDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Very unhappy';
      case 2:
        return 'Unhappy';
      case 3:
        return 'Neutral';
      case 4:
        return 'Happy';
      case 5:
        return 'Very happy';
      default:
        return 'Neutral';
    }
  }

  String _getHungerDescription(int level) {
    switch (level) {
      case 1:
        return 'Very hungry';
      case 2:
        return 'Hungry';
      case 3:
        return 'Neutral';
      case 4:
        return 'Satisfied';
      case 5:
        return 'Very full';
      default:
        return 'Neutral';
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
    print('🚨 BASIC BUILD: Meal logging page build method called');
    print('🚨 BASIC BUILD: This should ALWAYS show up in console');
    developer.log('🏗️ UI BUILD: Building meal logging page');
    developer.log('🏗️ UI BUILD: _selectedImagePath = ${_selectedImagePath != null ? 'present' : 'null'}');
    developer.log('🏗️ UI BUILD: _analysisResult = ${_analysisResult != null ? 'present' : 'null'}');
    developer.log('🏗️ UI BUILD: _isAnalyzing = $_isAnalyzing');
    print('🚨 BASIC BUILD: About to return Scaffold');
    
    return Scaffold(
      backgroundColor: SnapUI.backgroundColor,
      appBar: SnapUI.appBar(title: 'AI Meal Logger'),
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

              SnapUI.verticalSpaceMedium,
              _buildConditionalRecipeSuggestionsSection(),

              SnapUI.verticalSpaceLarge,

              // Save Button
              _buildSaveButton(),
            ] else if (_selectedImagePath != null) ...[
              SnapUI.verticalSpaceMedium,
              Container(
                padding: SnapUI.cardPadding,
                decoration: SnapUI.cardDecorationWithBorder,
                child: Column(
                  children: [
                    Text('⚠️ ANALYSIS MISSING', style: SnapUI.headingStyle.copyWith(color: Colors.red)),
                    Text('_analysisResult is null - save button hidden', style: SnapUI.bodyStyle),
                    Text('_isAnalyzing = $_isAnalyzing', style: SnapUI.captionStyle),
                  ],
                ),
              ),
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
              Icon(Icons.camera_alt, color: SnapUI.primaryColor, size: 24),
              SnapUI.horizontalSpaceSmall,
              Text('Capture Your Meal', style: SnapUI.headingStyle),
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
                  () {
                    print('🚨 BUTTON PRESS: From Gallery button clicked!');
                    _captureImage(ImageSource.gallery);
                  },
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
              child: Image.file(File(_selectedImagePath!), fit: BoxFit.cover),
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
                Icon(Icons.check_circle, color: Colors.green, size: 16),
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
              Icon(Icons.local_dining, color: SnapUI.primaryColor, size: 24),
              SnapUI.horizontalSpaceSmall,
              Expanded(
                child: Text('Nutrition Analysis', style: SnapUI.headingStyle),
              ),
              Flexible(
                child: _buildMealTypeIndicator(),
              ),
            ],
          ),

          SnapUI.verticalSpaceMedium,

          // Detected Foods - Enhanced List
          _buildDetectedFoodsList(foods),

          SnapUI.verticalSpaceMedium,

          // Total Weight Display
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: SnapUI.borderRadius,
              border: Border.all(
                color: Colors.grey.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.scale, color: Colors.grey[600], size: 18),
                SnapUI.horizontalSpaceSmall,
                Text(
                  'Total Weight: ${_calculateTotalWeight(foods).toInt()}g',
                  style: SnapUI.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),

          SnapUI.verticalSpaceSmall,

          // Macro Overview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SnapUI.primaryColor.withValues(alpha: 0.05),
              borderRadius: SnapUI.borderRadius,
              border: Border.all(
                color: SnapUI.primaryColor.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionItem(
                  'Calories',
                  '${nutrition.calories.round()}',
                  'kcal',
                ),
                _buildNutritionItem(
                  'Protein',
                  '${nutrition.protein.round()}',
                  'g',
                ),
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
                      style: SnapUI.captionStyle.copyWith(
                        color: Colors.orange[800],
                      ),
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

  Widget _buildDetectedFoodsList(List<FoodItem> foods) {
    if (foods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: SnapUI.borderRadius,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
            SnapUI.horizontalSpaceSmall,
            Expanded(
              child: Text(
                'No foods detected in this image',
                style: SnapUI.bodyStyle.copyWith(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.list_alt, color: SnapUI.primaryColor, size: 18),
            SnapUI.horizontalSpaceSmall,
            Text(
              'Detected Ingredients (${foods.length})',
              style: SnapUI.bodyStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: SnapUI.primaryColor,
              ),
            ),
          ],
        ),
        SnapUI.verticalSpaceSmall,
        ...foods.asMap().entries.map((entry) {
          final index = entry.key;
          final food = entry.value;
          
          return Container(
            margin: EdgeInsets.only(bottom: index < foods.length - 1 ? 8 : 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SnapUI.primaryColor.withValues(alpha: 0.03),
              borderRadius: SnapUI.borderRadius,
              border: Border.all(
                color: SnapUI.primaryColor.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                // Food category icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(food.category).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(food.category),
                    size: 16,
                    color: _getCategoryColor(food.category),
                  ),
                ),
                SnapUI.horizontalSpaceSmall,
                
                // Food details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              food.name.toUpperCase(),
                              style: SnapUI.bodyStyle.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          // Confidence badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getConfidenceColor(food.confidence).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(food.confidence * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _getConfidenceColor(food.confidence),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Weight
                          Icon(Icons.scale, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${food.estimatedWeight.toInt()}g',
                            style: SnapUI.captionStyle.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SnapUI.horizontalSpaceSmall,
                          
                          // Category
                          Icon(Icons.category, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              food.category,
                              style: SnapUI.captionStyle.copyWith(
                                color: _getCategoryColor(food.category),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          // Quick nutrition preview
                          Text(
                            '${food.nutrition.calories.toInt()} cal',
                            style: SnapUI.captionStyle.copyWith(
                              color: SnapUI.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      
                      // User correction indicator
                      if (food.isUserCorrected) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.edit, size: 12, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Edited by you',
                              style: SnapUI.captionStyle.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Edit button
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 20,
                    color: food.isUserCorrected ? Colors.green : Colors.grey[600],
                  ),
                  onPressed: () => _showFoodCorrectionDialog(food, index),
                  tooltip: 'Edit food item',
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Show food correction dialog for inline editing
  void _showFoodCorrectionDialog(FoodItem food, int index) async {
    final mealService = GetIt.instance<MealRecognitionService>();
    
    await showDialog(
      context: context,
      builder: (context) => FoodCorrectionDialog(
        originalFood: food,
        mealService: mealService,
        onFoodCorrected: (correctedFood) {
          setState(() {
            // Update the food item in the analysis result
            final updatedFoods = List<FoodItem>.from(_analysisResult!.detectedFoods);
            updatedFoods[index] = correctedFood;
            
            // Recalculate total nutrition
            final totalNutrition = _calculateTotalNutrition(updatedFoods);
            
            // Update the analysis result
            _analysisResult = MealRecognitionResult(
              detectedFoods: updatedFoods,
              totalNutrition: totalNutrition,
              confidenceScore: _analysisResult!.confidenceScore,
              primaryFoodCategory: _analysisResult!.primaryFoodCategory,
              allergenWarnings: _analysisResult!.allergenWarnings,
              analysisTimestamp: _analysisResult!.analysisTimestamp,
              mealType: _analysisResult!.mealType,
              mealTypeConfidence: _analysisResult!.mealTypeConfidence,
              mealTypeReason: _analysisResult!.mealTypeReason,
            );
            
            // Show success feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Food item updated successfully!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          });
        },
      ),
    );
  }

  /// Calculate total weight from list of foods
  double _calculateTotalWeight(List<FoodItem> foods) {
    return foods.fold(0.0, (total, food) => total + food.estimatedWeight);
  }

  /// Build formatted text with support for **bold** markdown
  Widget _buildFormattedText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Add text before the bold part
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: SnapUI.captionStyle,
        ));
      }
      
      // Add the bold part
      spans.add(TextSpan(
        text: match.group(1) ?? '',
        style: SnapUI.captionStyle.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ));
      
      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: SnapUI.captionStyle,
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  /// Calculate total nutrition from list of foods
  NutritionInfo _calculateTotalNutrition(List<FoodItem> foods) {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSugar = 0;
    double totalSodium = 0;
    double totalServingSize = 0;

    for (final food in foods) {
      totalCalories += food.nutrition.calories;
      totalProtein += food.nutrition.protein;
      totalCarbs += food.nutrition.carbs;
      totalFat += food.nutrition.fat;
      totalFiber += food.nutrition.fiber;
      totalSugar += food.nutrition.sugar;
      totalSodium += food.nutrition.sodium;
      totalServingSize += food.nutrition.servingSize;
    }

    return NutritionInfo(
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      sugar: totalSugar,
      sodium: totalSodium,
      servingSize: totalServingSize,
      vitamins: {},
      minerals: {},
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'protein':
        return Colors.red;
      case 'vegetables':
        return Colors.green;
      case 'dairy':
        return Colors.blue;
      case 'carbs':
      case 'grains':
        return Colors.orange;
      case 'fruits':
        return Colors.purple;
      case 'fats':
      case 'oils':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'protein':
        return Icons.egg;
      case 'vegetables':
        return Icons.local_florist;
      case 'dairy':
        return Icons.local_drink;
      case 'carbs':
      case 'grains':
        return Icons.grain;
      case 'fruits':
        return Icons.apple;
      case 'fats':
      case 'oils':
        return Icons.water_drop;
      default:
        return Icons.restaurant;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
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
          style: SnapUI.captionStyle.copyWith(color: SnapUI.primaryColor),
        ),
        Text(label, style: SnapUI.captionStyle),
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
              Icon(Icons.auto_awesome, color: SnapUI.primaryColor, size: 24),
              SnapUI.horizontalSpaceSmall,
              Text('AI Caption', style: SnapUI.headingStyle),
            ],
          ),

          SnapUI.verticalSpaceSmall,

          // Caption Type Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['motivational', 'witty', 'health_tip', 'descriptive']
                  .map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(type.replaceAll('_', ' ').toUpperCase()),
                        selected: _selectedCaptionType == type,
                        onSelected: (selected) {
                          if (selected) {
                            _regenerateCaption(type);
                          }
                        },
                        selectedColor: SnapUI.primaryColor.withValues(
                          alpha: 0.2,
                        ),
                        checkmarkColor: SnapUI.primaryColor,
                      ),
                    ),
                  )
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
                border: Border.all(
                  color: SnapUI.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _generatedCaption!,
                style: SnapUI.bodyStyle.copyWith(fontStyle: FontStyle.italic),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
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
          Text('How are you feeling?', style: SnapUI.headingStyle),

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
                    return Flexible(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedMoodRating = rating),
                        child: Icon(
                          rating <= _selectedMoodRating
                              ? Icons.sentiment_very_satisfied
                              : Icons.sentiment_neutral,
                          color: rating <= _selectedMoodRating
                              ? SnapUI.primaryColor
                              : Colors.grey,
                          size: 28,
                        ),
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
                    return Flexible(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedHungerLevel = level),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: level <= _selectedHungerLevel
                                ? SnapUI.primaryColor
                                : Colors.transparent,
                            border: Border.all(color: SnapUI.primaryColor),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: level <= _selectedHungerLevel
                              ? Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
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
          Text('Additional Details', style: SnapUI.headingStyle),

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
              Icon(Icons.restaurant_menu, color: SnapUI.primaryColor, size: 24),
              SnapUI.horizontalSpaceSmall,
              Text('Recipe Suggestions', style: SnapUI.headingStyle),
            ],
          ),

          SnapUI.verticalSpaceSmall,

          ...(_recipeSuggestions!.map(
            (recipe) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SnapUI.primaryColor.withValues(alpha: 0.05),
                borderRadius: SnapUI.borderRadius,
                border: Border.all(
                  color: SnapUI.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: SnapUI.bodyStyle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SnapUI.verticalSpaceXSmall,
                  _buildFormattedText(recipe.description),
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
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildConditionalRecipeSuggestionsSection() {
    if (_analysisResult == null) return const SizedBox.shrink();

    // Show explanation for ready-made meals
    if (!_analysisResult!.shouldShowRecipeSuggestions) {
      return Container(
        padding: SnapUI.cardPadding,
        decoration: SnapUI.cardDecorationWithBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                SnapUI.horizontalSpaceSmall,
                Text('Recipe Suggestions', style: SnapUI.headingStyle),
              ],
            ),
            SnapUI.verticalSpaceSmall,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: SnapUI.borderRadius,
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.restaurant_menu, color: Colors.blue, size: 20),
                  SnapUI.horizontalSpaceSmall,
                  Expanded(
                    child: Text(
                      _analysisResult!.mealType == MealType.readyMade
                        ? 'This appears to be a ready-made meal, so no recipe suggestions are needed!'
                        : 'Recipe suggestions are only shown for raw ingredients that can be cooked together.',
                      style: SnapUI.bodyStyle.copyWith(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show recipe suggestions for ingredients
    if (_recipeSuggestions == null || _recipeSuggestions!.isEmpty) {
      return Container(
        padding: SnapUI.cardPadding,
        decoration: SnapUI.cardDecorationWithBorder,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu, color: SnapUI.primaryColor, size: 24),
                SnapUI.horizontalSpaceSmall,
                Text('Recipe Suggestions', style: SnapUI.headingStyle),
              ],
            ),
            SnapUI.verticalSpaceSmall,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: SnapUI.borderRadius,
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue,
                    ),
                  ),
                  SnapUI.horizontalSpaceSmall,
                  Expanded(
                    child: Text(
                      'We detected ingredients! Recipe suggestions are being generated...',
                      style: SnapUI.bodyStyle.copyWith(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show actual recipe suggestions
    return _buildRecipeSuggestionsSection();
  }

  Widget _buildSaveButton() {
    developer.log('🔵 SAVE BUTTON: Building save button, _isSaving = $_isSaving');
    developer.log('🔵 SAVE BUTTON: Button enabled = ${!_isSaving}');
    
    return SnapUI.primaryButton(
      _isSaving ? 'Saving...' : 'Save Meal Log',
      () {
        developer.log('🔵 SAVE BUTTON: Button pressed! _isSaving = $_isSaving');
        developer.log('🔵 SAVE BUTTON: Calling _saveMealLog()');
        _saveMealLog();
      },
      icon: _isSaving ? null : Icons.save,
      isLoading: false, // NEVER disable the button - handle state internally
    );
  }

  Widget _buildMealTypeIndicator() {
    if (_analysisResult == null) return const SizedBox.shrink();

    final mealType = _analysisResult!.mealType;
    final confidence = _analysisResult!.mealTypeConfidence;
    
    Color indicatorColor;
    IconData indicatorIcon;
    String displayText;
    
    switch (mealType) {
      case MealType.ingredients:
        indicatorColor = Colors.blue;
        indicatorIcon = Icons.restaurant;
        displayText = 'Ingredients';
        break;
      case MealType.readyMade:
        indicatorColor = Colors.green;
        indicatorIcon = Icons.restaurant_menu;
        displayText = 'Ready-made';
        break;
      case MealType.mixed:
        indicatorColor = Colors.orange;
        indicatorIcon = Icons.blender;
        displayText = 'Mixed';
        break;
      default:
        indicatorColor = Colors.grey;
        indicatorIcon = Icons.help_outline;
        displayText = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(indicatorIcon, size: 12, color: indicatorColor),
          const SizedBox(width: 3),
          if (confidence > 0)
            Text(
              '${(confidence * 100).toInt()}%',
              style: TextStyle(
                color: indicatorColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              displayText,
              style: TextStyle(
                color: indicatorColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
