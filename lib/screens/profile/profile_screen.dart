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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _user;
  List<String> _secretPhotoUrls = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) return;

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
            profileViews: data['profile_views_count'] ?? 0,
            likesReceived: data['likes_received_count'] ?? 0,
            lineId: data['line_id'] ?? '',
            instagram: data['instagram'] ?? '',
            xHandle: data['x_handle'] ?? '',
            facebook: data['facebook'] ?? '',
          );
        });
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
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _ProfileHeader(
                      user: _user!,
                      onPhotosUpdated: _loadUserData,
                      onPhotoTap: (index) =>
                          _viewFullScreen(_user!.photoUrls, index),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(32),
                        ),
                      ),
                      transform: Matrix4.translationValues(0, -32, 0),
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                      child: Column(
                        children: [
                          _StatsRow(
                            views: _user!.profileViews,
                            likes: _user!.likesReceived,
                          ),
                          const SizedBox(height: 24),
                          _SectionTitle(title: 'ข้อมูลส่วนตัว'),
                          const SizedBox(height: 10),
                          _InfoCard(user: _user!),
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
                            _SectionTitle(title: 'รูปภาพ'),
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
                              _SectionTitle(title: 'รูปส่วนตัว 🔒'),
                              IconButton(
                                onPressed: () async {
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
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.brandPink,
                                ),
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
                                              .withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            _secretPhotoUrls[i],
                                            width: 90,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                          Positioned.fill(
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 8,
                                                sigmaY: 8,
                                              ),
                                              child: Container(
                                                color: AppColors.textPrimary,
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
                          const SizedBox(height: 120),
                        ],
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
    if (photoUrls.isNotEmpty) {
      debugPrint('\n--- PROFILE HEADER FIRST PHOTO ---');
      debugPrint('photoUrls.first: ${photoUrls.first}');
    }

    return Container(
      width: double.infinity,
      color: AppColors.textPrimary, // Profile picture area background is black
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 3 / 4, // Changed to 3:4
                child: photoUrls.isEmpty
                    ? Container(
                        color: AppColors.textSecondary,
                        child: const Icon(
                          Icons.person,
                          size: 120,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : PageView.builder(
                        controller: _pageController,
                        itemCount: photoUrls.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => widget.onPhotoTap(index),
                            child: Image.network(
                              photoUrls[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
              ),
              Positioned(
                top: 60,
                right: 20,
                child: GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PhotoManagerScreen(userId: widget.user.id),
                      ),
                    );
                    widget.onPhotosUpdated();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.background.withOpacity(0.3),
                      ),
                    ),
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.background,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (photoUrls.length > 1)
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      photoUrls.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AppColors.background.withOpacity(
                            _currentPage == index ? 1.0 : 0.4,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.textPrimary.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
            ),
            transform: Matrix4.translationValues(0, -32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -1,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${widget.user.age}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      widget.user.gender == Gender.female
                          ? Icons.female_rounded
                          : Icons.male_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.user.gender.labelTh,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Icon(
                      Icons.location_on_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${widget.user.district}, ${widget.user.province}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (widget.user.bio.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.background.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: Text(
                      widget.user.bio,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.views, required this.likes});

  final int views;
  final int likes;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.visibility_outlined,
            label: 'คนเข้ามาดู',
            value: _formatCount(views),
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_outline,
            label: 'กดใจ',
            value: _formatCount(likes),
            color: AppColors.accent,
          ),
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          if (user.lineId.isNotEmpty)
            _SocialLine(emoji: '💬', label: 'Line', value: user.lineId),
          if (user.instagram.isNotEmpty) ...[
            if (user.lineId.isNotEmpty) const Divider(height: 16),
            _SocialLine(emoji: '📸', label: 'IG', value: user.instagram),
          ],
          if (user.xHandle.isNotEmpty) ...[
            if (user.lineId.isNotEmpty || user.instagram.isNotEmpty)
              const Divider(height: 16),
            _SocialLine(emoji: '✖️', label: 'X', value: user.xHandle),
          ],
          if (user.facebook.isNotEmpty) ...[
            if (user.lineId.isNotEmpty ||
                user.instagram.isNotEmpty ||
                user.xHandle.isNotEmpty)
              const Divider(height: 16),
            _SocialLine(emoji: '📘', label: 'Facebook', value: user.facebook),
          ],
        ],
      ),
    );
  }
}

class _SocialLine extends StatelessWidget {
  const _SocialLine({
    required this.emoji,
    required this.label,
    required this.value,
  });

  final String emoji;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
