import 'package:flutter/material.dart';
import '../design_system/snap_ui.dart';
import '../services/weekly_review_service.dart';
import '../di/service_locator.dart';
import '../widgets/review_card.dart';
import '../utils/logger.dart';

class WeeklyReviewPage extends StatefulWidget {
  const WeeklyReviewPage({super.key});

  @override
  State<WeeklyReviewPage> createState() => _WeeklyReviewPageState();
}

class _WeeklyReviewPageState extends State<WeeklyReviewPage> with TickerProviderStateMixin {
  final WeeklyReviewService _reviewService = sl<WeeklyReviewService>();
  late TabController _tabController;
  String? _currentUserId;
  bool _isGeneratingWeekly = false;
  bool _isGeneratingMonthly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUserId = _reviewService.currentUserId;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Generate new weekly review
  Future<void> _generateWeeklyReview() async {
    if (_currentUserId == null || _isGeneratingWeekly) return;

    setState(() {
      _isGeneratingWeekly = true;
    });

    try {
      final review = await _reviewService.generateWeeklyReview(userId: _currentUserId!);
      
      if (!mounted) return;
      
      if (review != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New weekly review generated!'),
            backgroundColor: SnapColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to generate review. Please try again.'),
            backgroundColor: SnapColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Logger.d('Error generating weekly review: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error generating review. Please try again.'),
          backgroundColor: SnapColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingWeekly = false;
        });
      }
    }
  }

  /// Generate new monthly review
  Future<void> _generateMonthlyReview() async {
    if (_currentUserId == null || _isGeneratingMonthly) return;

    setState(() {
      _isGeneratingMonthly = true;
    });

    try {
      final review = await _reviewService.generateMonthlyReview(userId: _currentUserId!);
      
      if (!mounted) return;
      
      if (review != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New monthly review generated!'),
            backgroundColor: SnapColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to generate review. Please try again.'),
            backgroundColor: SnapColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      Logger.d('Error generating monthly review: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error generating review. Please try again.'),
          backgroundColor: SnapColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingMonthly = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Reviews'),
          backgroundColor: SnapColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Please log in to view your reviews'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SnapColors.background,
      appBar: AppBar(
        title: const Text('My Reviews'),
        backgroundColor: SnapColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_view_week),
              text: 'Weekly',
            ),
            Tab(
              icon: Icon(Icons.calendar_month),
              text: 'Monthly',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeeklyReviewsTab(),
          _buildMonthlyReviewsTab(),
        ],
      ),
    );
  }

  /// Build weekly reviews tab
  Widget _buildWeeklyReviewsTab() {
    return Column(
      children: [
        // Generate new review button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
          child: ElevatedButton.icon(
            onPressed: _isGeneratingWeekly ? null : _generateWeeklyReview,
            icon: _isGeneratingWeekly 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isGeneratingWeekly ? 'Generating...' : 'Generate This Week\'s Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SnapColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SnapDimensions.radiusMedium),
              ),
            ),
          ),
        ),
        
        // Reviews list
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _reviewService.getUserReviews(
              userId: _currentUserId!,
              reviewType: 'weekly',
              limit: 20,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: SnapColors.error,
                      ),
                      const SizedBox(height: SnapDimensions.spacingMedium),
                      Text(
                        'Error loading reviews',
                        style: SnapTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: SnapDimensions.spacingSmall),
                      Text(
                        'Please try again later',
                        style: SnapTextStyles.bodyMedium.copyWith(
                          color: SnapColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final reviews = snapshot.data ?? [];

              if (reviews.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_view_week_outlined,
                        size: 64,
                        color: SnapColors.textSecondary,
                      ),
                      const SizedBox(height: SnapDimensions.spacingMedium),
                      Text(
                        'No weekly reviews yet',
                        style: SnapTextStyles.headlineSmall,
                      ),
                      const SizedBox(height: SnapDimensions.spacingSmall),
                      Text(
                        'Generate your first weekly review to see your progress!',
                        style: SnapTextStyles.bodyMedium.copyWith(
                          color: SnapColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: SnapDimensions.spacingMedium),
                    child: ReviewCard(
                      review: review,
                      reviewType: 'weekly',
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build monthly reviews tab
  Widget _buildMonthlyReviewsTab() {
    return Column(
      children: [
        // Generate new review button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
          child: ElevatedButton.icon(
            onPressed: _isGeneratingMonthly ? null : _generateMonthlyReview,
            icon: _isGeneratingMonthly 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isGeneratingMonthly ? 'Generating...' : 'Generate This Month\'s Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: SnapColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(SnapDimensions.radiusMedium),
              ),
            ),
          ),
        ),
        
        // Reviews list
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _reviewService.getUserReviews(
              userId: _currentUserId!,
              reviewType: 'monthly',
              limit: 12,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: SnapColors.error,
                      ),
                      const SizedBox(height: SnapDimensions.spacingMedium),
                      Text(
                        'Error loading reviews',
                        style: SnapTextStyles.bodyLarge,
                      ),
                      const SizedBox(height: SnapDimensions.spacingSmall),
                      Text(
                        'Please try again later',
                        style: SnapTextStyles.bodyMedium.copyWith(
                          color: SnapColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final reviews = snapshot.data ?? [];

              if (reviews.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 64,
                        color: SnapColors.textSecondary,
                      ),
                      const SizedBox(height: SnapDimensions.spacingMedium),
                      Text(
                        'No monthly reviews yet',
                        style: SnapTextStyles.headlineSmall,
                      ),
                      const SizedBox(height: SnapDimensions.spacingSmall),
                      Text(
                        'Generate your first monthly review to see your long-term progress!',
                        style: SnapTextStyles.bodyMedium.copyWith(
                          color: SnapColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: SnapDimensions.spacingMedium),
                    child: ReviewCard(
                      review: review,
                      reviewType: 'monthly',
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
} 