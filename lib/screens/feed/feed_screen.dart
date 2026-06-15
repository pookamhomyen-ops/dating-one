import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/feed_post.dart';
import '../../models/gender.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/soulive_header.dart';
import 'create_post_sheet.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _supabase = Supabase.instance.client;
  List<FeedPost> _posts = [];
  bool _isLoading = true;
  int _filterIndex = 0;
  String _genderFilter = 'ทั้งหมด'; // all, female, male

  static const Color lavenderDark = Color(0xFF7C4DFF);
  static const Color lavenderLight = Color(0xFFA78BFA);

  @override
  void initState() {
    super.initState();
    _fetchRealtimeFeed();
  }

  Future<void> _fetchRealtimeFeed() async {
    try {
      setState(() => _isLoading = true);

      var query = _supabase.from('feed_posts_v').select();
      if (_genderFilter == 'female') {
        query = query.eq('author_gender', 'female');
      } else if (_genderFilter == 'male') {
        query = query.eq('author_gender', 'male');
      }

      final response = await query.order('created_at', ascending: false);

      final userId = _supabase.auth.currentUser?.id;
      List<String> likedPostIds = [];
      if (userId != null) {
        final liked = await _supabase
            .from('post_reactions')
            .select('post_id')
            .eq('profile_id', userId)
            .eq('reaction', 'like');
        likedPostIds = (liked as List).map((e) => e['post_id'] as String).toList();
      }

      final List<FeedPost> loadedPosts = (response as List).map((item) {
        return FeedPost(
          id: item['post_id'] as String,
          authorId: item['author_id'] as String? ?? '',
          authorName: item['author_name'] as String? ?? 'ผู้ใช้',
          authorGender: item['author_gender'] == 'female' ? Gender.female : Gender.male,
          authorPhotoUrl: item['author_photo_url'] as String? ?? '',
          content: item['content'] as String? ?? '',
          postedAt: item['created_at'] != null
              ? DateTime.parse(item['created_at'])
              : DateTime.now(),
          imageUrl: item['image_url'] as String?,
          likes: item['likes_count'] as int? ?? 0,
          comments: item['comments_count'] as int? ?? 0,
          likedByMe: likedPostIds.contains(item['post_id'] as String),
        );
      }).toList();

      setState(() {
        _posts = loadedPosts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Feed Error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(int index) async {
    final post = _posts[index];
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final alreadyLiked = post.likedByMe;

    setState(() {
      _posts[index] = post.copyWith(
        likedByMe: !alreadyLiked,
        likes: alreadyLiked ? post.likes - 1 : post.likes + 1,
      );
    });

    try {
      if (alreadyLiked) {
        await _supabase
            .from('post_reactions')
            .delete()
            .eq('post_id', post.id)
            .eq('profile_id', userId)
            .eq('reaction', 'like');
      } else {
        await _supabase.from('post_reactions').upsert({
          'post_id': post.id,
          'profile_id': userId,
          'reaction': 'like',
        });
      }
    } catch (e) {
      debugPrint('Like Error: $e');
      setState(() {
        _posts[index] = _posts[index].copyWith(
          likedByMe: alreadyLiked,
          likes: post.likes,
        );
      });
    } finally {
      final fresh = await _supabase
          .from('feed_posts_v')
          .select('likes_count, comments_count')
          .eq('post_id', post.id)
          .maybeSingle();
      if (fresh != null && mounted) {
        setState(() {
          _posts[index] = _posts[index].copyWith(
            likes: fresh['likes_count'] as int? ?? _posts[index].likes,
            comments: fresh['comments_count'] as int? ?? _posts[index].comments,
          );
        });
      }
    }
  }

  void _openComments(BuildContext context, int index) {
    final post = _posts[index];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isDismissible: true,
      enableDrag: true,
      builder: (_) => _CommentsSheet(
        post: post,
        supabase: _supabase,
        onCommentCountChanged: (newCount) {
          if (mounted) {
            setState(() {
              _posts[index] = _posts[index].copyWith(comments: newCount);
            });
          }
        },
      ),
    );
  }

  void _showSpecDropdown(BuildContext context) {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(16, 160, 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem(value: 'fit', child: Row(children: [const Text('💪', style: TextStyle(fontSize: 18)), const SizedBox(width: 10), const Text('หุ่นดี')])),
        PopupMenuItem(value: 'chubby', child: Row(children: [const Text('🧸', style: TextStyle(fontSize: 18)), const SizedBox(width: 10), const Text('อวบ')])),
        PopupMenuItem(value: 'very_chubby', child: Row(children: [const Text('🍑', style: TextStyle(fontSize: 18)), const SizedBox(width: 10), const Text('อวบระยะสุดท้าย')])),
        PopupMenuItem(value: 'fat', child: Row(children: [const Text('🐻', style: TextStyle(fontSize: 18)), const SizedBox(width: 10), const Text('อ้วน')])),
      ],
    ).then((val) {
      // ยังไม่ต้องทำระบบ
    });
  }

  Widget _buildFAB(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => CreatePostSheet(
            onPosted: () {
              setState(() => _genderFilter = 'ทั้งหมด');
              _fetchRealtimeFeed();
            },
          ),
        );
      },
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFFEC4899)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Color(0x557C4DFF), blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _buildFAB(context),
      body: SafeArea(
        child: RefreshIndicator(
          color: lavenderDark,
          onRefresh: _fetchRealtimeFeed,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SouliveHeader(pageTitle: 'Feed', trailing: SizedBox())),
              SliverToBoxAdapter(child: _StoriesRow(lavenderDark: lavenderDark, lavenderLight: lavenderLight)),
              
              // แถบตัวกรอง (Filters)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // ปุ่ม ทั้งหมด + dropdown gender
                        _FilterDropdown(
                          selected: _filterIndex == 0,
                          label: 'ทั้งหมด',
                          genderFilter: _genderFilter,
                          lavenderDark: lavenderDark,
                          lavenderLight: lavenderLight,
                          onTap: () => setState(() => _filterIndex = 0),
                          onGenderSelect: (g) {
                            setState(() {
                              _filterIndex = 0;
                              _genderFilter = g;
                            });
                            _fetchRealtimeFeed();
                          },
                        ),
                        const SizedBox(width: 8),
                        // ปุ่ม ติดตาม
                        GestureDetector(
                          onTap: () => setState(() => _filterIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: _filterIndex == 1 ? const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)]) : null,
                              color: _filterIndex == 1 ? null : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _filterIndex == 1 ? Colors.transparent : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.favorite_rounded, size: 14, color: _filterIndex == 1 ? Colors.white : const Color(0xFF06B6D4)),
                                const SizedBox(width: 5),
                                Text('ติดตาม', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _filterIndex == 1 ? Colors.white : AppColors.textPrimary)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ปุ่ม สเป็ก + ไอคอนตั้งค่า
                        GestureDetector(
                          onTap: () {
                            setState(() => _filterIndex = 2);
                            _showSpecDropdown(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: _filterIndex == 2 ? const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFFBBF24)]) : null,
                              color: _filterIndex == 2 ? null : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _filterIndex == 2 ? Colors.transparent : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.local_fire_department_rounded, size: 14, color: _filterIndex == 2 ? Colors.white : const Color(0xFFF97316)),
                                const SizedBox(width: 5),
                                Text('สเป็ก', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _filterIndex == 2 ? Colors.white : AppColors.textPrimary)),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down_rounded, size: 18, color: _filterIndex == 2 ? Colors.white : const Color(0xFFF97316)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ปุ่ม ใกล้เคียง
                        GestureDetector(
                          onTap: () => setState(() => _filterIndex = 3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: _filterIndex == 3 ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]) : null,
                              color: _filterIndex == 3 ? null : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _filterIndex == 3 ? Colors.transparent : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 14, color: _filterIndex == 3 ? Colors.white : const Color(0xFF10B981)),
                                const SizedBox(width: 5),
                                Text('ใกล้เคียง', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _filterIndex == 3 ? Colors.white : AppColors.textPrimary)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // แสดงเนื้อหาหรือวงโหลดอนิเมชัน
              _isLoading
                  ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: lavenderDark)))
                  : _posts.isEmpty
                      ? const SliverFillRemaining(child: Center(child: Text('ไม่มีโพสต์ใหม่ในขณะนี้', style: TextStyle(color: AppColors.textSecondary))))
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          sliver: SliverList.separated(
                            itemCount: _posts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              return _FeedPostCard(
                                post: _posts[index],
                                lavenderDark: lavenderDark,
                                lavenderLight: lavenderLight,
                                onLike: () => _toggleLike(index),
                                onComment: () => _openComments(context, index),
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
}

// โครงสร้างคอมโพเนนต์แถบสตอรี่แบบกระชับ
class _StoriesRow extends StatelessWidget {
  const _StoriesRow({required this.lavenderDark, required this.lavenderLight});
  final Color lavenderDark, lavenderLight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 105,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        scrollDirection: Axis.horizontal,
        itemCount: 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final isMe = i == 0;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: isMe ? [lavenderDark, lavenderLight] : [const Color(0xFFEC4899), const Color(0xFFF472B6)]),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: AppColors.surface, shape: BoxShape.circle),
                  child: CircleAvatar(radius: 28, backgroundColor: AppColors.border, child: Text(isMe ? 'Me' : 'User')),
                ),
              ),
              const SizedBox(height: 6),
              Text(isMe ? 'สตอรี่ของคุณ' : 'เพื่อน', style: TextStyle(fontSize: 12, color: isMe ? lavenderDark : AppColors.textPrimary)),
            ],
          );
        },
      ),
    );
  }
}

