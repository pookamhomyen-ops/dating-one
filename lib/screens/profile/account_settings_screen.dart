import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import 'profile_setup_screen.dart';
import 'profile_setup_step1_screen.dart';
import 'profile_setup_step2_screen.dart';
import 'profile_setup_step3_screen.dart';
import '../../models/gender.dart';
import '../auth/login_screen.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'ออกจากระบบ',
              style: TextStyle(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    return Supabase.instance.client
        .from('profiles')
        .select('display_name, gender, birth_date, province, district, relationship_status, broken_heart_days, current_activity, bio, hated_type, interests, line_id, instagram, twitter, facebook')
        .eq('id', user.id)
        .maybeSingle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _loadProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final name = profile?['display_name'] as String? ?? '';
          final genderStr = profile?['gender'] as String? ?? '';
          final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _ProfileHeroHeader(
                  initials: initials,
                  name: name,
                  genderStr: genderStr,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(label: 'ข้อมูลส่วนตัว'),
                      const SizedBox(height: 8),
                      _MenuGroup(
                        items: [
                          _MenuItem(
                            iconData: Icons.person_outline_rounded,
                            iconBg: AppColors.brandPink.withValues(alpha: 0.12),
                            iconColor: AppColors.brandPink,
                            title: 'โปรไฟล์หลัก',
                            subtitle: 'ชื่อ, เพศ, วันเกิด',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileSetupStep1Screen(isEditMode: true),
                              ),
                            ),
                          ),
                          _MenuItem(
                            iconData: Icons.location_on_outlined,
                            iconBg: AppColors.iconPurple.withValues(alpha: 0.12),
                            iconColor: AppColors.iconPurple,
                            title: 'ที่อยู่และสถานะ',
                            subtitle: 'อำเภอ, จังหวัด, สถานะหัวใจ',
                            onTap: () {
                              if (profile == null) return;
                              Gender gender = Gender.values.firstWhere(
                                (e) => e.name == genderStr,
                                orElse: () => Gender.other,
                              );
                              DateTime birthDate = DateTime(2000);
                              if (profile['birth_date'] != null) {
                                birthDate = DateTime.parse(profile['birth_date']);
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileSetupStep2Screen(
                                    name: name,
                                    gender: gender,
                                    birthDate: birthDate,
                                    isEditMode: true,
                                  ),
                                ),
                              );
                            },
                          ),
                          _MenuItem(
                            iconData: Icons.interests_outlined,
                            iconBg: AppColors.iconTeal.withValues(alpha: 0.12),
                            iconColor: AppColors.iconTeal,
                            title: 'ความสนใจและโซเชียล',
                            subtitle: 'Line, IG, X, Facebook, สิ่งที่ชอบ/ไม่ชอบ',
                            onTap: () {
                              if (profile == null) return;
                              Gender gender = Gender.values.firstWhere(
                                (e) => e.name == genderStr,
                                orElse: () => Gender.other,
                              );
                              DateTime birthDate = DateTime(2000);
                              if (profile['birth_date'] != null) {
                                birthDate = DateTime.parse(profile['birth_date']);
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileSetupStep3Screen(
                                    name: name,
                                    gender: gender,
                                    birthDate: birthDate,
                                    province: profile['province'] ?? '',
                                    district: profile['district'] ?? '',
                                    status: profile['relationship_status'] ?? 'โสด',
                                    brokenHeartDays: profile['broken_heart_days'] ?? 0,
                                    activity: profile['current_activity'] ?? 'ทำงาน',
                                    bio: profile['bio'] ?? '',
                                    isEditMode: true,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(label: 'บัญชี'),
                      const SizedBox(height: 8),
                      _MenuGroup(
                        items: [
                          _MenuItem(
                            iconData: Icons.logout_rounded,
                            iconBg: AppColors.destructive.withValues(alpha: 0.12),
                            iconColor: AppColors.destructive,
                            title: 'ออกจากระบบ',
                            titleColor: AppColors.destructive,
                            onTap: () => _handleLogout(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeroHeader extends StatelessWidget {
  final String initials;
  final String name;
  final String genderStr;

  const _ProfileHeroHeader({
    required this.initials,
    required this.name,
    required this.genderStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandPink,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'บัญชีของฉัน',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.25),
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (name.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  genderStr == 'female'
                      ? 'หญิง'
                      : genderStr == 'male'
                          ? 'ชาย'
                          : 'อื่นๆ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuGroup({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final isLast = entry.key == items.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 1, color: AppColors.border),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData iconData;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  const _MenuItem({
    required this.iconData,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 15,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
