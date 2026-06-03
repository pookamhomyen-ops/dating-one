import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../models/feed_post.dart';
import '../../theme/app_colors.dart';
import '../../utils/time_format.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/soulive_header.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late List<FeedPost> _posts;
  int _filterIndex = 0;
  final Set<String> _bookmarked = {};

  static const _filters = ['🔥 ทั้งหมด', '✨ ใหม่', '💖 ยอดนิยม', '📍 ใกล้ฉัน'];

  @override
  void initState() {
    super.initState();
    _posts = List.of(MockData.initialPosts);
  }

  void _toggleLike(int index) {
    setState(() {
      final post = _posts[index];
      if (post.likedByMe) {
        _posts[index] = post.copyWith(
          likedByMe: false,
          likes: post.likes - 1,
          dislikedByMe: false,
        );
      } else {
        _posts[index] = post.copyWith(
          likedByMe: true,
          likes: post.likes + 1,
          dislikedByMe: false,
        );
      }
    });
  }

  void _toggleDislike(int index) {
    setState(() {
      final post = _posts[index];
      final wasLiked = post.likedByMe;
      _posts[index] = post.copyWith(
        dislikedByMe: !post.dislikedByMe,
        likedByMe: false,
        likes: wasLiked ? post.likes - 1 : post.likes,
      );
    });
  }

  void _openComments(FeedPost post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CommentsSheet(post: post),
    );
  }

  bool _isNewPost(FeedPost post) {
    return DateTime.now().difference(post.postedAt).inHours < 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brandPink,
          onRefresh: () async {
            await Future<void>.delayed(const Duration(milliseconds: 600));
            setState(() => _posts = List.of(MockData.initialPosts));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SouliveHeader(pageTitle: 'ฟีด')),
              SliverToBoxAdapter(child: _StoriesRow()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final selected = _filterIndex == i;
                        return GestureDetector(
                          onTap: () => setState(() => _filterIndex = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.brandPink
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected
                                    ? AppColors.brandPink
                                    : AppColors.border,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.brandPink
                                            .withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              _filters[i],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                sliver: SliverList.separated(
                  itemCount: _posts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return _FeedPostCard(
                      post: post,
                      isNew: _isNewPost(post),
                      isHot: post.likes >= 50,
                      bookmarked: _bookmarked.contains(post.id),
                      onLike: () => _toggleLike(index),
                      onDislike: () => _toggleDislike(index),
                      onComment: () => _openComments(post),
                      onBookmark: () {
                        setState(() {
                          if (_bookmarked.contains(post.id)) {
                            _bookmarked.remove(post.id);
                          } else {
                            _bookmarked.add(post.id);
                          }
                        });
                      },
                      onShare: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('แชร์โพสต์ (เดโม)'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
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

class _StoriesRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stories = [
      ('คุณ', MockData.avatarUrl('me1'), true),
      ('มายด์', MockData.avatarUrl('mild'), false),
      ('เฟิร์น', MockData.avatarUrl('fern'), false),
      ('ภูมิ', MockData.avatarUrl('phoom2'), false),
      ('อารี', MockData.avatarUrl('aree'), false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 10),
          child: Text(
            '✨ สตอรี่วันนี้',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 92,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: stories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final (name, url, isMe) = stories[i];
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isMe
                            ? [AppColors.border, AppColors.border]
                            : [
                                AppColors.brandPink,
                                const Color(0xFFFFB347),
                              ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        shape: BoxShape.circle,
                      ),
                      child: AvatarImage(url: url, size: 54),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.post,
    required this.isNew,
    required this.isHot,
    required this.bookmarked,
    required this.onLike,
    required this.onDislike,
    required this.onComment,
    required this.onBookmark,
    required this.onShare,
  });

  final FeedPost post;
  final bool isNew;
  final bool isHot;
  final bool bookmarked;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onComment;
  final VoidCallback onBookmark;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final genderBg = AppColors.cardBackground(post.authorGender);
    final genderBorder = AppColors.cardBorder(post.authorGender);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: genderBorder.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: genderBorder.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [genderBg, AppColors.surface],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  AvatarImage(url: post.authorPhotoUrl, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isHot) ...[
                              const SizedBox(width: 6),
                              _Badge(label: '🔥 Hot', color: const Color(0xFFFF6B35)),
                            ] else if (isNew) ...[
                              const SizedBox(width: 6),
                              _Badge(label: '✨ ใหม่', color: AppColors.brandPink),
                            ],
                          ],
                        ),
                        Text(
                          '${post.authorGender.labelTh} · ${formatPostTime(post.postedAt)}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onBookmark,
                    icon: Icon(
                      bookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: bookmarked
                          ? AppColors.brandPink
                          : AppColors.textMuted,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                post.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (post.imageUrl != null)
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: NetworkImageBox(
                        url: post.imageUrl!,
                        height: 220,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '👆 แตะรูปเพื่อดูเต็มจอ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  _ReactionChip(emoji: '❤️', count: post.likes),
                  const SizedBox(width: 8),
                  _ReactionChip(emoji: '🔥', count: (post.likes / 3).round()),
                  const SizedBox(width: 8),
                  _ReactionChip(emoji: '😍', count: (post.likes / 5).round()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
              child: Row(
                children: [
                  _ActionPill(
                    icon: post.likedByMe ? Icons.favorite : Icons.favorite_border,
                    label: '${post.likes}',
                    active: post.likedByMe,
                    activeColor: AppColors.heartRed,
                    onTap: onLike,
                  ),
                  const SizedBox(width: 8),
                  _ActionPill(
                    icon: post.dislikedByMe
                        ? Icons.thumb_down
                        : Icons.thumb_down_outlined,
                    label: 'ไม่ชอบ',
                    active: post.dislikedByMe,
                    activeColor: Colors.orange,
                    onTap: onDislike,
                  ),
                  const SizedBox(width: 8),
                  _ActionPill(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: '${post.comments}',
                    onTap: onComment,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onShare,
                    icon: const Icon(Icons.ios_share_rounded, size: 20),
                    color: AppColors.textSecondary,
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.emoji, required this.count});

  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$emoji $count',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (activeColor ?? AppColors.brandPink)
        : AppColors.textSecondary;

    return Material(
      color: active ? color.withValues(alpha: 0.12) : AppColors.chipBg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatelessWidget {
  const _CommentsSheet({required this.post});

  final FeedPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '💬 ความคิดเห็น',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${post.comments}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandPink,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'ยังไม่มี backend — แสดง UI ความคิดเห็น',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: '💭 เขียนความคิดเห็น...',
                suffixIcon: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.send_rounded, color: AppColors.brandPink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