// ส่วนแสดงผลโพสต์การ์ด (ดึงข้อมูลจากตัวแปรโมเดลเรียลไทม์)
class _FeedPostCard extends StatefulWidget {
  const _FeedPostCard({
    required this.post,
    required this.lavenderDark,
    required this.lavenderLight,
    required this.onLike,
    required this.onComment,
  });
  final FeedPost post;
  final Color lavenderDark, lavenderLight;
  final VoidCallback onLike;
  final VoidCallback onComment;

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  bool _showComments = false;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }

  void _goToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile', arguments: widget.post.authorId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _goToProfile(context),
                  child: AvatarImage(url: widget.post.authorPhotoUrl, size: 48),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _goToProfile(context),
                        child: Row(
                          children: [
                            Text(widget.post.authorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                            const SizedBox(width: 4),
                            const Icon(Icons.verified, size: 16, color: Color(0xFF3B82F6)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _timeAgo(widget.post.postedAt),
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(widget.post.content, style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.textPrimary)),
          ),
          if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl: widget.post.imageUrl!,
                  height: 340,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 340,
                    color: AppColors.border,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => const SizedBox.shrink(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.onLike,
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                        child: Icon(
                          widget.post.likedByMe ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          key: ValueKey(widget.post.likedByMe),
                          size: 22,
                          color: widget.post.likedByMe ? const Color(0xFFEC4899) : const Color(0xFF7C4DFF),
                        ),
                      ),
                      const SizedBox(width: 5),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.post.likedByMe ? const Color(0xFFEC4899) : AppColors.textSecondary,
                        ),
                        child: Text('${widget.post.likes}'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () {
                    setState(() => _showComments = !_showComments);
                  },
                  child: Row(
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          _showComments ? '🔽' : '💬',
                          key: ValueKey(_showComments),
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${widget.post.comments}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _showComments
                ? _InlineCommentSection(postId: widget.post.id)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final FeedPost post;
  final SupabaseClient supabase;
  final ValueChanged<int> onCommentCountChanged;
  const _CommentsSheet({required this.post, required this.supabase, required this.onCommentCountChanged});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;
  late int _localCommentCount;

  @override
  void initState() {
    super.initState();
    _localCommentCount = widget.post.comments;
    _fetchComments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final res = await widget.supabase
          .from('post_comments')
          .select('id, content, created_at, author_id, profiles(display_name, profile_photos(public_url, is_primary, sort_order))')
          .eq('post_id', widget.post.id)
          .isFilter('parent_id', null)
          .order('created_at', ascending: true);
      setState(() {
        _comments = List<Map<String, dynamic>>.from(res as List);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Comments Error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    final userId = widget.supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _sending = true;
      _localCommentCount++;
    });
    try {
      await widget.supabase.from('post_comments').insert({
        'post_id': widget.post.id,
        'author_id': userId,
        'content': text,
      });
      _ctrl.clear();
      FocusScope.of(context).unfocus();
      await _fetchComments();
    } catch (e) {
      debugPrint('Send Comment Error: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: const Color(0xFFEDE9FE),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0] : '?',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF7C4DFF)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text('ความคิดเห็น', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(12)),
                        child: Text('$_localCommentCount', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C4DFF))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? const Center(child: Text('ยังไม่มีความคิดเห็น', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          controller: scrollCtrl,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: _comments.length,
                          itemBuilder: (_, i) {
                            final c = _comments[i];
                            final profile = c['profiles'] as Map<String, dynamic>?;
                            final name = profile?['display_name'] as String? ?? 'ผู้ใช้';
                            final photos = profile?['profile_photos'] as List?;
                            String? photoUrl;
                            if (photos != null && photos.isNotEmpty) {
                              final primary = photos.where((p) => p['is_primary'] == true).toList();
                              if (primary.isNotEmpty) {
                                photoUrl = primary.first['public_url'] as String?;
                              } else {
                                final sorted = [...photos]..sort((a, b) => (a['sort_order'] as int).compareTo(b['sort_order'] as int));
                                photoUrl = sorted.first['public_url'] as String?;
                              }
                            }
                            final diff = DateTime.now().difference(DateTime.parse(c['created_at']));
                            final timeStr = diff.inMinutes < 1 ? 'เมื่อกี้' : diff.inHours < 1 ? '${diff.inMinutes} นาที' : diff.inDays < 1 ? '${diff.inHours} ชม.' : '${diff.inDays} วัน';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFEDE9FE), width: 2),
                                    ),
                                    child: ClipOval(
                                      child: photoUrl != null && photoUrl.isNotEmpty
                                          ? CachedNetworkImage(imageUrl: photoUrl, fit: BoxFit.cover, errorWidget: (_, __, ___) => _avatarFallback(name))
                                          : _avatarFallback(name),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8FC),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary)),
                                              const SizedBox(width: 6),
                                              Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(c['content'] ?? '', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const Divider(height: 1),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
              ),
              padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'แสดงความคิดเห็น...',
                          hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendComment,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFFA78BFA)]),
                        shape: BoxShape.circle,
                      ),
                      child: _sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _FilterDropdown extends StatelessWidget {
  final bool selected;
  final String label;
  final String genderFilter;
  final Color lavenderDark, lavenderLight;
  final VoidCallback onTap;
  final ValueChanged<String> onGenderSelect;

  const _FilterDropdown({
    required this.selected,
    required this.label,
    required this.genderFilter,
    required this.lavenderDark,
    required this.lavenderLight,
    required this.onTap,
    required this.onGenderSelect,
  });

  String get _genderLabel {
    if (genderFilter == 'female') return 'ผู้หญิง';
    if (genderFilter == 'male') return 'ผู้ชาย';
    return 'ทั้งหมด';
  }

  List<Color> get _gradientColors {
    if (genderFilter == 'female') return [const Color(0xFFEC4899), const Color(0xFFF472B6)];
    if (genderFilter == 'male') return [const Color(0xFF3B82F6), const Color(0xFF60A5FA)];
    return [const Color(0xFF7C4DFF), const Color(0xFFA78BFA)];
  }

  Color get _accentColor {
    if (genderFilter == 'female') return const Color(0xFFEC4899);
    if (genderFilter == 'male') return const Color(0xFF3B82F6);
    return const Color(0xFF7C4DFF);
  }

  IconData get _leadingIcon {
    if (genderFilter == 'female') return Icons.female_rounded;
    if (genderFilter == 'male') return Icons.male_rounded;
    return Icons.people_alt_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDropdown(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(colors: _gradientColors) : null,
          color: selected ? null : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_leadingIcon, size: 14, color: selected ? Colors.white : _accentColor),
            const SizedBox(width: 4),
            Text(_genderLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.textPrimary)),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: selected ? Colors.white : _accentColor),
          ],
        ),
      ),
    );
  }

  void _showDropdown(BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset offset = box.localToGlobal(Offset.zero);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(offset.dx, offset.dy + box.size.height + 4, offset.dx + 160, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: [
        PopupMenuItem(
          value: 'ทั้งหมด',
          child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF7C4DFF))),
            const SizedBox(width: 10),
            const Text('ทั้งหมด', style: TextStyle(fontWeight: FontWeight.w500)),
          ]),
        ),
        PopupMenuItem(
          value: 'female',
          child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFFFCE7F3), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.female_rounded, size: 16, color: Color(0xFFEC4899))),
            const SizedBox(width: 10),
            const Text('ผู้หญิง', style: TextStyle(fontWeight: FontWeight.w500)),
          ]),
        ),
        PopupMenuItem(
          value: 'male',
          child: Row(children: [
            Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.male_rounded, size: 16, color: Color(0xFF3B82F6))),
            const SizedBox(width: 10),
            const Text('ผู้ชาย', style: TextStyle(fontWeight: FontWeight.w500)),
          ]),
        ),
      ],
    ).then((val) {
      if (val != null) onGenderSelect(val);
    });
  }
}

