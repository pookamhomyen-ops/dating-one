import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../discover/member_profile_screen.dart';

class LikedMeScreen extends StatefulWidget {
  const LikedMeScreen({super.key});

  @override
  State<LikedMeScreen> createState() => _LikedMeScreenState();
}

class _LikedMeScreenState extends State<LikedMeScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  final Set<String> _likedBack = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final me = Supabase.instance.client.auth.currentUser;
      if (me == null) return;

      // คนที่กดใจเรา
      final data = await Supabase.instance.client
          .from('profile_likes')
          .select('liker_id, profiles!profile_likes_liker_id_fkey(id, display_name, profile_photos(public_url, is_primary, sort_order))')
          .eq('liked_id', me.id)
          .order('created_at', ascending: false);

      // คนที่เรากดใจกลับ
      final myLikes = await Supabase.instance.client
          .from('profile_likes')
          .select('liked_id')
          .eq('liker_id', me.id);

      final Set<String> myLikedIds = (myLikes as List).map((e) => e['liked_id'] as String).toSet();

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _likedBack.addAll(myLikedIds);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('LikedMe error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(String targetId) async {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) return;

    final alreadyLiked = _likedBack.contains(targetId);
    setState(() {
      if (alreadyLiked) {
        _likedBack.remove(targetId);
      } else {
        _likedBack.add(targetId);
      }
    });

    try {
      if (alreadyLiked) {
        await Supabase.instance.client
            .from('profile_likes')
            .delete()
            .eq('liker_id', me.id)
            .eq('liked_id', targetId);
      } else {
        await Supabase.instance.client.from('profile_likes').upsert({
          'liker_id': me.id,
          'liked_id': targetId,
        });
        // สร้าง conversation เมื่อกดใจกลับ
        final ids = [me.id, targetId]..sort();
        await Supabase.instance.client.from('conversations').upsert({
          'user_low_id': ids[0],
          'user_high_id': ids[1],
        });
      }
    } catch (e) {
      // revert
      setState(() {
        if (alreadyLiked) {
          _likedBack.add(targetId);
        } else {
          _likedBack.remove(targetId);
        }
      });
    }
  }

  String _getPhotoUrl(Map<String, dynamic> user) {
    final profile = user['profiles'] as Map<String, dynamic>?;
    final photos = (profile?['profile_photos'] as List? ?? []);
    if (photos.isEmpty) return '';
    final sorted = List.from(photos)
      ..sort((a, b) {
        if (a['is_primary'] == true) return -1;
        if (b['is_primary'] == true) return 1;
        return (a['sort_order'] ?? 999).compareTo(b['sort_order'] ?? 999);
      });
    return sorted.first['public_url'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'คนที่กดใจคุณ',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  if (!_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.iconPurple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_users.length} คน',
                        style: const TextStyle(fontSize: 13, color: AppColors.iconPurple, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.iconPurple))
                  : _users.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.iconPurple,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              final profile = user['profiles'] as Map<String, dynamic>?;
                              final id = profile?['id'] as String? ?? '';
                              final name = profile?['display_name'] as String? ?? '';
                              final photoUrl = _getPhotoUrl(user);
                              final isLikedBack = _likedBack.contains(id);

                              return _UserCard(
                                id: id,
                                name: name,
                                photoUrl: photoUrl,
                                isLiked: isLikedBack,
                                heartColor: isLikedBack ? AppColors.brandPink : AppColors.iconPurple,
                                onHeartTap: () => _toggleLike(id),
                                onNameTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => MemberProfileScreen(memberId: id)),
                                ),
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
          Icon(Icons.favorite_outline_rounded, size: 72, color: AppColors.iconPurple.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('ยังไม่มีคนกดใจคุณ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('อัพเดทโปรไฟล์ให้น่าสนใจขึ้นนะ 💜', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Dart 2 ──────────────────────────────────────────────────────────────────

// (อยู่ในไฟล์เดียวกันเพื่อ reuse _UserCard)
class MyLikesScreen extends StatefulWidget {
  const MyLikesScreen({super.key});

  @override
  State<MyLikesScreen> createState() => _MyLikesScreenState();
}

class _MyLikesScreenState extends State<MyLikesScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  final Set<String> _unlikedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final me = Supabase.instance.client.auth.currentUser;
      if (me == null) return;

      final data = await Supabase.instance.client
          .from('profile_likes')
          .select('liked_id, profiles!profile_likes_liked_id_fkey(id, display_name, profile_photos(public_url, is_primary, sort_order))')
          .eq('liker_id', me.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('MyLikes error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleLike(String targetId) async {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) return;

    final isUnliked = _unlikedIds.contains(targetId);
    setState(() {
      if (isUnliked) {
        _unlikedIds.remove(targetId); // กลับมากดใจ
      } else {
        _unlikedIds.add(targetId); // ยกเลิก
      }
    });

    try {
      if (isUnliked) {
        await Supabase.instance.client.from('profile_likes').upsert({
          'liker_id': me.id,
          'liked_id': targetId,
        });
      } else {
        await Supabase.instance.client
            .from('profile_likes')
            .delete()
            .eq('liker_id', me.id)
            .eq('liked_id', targetId);
      }
    } catch (e) {
      setState(() {
        if (isUnliked) {
          _unlikedIds.add(targetId);
        } else {
          _unlikedIds.remove(targetId);
        }
      });
    }
  }

  String _getPhotoUrl(Map<String, dynamic> user) {
    final profile = user['profiles'] as Map<String, dynamic>?;
    final photos = (profile?['profile_photos'] as List? ?? []);
    if (photos.isEmpty) return '';
    final sorted = List.from(photos)
      ..sort((a, b) {
        if (a['is_primary'] == true) return -1;
        if (b['is_primary'] == true) return 1;
        return (a['sort_order'] ?? 999).compareTo(b['sort_order'] ?? 999);
      });
    return sorted.first['public_url'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'คนที่คุณกดใจ',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  if (!_isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.brandPink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_users.length} คน',
                        style: const TextStyle(fontSize: 13, color: AppColors.brandPink, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brandPink))
                  : _users.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.brandPink,
                          child: GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.72,
                            ),
                            itemCount: _users.length,
                            itemBuilder: (context, index) {
                              final user = _users[index];
                              final profile = user['profiles'] as Map<String, dynamic>?;
                              final id = profile?['id'] as String? ?? '';
                              final name = profile?['display_name'] as String? ?? '';
                              final photoUrl = _getPhotoUrl(user);
                              final isStillLiked = !_unlikedIds.contains(id);

                              return _UserCard(
                                id: id,
                                name: name,
                                photoUrl: photoUrl,
                                isLiked: isStillLiked,
                                heartColor: isStillLiked ? AppColors.brandPink : AppColors.iconPurple,
                                onHeartTap: () => _toggleLike(id),
                                onNameTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => MemberProfileScreen(memberId: id)),
                                ),
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
          Icon(Icons.favorite_border_rounded, size: 72, color: AppColors.brandPink.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text('ยังไม่ได้กดใจใคร', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          const Text('ไปหาคนที่ใช่กันเถอะ 💖', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ── Shared Widget ──────────────────────────────────────────────────────────

class _UserCard extends StatefulWidget {
  final String id;
  final String name;
  final String photoUrl;
  final bool isLiked;
  final Color heartColor;
  final VoidCallback onHeartTap;
  final VoidCallback onNameTap;

  const _UserCard({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.isLiked,
    required this.heartColor,
    required this.onHeartTap,
    required this.onNameTap,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          widget.photoUrl.isNotEmpty
              ? Image.network(widget.photoUrl, fit: BoxFit.cover)
              : Container(
                  color: AppColors.border,
                  child: const Icon(Icons.person, color: AppColors.textSecondary, size: 40),
                ),

          // Bottom gradient + name
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                ),
              ),
              child: GestureDetector(
                onTap: widget.onNameTap,
                child: Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Heart icon top-right
          Positioned(
            top: 6,
            right: 6,
            child: ScaleTransition(
              scale: _scale,
              child: GestureDetector(
                onTap: () {
                  _ctrl.forward(from: 0);
                  widget.onHeartTap();
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.heartColor.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                    color: widget.heartColor,
                    size: 17,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}