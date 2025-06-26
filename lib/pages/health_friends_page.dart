import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/health_community_service.dart';
import '../services/rag_service.dart';
import '../services/friend_service.dart';
import '../design_system/snap_ui.dart';
import '../design_system/widgets/snap_button.dart';
import '../design_system/widgets/snap_textfield.dart';
import '../design_system/widgets/snap_avatar.dart';

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
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    final ragService = Provider.of<RAGService>(context, listen: false);
    _friendService = Provider.of<FriendService>(context, listen: false);
    _healthCommunityService = HealthCommunityService(ragService, _friendService);
    
    _loadHealthSuggestions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthSuggestions() async {
    setState(() {
      _isLoadingSuggestions = true;
    });

    try {
      final suggestions = await _healthCommunityService.getHealthBasedFriendSuggestions();
      setState(() {
        _healthSuggestions = suggestions;
      });
    } catch (e) {
      debugPrint('Error loading health suggestions: \$e');
    } finally {
      setState(() {
        _isLoadingSuggestions = false;
      });
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
            Tab(text: 'My Friends'),
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
          _buildMyFriendsTab(),
        ],
      ),
    );
  }

  Widget _buildAIMatchesTab() {
    if (_isLoadingSuggestions) {
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

  Widget _buildMyFriendsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _friendService.getFriendsStream().asyncMap((friendIds) async {
        List<Map<String, dynamic>> friends = [];
        for (String friendId in friendIds) {
          final userData = await _friendService.getUserData(friendId);
          if (userData.exists) {
            friends.add(userData.data() as Map<String, dynamic>);
          }
        }
        return friends;
      }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: SnapColors.primaryYellow),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading friends: \${snapshot.error}',
              style: SnapTypography.body.copyWith(color: SnapColors.textSecondary),
            ),
          );
        }

        final friends = snapshot.data ?? [];

        if (friends.isEmpty) {
          return _buildEmptyFriendsState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (context, index) {
            return _buildFriendCard(friends[index]);
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

  Widget _buildFriendCard(Map<String, dynamic> friend) {
    final userId = friend['uid'] as String;
    final displayName = friend['display_name'] as String? ?? 'Unknown User';
    final bio = friend['bio'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SnapColors.border),
      ),
      child: Row(
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
          IconButton(
            icon: const Icon(Icons.chat, color: SnapColors.primaryYellow),
            onTap: () => _startChat(userId),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: SnapColors.textSecondary),
            onTap: () => _showFriendOptions(userId, displayName),
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

  Widget _buildEmptyFriendsState() {
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
              Icons.people,
              size: 40,
              color: SnapColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Friends Yet',
            style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Start connecting with people who share\nyour health and fitness goals',
            style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SnapButton(
            text: 'Find Friends',
            onTap: () => _tabController.animateTo(0),
            
            
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
    final success = await _friendService.sendFriendRequest(userId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Friend request sent!' : 'Failed to send friend request',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _startChat(String userId) {
    Navigator.pushNamed(context, '/chat', arguments: userId);
  }

  void _showUserProfile(String userId) {
    Navigator.pushNamed(context, '/user_profile', arguments: userId);
  }

  void _showFriendOptions(String userId, String displayName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SnapColors.backgroundLight,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.chat, color: SnapColors.primaryYellow),
              title: Text(
                'Message \$displayName',
                style: SnapTypography.body.copyWith(color: SnapColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _startChat(userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: SnapColors.primaryYellow),
              title: Text(
                'View Profile',
                style: SnapTypography.body.copyWith(color: SnapColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _showUserProfile(userId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.red),
              title: Text(
                'Remove Friend',
                style: SnapTypography.body.copyWith(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeFriend(userId, displayName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeFriend(String userId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SnapColors.backgroundLight,
        title: Text(
          'Remove Friend',
          style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove \$displayName from your friends?',
          style: SnapTypography.body.copyWith(color: SnapColors.textSecondary),
        ),
        actions: [
          TextButton(
            onTap: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: SnapTypography.body.copyWith(color: SnapColors.textSecondary),
            ),
          ),
          TextButton(
            onTap: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: SnapTypography.body.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _friendService.removeFriend(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Friend removed' : 'Failed to remove friend',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
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
