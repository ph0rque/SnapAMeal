import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../snap_ui.dart';
// Removed unnecessary imports - already provided by snap_ui.dart
import '../../services/chat_service.dart';
import '../../services/streak_service.dart';
import '../../services/anonymity_service.dart';
import '../../models/health_group.dart';

class HealthGroupChatWidget extends StatefulWidget {
  final String groupId;
  final HealthGroup group;

  const HealthGroupChatWidget({
    super.key,
    required this.groupId,
    required this.group,
  });

  @override
  State<HealthGroupChatWidget> createState() => _HealthGroupChatWidgetState();
}

class _HealthGroupChatWidgetState extends State<HealthGroupChatWidget> with TickerProviderStateMixin {
  late TabController _tabController;
  late ChatService _chatService;
  late StreakService _streakService;
  late AnonymityService _anonymityService;
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isAnonymousMode = false;
  bool _showGroupStats = true;
  Map<String, dynamic> _groupStats = {};
  List<Map<String, dynamic>> _streakLeaderboard = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _chatService = Provider.of<ChatService>(context, listen: false);
    _streakService = StreakService();
    _anonymityService = AnonymityService();
    
    _loadGroupStats();
    _loadStreakLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupStats() async {
    final stats = await _chatService.getHealthGroupStats(widget.groupId);
    setState(() {
      _groupStats = stats;
    });
  }

