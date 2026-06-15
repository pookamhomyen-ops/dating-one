import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
  }

  Future<void> _fetchMyPosts() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      final res = await _supabase
          .from('feed_posts_v')
          .select()
          .eq('author_id', userId)
          .order('created_at', ascending: false);
      setState(() {
        _posts = List<Map<String, dynamic>>.from(res as List);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('MyPosts Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ลบโพส?', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('โพสและความคิดเห็นทั้งหมดจะถูกลบถาวร'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _supabase.from('post_comments').delete().eq('post_id', postId);
      await _supabase.from('post_reactions').delete().eq('post_id', postId);
      await _supabase.from('post_media').delete().eq('post_id', postId);
      await _supabase.from('posts').delete().eq('id', postId);
      setState(() => _posts.removeWhere((p) => p['post_id'] == postId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('ลบโพสเรียบร้อย'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ลบไม่สำเร็จ: $e'), backgroundColor: Colors.red));
    }
  }

  String _formatDate(String createdAt) {
    final dt = DateTime.parse(createdAt).toLocal();
    return DateFormat('d MMM yyyy • HH:mm', 'th').format(dt);
  }

  void _openPostDetail(BuildContext context, Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PostDetailSheet(post: post, supabase: _supabase),
    );
  }

  void _openFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain)),
            Positioned(
              top: 40, right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.pop(context)),
        title: const Text('โพสของฉัน', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12)),
              child: Text('${_posts.length} โพส', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C4DFF))),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
          : _posts.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(width: 80, height: 80, decoration: const BoxDecoration(color: Color(0xFFEDE9FE), shape: BoxShape.circle), child: const Icon(Icons.edit_note_rounded, size: 40, color: Color(0xFF7C4DFF))),
                    const SizedBox(height: 16),
                    const Text('ยังไม่มีโพส', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    const Text('เริ่มแชร์เรื่องราวของคุณได้เลย!', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ]),
                )
              : RefreshIndicator(
                  onRefresh: _fetchMyPosts,
                  color: const Color(0xFF7C4DFF),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, i) {
                      final p = _posts[i];
                      final imageUrl = p['image_url'] as String?;
                      final hasImage = imageUrl != null && imageUrl.isNotEmpty;
                      return GestureDetector(
                        onTap: () => _openPostDetail(ctx, p),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            // Header row
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
                              child: Row(children: [
                                const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(_formatDate(p['created_at']), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                const Spacer(),
                                // like icon tappable
                                GestureDetector(
                                  onTap: () => _openPostDetail(ctx, p),
                                  child: Row(children: [
                                    const Icon(Icons.favorite_rounded, size: 15, color: Color(0xFFEC4899)),
                                    const SizedBox(width: 3),
                                    Text('${p['likes_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                                const SizedBox(width: 12),
                                // comment icon tappable
                                GestureDetector(
                                  onTap: () => _openPostDetail(ctx, p),
                                  child: Row(children: [
                                    const Icon(Icons.chat_bubble_rounded, size: 15, color: Color(0xFF06B6D4)),
                                    const SizedBox(width: 3),
                                    Text('${p['comments_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                                  ]),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => _deletePost(p['post_id'] as String),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.delete_outline_rounded, size: 17, color: Colors.red),
                                  ),
                                ),
                              ]),
                            ),
                            // Content
                            if ((p['content'] as String? ?? '').isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                                child: Text(p['content'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
                              ),
                            // Image 1:1
                            if (hasImage)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                                child: GestureDetector(
                                  onTap: () => _openFullImage(ctx, imageUrl),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: AppColors.border),
                                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (!hasImage) const SizedBox(height: 4),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Bottom Sheet แสดง likes + comments ──
class _PostDetailSheet extends StatefulWidget {
  final Map<String, dynamic> post;
  final SupabaseClient supabase;
  const _PostDetailSheet({required this.post, required this.supabase});

  @override
  State<_PostDetailSheet> createState() => _PostDetailSheetState();
}

class _PostDetailSheetState extends State<_PostDetailSheet> {
  List<Map<String, dynamic>> _likers = [];
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final postId = widget.post['post_id'] as String;
    try {
      // ดึง likers
      final likersRes = await widget.supabase
          .from('post_reactions')
          .select('profile_id, profiles(display_name, gender, profile_photos(public_url, is_primary, sort_order))')
          .eq('post_id', postId)
          .eq('reaction', 'like');

      // ดึง comments
      final commentsRes = await widget.supabase
          .from('post_comments')
          .select('id, content, created_at, author_id, profiles(display_name, gender, profile_photos(public_url, is_primary, sort_order))')
          .eq('post_id', postId)
          .isFilter('parent_id', null)
          .order('created_at', ascending: true);

      setState(() {
        _likers = List<Map<String, dynamic>>.from(likersRes as List);
        _comments = List<Map<String, dynamic>>.from(commentsRes as List);
        _loading = false;
      });
    } catch (e) {
      debugPrint('PostDetail Error: $e');
      setState(() => _loading = false);
    }
  }

  String? _getPhotoUrl(Map<String, dynamic>? profile) {
    final photos = profile?['profile_photos'] as List?;
    if (photos == null || photos.isEmpty) return null;
    final primary = photos.where((p) => p['is_primary'] == true).toList();
    if (primary.isNotEmpty) return primary.first['public_url'] as String?;
    final sorted = [...photos]..sort((a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
    return sorted.first['public_url'] as String?;
  }

  void _openLikerViewer(int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _LikerViewerDialog(likers: _likers, initialIndex: initialIndex, getPhotoUrl: _getPhotoUrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)))
            : Column(children: [
                // Handle
                const SizedBox(height: 10),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(controller: scrollCtrl, padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
                    // ── ส่วนที่ 1: Likers ──
                    Row(children: [
                      const Icon(Icons.favorite_rounded, size: 18, color: Color(0xFFEC4899)),
                      const SizedBox(width: 6),
                      Text('คนกดใจ (${_likers.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ]),
                    const SizedBox(height: 14),
                    if (_likers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('ยังไม่มีคนกดใจ', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1),
                        itemCount: _likers.length,
                        itemBuilder: (_, i) {
                          final profile = _likers[i]['profiles'] as Map<String, dynamic>?;
                          final name = profile?['display_name'] as String? ?? '?';
                          final gender = profile?['gender'] as String? ?? '';
                          final photoUrl = _getPhotoUrl(profile);
                          final borderColor = gender == 'female' ? const Color(0xFFEC4899) : const Color(0xFF3B82F6);
                          return GestureDetector(
                            onTap: () => _openLikerViewer(i),
                            child: Column(children: [
                              Container(
                                width: 72, height: 72,
                                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: borderColor, width: 2.5)),
                                child: ClipOval(
                                  child: photoUrl != null
                                      ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => _avatarFallback(name, borderColor))
                                      : _avatarFallback(name, borderColor),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                            ]),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    // ── ส่วนที่ 2: Comments ──
                    Row(children: [
                      const Icon(Icons.chat_bubble_rounded, size: 18, color: Color(0xFF06B6D4)),
                      const SizedBox(width: 6),
                      Text('ความคิดเห็น (${_comments.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ]),
                    const SizedBox(height: 14),
                    if (_comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('ยังไม่มีความคิดเห็น', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      )
                    else
                      ...(_comments.map((c) {
                        final profile = c['profiles'] as Map<String, dynamic>?;
                        final name = profile?['display_name'] as String? ?? 'ผู้ใช้';
                        final gender = profile?['gender'] as String? ?? '';
                        final photoUrl = _getPhotoUrl(profile);
                        final borderColor = gender == 'female' ? const Color(0xFFEC4899) : const Color(0xFF3B82F6);
                        final diff = DateTime.now().difference(DateTime.parse(c['created_at']));
                        final timeStr = diff.inMinutes < 1 ? 'เมื่อกี้' : diff.inHours < 1 ? '${diff.inMinutes} นาที' : diff.inDays < 1 ? '${diff.inHours} ชม.' : '${diff.inDays} วัน';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: borderColor, width: 2)),
                              child: ClipOval(
                                child: photoUrl != null
                                    ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => _avatarFallback(name, borderColor))
                                    : _avatarFallback(name, borderColor),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(16)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                                    const SizedBox(width: 6),
                                    Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(c['content'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
                                ]),
                              ),
                            ),
                          ]),
                        );
                      }).toList()),
                  ]),
                ),
              ]),
      ),
    );
  }

  Widget _avatarFallback(String name, Color color) {
    return Container(
      color: color.withValues(alpha: 0.15),
      child: Center(child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color))),
    );
  }
}

// ── Dialog ดูรูป liker เต็มจอ ──
class _LikerViewerDialog extends StatefulWidget {
  final List<Map<String, dynamic>> likers;
  final int initialIndex;
  final String? Function(Map<String, dynamic>?) getPhotoUrl;
  const _LikerViewerDialog({required this.likers, required this.initialIndex, required this.getPhotoUrl});

  @override
  State<_LikerViewerDialog> createState() => _LikerViewerDialogState();
}

class _LikerViewerDialogState extends State<_LikerViewerDialog> {
  late PageController _pageCtrl;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _pageCtrl = PageController(initialPage: _current);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liker = widget.likers[_current];
    final profile = liker['profiles'] as Map<String, dynamic>?;
    final name = profile?['display_name'] as String? ?? '?';
    final photoUrl = widget.getPhotoUrl(profile);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Container(
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ปุ่มปิด
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 12, 0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
          // รูปใน PageView
          SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _pageCtrl,
              itemCount: widget.likers.length,
              onPageChanged: (i) => setState(() => _current = i),
              itemBuilder: (_, i) {
                final p = widget.likers[i]['profiles'] as Map<String, dynamic>?;
                final url = widget.getPhotoUrl(p);
                final n = p?['display_name'] as String? ?? '?';
                final gender = p?['gender'] as String? ?? '';
                final borderColor = gender == 'female' ? const Color(0xFFEC4899) : const Color(0xFF3B82F6);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: borderColor, width: 3)),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: url != null
                            ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                            : Container(color: borderColor.withValues(alpha: 0.15), child: Center(child: Text(n.isNotEmpty ? n[0] : '?', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: borderColor)))),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          // indicator
          if (widget.likers.length > 1) ...[
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(widget.likers.length, (i) => Container(
              width: _current == i ? 18 : 6, height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(color: _current == i ? const Color(0xFF7C4DFF) : AppColors.border, borderRadius: BorderRadius.circular(3)),
            ))),
          ],
          const SizedBox(height: 16),
          // ปุ่มดูโปรไฟล์
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: GestureDetector(
              onTap: () {
                // TODO: navigate to profile
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFEC4899)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.person_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('ดูโปรไฟล์', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
