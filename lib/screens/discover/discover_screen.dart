import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'member_profile_screen.dart';
import '../../models/member.dart';
import '../../models/gender.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../../widgets/soulive_header.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  List<Member> _members = [];
  bool _isLoading = true;
  bool _nearMeActive = true;
  String _genderFilter = 'ทุกเพศ';
  final Set<String> _likedIds = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final currentUserId = client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final myProfile = await client
          .from('profiles')
          .select('latitude, longitude')
          .eq('id', currentUserId)
          .single();

      final double myLat = (myProfile['latitude'] as num?)?.toDouble() ?? 0.0;
      final double myLon = (myProfile['longitude'] as num?)?.toDouble() ?? 0.0;

      final response = await client
          .from('profiles')
          .select('''
            *,
            profile_photos(public_url, is_primary, sort_order),
            profile_interests(interests(name))
          ''')
          .neq('id', currentUserId);

      final List<Member> loadedMembers = [];

      for (var row in response as List) {
        Gender gender;
        switch (row['gender']) {
          case 'female':
            gender = Gender.female;
            break;
          case 'male':
            gender = Gender.male;
            break;
          default:
            gender = Gender.other;
        }

        int age = 0;
        if (row['birth_date'] != null) {
          final birthDate = DateTime.parse(row['birth_date']);
          final today = DateTime.now();
          age = today.year - birthDate.year;
          if (today.month < birthDate.month ||
              (today.month == birthDate.month && today.day < birthDate.day)) {
            age--;
          }
        }

        int? lastActiveMinutes;
        if (row['last_seen_at'] != null) {
          final lastSeen = DateTime.parse(row['last_seen_at']);
          lastActiveMinutes = DateTime.now().difference(lastSeen).inMinutes;
        }

        final double lat = (row['latitude'] as num?)?.toDouble() ?? 0.0;
        final double lon = (row['longitude'] as num?)?.toDouble() ?? 0.0;
        final double distanceKm = _calculateDistance(myLat, myLon, lat, lon);

        String photoUrl = '';
        final photos = (row['profile_photos'] as List? ?? []);
        if (photos.isNotEmpty) {
          final sortedPhotos = List.from(photos)
            ..sort((a, b) {
              if (a['is_primary'] == true && b['is_primary'] != true) return -1;
              if (a['is_primary'] != true && b['is_primary'] == true) return 1;
              return (a['sort_order'] as int? ?? 999).compareTo(
                b['sort_order'] as int? ?? 999,
              );
            });
          photoUrl = sortedPhotos.first['public_url'] ?? '';
        }

        final List<String> interests = [];
        final piList = (row['profile_interests'] as List? ?? []);
        for (var pi in piList) {
          final name = pi['interests']?['name'];
          if (name != null) interests.add(name as String);
        }

        loadedMembers.add(
          Member(
            id: row['id'],
            name: row['display_name'] ?? 'ไม่มีชื่อ',
            gender: gender,
            age: age,
            province: row['province'] ?? '',
            district: row['district'] ?? '',
            distanceKm: distanceKm,
            photoUrl: photoUrl,
            university: row['university'] ?? '',
            occupation: row['occupation'] ?? '',
            interests: interests,
            isOnline: row['is_online'] ?? false,
            lastActiveMinutes: lastActiveMinutes,
            isVerified: row['is_verified'] ?? false,
            bio: row['bio'] ?? '',
          ),
        );
      }

      loadedMembers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      setState(() {
        _members = loadedMembers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading members: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
        );
      }
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const r = 6371;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  @override
  Widget build(BuildContext context) {
    final likedMembers = _members.where((m) => _likedIds.contains(m.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SouliveHeader()),
                  
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ถูกใจล่าสุด',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF561B4D),
                            ),
                          ),
                          const SizedBox(height: 10),
                          likedMembers.isEmpty
                              ? const SizedBox(
                                  height: 90,
                                  child: Center(
                                    child: Text(
                                      'ยังไม่มีรายการถูกใจล่าสุด',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 90,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: likedMembers.length,
                                    itemBuilder: (context, index) {
                                      final member = likedMembers[index];
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MemberProfileScreen(
                                                memberId: member.id,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(right: 16),
                                          child: Column(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(2.5),
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.pinkAccent,
                                                      Colors.purpleAccent
                                                    ],
                                                  ),
                                                ),
                                                child: Container(
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  padding: const EdgeInsets.all(2),
                                                  child: CircleAvatar(
                                                    radius: 26,
                                                    backgroundColor: Colors.grey[200],
                                                    backgroundImage: member.photoUrl.isNotEmpty
                                                        ? NetworkImage(member.photoUrl)
                                                        : null,
                                                    child: member.photoUrl.isEmpty
                                                        ? const Icon(Icons.person, color: Colors.grey)
                                                        : null,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              SizedBox(
                                                width: 60,
                                                child: Text(
                                                  member.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.textPrimary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: _FilterBar(
                        nearMeActive: _nearMeActive,
                        genderLabel: _genderFilter,
                        onNearMe: () =>
                            setState(() => _nearMeActive = !_nearMeActive),
                        onFilter: () {},
                        onGender: () => _showGenderSheet(),
                        onSearch: () {},
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: _members.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    MemberProfileScreen(memberId: member.id),
                              ),
                            );
                          },
                          child: _MemberCard(
                            member: member,
                            liked: _likedIds.contains(member.id),
                            onLike: () {
                              setState(() {
                                if (_likedIds.contains(member.id)) {
                                  _likedIds.remove(member.id);
                                } else {
                                  _likedIds.add(member.id);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _showGenderSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
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
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'เลือกเพศ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              for (final label in ['ทุกเพศ', 'หญิง', 'ชาย', 'อื่นๆ'])
                ListTile(
                  title: Text(label),
                  trailing: _genderFilter == label
                      ? Icon(Icons.check, color: AppColors.brandPink)
                      : null,
                  onTap: () {
                    setState(() => _genderFilter = label);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
          );
      },
    );
  }
}

// ── FilterBar ────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.nearMeActive,
    required this.genderLabel,
    required this.onNearMe,
    required this.onFilter,
    required this.onGender,
    required this.onSearch,
  });

  final bool nearMeActive;
  final String genderLabel;
  final VoidCallback onNearMe;
  final VoidCallback onFilter;
  final VoidCallback onGender;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                _FilterPill(
                  label: 'ใกล้ฉัน',
                  icon: Icons.near_me_outlined,
                  filled: nearMeActive,
                  onTap: onNearMe,
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: 'ตัวกรอง',
                  icon: Icons.tune_rounded,
                  onTap: onFilter,
                ),
                const SizedBox(width: 8),
                _FilterPill(
                  label: genderLabel,
                  icon: Icons.wc_outlined,
                  onTap: onGender,
                  maxLabelWidth: 88,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _SearchButton(onTap: onSearch),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    this.filled = false,
    required this.onTap,
    this.maxLabelWidth,
  });
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  final double? maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? AppColors.navy : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: filled ? null : Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: filled ? AppColors.background : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxLabelWidth ?? 120),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: filled ? AppColors.background : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.search,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── MemberCard ───────────────────────────────────────────

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.liked,
    required this.onLike,
  });
  final Member member;
  final bool liked;
  final VoidCallback onLike;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _ProfilePhoto(member: member),
            const SizedBox(width: 14),
            Expanded(
              child: SizedBox(
                height: 110, // 🔒 ล็อกความสูงให้เท่ากับรูปภาพเป๊ะ เพื่อไม่ให้ตำแหน่งกระโดด
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // 🔒 ตรึงชื่อไว้บนสุด ตรึงสเตตัสไว้ล่างสุด
                  children: [
                    // บรรทัดบนสุด: ชื่อและอายุ
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.cake_outlined,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${member.age}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    
                    // บรรทัดกลาง: แยก อำเภอ และ จังหวัด พร้อมใส่ Emoji สวยๆ นำหน้า
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (member.district.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Text('📍 ', style: TextStyle(fontSize: 11)),
                                    Expanded(
                                      child: Text(
                                        member.district,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2), // ระยะห่างกระชับพิเศษไม่ให้เบียดบนล่าง
                              ],
                              if (member.province.isNotEmpty)
                                Row(
                                  children: [
                                    const Text('🗺️ ', style: TextStyle(fontSize: 11)),
                                    Expanded(
                                      child: Text(
                                        member.province,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        
                        // 🔒 ตรึงตำแหน่งปุ่มกดให้อยู่ที่เดิม ไม่ขยับตามบรรทัดข้อความ
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: AppColors.surface,
                              shape: const CircleBorder(),
                              elevation: 1,
                              shadowColor: AppColors.textPrimary,
                              child: InkWell(
                                onTap: () {},
                                customBorder: const CircleBorder(),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _LikeButton(liked: liked, onTap: onLike),
                          ],
                        ),
                      ],
                    ),
                    
                    // บรรทัดล่างสุด: สเตตัส (Bio) ตรึงไว้ขอบล่างของรูปภาพพอดี
                    Text(
                      member.bio,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── ProfilePhoto ─────────────────────────────────────────

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.member});
  final Member member;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: NetworkImageBox(
              url: member.photoUrl,
              width: double.infinity,
              height: double.infinity,
              borderRadius: 8,
            ),
          ),
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 12,
                    color: AppColors.background,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${member.distanceKm.toStringAsFixed(1)} กม.',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.background,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── LikeButton ───────────────────────────────────────────

class _LikeButton extends StatefulWidget {
  const _LikeButton({required this.liked, required this.onTap});
  final bool liked;
  final VoidCallback onTap;

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton>
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
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 50),
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
      child: Material(
        color: widget.liked ? AppColors.brandPink : AppColors.surface,
        shape: const CircleBorder(),
        elevation: widget.liked ? 6 : 3,
        shadowColor: widget.liked
            ? AppColors.brandPink.withValues(alpha: 0.4)
            : AppColors.textPrimary,
        child: InkWell(
          onTap: () {
            _controller.forward(from: 0.0);
            widget.onTap();
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.liked
                    ? Colors.transparent
                    : AppColors.brandPink.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              widget.liked ? Icons.favorite : Icons.favorite_border,
              color: widget.liked ? AppColors.background : AppColors.brandPink,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}