import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/feed_post.dart';
import '../../models/gender.dart';
import '../../theme/app_colors.dart';
import '../../widgets/avatar_image.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/soulive_header.dart';

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

  static const Color lavenderDark = Color(0xFF7C4DFF);
  static const Color lavenderLight = Color(0xFFA78BFA);
  static const _filters = [' ทั้งหมด', '⚡ ใหม่', '🔥 ยอดนิยม', '📍 ใกล้เคียง'];

  @override
  void initState() {
    super.initState();
    _fetchRealtimeFeed();
  }

  // 🛠️ แก้ไขฟังก์ชันดึงข้อมูลให้ถูกต้องตามไวยากรณ์ Supabase Dart SDK
  Future<void> _fetchRealtimeFeed() async {
    try {
      setState(() => _isLoading = true);
      
      // ปรับปรุงการดึงข้อมูลสัมพันธ์ (Relation JOIN) ให้ถูกต้อง
      final response = await _supabase
          .from('posts')
          .select('id, author_id, content, created_at, likes_count, comments_count, profiles(display_name, gender, province, is_verified, is_online)')
          .order('created_at', ascending: false);

      final List<FeedPost> loadedPosts = [];
      for (var item in response as List) {
        final authorId = item['author_id'] as String?;
        final postId = item['id'] as String;
        final profile = item['profiles'] as Map<String, dynamic>?;

        final authorPhotoUrl = authorId != null 
            ? _supabase.storage.from('profiles').getPublicUrl('$authorId.jpg')
            : 'https://i.pravatar.cc/200';
            
        final postImageUrl = _supabase.storage.from('posts').getPublicUrl('$postId.jpg');

        loadedPosts.add(
          FeedPost(
            id: postId,
            authorId: authorId ?? '',
            authorName: profile?['display_name'] ?? 'ผู้ใช้งานไม่มีชื่อ',
            authorGender: profile?['gender'] == 'female' ? Gender.female : Gender.male,
            authorPhotoUrl: authorPhotoUrl,
            content: item['content'] ?? '(ไม่มีเนื้อหาข้อความ)',
            postedAt: item['created_at'] != null ? DateTime.parse(item['created_at']) : DateTime.now(),
            imageUrl: postImageUrl,
            likes: item['likes_count'] ?? 0,
            comments: item['comments_count'] ?? 0,
            likedByMe: false,
          ),
        );
      }

      setState(() {
        _posts = loadedPosts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Supabase Error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final selected = _filterIndex == i;
                        return GestureDetector(
                          onTap: () => setState(() => _filterIndex = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: selected ? const LinearGradient(colors: [lavenderDark, lavenderLight]) : null,
                              color: selected ? null : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: selected ? Colors.transparent : AppColors.border),
                            ),
                            child: Row(
                              children: [
                                if (i == 0) Icon(Icons.auto_awesome_rounded, size: 14, color: selected ? Colors.white : lavenderDark),
                                if (i == 0) const SizedBox(width: 4),
                                Text(_filters[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.textPrimary)),
                              ],
                            ),
                          ),
                        );
                      },
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
        itemCount: 4,
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
class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({required this.post, required this.lavenderDark, required this.lavenderLight});
  final FeedPost post;
  final Color lavenderDark, lavenderLight;

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
                AvatarImage(url: post.authorPhotoUrl, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textPrimary)),
                          const SizedBox(width: 4),
                          const Icon(Icons.verified, size: 16, color: Color(0xFF3B82F6)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('25 • กรุงเทพฯ • ออนไลน์', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(post.content, style: const TextStyle(fontSize: 15, height: 1.45, color: AppColors.textPrimary)),
          ),
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: NetworkImageBox(url: post.imageUrl!, height: 340, width: double.infinity),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _ReactionBtn(emoji: '💜', count: '${post.likes}', color: const Color(0xFF6366F1)),
                const SizedBox(width: 14),
                const _ReactionBtn(emoji: '🔥', count: '12', color: Color(0xFFEA580C)),
                const SizedBox(width: 14),
                _ReactionBtn(emoji: '✨', count: '6', color: lavenderDark),
              ],
            ),
          ),
        ],
      ),
    );
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