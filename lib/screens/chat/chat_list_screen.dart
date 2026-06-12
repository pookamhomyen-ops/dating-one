import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../utils/time_format.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/soulive_header.dart';
import 'chat_detail_screen.dart';
import '../../models/chat_thread.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    try {
      final me = Supabase.instance.client.auth.currentUser;
      if (me == null) return;

      final data = await Supabase.instance.client
          .from('my_conversations_v')
          .select()
          .eq('my_id', me.id)
          .order('last_message_at', ascending: false);

      if (mounted) {
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ChatList error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeRealtime() {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) return;

    _channel = Supabase.instance.client
        .channel('conversations_${me.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (_) => _loadConversations(),
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SouliveHeader(pageTitle: 'แชท'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                _isLoading ? '' : '${_conversations.length} การสนทนา',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brandPink))
                  : _conversations.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _loadConversations,
                          color: AppColors.brandPink,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: _conversations.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              return _ChatTile(
                                data: _conversations[index],
                                onTap: () async {
                                  final conv = _conversations[index];
                                  final thread = ChatThread(
                                    id: conv['conversation_id'],
                                    partnerName: conv['partner_name'] ?? '',
                                    partnerPhotoUrl: conv['partner_photo_url'] ?? '',
                                    lastMessage: conv['last_message_preview'] ?? '',
                                    lastMessageAt: conv['last_message_at'] != null
                                        ? DateTime.parse(conv['last_message_at'])
                                        : DateTime.now(),
                                    unreadCount: conv['unread_count'] ?? 0,
                                    isOnline: conv['partner_is_online'] ?? false,
                                  );
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatDetailScreen(thread: thread),
                                    ),
                                  );
                                  _loadConversations();
                                },
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 72, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          const Text('ยังไม่มีการสนทนา', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('ไปหาแมตช์ก่อนนะ 💖', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  const _ChatTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = data['partner_name'] as String? ?? '';
    final photoUrl = data['partner_photo_url'] as String? ?? '';
    final lastMsg = data['last_message_preview'] as String? ?? '';
    final lastAt = data['last_message_at'] != null
        ? DateTime.parse(data['last_message_at'])
        : null;
    final unread = data['unread_count'] as int? ?? 0;
    final isOnline = data['partner_is_online'] as bool? ?? false;
    final hasUnread = unread > 0;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasUnread ? AppColors.brandPink.withValues(alpha: 0.4) : AppColors.border,
              width: hasUnread ? 1.5 : 1,
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                children: [
                  AvatarImage(url: photoUrl, size: 54),
                  if (isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (lastAt != null)
                          Text(
                            formatChatTime(lastAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: hasUnread ? AppColors.brandPink : AppColors.textSecondary,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMsg.isEmpty ? 'เริ่มบทสนทนา 👋' : lastMsg,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: const BoxDecoration(
                              color: AppColors.brandPink,
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            child: Text(
                              '$unread',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}