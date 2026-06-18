import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../discover/member_profile_screen.dart';
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

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _myId;
  RealtimeChannel? _channel;
  bool _hasText = false;
  late AnimationController _sendBtnCtrl;
  late Animation<double> _sendBtnScale;
  String? _partnerId;
  bool _isBlocked = false;
  bool _isBlockedByThem = false;
  bool _hasReported = false;

  @override
  void initState() {
    super.initState();
    _myId = Supabase.instance.client.auth.currentUser?.id;
    _loadMessages();
    _subscribeRealtime();
    _markAsRead();
    _checkBlockStatus();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
    _sendBtnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _sendBtnScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.82, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _sendBtnCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    _sendBtnCtrl.dispose();
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
          .update({
            'unread_count': 0,
            'last_read_at': DateTime.now().toIso8601String(),
          })
          .eq('conversation_id', widget.thread.id)
          .eq('profile_id', me.id);
    } catch (e) {
      debugPrint('markAsRead error: $e');
    }
  }

  Future<void> _checkBlockStatus() async {
    try {
      final me = Supabase.instance.client.auth.currentUser;
      if (me == null) return;
      final conv = await Supabase.instance.client
          .from('conversations')
          .select('user_low_id, user_high_id')
          .eq('id', widget.thread.id)
          .single();
      final partnerId = conv['user_low_id'] == me.id
          ? conv['user_high_id'] as String
          : conv['user_low_id'] as String;

      final blockCheck = await Supabase.instance.client
          .from('blocked_users')
          .select('blocker_id, blocked_id')
          .or('and(blocker_id.eq.${me.id},blocked_id.eq.$partnerId),and(blocker_id.eq.$partnerId,blocked_id.eq.${me.id})');

      bool isBlocked = false;
      bool isBlockedByThem = false;
      for (final row in blockCheck as List) {
        if (row['blocker_id'] == me.id) isBlocked = true;
        if (row['blocker_id'] == partnerId) isBlockedByThem = true;
      }

      bool hasReported = false;
      final me2 = Supabase.instance.client.auth.currentUser;
      if (me2 != null) {
        final reportCheck = await Supabase.instance.client
            .from('reports')
            .select('id')
            .eq('reporter_id', me2.id)
            .eq('reported_id', partnerId)
            .maybeSingle();
        hasReported = reportCheck != null;
      }

      if (mounted) {
        setState(() {
          _partnerId = partnerId;
          _isBlocked = isBlocked;
          _isBlockedByThem = isBlockedByThem;
          _hasReported = hasReported;
        });
      }
    } catch (e) {
      debugPrint('checkBlockStatus error: $e');
    }
  }

  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              if (!_hasReported)
                ListTile(
                  leading: const Icon(Icons.flag_outlined, color: AppColors.destructive),
                  title: Text('รายงาน ${widget.thread.partnerName}', style: const TextStyle(color: AppColors.destructive)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showReportReasonSheet();
                  },
                )
              else
                ListTile(
                  leading: Icon(Icons.flag_rounded, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  title: Text('รายงานแล้ว', style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.5))),
                  enabled: false,
                ),
              if (!_isBlocked)
                ListTile(
                  leading: const Icon(Icons.block_rounded, color: AppColors.destructive),
                  title: Text('บล็อก ${widget.thread.partnerName}', style: const TextStyle(color: AppColors.destructive)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmBlock();
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportReasonSheet() {
    String? selectedReason;
    String? selectedSubtype;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final reasons = [
            {'value': 'scam_money', 'label': 'หลอกโอนเงิน'},
            {'value': 'rude_language', 'label': 'พูดจาหยาบคาย'},
            {'value': 'nudity', 'label': 'ภาพโป๊เปลือย'},
            {'value': 'just_block', 'label': 'อยากบล็อกเฉยๆ'},
            {'value': 'gender_mismatch', 'label': 'เพศไม่ตรงตามจริง'},
          ];
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'เลือกเหตุผลในการรายงาน',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    ...reasons.map((r) => RadioListTile<String>(
                          value: r['value']!,
                          groupValue: selectedReason,
                          title: Text(r['label']!),
                          activeColor: AppColors.brandPink,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setSheetState(() => selectedReason = v),
                        )),
                    if (selectedReason == 'gender_mismatch') ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 4, bottom: 4),
                        child: Text('ระบุเพิ่มเติม', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ),
                      RadioListTile<String>(
                        value: 'is_ladyboy',
                        groupValue: selectedSubtype,
                        title: const Text('เขาเป็นกระเทย'),
                        activeColor: AppColors.brandPink,
                        contentPadding: const EdgeInsets.only(left: 16),
                        onChanged: (v) => setSheetState(() => selectedSubtype = v),
                      ),
                      RadioListTile<String>(
                        value: 'not_sure',
                        groupValue: selectedSubtype,
                        title: const Text('ไม่แน่ใจ'),
                        activeColor: AppColors.brandPink,
                        contentPadding: const EdgeInsets.only(left: 16),
                        onChanged: (v) => setSheetState(() => selectedSubtype = v),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedReason == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _submitReport(selectedReason!, selectedSubtype);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ส่งรายงาน'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitReport(String reason, String? subtype) async {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null || _partnerId == null) return;
    try {
      await Supabase.instance.client.from('reports').insert({
        'reporter_id': me.id,
        'reported_id': _partnerId,
        'reason': reason,
        if (subtype != null) 'gender_mismatch_subtype': subtype,
      });
      if (mounted) {
        setState(() => _hasReported = true);
        _showFancySnackbar('ส่งรายงานเรียบร้อยแล้ว 🚩', isSuccess: true);
      }
    } catch (e) {
      debugPrint('Report error: $e');
      if (mounted) {
        _showFancySnackbar('ส่งรายงานไม่สำเร็จ ลองใหม่อีกครั้งนะ', isSuccess: false);
      }
    }
  }

  void _showFancySnackbar(String message, {required bool isSuccess}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _FancyToast(
        message: message,
        isSuccess: isSuccess,
        onDismissed: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  void _confirmBlock() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการบล็อก'),
        content: Text('คุณต้องการบล็อก ${widget.thread.partnerName} ใช่หรือไม่? คุณจะไม่เห็นกันอีกต่อไป'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('บล็อก', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true) _doBlock();
    });
  }

  Future<void> _doBlock() async {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null || _partnerId == null) return;
    try {
      await Supabase.instance.client.from('blocked_users').insert({
        'blocker_id': me.id,
        'blocked_id': _partnerId,
      });
      if (mounted) {
        setState(() => _isBlocked = true);
      }
    } catch (e) {
      debugPrint('Block error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บล็อกไม่สำเร็จ: $e'), backgroundColor: AppColors.destructive),
        );
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending || _myId == null) return;
    HapticFeedback.lightImpact();
    _sendBtnCtrl.forward(from: 0);
    setState(() => _isSending = true);
    _controller.clear();
    FocusScope.of(context).unfocus();
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
            'last_message_preview':
                text.length > 50 ? '${text.substring(0, 50)}...' : text,
          })
          .eq('id', widget.thread.id);
    } catch (e) {
      debugPrint('Send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ส่งข้อความไม่สำเร็จ'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
      backgroundColor: const Color(0xFFF3F0FF),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.5,
                    ),
                  )
                : _messages.isEmpty
                    ? _buildEmptyChat()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMine = msg['sender_id'] == _myId;
                          final prevMsg =
                              index > 0 ? _messages[index - 1] : null;
                          final nextMsg = index < _messages.length - 1
                              ? _messages[index + 1]
                              : null;
                          final showDate = prevMsg == null ||
                              _isDifferentDay(
                                DateTime.parse(prevMsg['created_at']),
                                DateTime.parse(msg['created_at']),
                              );
                          final isLastInGroup = nextMsg == null ||
                              nextMsg['sender_id'] != msg['sender_id'];
                          return Column(
                            children: [
                              if (showDate)
                                _buildDateDivider(
                                    DateTime.parse(msg['created_at'])),
                              _MessageBubble(
                                text: msg['body'] ?? '',
                                isMine: isMine,
                                sentAt: DateTime.parse(msg['created_at']),
                                isLastInGroup: isLastInGroup,
                                partnerPhotoUrl:
                                    widget.thread.partnerPhotoUrl,
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 80,
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppColors.textPrimary,
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: () {
          if (_partnerId != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberProfileScreen(memberId: _partnerId!),
              ),
            );
          }
        },
        child: Row(
        children: [
          Stack(
            children: [
              AvatarImage(
                url: widget.thread.partnerPhotoUrl,
                size: 56,
                borderColor: widget.thread.isOnline
                    ? Colors.green
                    : Colors.transparent,
              ),
              if (widget.thread.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.thread.partnerName,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.thread.isOnline ? '🟢 ออนไลน์อยู่' : 'ออฟไลน์',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.thread.isOnline
                        ? Colors.green
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
          onPressed: _showMenu,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AvatarImage(url: widget.thread.partnerPhotoUrl, size: 72),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.thread.partnerName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'เริ่มบทสนทนาแรกกันเลย! 💬',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _QuickReplyChips(onTap: (text) {
            _controller.text = text;
            _sendMessage();
          }),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
              child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              formatChatTime(date),
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
              child: Divider(color: AppColors.border.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    if (_isBlocked || _isBlockedByThem) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
            12, 16, 12, 16 + MediaQuery.of(context).padding.bottom),
        child: Center(
          child: Text(
            '- Block -',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, 10 + MediaQuery.of(context).padding.bottom),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F0FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _hasText
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'พิมพ์ข้อความ...',
                  hintStyle: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textPrimary),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
                maxLines: 5,
                minLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ScaleTransition(
            scale: _sendBtnScale,
            child: GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _hasText ? const Color(0xFF00897B) : AppColors.border,
                  shape: BoxShape.circle,
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00897B)
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: _hasText ? Colors.white : AppColors.textSecondary,
                        size: 20,
                      ),
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

class _FancyToast extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback onDismissed;
  const _FancyToast({
    required this.message,
    required this.isSuccess,
    required this.onDismissed,
  });

  @override
  State<_FancyToast> createState() => _FancyToastState();
}

class _FancyToastState extends State<_FancyToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.7, end: 1.06), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2200), () async {
      if (!mounted) return;
      await _ctrl.reverse();
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: widget.isSuccess
                      ? const Color(0xFF00897B)
                      : const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isSuccess
                              ? const Color(0xFF00897B)
                              : const Color(0xFFE53935))
                          .withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isSuccess
                            ? Icons.check_rounded
                            : Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickReplyChips extends StatelessWidget {
  final ValueChanged<String> onTap;
  const _QuickReplyChips({required this.onTap});

  static const _replies = [
    '👋 สวัสดี!',
    '😊 หวัดดีครับ',
    '☕ ชอบกาแฟไหม?',
    '📸 โปรไฟล์น่ารักมากเลย',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: _replies
          .map(
            (r) => GestureDetector(
              onTap: () => onTap(r),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEDE9FE), Color(0xFFFCE7F3)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Text(
                  r,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  final String text;
  final bool isMine;
  final DateTime sentAt;
  final bool isLastInGroup;
  final String partnerPhotoUrl;

  const _MessageBubble({
    required this.text,
    required this.isMine,
    required this.sentAt,
    required this.isLastInGroup,
    required this.partnerPhotoUrl,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.7, end: 1.0));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn)
        .drive(Tween(begin: 0.0, end: 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMine = widget.isMine;
    final isLastInGroup = widget.isLastInGroup;
    final partnerPhotoUrl = widget.partnerPhotoUrl;
    final text = widget.text;
    final sentAt = widget.sentAt;

    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: isLastInGroup ? 10 : 3,
            left: isMine ? 48 : 0,
            right: isMine ? 0 : 48,
          ),
          child: Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine && isLastInGroup) ...[
                AvatarImage(url: partnerPhotoUrl, size: 28),
                const SizedBox(width: 6),
              ] else if (!isMine) ...[
                const SizedBox(width: 34),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(
                              isMine ? 18 : (isLastInGroup ? 4 : 18)),
                          bottomRight: Radius.circular(
                              isMine ? (isLastInGroup ? 4 : 18) : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isMine
                                ? const Color(0xFF4DB6AC).withValues(alpha: 0.2)
                                : AppColors.textPrimary.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                    if (isLastInGroup)
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 3, left: 4, right: 4),
                        child: Text(
                          formatChatTime(sentAt),
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
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