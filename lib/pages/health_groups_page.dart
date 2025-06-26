import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/health_community_service.dart';
import '../services/rag_service.dart';
import '../services/friend_service.dart';
import '../models/health_group.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/widgets/snap_button.dart';
import '../design_system/widgets/snap_textfield.dart';

class HealthGroupsPage extends StatefulWidget {
  const HealthGroupsPage({super.key});

  @override
  State<HealthGroupsPage> createState() => _HealthGroupsPageState();
}

class _HealthGroupsPageState extends State<HealthGroupsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late HealthCommunityService _healthCommunityService;
  final TextEditingController _searchController = TextEditingController();
  HealthGroupType? _selectedType;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize the health community service
    final ragService = Provider.of<RAGService>(context, listen: false);
    final friendService = Provider.of<FriendService>(context, listen: false);
    _healthCommunityService = HealthCommunityService(ragService, friendService);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
          style: SnapTypography.heading2.copyWith(color: SnapColors.snapYellow),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: SnapColors.snapYellow,
          unselectedLabelColor: SnapColors.textSecondary,
          indicatorColor: SnapColors.snapYellow,
          tabs: const [
            Tab(text: 'My Groups'),
            Tab(text: 'Discover'),
            Tab(text: 'Challenges'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: SnapColors.snapYellow),
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
            child: CircularProgressIndicator(color: SnapColors.snapYellow),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading groups: \${snapshot.error}',
              style: SnapTypography.body1.copyWith(color: SnapColors.textSecondary),
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
              searchTerm: _searchTerm.isEmpty ? null : _searchTerm,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: SnapColors.snapYellow),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading groups: \${snapshot.error}',
                    style: SnapTypography.body1.copyWith(color: SnapColors.textSecondary),
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
          SnapTextField(
            controller: _searchController,
            hintText: 'Search groups...',
            prefixIcon: Icons.search,
            onChanged: (value) {
              setState(() {
                _searchTerm = value;
              });
            },
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
            color: isSelected ? SnapColors.snapYellow : Colors.transparent,
            border: Border.all(
              color: isSelected ? SnapColors.snapYellow : SnapColors.textSecondary,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: SnapTypography.caption.copyWith(
              color: isSelected ? SnapColors.backgroundDark : SnapColors.textSecondary,
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
        border: Border.all(color: SnapColors.borderDark),
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
                  color: SnapColors.snapYellow,
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
                      style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
                    ),
                    Text(
                      group.typeDisplayName,
                      style: SnapTypography.caption.copyWith(color: SnapColors.snapYellow),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SnapColors.snapYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '\${group.memberCount} members',
                  style: SnapTypography.caption.copyWith(color: SnapColors.snapYellow),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            group.description,
            style: SnapTypography.body2.copyWith(color: SnapColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (group.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: group.tags.take(3).map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SnapColors.backgroundDark,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#\$tag',
                  style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
                ),
              )).toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SnapButton(
                  text: isMyGroup ? 'View Group' : 'Join Group',
                  onPressed: () => _handleGroupAction(group, isMyGroup),
                  backgroundColor: SnapColors.snapYellow,
                  textColor: SnapColors.backgroundDark,
                ),
              ),
              if (!isMyGroup) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: SnapColors.textSecondary),
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
              color: SnapColors.snapYellow.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(
              Icons.group,
              size: 40,
              color: SnapColors.snapYellow,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Groups Yet',
            style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Join health groups to connect with\nlike-minded fitness enthusiasts',
            style: SnapTypography.body2.copyWith(color: SnapColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SnapButton(
            text: 'Discover Groups',
            onPressed: () => _tabController.animateTo(1),
            backgroundColor: SnapColors.snapYellow,
            textColor: SnapColors.backgroundDark,
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
            style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: SnapTypography.body2.copyWith(color: SnapColors.textSecondary),
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
            success ? 'Successfully joined \${group.name}!' : 'Failed to join group',
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
                      color: SnapColors.snapYellow,
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
                          style: SnapTypography.heading2.copyWith(color: SnapColors.textPrimary),
                        ),
                        Text(
                          group.typeDisplayName,
                          style: SnapTypography.body1.copyWith(color: SnapColors.snapYellow),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Description',
                style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                group.description,
                style: SnapTypography.body1.copyWith(color: SnapColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatItem('Members', '\${group.memberCount}'),
                  _buildStatItem('Privacy', group.privacy.name.toUpperCase()),
                  _buildStatItem('Activity', group.activityLevel.name.toUpperCase()),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: SnapButton(
                  text: 'Join Group',
                  onPressed: () {
                    Navigator.pop(context);
                    _joinGroup(group);
                  },
                  backgroundColor: SnapColors.snapYellow,
                  textColor: SnapColors.backgroundDark,
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
            style: SnapTypography.heading3.copyWith(color: SnapColors.snapYellow),
          ),
          Text(
            label,
            style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _showCreateGroupDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    HealthGroupType selectedType = HealthGroupType.support;
    HealthGroupPrivacy selectedPrivacy = HealthGroupPrivacy.public;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: SnapColors.backgroundLight,
          title: Text(
            'Create Health Group',
            style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SnapTextField(
                  controller: nameController,
                  hintText: 'Group name',
                ),
                const SizedBox(height: 12),
                SnapTextField(
                  controller: descriptionController,
                  hintText: 'Group description',
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HealthGroupType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Group Type',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: SnapColors.backgroundLight,
                  style: SnapTypography.body1.copyWith(color: SnapColors.textPrimary),
                  items: HealthGroupType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text('\${type.name.toUpperCase()} - \${_getTypeDisplayName(type)}'),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<HealthGroupPrivacy>(
                  value: selectedPrivacy,
                  decoration: const InputDecoration(
                    labelText: 'Privacy',
                    border: OutlineInputBorder(),
                  ),
                  dropdownColor: SnapColors.backgroundLight,
                  style: SnapTypography.body1.copyWith(color: SnapColors.textPrimary),
                  items: HealthGroupPrivacy.values.map((privacy) => DropdownMenuItem(
                    value: privacy,
                    child: Text(privacy.name.toUpperCase()),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedPrivacy = value;
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
                style: SnapTypography.body1.copyWith(color: SnapColors.textSecondary),
              ),
            ),
            SnapButton(
              text: 'Create',
              onPressed: () => _createGroup(
                nameController.text,
                descriptionController.text,
                selectedType,
                selectedPrivacy,
              ),
              backgroundColor: SnapColors.snapYellow,
              textColor: SnapColors.backgroundDark,
            ),
          ],
        ),
      ),
    );
  }

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

  void _createGroup(String name, String description, HealthGroupType type, HealthGroupPrivacy privacy) async {
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
            groupId != null ? 'Group created successfully!' : 'Failed to create group',
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
