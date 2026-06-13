import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'photo_manager_screen.dart';
import 'secret_photo_manager_screen.dart';
import 'account_settings_screen.dart';
import '../../models/user_profile.dart';
import '../../models/gender.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/full_screen_image_viewer.dart';
import 'liked_me_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _user;
  List<String> _secretPhotoUrls = [];
  bool _isLoading = true;
  RealtimeChannel? _likesChannel;
  int _likedMeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _subscribeToLikes();
  }

  void _subscribeToLikes() {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;

    _likesChannel = Supabase.instance.client
        .channel('profile_likes_${authUser.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profile_likes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'liked_id',
            value: authUser.id,
          ),
          callback: (payload) async {
            final res = await Supabase.instance.client
                .from('profile_likes')
                .select('id')
                .eq('liked_id', authUser.id);
            if (mounted) {
              setState(() {
                _likedMeCount = (res as List).length;
                if (_user != null) {
                  _user = _user!.copyWith(profileViews: _likedMeCount);
                }
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _likesChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) return;

      final likesReceivedRes = await Supabase.instance.client
          .from('profile_likes')
          .select('id')
          .eq('liked_id', authUser.id);

      final likesGivenRes = await Supabase.instance.client
          .from('profile_likes')
          .select('id')
          .eq('liker_id', authUser.id);

      final likesReceived = (likesReceivedRes as List).length;
      final likesGiven = (likesGivenRes as List).length;

      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (data != null && mounted) {
        final photosData = await Supabase.instance.client
            .from('profile_photos')
            .select()
            .eq('profile_id', authUser.id)
            .order('is_primary', ascending: false)
            .order('sort_order');

        // Debug raw query result
        debugPrint('\n--- PHOTO QUERY RESULT ---');
        for (var p in (photosData as List)) {
          debugPrint(
            'photo_id: ${p['id']}, sort_order: ${p['sort_order']}, is_primary: ${p['is_primary']}, public_url: ${p['public_url']}',
          );
        }

        final photoUrls = (photosData as List)
            .map((p) => p['public_url'] as String)
            .where((url) => url.isNotEmpty)
            .toList();

        // Debug final URL order
        debugPrint('\n--- FINAL PHOTO URL ORDER ---');
        for (int i = 0; i < photoUrls.length; i++) {
          debugPrint('$i = ${photoUrls[i]}');
        }

        final secretData = await Supabase.instance.client
            .from('secret_photos')
            .select()
            .eq('profile_id', authUser.id)
            .order('sort_order');

        final secretUrls = (secretData as List)
            .map((p) => p['public_url'] as String)
            .where((url) => url.isNotEmpty)
            .toList();

        int age = 0;
        if (data['birth_date'] != null) {
          final birthDate = DateTime.parse(data['birth_date']);
          age = DateTime.now().year - birthDate.year;
          if (DateTime.now().month < birthDate.month ||
              (DateTime.now().month == birthDate.month &&
                  DateTime.now().day < birthDate.day)) {
            age--;
          }
        }

        final gender = Gender.values.firstWhere(
          (e) => e.name == data['gender'],
          orElse: () => Gender.other,
        );

        setState(() {
          _secretPhotoUrls = secretUrls;
        });

        final likedMeResult = await Supabase.instance.client
            .from('profile_likes')
            .select()
            .eq('liked_id', authUser.id);
        final myLikesResult = await Supabase.instance.client
            .from('profile_likes')
            .select()
            .eq('liker_id', authUser.id);

        final likedMeCount = (likedMeResult as List).length;
        final myLikesCount = (myLikesResult as List).length;

        if (mounted) {
          setState(() {
            _user = UserProfile(
              id: data['id'],
              name: data['display_name'] ?? 'ไม่มีชื่อ',
              gender: gender,
              age: age,
              province: data['province'] ?? '',
              district: data['district'] ?? '',
              photoUrls: photoUrls,
              bio: data['bio'] ?? '',
              interests: [],
              profileViews: likedMeCount,
              likesReceived: myLikesCount,
              lineId: data['line_id'] ?? '',
              instagram: data['instagram'] ?? '',
              xHandle: data['x_handle'] ?? '',
              facebook: data['facebook'] ?? '',
            );
            _likedMeCount = likedMeCount;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _viewFullScreen(List<String> urls, int index, {bool isPrivate = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(
          urls: urls,
          initialIndex: index,
          isPrivate: isPrivate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_user == null) {
      return const Scaffold(body: Center(child: Text('ไม่พบข้อมูลผู้ใช้')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _loadUserData,
          child: CustomScrollView(
            slivers: [
              // 1. Header Gallery
              SliverToBoxAdapter(
                child: _ProfileHeader(
                  user: _user!,
                  onPhotosUpdated: _loadUserData,
                  onPhotoTap: (index) =>
                      _viewFullScreen(_user!.photoUrls, index),
                ),
              ),
              // 2. ข้อมูลผู้ใช้
              SliverToBoxAdapter(
                child: _ProfileInfoCard(user: _user!),
              ),
              // 3. ส่วนความสนใจและรูปภาพอื่นๆ
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Column(
                    children: [
                      if (_user!.interests.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _SectionTitle(title: 'ความสนใจ'),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _user!.interests
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: AppColors.background,
                                  side: BorderSide(
                                    color: AppColors.accent.withOpacity(
                                      0.1,
                                    ),
                                  ),
                                  labelStyle: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.accent,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (_user!.photoUrls.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _SectionTitle(title: 'รูปโปรไฟล์'),
                            _SectionSettingsButton(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PhotoManagerScreen(userId: _user!.id),
                                  ),
                                );
                                _loadUserData();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _user!.photoUrls.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) => GestureDetector(
                              onTap: () =>
                                  _viewFullScreen(_user!.photoUrls, i),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.textPrimary
                                          .withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: NetworkImageBox(
                                  url: _user!.photoUrls[i],
                                  width: 90,
                                  height: 120,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _SectionTitle(title: 'รูปส่วนตัว'),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFFB300)
                                        .withOpacity(0.4),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 13,
                                  color: Color(0xFFFFB300),
                                ),
                              ),
                            ],
                          ),
                          _SectionSettingsButton(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SecretPhotoManagerScreen(
                                    userId: _user!.id,
                                  ),
                                ),
                              );
                              _loadUserData();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_secretPhotoUrls.isEmpty)
                        Container(
                          width: double.infinity,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.background,
                              width: 2,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'ยังไม่มีรูปส่วนตัว กด + เพื่อเพิ่ม',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _secretPhotoUrls.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) => GestureDetector(
                              onTap: () => _viewFullScreen(
                                _secretPhotoUrls,
                                i,
                                isPrivate: true,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.textPrimary
                                          .withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    children: [
                                      SizedBox(
                                        width: 90,
                                        height: 120,
                                        child: Image.network(
                                          _secretPhotoUrls[i],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                              sigmaX: 5, sigmaY: 5),
                                          child: Container(
                                            color:
                                                Colors.black.withOpacity(0.05),
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
                      const SizedBox(height: 48),
                      _SettingsButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AccountSettingsScreen(),
                            ),
                          );
                          _loadUserData();
                        },
                      ),
                      const SizedBox(height: 24),
                      _StatsRow(
                        likedMeCount: _user!.profileViews,
                        myLikesCount: _user!.likesReceived,
                        onLikedMeTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LikedMeScreen()),
                        ),
                        onMyLikesTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MyLikesScreen()),
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SettingsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.background,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings_rounded, size: 24),
            SizedBox(width: 12),
            Text(
              'การตั้งค่าบัญชี',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({
    required this.user,
    required this.onPhotosUpdated,
    required this.onPhotoTap,
  });

  final UserProfile user;
  final VoidCallback onPhotosUpdated;
  final Function(int) onPhotoTap;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photoUrls = widget.user.photoUrls;
    final screenHeight = MediaQuery.of(context).size.height;
    final user = widget.user;

    return Stack(
      children: [
        // ── รูปภาพ ──
        GestureDetector(
          onTapDown: (details) {
            if (photoUrls.length <= 1) return;
            final half = MediaQuery.of(context).size.width / 2;
            final isRight = details.globalPosition.dx > half;
            if (isRight && _currentPage < photoUrls.length - 1) {
              final next = _currentPage + 1;
              setState(() => _currentPage = next);
              _pageController.animateToPage(next,
                  duration: const Duration(milliseconds: 50),
                  curve: Curves.linear);
            } else if (!isRight && _currentPage > 0) {
              final prev = _currentPage - 1;
              setState(() => _currentPage = prev);
              _pageController.animateToPage(prev,
                  duration: const Duration(milliseconds: 50),
                  curve: Curves.linear);
            }
          },
          onLongPress: () => widget.onPhotoTap(_currentPage),
          child: SizedBox(
            height: screenHeight * 0.65,
            width: double.infinity,
            child: photoUrls.isEmpty
                ? Container(
                    color: AppColors.textSecondary,
                    child: const Icon(Icons.person, size: 100),
                  )
                : ColorFiltered(
                    colorFilter: ColorFilter.matrix([
                      1.08, 0,    0,    0, 0,
                      0,    1.05, 0,    0, 0,
                      0,    0,    1.02, 0, 0,
                      0,    0,    0,    1, 0,
                    ]),
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: photoUrls.length,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (context, index) => Image.network(
                        photoUrls[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
          ),
        ),

        // Layer 2 — Vignette รอบขอบ
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.3,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.10),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Layer 3 — Gradient ด้านล่าง
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.52),
                  ],
                  stops: const [0.0, 0.50, 0.75, 1.0],
                ),
              ),
            ),
          ),
        ),

        // ── indicator bar ──
        if (photoUrls.length > 1)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: List.generate(
                photoUrls.length,
                (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? AppColors.background
                          : AppColors.background.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // ── โปรไฟล์ Avatar ──
        Positioned(
          top: 60,
          right: 16,
          child: _ProfileAvatarButton(
            photoUrl: widget.user.primaryPhoto,
          ),
        ),

        // ── bio overlay ──
        if (user.bio.isNotEmpty)
          Positioned(
            bottom: 44,
            left: 20,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.68,
              ),
              child: Text(
                user.bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.background.withValues(alpha: 0.92),
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ชื่อ + อายุ
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${user.age} ปี',
                style: const TextStyle(
                  fontSize: 24,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              const _SettingsIconButton(),
            ],
          ),
          const SizedBox(height: 16),
          // เพศ
          _InfoLine(
            icon: user.gender == Gender.female
                ? Icons.female_rounded
                : Icons.male_rounded,
            text: user.gender.labelTh,
            iconColor: user.gender == Gender.female
                ? AppColors.iconPink
                : AppColors.iconBlue,
          ),
          const SizedBox(height: 12),
          // ที่อยู่
          _InfoLine(
            icon: Icons.location_on_rounded,
            text: '${user.district}, ${user.province}',
            iconColor: AppColors.iconOrange,
          ),
          const SizedBox(height: 24),
          // ช่องทางติดต่อ
          const Text(
            'ช่องทางติดต่อ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          if (user.lineId.isNotEmpty)
            _SocialInfoTile(
                label: 'Line ID',
                value: user.lineId,
                color: AppColors.iconGreen,
                badgeText: 'LINE'),
          if (user.instagram.isNotEmpty) ...[
            if (user.lineId.isNotEmpty) const SizedBox(height: 12),
            _SocialInfoTile(
                label: 'Instagram',
                value: user.instagram,
                color: AppColors.iconPink,
                badgeText: 'IG'),
          ],
          if (user.xHandle.isNotEmpty) ...[
            if (user.lineId.isNotEmpty || user.instagram.isNotEmpty)
              const SizedBox(height: 12),
            _SocialInfoTile(
                label: 'X (Twitter)',
                value: user.xHandle,
                color: AppColors.textPrimary,
                badgeText: 'X'),
          ],
          if (user.facebook.isNotEmpty) ...[
            if (user.lineId.isNotEmpty ||
                user.instagram.isNotEmpty ||
                user.xHandle.isNotEmpty)
              const SizedBox(height: 12),
            _SocialInfoTile(
                label: 'Facebook',
                value: user.facebook,
                color: AppColors.iconBlue,
                badgeText: 'FB'),
          ],
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.likedMeCount,
    required this.myLikesCount,
    required this.onLikedMeTap,
    required this.onMyLikesTap,
  });

  final int likedMeCount;
  final int myLikesCount;
  final VoidCallback onLikedMeTap;
  final VoidCallback onMyLikesTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onLikedMeTap,
                child: _StatCard(
                  icon: Icons.favorite_rounded,
                  label: 'คนเข้ามาดู',
                  value: _formatCount(likedMeCount),
                  color: AppColors.iconPurple,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onMyLikesTap,
                child: _StatCard(
                  icon: Icons.thumb_up_rounded,
                  label: 'กดใจ',
                  value: _formatCount(myLikesCount),
                  color: AppColors.brandPink,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.close_rounded,
                label: 'คุณกดผ่าน',
                value: '0',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.visibility_outlined,
                label: 'เข้ามาดูคุณ',
                value: '0',
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _InfoLine({
    required this.icon,
    required this.text,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String badgeText;

  const _SocialInfoTile({
    required this.label,
    required this.value,
    required this.color,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileChatButton extends StatefulWidget {
  final bool isOnline;

  const _ProfileChatButton({required this.isOnline});

  @override
  State<_ProfileChatButton> createState() => _ProfileChatButtonState();
}

class _ProfileChatButtonState extends State<_ProfileChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          _controller.forward(from: 0.0);
          // Logic เปิดแชท
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isOnline
                  ? [const Color(0xFF00E676), const Color(0xFF00C853)]
                  : [AppColors.brandPink, const Color(0xFFE91E63)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (widget.isOnline
                        ? const Color(0xFF00C853)
                        : AppColors.brandPink)
                    .withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'แชท',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.isOnline) ...[
                const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isFilled;

  const _ProfileActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isFilled = false,
  });

  @override
  State<_ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<_ProfileActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          _controller.forward(from: 0.0);
          widget.onTap();
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: widget.isFilled ? widget.color : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isFilled ? Colors.transparent : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: widget.isFilled ? AppColors.background : widget.color,
            size: 32,
          ),
        ),
      ),
    );
  }
}

class _SettingsIconButton extends StatefulWidget {
  const _SettingsIconButton();

  @override
  State<_SettingsIconButton> createState() => _SettingsIconButtonState();
}

class _SettingsIconButtonState extends State<_SettingsIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotateAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rotateAnim = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _ctrl.forward(from: 0.0),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.rotate(
            angle: _rotateAnim.value * 3.14159,
            child: child,
          ),
        ),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.settings_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatarButton extends StatefulWidget {
  final String photoUrl;
  const _ProfileAvatarButton({required this.photoUrl});

  @override
  State<_ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends State<_ProfileAvatarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1750),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.06), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glowAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 80),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _ctrl.forward(from: 0.0),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPink.withOpacity(0.5 * _glowAnim.value),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: child,
          ),
        ),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.background.withOpacity(0.9),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipOval(
            child: widget.photoUrl.isNotEmpty
                ? Image.network(
                    widget.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.textSecondary,
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 28),
                    ),
                  )
                : Container(
                    color: AppColors.textSecondary,
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
          ),
        ),
      ),
    );
  }
}

class _SectionSettingsButton extends StatefulWidget {
  final VoidCallback onTap;
  const _SectionSettingsButton({required this.onTap});

  @override
  State<_SectionSettingsButton> createState() => _SectionSettingsButtonState();
}

class _SectionSettingsButtonState extends State<_SectionSettingsButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _rotateAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rotateAnim = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward(from: 0.0);
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: Transform.rotate(
            angle: _rotateAnim.value * 3.14159,
            child: child,
          ),
        ),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.settings_rounded,
            size: 18,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
