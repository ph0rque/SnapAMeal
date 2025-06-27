import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/story_service.dart';
import '../utils/logger.dart';
import '../design_system/snap_ui.dart';
import 'story_view_page.dart';

class MilestoneStoriesPage extends StatefulWidget {
  final String? userId;

  const MilestoneStoriesPage({super.key, this.userId});

  @override
  State<MilestoneStoriesPage> createState() => _MilestoneStoriesPageState();
}

class _MilestoneStoriesPageState extends State<MilestoneStoriesPage> {
  final StoryService _storyService = StoryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedTier = 'all';
  bool _isLoading = true;
  List<DocumentSnapshot> _milestoneStories = [];

  @override
  void initState() {
    super.initState();
    _loadMilestoneStories();
  }

  Future<void> _loadMilestoneStories() async {
    setState(() => _isLoading = true);

    try {
      final userId = widget.userId ?? _auth.currentUser?.uid;
      if (userId == null) return;

      final stories = await _storyService.getMilestoneStories(
        userId,
        limit: 50,
      );

      setState(() {
        _milestoneStories = stories;
        _isLoading = false;
      });
    } catch (e) {
      Logger.d('Error loading milestone stories: $e');
      setState(() => _isLoading = false);
    }
  }

  List<DocumentSnapshot> get _filteredStories {
    if (_selectedTier == 'all') return _milestoneStories;

    return _milestoneStories.where((story) {
      final data = story.data() as Map<String, dynamic>;
      final permanence = data['permanence'] as Map<String, dynamic>?;
      return permanence?['tier'] == _selectedTier;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: SnapColors.backgroundDark,
        foregroundColor: SnapColors.textPrimary,
        title: Text(
          'Milestone Stories',
          style: SnapTypography.heading2.copyWith(
            color: SnapColors.textPrimary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: SnapColors.textPrimary),
            onSelected: (value) {
              setState(() => _selectedTier = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Stories')),
              const PopupMenuItem(value: 'weekly', child: Text('Weekly')),
              const PopupMenuItem(value: 'monthly', child: Text('Monthly')),
              const PopupMenuItem(value: 'milestone', child: Text('Milestone')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: SnapColors.primary),
            )
          : _buildMilestoneTimeline(),
    );
  }

  Widget _buildMilestoneTimeline() {
    final filteredStories = _filteredStories;

    if (filteredStories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_outlined,
              size: 64,
              color: SnapColors.textSecondary,
            ),
            const SizedBox(height: SnapDimensions.paddingMedium),
            Text(
              'No milestone stories yet',
              style: SnapTypography.heading3.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
            const SizedBox(height: SnapDimensions.paddingSmall),
            Text(
              'Stories with high engagement become milestones\nand stay visible longer',
              textAlign: TextAlign.center,
              style: SnapTypography.body.copyWith(
                color: SnapColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(SnapDimensions.paddingMedium),
      itemCount: filteredStories.length,
      itemBuilder: (context, index) {
        final story = filteredStories[index];
        final data = story.data() as Map<String, dynamic>;

        return _buildMilestoneStoryCard(story, data, index);
      },
    );
  }

  Widget _buildMilestoneStoryCard(
    DocumentSnapshot story,
    Map<String, dynamic> data,
    int index,
  ) {
    final permanence = data['permanence'] as Map<String, dynamic>?;
    final engagement = data['engagement'] as Map<String, dynamic>?;
    final timestamp = data['timestamp'] as Timestamp?;
    final mediaUrl = data['mediaUrl'] as String?;
    final isVideo = data['isVideo'] as bool? ?? false;
    final tier = permanence?['tier'] as String? ?? 'standard';

    final timeAgo = timestamp != null
        ? _formatTimeAgo(timestamp.toDate())
        : 'Unknown time';

    return Container(
      margin: const EdgeInsets.only(bottom: SnapDimensions.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getTierColor(tier),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SnapColors.backgroundDark,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getTierIcon(tier),
                  size: 8,
                  color: SnapColors.backgroundDark,
                ),
              ),
              if (index < _filteredStories.length - 1)
                Container(width: 2, height: 100, color: SnapColors.divider),
            ],
          ),
          const SizedBox(width: SnapDimensions.paddingMedium),

          // Story card
          Expanded(
            child: GestureDetector(
              onTap: () => _viewStory(story),
              child: Container(
                decoration: BoxDecoration(
                  color: SnapColors.cardBackground,
                  borderRadius: BorderRadius.circular(
                    SnapDimensions.radiusMedium,
                  ),
                  border: Border.all(
                    color: _getTierColor(tier).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Story preview
                    if (mediaUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(SnapDimensions.radiusMedium),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                mediaUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: SnapColors.divider,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: SnapColors.textSecondary,
                                    ),
                                  );
                                },
                              ),
                              if (isVideo)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_arrow,
                                      color: SnapColors.textPrimary,
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    // Story details
                    Padding(
                      padding: const EdgeInsets.all(
                        SnapDimensions.paddingMedium,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tier badge and time
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getTierColor(tier),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  tier.toUpperCase(),
                                  style: SnapTypography.caption.copyWith(
                                    color: SnapColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                timeAgo,
                                style: SnapTypography.caption.copyWith(
                                  color: SnapColors.textSecondary,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: SnapDimensions.paddingSmall),

                          // Engagement stats
                          Row(
                            children: [
                              _buildEngagementStat(
                                Icons.visibility,
                                engagement?['views'] ?? 0,
                              ),
                              const SizedBox(
                                width: SnapDimensions.paddingMedium,
                              ),
                              _buildEngagementStat(
                                Icons.favorite,
                                engagement?['likes'] ?? 0,
                              ),
                              const SizedBox(
                                width: SnapDimensions.paddingMedium,
                              ),
                              _buildEngagementStat(
                                Icons.comment,
                                engagement?['comments'] ?? 0,
                              ),
                              const SizedBox(
                                width: SnapDimensions.paddingMedium,
                              ),
                              _buildEngagementStat(
                                Icons.share,
                                engagement?['shares'] ?? 0,
                              ),
                            ],
                          ),

                          // Permanence info
                          if (permanence != null) ...[
                            const SizedBox(height: SnapDimensions.paddingSmall),
                            _buildPermanenceInfo(permanence),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementStat(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, size: 16, color: SnapColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: SnapTypography.caption.copyWith(
            color: SnapColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPermanenceInfo(Map<String, dynamic> permanence) {
    final expiresAt = permanence['expiresAt'] as Timestamp?;
    final duration = permanence['duration'] as int?;

    if (expiresAt == null || duration == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final expiry = expiresAt.toDate();
    final timeLeft = expiry.difference(now);

    String timeLeftText;
    if (timeLeft.isNegative) {
      timeLeftText = 'Expired';
    } else if (timeLeft.inDays > 0) {
      timeLeftText = '${timeLeft.inDays}d left';
    } else if (timeLeft.inHours > 0) {
      timeLeftText = '${timeLeft.inHours}h left';
    } else {
      timeLeftText = '${timeLeft.inMinutes}m left';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: SnapColors.divider.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        timeLeftText,
        style: SnapTypography.caption.copyWith(
          color: timeLeft.isNegative
              ? SnapColors.error
              : SnapColors.textSecondary,
        ),
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'weekly':
        return SnapColors.secondary;
      case 'monthly':
        return SnapColors.primary;
      case 'milestone':
        return SnapColors.accent;
      default:
        return SnapColors.textSecondary;
    }
  }

  IconData _getTierIcon(String tier) {
    switch (tier) {
      case 'weekly':
        return Icons.star;
      case 'monthly':
        return Icons.auto_awesome;
      case 'milestone':
        return Icons.emoji_events;
      default:
        return Icons.circle;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _viewStory(DocumentSnapshot story) {
    final data = story.data() as Map<String, dynamic>;
    final mediaUrl = data['mediaUrl'] as String?;

    if (mediaUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StoryViewPage(
          userId: widget.userId ?? _auth.currentUser?.uid ?? '',
        ),
      ),
    );
  }
}
