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

      // 7. โหลด profile ของ user ปัจจุบันก่อน
      final myProfile = await client
          .from('profiles')
          .select('latitude, longitude')
          .eq('id', currentUserId)
          .single();

      final double myLat = (myProfile['latitude'] as num?)?.toDouble() ?? 0.0;
      final double myLon = (myProfile['longitude'] as num?)?.toDouble() ?? 0.0;

      // 8-10. โหลด profiles ของผู้ใช้อื่นพร้อมรูปและ interests
      final response = await client.from('profiles').select('''
            *,
            profile_photos(public_url, is_primary, sort_order),
            profile_interests(interests(name))
          ''').neq('id', currentUserId);

      final List<Member> loadedMembers = [];

      for (var row in response as List) {
        // 12. แปลง gender
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

        // 13. คำนวณ age
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

        // 14. คำนวณ lastActiveMinutes
        int? lastActiveMinutes;
        if (row['last_seen_at'] != null) {
          final lastSeen = DateTime.parse(row['last_seen_at']);
          lastActiveMinutes = DateTime.now().difference(lastSeen).inMinutes;
        }

        // 15. คำนวณ distanceKm (Haversine Formula)
        final double lat = (row['latitude'] as num?)?.toDouble() ?? 0.0;
        final double lon = (row['longitude'] as num?)?.toDouble() ?? 0.0;
        final double distanceKm = _calculateDistance(myLat, myLon, lat, lon);

        // 9. เลือกรูปตามลำดับ
        String photoUrl = '';
        final photos = (row['profile_photos'] as List? ?? []);
        if (photos.isNotEmpty) {
          final sortedPhotos = List.from(photos)
            ..sort((a, b) {
              if (a['is_primary'] == true && b['is_primary'] != true) return -1;
              if (a['is_primary'] != true && b['is_primary'] == true) return 1;
              return (a['sort_order'] as int? ?? 999)
                  .compareTo(b['sort_order'] as int? ?? 999);
            });
          photoUrl = sortedPhotos.first['public_url'] ?? '';
        }

        // 10. โหลด interests
        final List<String> interests = [];
        final piList = (row['profile_interests'] as List? ?? []);
        for (var pi in piList) {
          final name = pi['interests']?['name'];
          if (name != null) interests.add(name as String);
        }

        // 11. สร้าง Member
        loadedMembers.add(Member(
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
        ));
      }

      // 16. เรียงตามระยะทาง
      loadedMembers.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      setState(() {
        _members = loadedMembers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading members: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        // 19. แสดง SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')),
        );
      }
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // km
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double get _nearestKm =>
      _members.isEmpty ? 0 : _members.first.distanceKm;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(
                    child: SouliveHeader(
                      showGreeting: true,
                      showLikesBanner: true,
                      likesCount: 12,
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppColors.brandPink,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ผู้ใช้ใกล้คุณ (${_formatKm(_nearestKm)})',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverList.separated(
                      itemCount: _members.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MemberProfileScreen(memberId: member.id),
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

  String _formatKm(double km) {
    if (km < 1) return '${(km * 1000).round()} ม.';
    final rounded = km == km.roundToDouble()
        ? km.toInt().toString()
        : km.toStringAsFixed(1);
    return '$rounded กม.';
  }

  void _showGenderSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              for (final label in ['ทุกเพศ', 'หญิง', 'ชาย', 'อื่นๆ'])
                ListTile(
                  title: Text(label),
                  trailing: _genderFilter == label
                      ? const Icon(Icons.check, color: AppColors.brandPink)
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
              color: filled ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxLabelWidth ?? 120,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.white : AppColors.textPrimary,
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
    final bg = AppColors.cardBackground(member.gender);
    final border = AppColors.cardBorder(member.gender);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfilePhoto(member: member),
            const SizedBox(width: 12),
            Expanded(child: _MemberInfo(member: member)),
            const SizedBox(width: 4),
            _LikeButton(liked: liked, onTap: onLike),
          ],
        ),
      ),
    );
  }
}

class _ProfilePhoto extends StatelessWidget {
  const _ProfilePhoto({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 128,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: NetworkImageBox(
              url: member.photoUrl,
              width: 108,
              height: 128,
              borderRadius: 14,
            ),
          ),
          Positioned(
            top: 6,
            left: 6,
            right: 6,
            child: _StatusBadge(member: member),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    final online = member.isOnline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: online ? const Color(0xFF4ADE80) : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              member.statusLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberInfo extends StatelessWidget {
  const _MemberInfo({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                '${member.name}, ${member.age}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (member.isVerified) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: AppColors.verified,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        _DetailLine(icon: Icons.school_outlined, text: member.university),
        const SizedBox(height: 4),
        _DetailLine(icon: Icons.work_outline, text: member.occupation),
        const SizedBox(height: 4),
        _DetailLine(
          icon: Icons.location_on_outlined,
          text: '${_distanceText(member.distanceKm)} จากคุณ',
        ),
        if (member.interests.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: member.interests
                .take(3)
                .map((tag) => _InterestChip(label: tag))
                .toList(),
          ),
        ],
      ],
    );
  }

  String _distanceText(double km) {
    if (km < 1) return '${(km * 1000).round()} ม.';
    final v = km == km.roundToDouble() ? km.toInt() : km;
    return '$v กม.';
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.chipBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _LikeButton extends StatelessWidget {
  const _LikeButton({required this.liked, required this.onTap});

  final bool liked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: liked ? AppColors.brandPink : AppColors.surface,
      shape: const CircleBorder(),
      elevation: liked ? 0 : 1,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: liked ? null : Border.all(color: AppColors.border),
          ),
          child: Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            color: liked ? Colors.white : AppColors.brandPink,
            size: 22,
          ),
        ),
      ),
    );
  }
}
