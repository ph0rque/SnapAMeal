import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design_system/snap_ui.dart';
import '../models/health_profile.dart';

import 'health_dashboard_page.dart';

class HealthOnboardingPage extends StatefulWidget {
  const HealthOnboardingPage({super.key});

  @override
  State<HealthOnboardingPage> createState() => _HealthOnboardingPageState();
}

class _HealthOnboardingPageState extends State<HealthOnboardingPage> {
  final PageController _pageController = PageController();
  
  int _currentPage = 0;
  final int _totalPages = 6;
  
  // Form data
  String _name = '';
  int _age = 25;
  Gender _gender = Gender.male;
  double _height = 170.0; // cm
  double _currentWeight = 70.0; // kg
  double _targetWeight = 65.0; // kg
  ActivityLevel _activityLevel = ActivityLevel.moderatelyActive;
  final Set<HealthGoalType> _selectedGoals = {};
  final Set<DietaryPreference> _selectedDietaryPrefs = {};
  
  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create health profile
      final healthProfile = HealthProfile(
        userId: user.uid,
        age: _age,
        gender: _gender.name,
        heightCm: _height,
        weightKg: _currentWeight,
        targetWeightKg: _targetWeight,
        activityLevel: _activityLevel,
        primaryGoals: _selectedGoals.toList(),
        dietaryPreferences: _selectedDietaryPrefs.toList(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('health_profiles')
          .doc(user.uid)
          .set(healthProfile.toFirestore());

      // Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HealthDashboardPage(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: SnapColors.accentRed,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),
            
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomePage(),
                  _buildBasicInfoPage(),
                  _buildPhysicalStatsPage(),
                  _buildActivityLevelPage(),
                  _buildHealthGoalsPage(),
                  _buildDietaryPreferencesPage(),
                ],
              ),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentPage + 1} of $_totalPages',
                style: SnapTypography.caption.copyWith(
                  color: SnapColors.textSecondary,
                ),
              ),
              Text(
                '${((_currentPage + 1) / _totalPages * 100).round()}%',
                style: SnapTypography.caption.copyWith(
                  color: SnapColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: SnapColors.greyLight,
            valueColor: AlwaysStoppedAnimation<Color>(SnapColors.primaryYellow),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: SnapColors.primaryYellow.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                size: 60,
                color: SnapColors.primaryYellow,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to Your Health Journey! 🌟',
              style: SnapTypography.heading1.copyWith(
                color: SnapColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Let\'s set up your personalized health profile to provide you with AI-powered insights and recommendations tailored just for you.',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SnapColors.accentBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: SnapColors.accentBlue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your health data is private and secure. We use it only to provide personalized recommendations.',
                      style: SnapTypography.caption.copyWith(
                        color: SnapColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Add some bottom padding for smaller screens
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell us about yourself',
              style: SnapTypography.heading2.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This helps us personalize your experience',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            // Name input
            Text(
              'What should we call you?',
              style: SnapTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (value) => setState(() => _name = value),
              style: SnapTypography.body.copyWith(
                color: SnapColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: SnapTypography.body.copyWith(
                  color: SnapColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: SnapColors.greyLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: SnapColors.greyLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: SnapColors.primaryYellow, width: 2),
                ),
                filled: true,
                fillColor: SnapColors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            
            // Age slider
            Text(
              'Age: $_age years',
              style: SnapTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _age.toDouble(),
              min: 16,
              max: 80,
              divisions: 64,
              activeColor: SnapColors.primaryYellow,
              onChanged: (value) => setState(() => _age = value.round()),
            ),
            const SizedBox(height: 24),
            
            // Gender selection
            Text(
              'Gender',
              style: SnapTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: Gender.values.map((gender) {
                final isSelected = _gender == gender;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _gender = gender),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? SnapColors.primaryYellow.withValues(alpha: 0.1)
                              : SnapColors.greyLight,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected 
                              ? Border.all(color: SnapColors.primaryYellow, width: 2)
                              : null,
                        ),
                        child: Text(
                          _getGenderDisplayName(gender),
                          style: SnapTypography.body.copyWith(
                            color: isSelected 
                                ? SnapColors.primaryYellow 
                                : SnapColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            // Add some bottom padding to ensure scrolling works properly
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPhysicalStatsPage() {
    // Convert metric to imperial for display
    final heightFeet = (_height / 30.48).floor();
    final heightInches = ((_height % 30.48) / 2.54);
    final currentWeightLbs = _currentWeight * 2.20462;
    final targetWeightLbs = _targetWeight * 2.20462;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Physical Stats',
              style: SnapTypography.heading2.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Help us calculate your personalized metrics',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            // Height
            Text(
              'Height: $heightFeet\'${heightInches.toStringAsFixed(1)}"',
              style: SnapTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _height,
              min: 140, // ~4'7"
              max: 220, // ~7'2"
              divisions: 80,
              activeColor: SnapColors.primaryYellow,
              onChanged: (value) => setState(() => _height = value),
            ),
            const SizedBox(height: 24),
            
            // Current weight
            Text(
              'Current Weight: ${currentWeightLbs.round()} lbs',
              style: SnapTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _currentWeight,
              min: 40, // ~88 lbs
              max: 150, // ~330 lbs
              divisions: 110,
              activeColor: SnapColors.primaryYellow,
              onChanged: (value) => setState(() => _currentWeight = value),
            ),
            const SizedBox(height: 24),
            
            // Target weight
            Text(
              'Target Weight: ${targetWeightLbs.round()} lbs',
              style: SnapTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _targetWeight,
              min: 40, // ~88 lbs
              max: 150, // ~330 lbs
              divisions: 110,
              activeColor: SnapColors.primaryYellow,
              onChanged: (value) => setState(() => _targetWeight = value),
            ),
            const SizedBox(height: 24),
            
            // BMI calculation
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: SnapColors.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calculate,
                    color: SnapColors.accentGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your current BMI: ${(_currentWeight / ((_height / 100) * (_height / 100))).toStringAsFixed(1)}',
                      style: SnapTypography.body.copyWith(
                        color: SnapColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityLevelPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Level',
            style: SnapTypography.heading2.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How active are you in a typical week?',
            style: SnapTypography.body.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView(
              children: ActivityLevel.values.map((level) {
                final isSelected = _activityLevel == level;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _activityLevel = level),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? SnapColors.primaryYellow.withValues(alpha: 0.1)
                            : SnapColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                              ? SnapColors.primaryYellow 
                              : SnapColors.greyLight,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getActivityLevelTitle(level),
                            style: SnapTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected 
                                  ? SnapColors.primaryYellow 
                                  : SnapColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getActivityLevelDescription(level),
                            style: SnapTypography.caption.copyWith(
                              color: SnapColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthGoalsPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Goals',
            style: SnapTypography.heading2.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What do you want to achieve? (Select all that apply)',
            style: SnapTypography.body.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: HealthGoalType.values.length,
              itemBuilder: (context, index) {
                final goal = HealthGoalType.values[index];
                final isSelected = _selectedGoals.contains(goal);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedGoals.remove(goal);
                      } else {
                        _selectedGoals.add(goal);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? SnapColors.primaryYellow.withValues(alpha: 0.1)
                          : SnapColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? SnapColors.primaryYellow 
                            : SnapColors.greyLight,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getGoalIcon(goal),
                          size: 32,
                          color: isSelected 
                              ? SnapColors.primaryYellow 
                              : SnapColors.textSecondary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getGoalDisplayName(goal),
                          style: SnapTypography.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected 
                                ? SnapColors.primaryYellow 
                                : SnapColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietaryPreferencesPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dietary Preferences',
            style: SnapTypography.heading2.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Any dietary restrictions or preferences? (Optional)',
            style: SnapTypography.body.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: ListView(
              children: DietaryPreference.values.map((pref) {
                final isSelected = _selectedDietaryPrefs.contains(pref);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedDietaryPrefs.add(pref);
                        } else {
                          _selectedDietaryPrefs.remove(pref);
                        }
                      });
                    },
                    title: Text(
                      _getDietaryPreferenceDisplayName(pref),
                      style: SnapTypography.body,
                    ),
                    activeColor: SnapColors.primaryYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    tileColor: SnapColors.white,
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: SnapColors.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: SnapColors.accentGreen,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You\'re all set! Your AI coach will use this information to provide personalized recommendations.',
                    style: SnapTypography.body.copyWith(
                      color: SnapColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousPage,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: SnapColors.primaryYellow),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Back',
                  style: SnapTypography.body.copyWith(
                    color: SnapColors.primaryYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 16),
          Expanded(
            flex: _currentPage == 0 ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _canProceed() ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: SnapColors.primaryYellow,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentPage == _totalPages - 1 ? 'Complete Setup' : 'Next',
                      style: SnapTypography.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0: // Welcome page
        return true;
      case 1: // Basic info
        return _name.isNotEmpty;
      case 2: // Physical stats
        return true;
      case 3: // Activity level
        return true;
      case 4: // Health goals
        return _selectedGoals.isNotEmpty;
      case 5: // Dietary preferences
        return true;
      default:
        return false;
    }
  }

  String _getGenderDisplayName(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
    }
  }

  String _getActivityLevelTitle(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.lightlyActive:
        return 'Lightly Active';
      case ActivityLevel.moderatelyActive:
        return 'Moderately Active';
      case ActivityLevel.veryActive:
        return 'Very Active';
      case ActivityLevel.extremelyActive:
        return 'Extremely Active';
      case ActivityLevel.extraActive:
        return 'Extra Active';
    }
  }

  String _getActivityLevelDescription(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 'Little or no exercise, desk job';
      case ActivityLevel.lightlyActive:
        return 'Light exercise 1-3 days/week';
      case ActivityLevel.moderatelyActive:
        return 'Moderate exercise 3-5 days/week';
      case ActivityLevel.veryActive:
        return 'Hard exercise 6-7 days/week';
      case ActivityLevel.extremelyActive:
        return 'Very hard exercise, physical job';
      case ActivityLevel.extraActive:
        return 'Very hard exercise, physical job';
    }
  }

  IconData _getGoalIcon(HealthGoalType goal) {
    switch (goal) {
      case HealthGoalType.weightLoss:
        return Icons.trending_down;
      case HealthGoalType.weightGain:
        return Icons.trending_up;
      case HealthGoalType.muscleGain:
        return Icons.fitness_center;
      case HealthGoalType.fatLoss:
        return Icons.local_fire_department;
      case HealthGoalType.intermittentFasting:
        return Icons.timer;
      case HealthGoalType.improveMetabolism:
        return Icons.speed;
      case HealthGoalType.betterSleep:
        return Icons.bedtime;
      case HealthGoalType.stressReduction:
        return Icons.spa;
      case HealthGoalType.increaseEnergy:
        return Icons.bolt;
      case HealthGoalType.improveDigestion:
        return Icons.restaurant;
      case HealthGoalType.longevity:
        return Icons.favorite;
      case HealthGoalType.mentalClarity:
        return Icons.psychology;
      case HealthGoalType.enduranceImprovement:
        return Icons.directions_run;
      case HealthGoalType.generalFitness:
        return Icons.fitness_center;
      case HealthGoalType.chronicDiseaseManagement:
        return Icons.medical_services;
      case HealthGoalType.mentalWellness:
        return Icons.psychology;
      case HealthGoalType.nutritionImprovement:
        return Icons.restaurant_menu;
      case HealthGoalType.sleepImprovement:
        return Icons.bedtime;
      case HealthGoalType.habitBuilding:
        return Icons.check_circle;
      case HealthGoalType.custom:
        return Icons.star;
    }
  }

  String _getGoalDisplayName(HealthGoalType goal) {
    switch (goal) {
      case HealthGoalType.weightLoss:
        return 'Weight Loss';
      case HealthGoalType.weightGain:
        return 'Weight Gain';
      case HealthGoalType.muscleGain:
        return 'Muscle Gain';
      case HealthGoalType.fatLoss:
        return 'Fat Loss';
      case HealthGoalType.intermittentFasting:
        return 'Intermittent Fasting';
      case HealthGoalType.improveMetabolism:
        return 'Improve Metabolism';
      case HealthGoalType.betterSleep:
        return 'Better Sleep';
      case HealthGoalType.stressReduction:
        return 'Stress Reduction';
      case HealthGoalType.increaseEnergy:
        return 'Increase Energy';
      case HealthGoalType.improveDigestion:
        return 'Improve Digestion';
      case HealthGoalType.longevity:
        return 'Longevity';
      case HealthGoalType.mentalClarity:
        return 'Mental Clarity';
      case HealthGoalType.enduranceImprovement:
        return 'Endurance Improvement';
      case HealthGoalType.generalFitness:
        return 'General Fitness';
      case HealthGoalType.chronicDiseaseManagement:
        return 'Chronic Disease Management';
      case HealthGoalType.mentalWellness:
        return 'Mental Wellness';
      case HealthGoalType.nutritionImprovement:
        return 'Nutrition Improvement';
      case HealthGoalType.sleepImprovement:
        return 'Sleep Improvement';
      case HealthGoalType.habitBuilding:
        return 'Habit Building';
      case HealthGoalType.custom:
        return 'Custom Goal';
    }
  }

  String _getDietaryPreferenceDisplayName(DietaryPreference pref) {
    switch (pref) {
      case DietaryPreference.vegetarian:
        return 'Vegetarian';
      case DietaryPreference.vegan:
        return 'Vegan';
      case DietaryPreference.keto:
        return 'Ketogenic';
      case DietaryPreference.paleo:
        return 'Paleo';
      case DietaryPreference.mediterranean:
        return 'Mediterranean';
      case DietaryPreference.lowCarb:
        return 'Low Carb';
      case DietaryPreference.lowFat:
        return 'Low Fat';
      case DietaryPreference.glutenFree:
        return 'Gluten Free';
      case DietaryPreference.dairyFree:
        return 'Dairy Free';
      case DietaryPreference.nutFree:
        return 'Nut Free';
      case DietaryPreference.lowSodium:
        return 'Low Sodium';
      case DietaryPreference.diabetic:
        return 'Diabetic Friendly';
      case DietaryPreference.none:
        return 'No Restrictions';
      case DietaryPreference.pescatarian:
        return 'Pescatarian';
      case DietaryPreference.intermittentFasting:
        return 'Intermittent Fasting';
      case DietaryPreference.custom:
        return 'Custom';
    }
  }
} 