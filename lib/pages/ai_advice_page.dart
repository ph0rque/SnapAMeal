import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design_system/snap_ui.dart';
// Removed unnecessary imports - already provided by snap_ui.dart
import '../models/ai_advice.dart';
import '../models/health_profile.dart';
import '../services/ai_advice_service.dart';
import '../services/auth_service.dart';

class AIAdvicePage extends StatefulWidget {
  const AIAdvicePage({super.key});

  @override
  State<AIAdvicePage> createState() => _AIAdvicePageState();
}

class _AIAdvicePageState extends State<AIAdvicePage>
    with TickerProviderStateMixin {
  final AIAdviceService _adviceService = AIAdviceService();
  final AuthService _authService = AuthService();
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late TabController _tabController;

  bool _isGeneratingAdvice = false;
  String? _currentUserId;
  HealthProfile? _healthProfile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    _currentUserId = authService.getCurrentUser()?.uid;

    if (_currentUserId != null) {
      _healthProfile = await _adviceService.getHealthProfile(_currentUserId!);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: SnapColors.backgroundDark,
        elevation: 0,
        title: Text(
          'AI Health Advisor',
          style: SnapTypography.heading2.copyWith(
            color: SnapColors.primaryYellow,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: SnapColors.primaryYellow,
          unselectedLabelColor: SnapColors.textSecondary,
          indicatorColor: SnapColors.primaryYellow,
          tabs: const [
            Tab(text: 'Chat'),
            Tab(text: 'My Advice'),
            Tab(text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatTab(),
          _buildAdviceHistoryTab(),
          _buildProfileTab(),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    if (_currentUserId == null) {
      return const Center(
        child: Text(
          'Please log in to access AI advice',
          style: TextStyle(color: SnapColors.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        // Welcome message - made more compact
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: SnapColors.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: SnapColors.primaryYellow.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: SnapColors.primaryYellow,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.psychology,
                      color: SnapColors.backgroundDark,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI Health Advisor',
                      style: SnapTypography.titleLarge.copyWith(
                        color: SnapColors.primaryYellow,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ask questions about health, nutrition, fitness, or wellness.',
                style: SnapTypography.caption.copyWith(
                  color: SnapColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              _buildQuickQuestions(),
            ],
          ),
        ),

        // Chat interface
        Expanded(
          child: StreamBuilder<List<AIAdvice>>(
            stream: _adviceService.getAdviceStream(_currentUserId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: SnapColors.primaryYellow,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading advice: ${snapshot.error}',
                    style: SnapTypography.body.copyWith(
                      color: SnapColors.textSecondary,
                    ),
                  ),
                );
              }

              final adviceList = snapshot.data ?? [];

              if (adviceList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: SnapColors.textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No advice yet',
                        style: SnapTypography.heading3.copyWith(
                          color: SnapColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Ask a question or tap one of the suggestions above',
                          style: SnapTypography.body.copyWith(
                            color: SnapColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: adviceList.length,
                itemBuilder: (context, index) {
                  final advice = adviceList[index];
                  return _buildAdviceCard(advice);
                },
              );
            },
          ),
        ),

        // Input area
        _buildInputArea(),
      ],
    );
  }

  Widget _buildQuickQuestions() {
    final questions = [
      'What should I eat today?',
      'How can I improve my fasting?',
      'Give me workout motivation',
      'Help with sleep schedule',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: questions
          .map(
            (question) => GestureDetector(
              onTap: () => _askQuestion(question),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SnapColors.primaryYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SnapColors.primaryYellow.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  question,
                  style: SnapTypography.caption.copyWith(
                    color: SnapColors.primaryYellow,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildAdviceCard(AIAdvice advice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getAdviceTypeColor(
                    advice.type,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getAdviceTypeIcon(advice.type),
                  color: _getAdviceTypeColor(advice.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advice.title,
                      style: SnapTypography.titleLarge.copyWith(
                        color: SnapColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${advice.typeDisplayName} • ${advice.categoryDisplayName}',
                      style: SnapTypography.caption.copyWith(
                        color: SnapColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildAdvicePriorityBadge(advice.priority),
            ],
          ),

          const SizedBox(height: 12),

          // Content
          Text(
            advice.content,
            style: SnapTypography.body.copyWith(color: SnapColors.textPrimary),
          ),

          // Suggested Actions
          if (advice.suggestedActions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Suggested Actions:',
              style: SnapTypography.headlineMedium.copyWith(
                color: SnapColors.primaryYellow,
              ),
            ),
            const SizedBox(height: 8),
            ...advice.suggestedActions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: SnapColors.primaryYellow,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        action,
                        style: SnapTypography.body.copyWith(
                          color: SnapColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              // Rating buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.thumb_down,
                      color: advice.isNegativelyRated
                          ? SnapColors.error
                          : SnapColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => _rateAdvice(advice.id, -1),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.thumb_up,
                      color: advice.isPositivelyRated
                          ? SnapColors.primaryYellow
                          : SnapColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => _rateAdvice(advice.id, 1),
                  ),
                ],
              ),

              const Spacer(),

              // Bookmark
              IconButton(
                icon: Icon(
                  advice.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: advice.isBookmarked
                      ? SnapColors.primaryYellow
                      : SnapColors.textSecondary,
                  size: 20,
                ),
                onPressed: () =>
                    _bookmarkAdvice(advice.id, !advice.isBookmarked),
              ),

              // Share
              IconButton(
                icon: const Icon(
                  Icons.share,
                  color: SnapColors.textSecondary,
                  size: 20,
                ),
                onPressed: () => _shareAdvice(advice),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvicePriorityBadge(AdvicePriority priority) {
    Color color;
    switch (priority) {
      case AdvicePriority.urgent:
        color = SnapColors.error;
        break;
      case AdvicePriority.high:
        color = SnapColors.primaryYellow;
        break;
      case AdvicePriority.medium:
        color = SnapColors.textSecondary;
        break;
      case AdvicePriority.low:
        color = SnapColors.textSecondary.withValues(alpha: 0.6);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        priority.name.toUpperCase(),
        style: SnapTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getAdviceTypeColor(AdviceType type) {
    switch (type) {
      case AdviceType.nutrition:
        return Colors.green;
      case AdviceType.exercise:
        return Colors.blue;
      case AdviceType.fasting:
        return Colors.orange;
      case AdviceType.sleep:
        return Colors.purple;
      case AdviceType.motivation:
        return SnapColors.primaryYellow;
      default:
        return SnapColors.textSecondary;
    }
  }

  IconData _getAdviceTypeIcon(AdviceType type) {
    switch (type) {
      case AdviceType.nutrition:
        return Icons.restaurant;
      case AdviceType.exercise:
        return Icons.fitness_center;
      case AdviceType.fasting:
        return Icons.timer;
      case AdviceType.sleep:
        return Icons.bedtime;
      case AdviceType.motivation:
        return Icons.emoji_events;
      case AdviceType.mentalHealth:
        return Icons.psychology;
      case AdviceType.hydration:
        return Icons.water_drop;
      default:
        return Icons.lightbulb;
    }
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        border: Border(top: BorderSide(color: SnapColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SnapTextField(
              controller: _queryController,
              hintText: 'Ask for health advice...',
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: SnapColors.primaryYellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: _isGeneratingAdvice
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: SnapColors.backgroundDark,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send, color: SnapColors.backgroundDark),
              onPressed: _isGeneratingAdvice ? null : _sendQuery,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceHistoryTab() {
    if (_currentUserId == null) {
      return const Center(
        child: Text(
          'Please log in to view advice history',
          style: TextStyle(color: SnapColors.textSecondary),
        ),
      );
    }

    return StreamBuilder<List<AIAdvice>>(
      stream: _adviceService.getAdviceStream(_currentUserId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: SnapColors.primaryYellow),
          );
        }

        final adviceList = snapshot.data ?? [];
        final bookmarkedAdvice = adviceList
            .where((advice) => advice.isBookmarked)
            .toList();
        final recentAdvice = adviceList.take(10).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats
              _buildAdviceStats(adviceList),

              const SizedBox(height: 24),

              // Bookmarked advice
              if (bookmarkedAdvice.isNotEmpty) ...[
                Text(
                  'Bookmarked Advice',
                  style: SnapTypography.headlineMedium.copyWith(
                    color: SnapColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ...bookmarkedAdvice.map((advice) => _buildAdviceCard(advice)),
                const SizedBox(height: 24),
              ],

              // Recent advice
              Text(
                'Recent Advice',
                style: SnapTypography.headlineMedium.copyWith(
                  color: SnapColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...recentAdvice.map((advice) => _buildAdviceCard(advice)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdviceStats(List<AIAdvice> adviceList) {
    final totalAdvice = adviceList.length;
    final positiveRatings = adviceList
        .where((advice) => advice.isPositivelyRated)
        .length;
    final bookmarked = adviceList.where((advice) => advice.isBookmarked).length;
    final thisWeek = adviceList
        .where(
          (advice) => advice.createdAt.isAfter(
            DateTime.now().subtract(const Duration(days: 7)),
          ),
        )
        .length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your AI Advice Stats',
            style: SnapTypography.titleLarge.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Advice',
                  totalAdvice.toString(),
                  Icons.lightbulb,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'This Week',
                  thisWeek.toString(),
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Liked',
                  positiveRatings.toString(),
                  Icons.thumb_up,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Bookmarked',
                  bookmarked.toString(),
                  Icons.bookmark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: SnapColors.primaryYellow, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.primaryYellow,
          ),
        ),
        Text(
          label,
          style: SnapTypography.caption.copyWith(
            color: SnapColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    if (_currentUserId == null) {
      return const Center(
        child: Text(
          'Please log in to view profile',
          style: TextStyle(color: SnapColors.textSecondary),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health profile summary
          _buildHealthProfileSummary(),

          const SizedBox(height: 24),

          // Advice preferences
          _buildAdvicePreferences(),

          const SizedBox(height: 24),

          // Actions
          SnapButton(
            text: 'Update Health Profile',
            onTap: _updateHealthProfile,
          ),

          const SizedBox(height: 16),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showLogoutDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: SnapColors.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthProfileSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Health Profile',
            style: SnapTypography.titleLarge.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          if (_healthProfile != null) ...[
            _buildProfileItem(
              'Age',
              _healthProfile!.age?.toString() ?? 'Not set',
            ),
            _buildProfileItem(
              'Activity Level',
              _healthProfile!.activityLevelDisplayName,
            ),
            _buildProfileItem(
              'Primary Goals',
              _healthProfile!.primaryGoalsDisplayNames.join(', '),
            ),
          ] else ...[
            Text(
              'No health profile found. Please update your profile to get personalized advice.',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not set' : value,
              style: SnapTypography.body.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvicePreferences() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Advice Preferences',
            style: SnapTypography.titleLarge.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Receive AI Advice',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Get personalized health advice based on your activity',
              style: SnapTypography.caption.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
            value: _healthProfile?.receiveAdvice ?? true,
            onChanged: _toggleAdvicePreference,
            activeThumbColor: SnapColors.primaryYellow,
          ),
        ],
      ),
    );
  }

  Future<void> _askQuestion(String question) async {
    _queryController.text = question;
    await _sendQuery();
  }

  Future<void> _sendQuery() async {
    if (_queryController.text.trim().isEmpty || _currentUserId == null) return;

    setState(() {
      _isGeneratingAdvice = true;
    });

    try {
      await _adviceService.handleConversationalQuery(
        _currentUserId!,
        _queryController.text.trim(),
      );
      _queryController.clear();

      // Scroll to top to show new advice
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating advice: $e'),
            backgroundColor: SnapColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingAdvice = false;
        });
      }
    }
  }

  Future<void> _rateAdvice(String adviceId, int rating) async {
    try {
      await _adviceService.recordAdviceFeedback(adviceId, rating);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rating advice: $e'),
            backgroundColor: SnapColors.error,
          ),
        );
      }
    }
  }

  Future<void> _bookmarkAdvice(String adviceId, bool bookmarked) async {
    try {
      await _adviceService.bookmarkAdvice(adviceId, bookmarked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error bookmarking advice: $e'),
            backgroundColor: SnapColors.error,
          ),
        );
      }
    }
  }

  Future<void> _shareAdvice(AIAdvice advice) async {
    // Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing functionality coming soon!'),
        backgroundColor: SnapColors.textSecondary,
      ),
    );
  }

  Future<void> _updateHealthProfile() async {
    // Navigate to health profile update page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Health profile update coming soon!'),
        backgroundColor: SnapColors.textSecondary,
      ),
    );
  }

  Future<void> _toggleAdvicePreference(bool value) async {
    if (_healthProfile != null) {
      try {
        final updatedProfile = _healthProfile!.copyWith(receiveAdvice: value);
        await _adviceService.updateHealthProfile(updatedProfile);
        setState(() {
          _healthProfile = updatedProfile;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating preference: $e'),
              backgroundColor: SnapColors.error,
            ),
          );
        }
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
            },
            style: TextButton.styleFrom(foregroundColor: SnapColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
