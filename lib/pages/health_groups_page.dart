import 'package:flutter/material.dart';
import '../design_system/snap_ui.dart';
import '../services/health_community_service.dart';
import '../services/rag_service.dart';
import '../services/friend_service.dart';
import '../services/openai_service.dart';
import '../models/health_group.dart';

class HealthGroupsPage extends StatefulWidget {
  const HealthGroupsPage({super.key});

  @override
  State<HealthGroupsPage> createState() => _HealthGroupsPageState();
}

class _HealthGroupsPageState extends State<HealthGroupsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late HealthCommunityService _healthCommunityService;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  HealthGroupType? _selectedType;
  HealthGroupPrivacy? _selectedPrivacy = HealthGroupPrivacy.public;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize services
    final friendService = FriendService();
    final ragService = RAGService(OpenAIService());
    _healthCommunityService = HealthCommunityService(ragService, friendService);
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
      backgroundColor: SnapColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: SnapColors.backgroundDark,
        title: Text(
          'Health Groups',
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
            Tab(text: 'My Groups'),
            Tab(text: 'Discover'),
            Tab(text: 'Challenges'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: SnapColors.primaryYellow),
            onPressed: _showCreateGroupDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyGroupsTab(),
          _buildDiscoverTab(),
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            return _buildGroupCard(groups[index], isMyGroup: true);
          },
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
                  '\${group.memberCount} members',
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
                        '#\$tag',
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
                  text: isMyGroup ? 'View Group' : 'Join Group',
                  onTap: () => _handleGroupAction(group, isMyGroup),
                ),
              ),
              if (!isMyGroup) ...[
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
          SnapButton(
            text: 'Discover Groups',
            onTap: () => _tabController.animateTo(1),
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
            'Try adjusting your search or filters',
            style: SnapTypography.caption.copyWith(
              color: SnapColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _handleGroupAction(HealthGroup group, bool isMyGroup) {
    if (isMyGroup) {
      Navigator.pushNamed(context, '/group_chat', arguments: group.id);
    } else {
      _joinGroup(group);
    }
  }

  void _joinGroup(HealthGroup group) async {
    final success = await _healthCommunityService.joinHealthGroup(group.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Successfully joined \${group.name}!'
                : 'Failed to join group',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
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
                  _buildStatItem('Members', '\${group.memberCount}'),
                  _buildStatItem('Privacy', group.privacy.name.toUpperCase()),
                  _buildStatItem(
                    'Activity',
                    group.activityLevel.name.toUpperCase(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: SnapButton(
                  text: 'Join Group',
                  onTap: () => _joinGroup(group),
                ),
              ),
            ],
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
          content: SingleChildScrollView(
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
                            '\${type.name.toUpperCase()} - \${_getTypeDisplayName(type)}',
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
                          child: Text(privacy.name.toUpperCase()),
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
    final type = _selectedType!;
    final privacy = _selectedPrivacy!;

    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
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
}
