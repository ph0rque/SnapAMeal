import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../design_system/snap_ui.dart';
import '../services/health_community_service.dart';
import '../services/friend_service.dart';
import '../services/rag_service.dart';
import '../services/openai_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HealthFriendsPage extends StatefulWidget {
  const HealthFriendsPage({super.key});

  @override
  State<HealthFriendsPage> createState() => _HealthFriendsPageState();
}

class _HealthFriendsPageState extends State<HealthFriendsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late HealthCommunityService _healthCommunityService;
  late FriendService _friendService;
  
  List<Map<String, dynamic>> _healthSuggestions = [];
  List<Map<String, dynamic>> _currentFriends = [];
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize services
    _friendService = FriendService();
    final ragService = RAGService(OpenAIService());
    _healthCommunityService = HealthCommunityService(ragService, _friendService);
    
    _getCurrentUser();
    _loadHealthSuggestions();
    _loadFriends();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthSuggestions() async {
    if (_currentUserId == null) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final suggestions = await _healthCommunityService.getHealthBasedFriendSuggestions();
      setState(() {
        _healthSuggestions = suggestions;
      });
    } catch (e) {
      debugPrint('Error loading health suggestions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFriends() async {
    if (_currentUserId == null) return;

    try {
      final friendsStream = _friendService.getFriendsStream();
      friendsStream.listen((friends) {
        if (mounted) {
          setState(() {
            _currentFriends = friends.map((friendId) {
              return {
                'id': friendId,
                'display_name': 'Friend $friendId', // Placeholder - would need to fetch actual data
              };
            }).toList();
          });
        }
      });
    } catch (e) {
      debugPrint('Error loading friends: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: SnapColors.backgroundDark,
        title: Text(
          'Health Friends',
          style: SnapTypography.heading2.copyWith(color: SnapColors.primaryYellow),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: SnapColors.primaryYellow,
          unselectedLabelColor: SnapColors.textSecondary,
          indicatorColor: SnapColors.primaryYellow,
          tabs: const [
            Tab(text: 'AI Matches'),
            Tab(text: 'Discover'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: SnapColors.primaryYellow),
            onPressed: _loadHealthSuggestions,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAIMatchesTab(),
          _buildDiscoverTab(),
        ],
      ),
    );
  }

  Widget _buildAIMatchesTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: SnapColors.primaryYellow),
            SizedBox(height: 16),
            Text(
              'Finding your perfect health matches...',
              style: TextStyle(color: SnapColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_healthSuggestions.isEmpty) {
      return _buildEmptyAIMatchesState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _healthSuggestions.length,
      itemBuilder: (context, index) {
        return _buildHealthSuggestionCard(_healthSuggestions[index]);
      },
    );
  }

  Widget _buildDiscoverTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendService.searchUsers(''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: SnapColors.primaryYellow),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading users: \${snapshot.error}',
              style: SnapTypography.body.copyWith(color: SnapColors.textSecondary),
            ),
          );
        }

        final users = snapshot.data ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            return _buildUserCard(users[index]);
          },
        );
      },
    );
  }

  Widget _buildHealthSuggestionCard(Map<String, dynamic> suggestion) {
    final userId = suggestion['user_id'] as String;
    final healthGoals = List<String>.from(suggestion['health_goals'] ?? []);
    final interests = List<String>.from(suggestion['interests'] ?? []);
    final similarityScore = suggestion['similarity_score'] as double? ?? 0.0;
    final suggestionReason = suggestion['suggestion_reason'] as String? ?? 
        'You share similar health goals and could motivate each other!';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.primaryYellow.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SnapAvatar(
                name: 'User',
                radius: 25,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<DocumentSnapshot>(
                      future: _friendService.getUserData(userId),
                      builder: (context, snapshot) {
                        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                        return Text(
                          userData['display_name'] ?? 'Loading...',
                          style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
                        );
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getMatchQualityColor(similarityScore),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '\${(similarityScore * 100).round()}% Match',
                        style: SnapTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.auto_awesome,
                color: SnapColors.primaryYellow,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SnapColors.primaryYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: SnapColors.primaryYellow,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestionReason,
                    style: SnapTypography.caption.copyWith(color: SnapColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
          if (healthGoals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Shared Health Goals',
              style: SnapTypography.caption.copyWith(
                color: SnapColors.primaryYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: healthGoals.take(3).map((goal) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SnapColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  goal,
                  style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SnapButton(
                  text: 'Add Friend',
                  onTap: () => _sendFriendRequest(userId),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.info_outline, color: SnapColors.textSecondary),
                onPressed: () => _showUserProfile(userId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final userId = user['uid'] as String;
    final displayName = user['display_name'] as String? ?? 'Unknown User';
    final bio = user['bio'] as String? ?? '';

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
          Row(
            children: [
              SnapAvatar(
                name: 'User',
                radius: 25,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
                    ),
                    if (bio.isNotEmpty)
                      Text(
                        bio,
                        style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SnapButton(
                  text: 'Add Friend',
                  onTap: () => _sendFriendRequest(userId),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.info_outline, color: SnapColors.textSecondary),
                onPressed: () => _showUserProfile(userId),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAIMatchesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: SnapColors.primaryYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 40,
              color: SnapColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No AI Matches Yet',
            style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your health profile to get\npersonalized friend suggestions',
            style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SnapButton(
            text: 'Complete Profile',
            onTap: _showHealthProfileSetup,
          ),
        ],
      ),
    );
  }

  Color _getMatchQualityColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    if (score >= 0.4) return Colors.blue;
    return Colors.grey;
  }

  void _sendFriendRequest(String userId) async {
    try {
      await _friendService.sendFriendRequest(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Friend request sent!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send friend request: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserProfile(String userId) {
    Navigator.pushNamed(context, '/user_profile', arguments: userId);
  }

  void _showHealthProfileSetup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SnapColors.backgroundLight,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: SnapColors.textSecondary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Complete Your Health Profile',
                style: SnapTypography.heading2.copyWith(color: SnapColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                'Help us find the perfect health buddies for you by sharing your goals and interests.',
                style: SnapTypography.body.copyWith(color: SnapColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Text(
                'Health Goals',
                style: SnapTypography.heading3.copyWith(color: SnapColors.primaryYellow),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Weight Loss',
                  'Muscle Building',
                  'Endurance',
                  'Flexibility',
                  'Mental Health',
                  'Nutrition',
                  'Sleep Quality',
                ].map((goal) => _buildSelectableChip(goal, false)).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                'Interests',
                style: SnapTypography.heading3.copyWith(color: SnapColors.primaryYellow),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Running',
                  'Yoga',
                  'Weightlifting',
                  'Cycling',
                  'Swimming',
                  'Hiking',
                  'Dancing',
                  'Martial Arts',
                ].map((interest) => _buildSelectableChip(interest, false)).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: SnapButton(
                  text: 'Save Profile',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement profile saving
                    _loadHealthSuggestions();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        // TODO: Implement selection logic
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? SnapColors.primaryYellow : Colors.transparent,
          border: Border.all(
            color: isSelected ? SnapColors.primaryYellow : SnapColors.textSecondary,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: SnapTypography.caption.copyWith(
            color: isSelected ? SnapColors.backgroundDark : SnapColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
