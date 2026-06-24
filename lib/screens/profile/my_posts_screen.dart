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

  void _openLikersSheet(BuildContext context, Map<String, dynamic> post) {
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
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (ctx, i) {
                      final p = _posts[i];
                      final imageUrl = p['image_url'] as String?;
                      final hasImage = imageUrl != null && imageUrl.isNotEmpty;
                      return _MyPostCard(
                        post: p,
                        hasImage: hasImage,
                        imageUrl: imageUrl,
                        formatDate: _formatDate,
                        onDelete: () => _deletePost(p['post_id'] as String),
                        onOpenLikers: () => _openLikersSheet(ctx, p),
                        openFullImage: (url) => _openFullImage(ctx, url),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── การ์ดโพสแบบ StatefulWidget (มี inline comments) ──
class _MyPostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final bool hasImage;
  final String? imageUrl;
  final String Function(String) formatDate;
  final VoidCallback onDelete;
  final VoidCallback onOpenLikers;
  final void Function(String) openFullImage;

  const _MyPostCard({
    required this.post,
    required this.hasImage,
    required this.imageUrl,
    required this.formatDate,
    required this.onDelete,
    required this.onOpenLikers,
    required this.openFullImage,
  });

  @override
  State<_MyPostCard> createState() => _MyPostCardState();
}

class _MyPostCardState extends State<_MyPostCard> {
  final _supabase = Supabase.instance.client;
  bool _showComments = false;
  bool _showLikers = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
          child: Row(children: [
            const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(widget.formatDate(p['created_at']), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _showLikers = !_showLikers),
              child: Row(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _showLikers ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(_showLikers),
                    size: 16,
                    color: const Color(0xFFEC4899),
                  ),
                ),
                const SizedBox(width: 3),
                Text('${p['likes_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => setState(() => _showComments = !_showComments),
              child: Row(children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _showComments ? '🔽' : '💬',
                    key: ValueKey(_showComments),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(width: 3),
                Text('${p['comments_count'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: widget.onDelete,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_outline_rounded, size: 17, color: Colors.red),
              ),
            ),
          ]),
        ),
        if ((p['content'] as String? ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(p['content'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
          ),
        if (widget.hasImage && widget.imageUrl != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: GestureDetector(
              onTap: () => widget.openFullImage(widget.imageUrl!),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(color: AppColors.border),
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        if (!widget.hasImage) const SizedBox(height: 4),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _showComments
              ? _MyPostInlineComments(postId: p['post_id'] as String)
              : const SizedBox.shrink(),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _showLikers
              ? _MyPostInlineLikers(
                  postId: p['post_id'] as String,
                  supabase: _supabase,
                )
              : const SizedBox.shrink(),
        ),
      ]),
    );
  }
}

// ── Inline Comments สำหรับหน้า MyPosts ──
class _MyPostInlineComments extends StatefulWidget {
  final String postId;
  const _MyPostInlineComments({required this.postId});

  @override
  State<_MyPostInlineComments> createState() => _MyPostInlineCommentsState();
}

class _MyPostInlineCommentsState extends State<_MyPostInlineComments> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _hasMore = false;
  int _page = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  int _calcAge(String? s) {
    if (s == null) return 0;
    try {
      final b = DateTime.parse(s);
      final n = DateTime.now();
      int a = n.year - b.year;
      if (n.month < b.month || (n.month == b.month && n.day < b.day)) a--;
      return a;
    } catch (_) { return 0; }
  }

  String _formatDate(String? s) {
    if (s == null) return '';
    try {
      final dt = DateTime.parse(s).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  Color _borderColor(String? gender) {
    if (gender == 'male') return const Color(0xFFBFDBFE);
    if (gender == 'female') return const Color(0xFFFCE7F3);
    return const Color(0xFFEDE9FE);
  }

  String? _photoUrl(Map<String, dynamic>? profile) {
    final photos = profile?['profile_photos'] as List?;
    if (photos == null || photos.isEmpty) return null;
    final sorted = [...photos]..sort((a, b) {
      if (a['is_primary'] == true) return -1;
      if (b['is_primary'] == true) return 1;
      return (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0);
    });
    return sorted.first['public_url'] as String?;
  }

  Future<void> _fetch({bool more = false}) async {
    if (!more) setState(() { _loading = true; _page = 0; });
    try {
      final offset = more ? (_page + 1) * _pageSize : 0;
      final res = await _supabase
          .from('post_comments')
          .select('id, content, created_at, author_id, profiles(display_name, gender, birth_date, profile_photos(public_url, is_primary, sort_order))')
          .eq('post_id', widget.postId)
          .isFilter('parent_id', null)
          .order('created_at', ascending: true)
          .range(offset, offset + _pageSize - 1);
      final list = List<Map<String, dynamic>>.from(res as List);
      setState(() {
        if (more) { _comments.addAll(list); _page++; }
        else { _comments = list; _page = 0; }
        _hasMore = list.length == _pageSize;
        _loading = false;
      });
    } catch (e) {
      debugPrint('MyPost Comments Error: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C4DFF))))
        else if (_comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('ยังไม่มีความคิดเห็น', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          )
        else ...[
          ..._comments.map((c) {
            final profile = c['profiles'] as Map<String, dynamic>?;
            final name = profile?['display_name'] as String? ?? 'ผู้ใช้';
            final gender = profile?['gender'] as String?;
            final age = _calcAge(profile?['birth_date'] as String?);
            final dateStr = _formatDate(c['created_at'] as String?);
            final photoUrl = _photoUrl(profile);
            final borderColor = _borderColor(gender);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: borderColor, width: 2)),
                  child: ClipOval(
                    child: photoUrl != null
                        ? CachedNetworkImage(imageUrl: photoUrl, width: 36, height: 36, fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)))
                        : const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                      if (age > 0) ...[
                        const SizedBox(width: 4),
                        Text('อายุ $age', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                      const Spacer(),
                      Text(dateStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ]),
                    const SizedBox(height: 2),
                    Text(c['content'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                  ]),
                ),
              ]),
            );
          }),
          if (_hasMore)
            GestureDetector(
              onTap: () => _fetch(more: true),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('แสดงความคิดเห็นเพิ่มเติม', style: TextStyle(fontSize: 13, color: Color(0xFF7C4DFF), fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ]),
    );
  }
}

