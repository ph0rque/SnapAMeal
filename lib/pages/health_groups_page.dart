import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../design_system/snap_ui.dart';
import '../services/health_community_service.dart';
import '../services/rag_service.dart';
import '../services/friend_service.dart';
import '../services/openai_service.dart';
import '../models/health_group.dart';
import '../pages/chat_page.dart';

class HealthGroupsPage extends StatefulWidget {
  const HealthGroupsPage({super.key});

  @override
  State<HealthGroupsPage> createState() => _HealthGroupsPageState();
}

class _HealthGroupsPageState extends State<HealthGroupsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late HealthCommunityService _healthCommunityService;
  late FriendService _friendService;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  HealthGroupType? _selectedType;
  HealthGroupPrivacy? _selectedPrivacy = HealthGroupPrivacy.public;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Added Friends tab

    // Initialize services
    _friendService = FriendService();
    final ragService = RAGService(OpenAIService());
    _healthCommunityService = HealthCommunityService(ragService, _friendService);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: SnapColors.backgroundLight,
        foregroundColor: Colors.black, // Explicit black color for visibility
        iconTheme: const IconThemeData(color: Colors.black), // Explicit icon color
        title: Text(
          'Community',
          style: SnapTypography.heading2.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: SnapColors.primaryYellow,
          unselectedLabelColor: SnapColors.textSecondary,
          indicatorColor: SnapColors.primaryYellow,
          isScrollable: true, // Make tabs scrollable since we have 4 now
          tabs: const [
            Tab(text: 'Groups'),
            Tab(text: 'Discover'),
            Tab(text: 'Friends'),
            Tab(text: 'Challenges'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyGroupsTab(),
          _buildDiscoverTab(),
          _buildFriendsTab(),
          _buildChallengesTab(),
        ],
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    return StreamBuilder<List<HealthGroup>>(
      stream: _healthCommunityService.getUserHealthGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: SnapColors.primaryYellow),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading groups: \${snapshot.error}',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
          );
        }

        final groups = snapshot.data ?? [];

        if (groups.isEmpty) {
          return _buildEmptyGroupsState();
        }

        return Column(
          children: [
            // Add Group button at the top of the Groups tab
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showCreateGroupDialog,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Create New Group'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SnapColors.primaryYellow,
                        foregroundColor: SnapColors.backgroundDark,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Groups list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  return _buildGroupCard(groups[index], isMyGroup: true);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDiscoverTab() {
    return Column(
      children: [
        _buildSearchAndFilters(),
        Expanded(
          child: StreamBuilder<List<HealthGroup>>(
            stream: _healthCommunityService.searchHealthGroups(
              type: _selectedType,
              searchTerm: _searchController.text.isEmpty
                  ? null
                  : _searchController.text,
            ),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: SnapColors.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading groups',
                        style: SnapTypography.heading3.copyWith(
                          color: SnapColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your connection and try again',
                        style: SnapTypography.body.copyWith(
                          color: SnapColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SnapButton(
                        text: 'Retry',
                        onTap: () => setState(() {}),
                      ),
                    ],
                  ),
                );
              }

              final groups = snapshot.data ?? [];

              if (groups.isEmpty) {
                return _buildNoGroupsFoundState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  return _buildGroupCard(groups[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsTab() {
    return Container(
      color: SnapColors.backgroundLight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Search for Friends",
            style: SnapTypography.heading3.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 250, // Reduced height to prevent overflow
            child: SnapUserSearch(),
          ),
          const SizedBox(height: 20),
          Text(
            "My Friends", 
            style: SnapTypography.heading3.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150, // Constrained height for friends list
            child: _buildFriendsList(),
          ),
          const SizedBox(height: 20),
          Text(
            "Friend Requests",
            style: SnapTypography.heading3.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150, // Constrained height for friend requests
            child: _buildFriendRequestList(),
          ),
          const SizedBox(height: 20), // Bottom padding
        ],
      ),
      ),
    );
  }

  Widget _buildChallengesTab() {
    return const Center(
      child: Text(
        'Challenges coming soon!',
        style: TextStyle(color: SnapColors.textSecondary),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: SnapColors.backgroundLight,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search groups...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: HealthGroupType.values.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildFilterChip('All', _selectedType == null, () {
                    setState(() {
                      _selectedType = null;
                    });
                  });
                }

                final type = HealthGroupType.values[index - 1];
                return _buildFilterChip(
                  type.name.toUpperCase(),
                  _selectedType == type,
                  () {
                    setState(() {
                      _selectedType = _selectedType == type ? null : type;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? SnapColors.primaryYellow : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? SnapColors.primaryYellow
                  : SnapColors.textSecondary,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: SnapTypography.caption.copyWith(
              color: isSelected
                  ? SnapColors.backgroundDark
                  : SnapColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(HealthGroup group, {bool isMyGroup = false}) {
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SnapColors.primaryYellow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    group.typeIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: SnapTypography.heading3.copyWith(
                        color: SnapColors.textPrimary,
                      ),
                    ),
                    Text(
                      group.typeDisplayName,
                      style: SnapTypography.caption.copyWith(
                        color: SnapColors.primaryYellow,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SnapColors.primaryYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${group.memberCount} members',
                  style: SnapTypography.caption.copyWith(
                    color: SnapColors.primaryYellow,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            group.description,
            style: SnapTypography.caption.copyWith(
              color: SnapColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (group.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: group.tags
                  .take(3)
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: SnapColors.backgroundDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#$tag',
                        style: SnapTypography.caption.copyWith(
                          color: SnapColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
                        Row(
                children: [
                  Expanded(
                    child: SnapButton(
                      text: isMyGroup ? 'Group Info' : 'Join Group',
                      onTap: () => isMyGroup 
                          ? _showGroupDetails(group) 
                          : _handleGroupAction(group, isMyGroup),
                    ),
                  ),
                  if (isMyGroup) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.chat,
                        color: SnapColors.primaryYellow,
                      ),
                      onPressed: () => _navigateToGroupChat(group),
                      tooltip: 'Group Chat',
                    ),
                  ] else ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.info_outline,
                        color: SnapColors.textSecondary,
                      ),
                      onPressed: () => _showGroupDetails(group),
                    ),
                  ],
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildEmptyGroupsState() {
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
              Icons.group,
              size: 40,
              color: SnapColors.primaryYellow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Groups Yet',
            style: SnapTypography.heading3.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join health groups to connect with\nlike-minded fitness enthusiasts',
            style: SnapTypography.caption.copyWith(
              color: SnapColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SnapButton(
                  text: 'Create Group',
                  onTap: _showCreateGroupDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SnapButton(
                  text: 'Discover Groups',
                  onTap: () => _tabController.animateTo(1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoGroupsFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 60,
            color: SnapColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Groups Found',
            style: SnapTypography.heading3.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search, or create the first group in this category!',
            style: SnapTypography.caption.copyWith(
              color: SnapColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          SnapButton(
            text: 'Create First Group',
            onTap: _showCreateGroupDialog,
          ),
        ],
      ),
    );
  }

  void _handleGroupAction(HealthGroup group, bool isMyGroup) {
    if (isMyGroup) {
      _navigateToGroupChat(group);
    } else {
      _joinGroup(group);
    }
  }

    void _navigateToGroupChat(HealthGroup group) async {
    // Show permission notice dialog instead of trying to access chat
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SnapColors.backgroundLight,
        title: Text(
          'Group Chat Unavailable',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group chat features are currently being set up. In the meantime, you can:',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildAlternativeOption(Icons.people, 'Connect with group members via the Friends tab'),
            const SizedBox(height: 8),
            _buildAlternativeOption(Icons.forum, 'Use general chat to discuss with other users'),
            const SizedBox(height: 8),
            _buildAlternativeOption(Icons.info, 'Check group details for member information'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: SnapTypography.body.copyWith(
                color: SnapColors.primaryYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/chats');
            },
            child: Text(
              'Go to Chats',
              style: SnapTypography.body.copyWith(
                color: SnapColors.primaryYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeOption(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: SnapColors.primaryYellow),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: SnapTypography.caption.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }



  void _joinGroup(HealthGroup group) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: SnapColors.primaryYellow,
        ),
      ),
    );

    try {
      final success = await _healthCommunityService.joinHealthGroup(group.id);

      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        
                  if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Successfully joined ${group.name}! Group features are now available.',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'View',
                  textColor: Colors.white,
                  onPressed: () => _showGroupDetails(group),
                ),
              ),
            );
        } else {
          _showJoinGroupErrorDialog(group);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading dialog
        _showJoinGroupErrorDialog(group);
      }
    }
  }

  void _showJoinGroupErrorDialog(HealthGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SnapColors.backgroundLight,
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text(
              'Join Group Issue',
              style: SnapTypography.heading3.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unable to join "${group.name}" at the moment. This might be due to:',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _buildAlternativeOption(Icons.people, 'Group may be full or require approval'),
            const SizedBox(height: 8),
            _buildAlternativeOption(Icons.settings, 'Temporary system maintenance'),
            const SizedBox(height: 8),
            _buildAlternativeOption(Icons.wifi_off, 'Connection issues'),
            const SizedBox(height: 16),
            Text(
              'You can still:',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _buildAlternativeOption(Icons.visibility, 'View group details and member list'),
            const SizedBox(height: 8),
            _buildAlternativeOption(Icons.person_add, 'Connect with members individually'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: SnapTypography.body.copyWith(
                color: SnapColors.primaryYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showGroupDetails(group);
            },
            child: Text(
              'View Group',
              style: SnapTypography.body.copyWith(
                color: SnapColors.primaryYellow,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails(HealthGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SnapColors.backgroundLight,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: SnapColors.primaryYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          group.typeIcon,
                          style: const TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group.name,
                            style: SnapTypography.heading2.copyWith(
                              color: SnapColors.textPrimary,
                            ),
                          ),
                          Text(
                            group.typeDisplayName,
                            style: SnapTypography.body.copyWith(
                              color: SnapColors.primaryYellow,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: SnapTypography.heading3.copyWith(
                    color: SnapColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  group.description,
                  style: SnapTypography.body.copyWith(
                    color: SnapColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatItem('Members', '${group.memberCount}'),
                    _buildStatItem('Privacy', group.privacy.name.toUpperCase()),
                    _buildStatItem(
                      'Activity',
                      group.activityLevel.name.toUpperCase(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _buildGroupActionButton(group),
                ),
                const SizedBox(height: 8), // Add bottom padding for scroll
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
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
      ),
    );
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: SnapColors.backgroundLight,
          title: Text(
            'Create Health Group',
            style: SnapTypography.heading3.copyWith(
              color: SnapColors.textPrimary,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0), // More horizontal padding
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.85, // Make dialog wider (85% of screen width)
            child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SnapTextField(
                  controller: _nameController,
                  hintText: 'Group name',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Group description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HealthGroupType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Group Type',
                    hintText: 'Select a group type',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: SnapColors.backgroundLight,
                  style: SnapTypography.body.copyWith(
                    color: SnapColors.textPrimary,
                  ),
                  items: HealthGroupType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            _getTypeDisplayName(type),
                            overflow: TextOverflow.ellipsis,
                            style: SnapTypography.body.copyWith(
                              color: SnapColors.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HealthGroupPrivacy>(
                  value: _selectedPrivacy,
                  decoration: const InputDecoration(
                    labelText: 'Privacy',
                    hintText: 'Select privacy level',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: SnapColors.backgroundLight,
                  style: SnapTypography.body.copyWith(
                    color: SnapColors.textPrimary,
                  ),
                  items: HealthGroupPrivacy.values
                      .map(
                        (privacy) => DropdownMenuItem(
                          value: privacy,
                          child: Text(
                            privacy.name[0].toUpperCase() + privacy.name.substring(1),
                            overflow: TextOverflow.ellipsis,
                            style: SnapTypography.body.copyWith(
                              color: SnapColors.textPrimary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPrivacy = value;
                      });
                    }
                  },
                ),
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: SnapTypography.body.copyWith(
                  color: SnapColors.textSecondary,
                ),
              ),
            ),
            SnapButton(text: 'Create Group', onTap: _createGroup),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  String _getTypeDisplayName(HealthGroupType type) {
    switch (type) {
      case HealthGroupType.fasting:
        return 'Fasting Support';
      case HealthGroupType.calorieGoals:
        return 'Calorie Goals';
      case HealthGroupType.workoutBuddies:
        return 'Workout Buddies';
      case HealthGroupType.nutrition:
        return 'Nutrition';
      case HealthGroupType.wellness:
        return 'Wellness';
      case HealthGroupType.challenges:
        return 'Challenges';
      case HealthGroupType.support:
        return 'Support';
      case HealthGroupType.recipes:
        return 'Recipes';
    }
  }

  void _createGroup() async {
    final name = _nameController.text;
    final description = _descriptionController.text;
    final type = _selectedType;
    final privacy = _selectedPrivacy;

    if (name.isEmpty || description.isEmpty || type == null || privacy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields and select group type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.pop(context);

    final groupId = await _healthCommunityService.createHealthGroup(
      name: name,
      description: description,
      type: type,
      privacy: privacy,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            groupId != null
                ? 'Group created successfully!'
                : 'Failed to create group',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: groupId != null ? Colors.green : Colors.red,
        ),
      );

      if (groupId != null) {
        _tabController.animateTo(0);
      }
    }
  }

  Widget _buildGroupActionButton(HealthGroup group) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return SnapButton(
        text: 'Join Group',
        onTap: () => _joinGroup(group),
      );
    }

    final isMember = group.isMember(currentUserId);
    final isCreator = group.isCreator(currentUserId);

    if (!isMember) {
      return SnapButton(
        text: 'Join Group',
        onTap: () => _joinGroup(group),
      );
    } else if (isCreator) {
      return SnapButton(
        text: 'Manage Group',
        onTap: () => _showManageGroupOptions(group),
        type: SnapButtonType.secondary,
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: SnapButton(
              text: 'Group Info',
              onTap: () => Navigator.pop(context), // Close current dialog to show group details
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SnapButton(
                  text: 'Find Members',
                  onTap: () => _showGroupMembers(group),
                  type: SnapButtonType.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmLeaveGroup(group),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Leave Group'),
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  void _confirmLeaveGroup(HealthGroup group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SnapColors.backgroundLight,
        title: Text(
          'Leave Group',
          style: SnapTypography.heading3.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to leave "${group.name}"? You will lose access to group content and chat.',
          style: SnapTypography.body.copyWith(
            color: SnapColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close group details
              _leaveGroup(group);
            },
            child: Text(
              'Leave',
              style: SnapTypography.body.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _leaveGroup(HealthGroup group) async {
    final success = await _healthCommunityService.leaveHealthGroup(group.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Left ${group.name} successfully'
                : 'Failed to leave group',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _showManageGroupOptions(HealthGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SnapColors.backgroundLight,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Manage Group',
              style: SnapTypography.heading3.copyWith(
                color: SnapColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.people, color: SnapColors.primaryYellow),
              title: const Text('View Members'),
              onTap: () {
                Navigator.pop(context);
                _showGroupMembers(group);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: SnapColors.primaryYellow),
              title: const Text('Edit Group'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit group feature coming soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: SnapColors.primaryYellow),
              title: const Text('Manage Members'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Member management feature coming soon!'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupMembers(HealthGroup group) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SnapColors.backgroundLight,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
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
              Row(
                children: [
                  Icon(Icons.people, color: SnapColors.primaryYellow, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${group.name} Members',
                      style: SnapTypography.heading3.copyWith(
                        color: SnapColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${group.memberCount} members',
                style: SnapTypography.body.copyWith(
                  color: SnapColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: group.memberIds.isEmpty
                    ? Center(
                        child: Text(
                          'No members to display',
                          style: SnapTypography.body.copyWith(
                            color: SnapColors.textSecondary,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: group.memberIds.length,
                        itemBuilder: (context, index) {
                          final memberId = group.memberIds[index];
                          final isCreator = group.isCreator(memberId);
                          final isAdmin = group.isAdmin(memberId);
                          
                          return FutureBuilder<DocumentSnapshot>(
                            future: _friendService.getUserData(memberId),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const ListTile(
                                  leading: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: SnapColors.primaryYellow,
                                  ),
                                  title: Text('Loading...'),
                                );
                              }
                              
                              final userData = snapshot.data!.data() as Map<String, dynamic>?;
                              final username = userData?['username'] ?? 'Unknown User';
                              
                              return ListTile(
                                leading: SnapAvatar(
                                  name: username,
                                  imageUrl: userData?['profileImageUrl'],
                                  radius: 20,
                                ),
                                title: Text(
                                  username,
                                  style: SnapTypography.body.copyWith(
                                    color: SnapColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                subtitle: Text(
                                  isCreator 
                                      ? 'Creator' 
                                      : isAdmin 
                                          ? 'Admin' 
                                          : 'Member',
                                  style: SnapTypography.caption.copyWith(
                                    color: isCreator || isAdmin 
                                        ? SnapColors.primaryYellow 
                                        : SnapColors.textSecondary,
                                  ),
                                ),
                                trailing: SizedBox(
                                  width: 48,
                                  child: IconButton(
                                    icon: const Icon(Icons.person_add, 
                                        color: SnapColors.primaryYellow),
                                    onPressed: () => _addAsFriend(memberId, username),
                                    tooltip: 'Add as Friend',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addAsFriend(String userId, String username) async {
    try {
      await _friendService.sendFriendRequest(userId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Friend request sent to $username'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send friend request to $username'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildFriendsList() {
    return StreamBuilder<List<String>>(
      stream: _friendService.getFriendsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error', style: TextStyle(color: SnapColors.textSecondary));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(color: SnapColors.primaryYellow);
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('You have no friends yet.', style: TextStyle(color: SnapColors.textSecondary));
        }

        final friendIds = snapshot.data!;
        return ListView.builder(
          itemCount: friendIds.length,
          itemBuilder: (context, index) {
            final friendId = friendIds[index];
            return FutureBuilder<DocumentSnapshot>(
              future: _friendService.getUserData(friendId),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const ListTile(title: Text("..."));
                }
                final friendData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                if (friendData == null) {
                  return const ListTile(title: Text("Friend data missing"));
                }
                return ListTile(
                  title: Text(
                    friendData['username'] ?? 'No name',
                    style: SnapTypography.body.copyWith(color: SnapColors.textPrimary),
                  ),
                  leading: SnapAvatar(
                    name: friendData['username'],
                    imageUrl: friendData['profileImageUrl'],
                  ),
                  onTap: () {
                    _navigateToChat(friendId);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _navigateToChat(String friendId) async {
    final chatRoomId = await _friendService.getOrCreateOneOnOneChatRoom(
      friendId,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ChatPage(chatRoomId: chatRoomId, recipientId: friendId),
      ),
    );
  }

  Widget _buildFriendRequestList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _friendService.getFriendRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error', style: TextStyle(color: SnapColors.textSecondary));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(color: SnapColors.primaryYellow);
        }
        if (snapshot.data!.docs.isEmpty) {
          return const Text('No pending friend requests.', style: TextStyle(color: SnapColors.textSecondary));
        }

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final request = doc.data() as Map<String, dynamic>;
            final senderId = request['senderId'];

            return FutureBuilder<DocumentSnapshot>(
              future: _friendService.getUserData(senderId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(title: Text("Loading..."));
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return const ListTile(title: Text("Unknown user"));
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                if (userData == null) {
                  return const ListTile(title: Text("User data missing"));
                }

                return ListTile(
                  title: Text(
                    userData['username'] ?? 'No name',
                    style: SnapTypography.body.copyWith(color: SnapColors.textPrimary),
                  ),
                  leading: SnapAvatar(
                    name: userData['username'],
                    imageUrl: userData['profileImageUrl'],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check,
                          color: SnapColors.accentGreen,
                        ),
                        onPressed: () async {
                          await _friendService.acceptFriendRequest(senderId);
                          setState(() {});
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: SnapColors.accentRed,
                        ),
                        onPressed: () async {
                          await _friendService.declineFriendRequest(senderId);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
