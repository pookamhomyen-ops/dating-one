import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/chat_thread.dart';
import '../../theme/app_colors.dart';
import '../../utils/time_format.dart';
import '../../widgets/avatar_image.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.thread});
  final ChatThread thread;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _myId;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _myId = Supabase.instance.client.auth.currentUser?.id;
    _loadMessages();
    _subscribeRealtime();
    _markAsRead();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final data = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('conversation_id', widget.thread.id)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Messages error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('messages_${widget.thread.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: widget.thread.id,
          ),
          callback: (payload) {
            final newMsg = payload.newRecord;
            if (mounted) {
              setState(() => _messages.add(newMsg));
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _markAsRead() async {
    try {
      final me = Supabase.instance.client.auth.currentUser;
      if (me == null) return;
      await Supabase.instance.client
          .from('conversation_members')
          .update({'unread_count': 0, 'last_read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', widget.thread.id)
          .eq('profile_id', me.id);
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending || _myId == null) return;

    setState(() => _isSending = true);
    _controller.clear();

    try {
      await Supabase.instance.client.from('messages').insert({
        'conversation_id': widget.thread.id,
        'sender_id': _myId,
        'message_type': 'text',
        'body': text,
      });

      await Supabase.instance.client
          .from('conversations')
          .update({
            'last_message_at': DateTime.now().toIso8601String(),
            'last_message_preview': text.length > 50 ? '${text.substring(0, 50)}...' : text,
          })
          .eq('id', widget.thread.id);
    } catch (e) {
      debugPrint('Send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งข้อความไม่สำเร็จ'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            AvatarImage(url: widget.thread.partnerPhotoUrl, size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.thread.partnerName,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  widget.thread.isOnline ? 'ออนไลน์' : 'ออฟไลน์',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.thread.isOnline ? Colors.green : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandPink))
                : _messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMine = msg['sender_id'] == _myId;
                          final prevMsg = index > 0 ? _messages[index - 1] : null;
                          final showDate = prevMsg == null ||
                              _isDifferentDay(
                                DateTime.parse(prevMsg['created_at']),
                                DateTime.parse(msg['created_at']),
                              );
                          return Column(
                            children: [
                              if (showDate) _buildDateDivider(DateTime.parse(msg['created_at'])),
                              _MessageBubble(
                                text: msg['body'] ?? '',
                                isMine: isMine,
                                sentAt: DateTime.parse(msg['created_at']),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('👋', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'เริ่มคุยกับ ${widget.thread.partnerName} เลย!',
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              formatChatTime(date),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: AppColors.surface,
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'พิมพ์ข้อความ...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: IconButton.filled(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.brandPink,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDifferentDay(DateTime a, DateTime b) {
    return a.year != b.year || a.month != b.month || a.day != b.day;
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMine;
  final DateTime sentAt;

  const _MessageBubble({required this.text, required this.isMine, required this.sentAt});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? AppColors.brandPink : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMine ? 18 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.textPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatChatTime(sentAt),
              style: TextStyle(
                fontSize: 10,
                color: isMine ? Colors.white.withValues(alpha: 0.75) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}