  Future<void> _loadStreakLeaderboard() async {
    final leaderboard = await _streakService.getGroupStreakLeaderboard(widget.groupId);
    setState(() {
      _streakLeaderboard = leaderboard;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: SnapColors.backgroundDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.group.name,
              style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
            ),
            Text(
              '\${widget.group.memberCount} members • \${widget.group.typeDisplayName}',
              style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isAnonymousMode ? Icons.visibility_off : Icons.visibility,
              color: _isAnonymousMode ? SnapColors.primaryYellow : SnapColors.textSecondary,
            ),
            onPressed: _toggleAnonymousMode,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: SnapColors.textSecondary),
            onPressed: _showGroupInfo,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: SnapColors.primaryYellow,
          unselectedLabelColor: SnapColors.textSecondary,
          indicatorColor: SnapColors.primaryYellow,
          tabs: const [
            Tab(text: 'Chat'),
            Tab(text: 'Streaks'),
            Tab(text: 'Support'),
          ],
        ),
      ),
      body: Column(
        children: [
          if (_showGroupStats) _buildGroupStatsHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChatTab(),
                _buildStreaksTab(),
                _buildSupportTab(),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildGroupStatsHeader() {
    if (_groupStats.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      color: SnapColors.backgroundLight,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Members', '${_groupStats['totalMembers'] ?? 0}', Icons.people),
          ),
          if (_groupStats['activeFasters'] != null) ...[
            Expanded(
              child: _buildStatItem('Active Fasters', '${_groupStats['activeFasters']}', Icons.timer),
            ),
          ],
          Expanded(
            child: _buildStatItem('Today\'s Goal', '80%', Icons.track_changes),
          ),
          IconButton(
            icon: Icon(
              _showGroupStats ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: SnapColors.textSecondary,
            ),
            onPressed: () => setState(() => _showGroupStats = !_showGroupStats),
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
          style: SnapTypography.heading3.copyWith(color: SnapColors.primaryYellow),
        ),
        Text(
          label,
          style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _chatService.getMessages(widget.groupId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: SnapColors.primaryYellow),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading messages',
                    style: SnapTypography.body.copyWith(color: SnapColors.textSecondary),
                  ),
                );
              }

              final messages = snapshot.data?.docs ?? [];

              if (messages.isEmpty) {
                return _buildEmptyChatState();
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(messages[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStreaksTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: SnapColors.backgroundLight,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Group Streak Leaderboard',
                  style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
                ),
              ),
              SnapButton(
                text: 'Start Streak',
                onTap: _showCreateStreakDialog,
              ),
            ],
          ),
        ),
        Expanded(
          child: _streakLeaderboard.isEmpty
              ? _buildEmptyStreaksState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _streakLeaderboard.length,
                  itemBuilder: (context, index) {
                    return _buildStreakCard(_streakLeaderboard[index], index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSupportTab() {
    return StreamBuilder<List<AnonymousMessage>>(
      stream: _anonymityService.getAnonymousMessages(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: SnapColors.primaryYellow),
          );
        }

        final messages = snapshot.data ?? [];

        if (messages.isEmpty) {
          return _buildEmptySupportState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return _buildAnonymousMessageCard(messages[index]);
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(DocumentSnapshot message) {
    final data = message.data() as Map<String, dynamic>;
    final senderId = data['senderId'] as String;
    final messageText = data['message'] as String;
    final timestamp = data['timestamp'] as Timestamp;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SnapAvatar(name: 'User', radius: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: _getUserDisplayName(senderId),
                  builder: (context, snapshot) {
                    final userData = snapshot.data ?? {};
                    return Text(
                      userData['display_name'] ?? 'Unknown',
                      style: SnapTypography.caption.copyWith(
                        color: SnapColors.primaryYellow,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: SnapColors.backgroundLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    messageText,
                    style: SnapTypography.caption.copyWith(color: SnapColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(timestamp),
                  style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(Map<String, dynamic> streak, int rank) {
    final completedToday = streak['completed_today'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: rank < 3 ? Border.all(color: _getRankColor(rank), width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                '\${rank + 1}',
                style: SnapTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SnapAvatar(name: 'User', radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: _getUserDisplayName(streak['user_id'] as String),
                  builder: (context, snapshot) {
                    final userData = snapshot.data ?? {};
                    return Text(
                      userData['display_name'] ?? 'Unknown',
                      style: SnapTypography.body.copyWith(color: SnapColors.textPrimary),
                    );
                  },
                ),
                Text(
                  '${streak['current_streak']} day streak',
                  style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Icon(
                completedToday ? Icons.check_circle : Icons.radio_button_unchecked,
                color: completedToday ? Colors.green : SnapColors.textSecondary,
                size: 20,
              ),
              Text(
                'Today',
                style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnonymousMessageCard(AnonymousMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SnapColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSensitivityColor(message.sensitivityLevel),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FutureBuilder<Map<String, dynamic>?>(
                future: _anonymityService.getAnonymousDisplayInfo(message.anonymousId),
                builder: (context, snapshot) {
                  final info = snapshot.data;
                  return Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: SnapColors.primaryYellow,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Center(
                          child: Text(
                            info?['avatar'] ?? '😊',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        info?['name'] ?? 'Anonymous',
                        style: SnapTypography.caption.copyWith(
                          color: SnapColors.primaryYellow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getCategoryColor(message.category),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message.category.toUpperCase(),
                  style: SnapTypography.caption.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message.content,
            style: SnapTypography.caption.copyWith(color: SnapColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ..._anonymityService.getSupportReactionTypes().take(3).map((reaction) => 
                GestureDetector(
                  onTap: () => _addSupportReaction(message.id, reaction['id']),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: SnapColors.backgroundDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(reaction['emoji'], style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          _getReactionCount(message, reaction['id']).toString(),
                          style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(Timestamp.fromDate(message.timestamp)),
                style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.groups,
            size: 60,
            color: SnapColors.primaryYellow,
          ),
          const SizedBox(height: 16),
          Text(
            'Start the conversation!',
            style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Share your health journey with the group',
            style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStreaksState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 60,
            color: SnapColors.primaryYellow,
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Streaks',
            style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a group challenge to motivate each other',
            style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySupportState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.favorite,
            size: 60,
            color: SnapColors.primaryYellow,
          ),
          const SizedBox(height: 16),
          Text(
            'Safe Space for Sharing',
            style: SnapTypography.heading3.copyWith(color: SnapColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Share sensitive topics anonymously\nand get support from the community',
            style: SnapTypography.caption.copyWith(color: SnapColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: SnapColors.backgroundLight,
      child: Row(
        children: [
          if (_tabController.index == 2) // Support tab
            IconButton(
              icon: const Icon(Icons.psychology, color: SnapColors.primaryYellow),
              onPressed: _showSensitiveTopicDialog,
            ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: SnapTypography.body.copyWith(color: SnapColors.textPrimary),
              decoration: InputDecoration(
                hintText: _getMessageHint(),
                hintStyle: SnapTypography.body.copyWith(color: SnapColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: SnapColors.backgroundDark,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: SnapColors.primaryYellow),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _getMessageHint() {
    switch (_tabController.index) {
      case 0:
        return _isAnonymousMode ? 'Send anonymous message...' : 'Type a message...';
      case 1:
        return 'Cheer on your streak buddies...';
      case 2:
        return 'Share anonymously...';
      default:
        return 'Type a message...';
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    if (_tabController.index == 2) {
      // Send as anonymous message
      await _anonymityService.postAnonymousMessage(
        groupId: widget.groupId,
        content: text,
        category: 'general',
        sensitivityLevel: 1,
      );
    } else {
      // Send as regular message
      await _chatService.sendMessage(widget.groupId, text);
    }

    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleAnonymousMode() {
    setState(() {
      _isAnonymousMode = !_isAnonymousMode;
    });
  }

  void _showGroupInfo() {
    // TODO: Implement group info dialog
  }

  void _showCreateStreakDialog() {
    // TODO: Implement create streak dialog
  }

  void _showSensitiveTopicDialog() {
    // TODO: Implement sensitive topic selection dialog
  }

  void _addSupportReaction(String messageId, String reactionType) async {
    await _anonymityService.addSupportReaction(messageId, reactionType);
  }

  Future<Map<String, dynamic>> _getUserDisplayName(String userId) async {
    // TODO: Implement user data fetching
    return {'display_name': 'User'};
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '\${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '\${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '\${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0:
        return Colors.amber; // Gold
      case 1:
        return Colors.grey; // Silver
      case 2:
        return Colors.orange; // Bronze
      default:
        return SnapColors.textSecondary;
    }
  }

  Color _getSensitivityColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return SnapColors.textSecondary;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'weight':
        return Colors.blue;
      case 'mental-health':
        return Colors.purple;
      case 'addiction':
        return Colors.red;
      case 'medical':
        return Colors.green;
      case 'relationships':
        return Colors.pink;
      case 'motivation':
        return Colors.orange;
      case 'financial':
        return Colors.brown;
      default:
        return SnapColors.textSecondary;
    }
  }

  int _getReactionCount(AnonymousMessage message, String reactionType) {
    return message.supportReactions
        .where((reaction) => reaction.startsWith('\$reactionType:'))
        .length;
  }
}