class _ReactionBtn extends StatelessWidget {
  const _ReactionBtn({required this.emoji, required this.count, required this.color});
  final String emoji, count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          Text(count, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _InlineCommentSection extends StatefulWidget {
  final String postId;
  const _InlineCommentSection({required this.postId});

  @override
  State<_InlineCommentSection> createState() => _InlineCommentSectionState();
}

class _InlineCommentSectionState extends State<_InlineCommentSection> {
  final _supabase = Supabase.instance.client;
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      final res = await _supabase
          .from('post_comments')
          .select('id, content, created_at, author_id, profiles(display_name, profile_photos(public_url, is_primary, sort_order))')
          .eq('post_id', widget.postId)
          .isFilter('parent_id', null)
          .order('created_at', ascending: true)
          .limit(5); // Show only last 5 for inline
      setState(() {
        _comments = List<Map<String, dynamic>>.from(res as List);
        _loading = false;
      });
    } catch (e) {
      debugPrint('Inline Comments Error: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _sending) return;
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _sending = true);
    try {
      await _supabase.from('post_comments').insert({
        'post_id': widget.postId,
        'author_id': userId,
        'content': text,
      });
      _ctrl.clear();
      await _fetchComments();
    } catch (e) {
      debugPrint('Send Inline Comment Error: $e');
    } finally {
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB).withValues(alpha: 0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_comments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('ยังไม่มีความคิดเห็น', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            )
          else
            ..._comments.map((c) {
              final profile = c['profiles'] as Map<String, dynamic>?;
              final name = profile?['display_name'] as String? ?? 'ผู้ใช้';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(c['content'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'เขียนความคิดเห็น...',
                    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendComment,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: Color(0xFF7C4DFF), shape: BoxShape.circle),
                  child: _sending
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}