// ── Inline Likers สำหรับหน้า MyPosts ──
class _MyPostInlineLikers extends StatefulWidget {
  final String postId;
  final SupabaseClient supabase;
  const _MyPostInlineLikers({required this.postId, required this.supabase});

  @override
  State<_MyPostInlineLikers> createState() => _MyPostInlineLikersState();
}

class _MyPostInlineLikersState extends State<_MyPostInlineLikers> {
  List<Map<String, dynamic>> _likers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await widget.supabase
          .from('post_reactions')
          .select('profile_id, profiles(display_name, gender, profile_photos(public_url, is_primary, sort_order))')
          .eq('post_id', widget.postId)
          .eq('reaction', 'like');
      setState(() {
        _likers = List<Map<String, dynamic>>.from(res as List);
        _loading = false;
      });
    } catch (e) {
      debugPrint('InlineLikers Error: $e');
      setState(() => _loading = false);
    }
  }

  String? _photoUrl(Map<String, dynamic>? profile) {
    final photos = profile?['profile_photos'] as List?;
    if (photos == null || photos.isEmpty) return null;
    final sorted = [...photos]..sort((a, b) {
      if (a['is_primary'] == true) return -1;
      if (b['is_primary'] == true) return 1;
      return (a['sort_order'] ?? 0).compareTo(b['sort_order'] ?? 0);
    });
    return sorted.first['public_url'] as String?;
  }

  Color _borderColor(String? gender) {
    if (gender == 'female') return const Color(0xFFFCE7F3);
    if (gender == 'male') return const Color(0xFFBFDBFE);
    return const Color(0xFFEDE9FE);
  }

  void _openViewer(int index) {
    final profile = _likers[index]['profiles'] as Map<String, dynamic>?;
    final gender = profile?['gender'] as String?;
    final name = profile?['display_name'] as String? ?? '?';
    final photoUrl = _photoUrl(profile);
    final bgColor = gender == 'female'
        ? const Color(0xFFFCE7F3)
        : gender == 'male'
            ? const Color(0xFFDBEAFE)
            : Colors.white;
    final borderColor = _borderColor(gender);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 80),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // ปุ่มปิดมุมขวาบน
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 12, 0),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: Colors.black12, shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 20, color: Colors.black54),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // รูปโปรไฟล์
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: photoUrl != null
                      ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover)
                      : Container(
                          color: borderColor.withValues(alpha: 0.3),
                          child: Center(child: Text(name.isNotEmpty ? name[0] : '?',
                              style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: borderColor))),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            // ปุ่มดูโปรไฟล์
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  final authorId = _likers[index]['profile_id'] as String?;
                  if (authorId != null) Navigator.pushNamed(context, '/profile', arguments: authorId);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFEC4899)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text('ดูโปรไฟล์ของ $name', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF1F2),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 10),
        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEC4899))))
        else if (_likers.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('ยังไม่มีคนกดใจ', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: _likers.length,
            itemBuilder: (_, i) {
              final profile = _likers[i]['profiles'] as Map<String, dynamic>?;
              final name = profile?['display_name'] as String? ?? '?';
              final gender = profile?['gender'] as String?;
              final photoUrl = _photoUrl(profile);
              final borderColor = _borderColor(gender);
              return GestureDetector(
                onTap: () => _openViewer(i),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: borderColor, width: 2.5)),
                    child: ClipOval(
                      child: SizedBox(
                        width: 56, height: 56,
                        child: photoUrl != null
                            ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover,
                                errorWidget: (_, _, _) => Container(color: borderColor.withValues(alpha: 0.2),
                                    child: Center(child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: borderColor, fontWeight: FontWeight.w700)))))
                            : Container(color: borderColor.withValues(alpha: 0.2),
                                child: Center(child: Text(name.isNotEmpty ? name[0] : '?', style: TextStyle(color: borderColor, fontWeight: FontWeight.w700)))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                ]),
              );
            },
          ),
        const SizedBox(height: 4),
      ]),
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
                                      ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover, errorWidget: (_, _, _) => _avatarFallback(name, borderColor))
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
                                    ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover, errorWidget: (_, _, _) => _avatarFallback(name, borderColor))
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
