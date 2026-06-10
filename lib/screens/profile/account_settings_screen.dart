import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import 'profile_setup_screen.dart';
import '../auth/login_screen.dart';

// ✅ เรียกพาร์ทตรงจากโฟลเดอร์จริงของโปรเจกต์
import 'package:dating_one/screens/discover/discover_screen.dart';
import 'package:dating_one/screens/discover/member_profile_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'บัญชีของฉัน',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 1. เมนูตั้งค่าโปรไฟล์เดิม
          _buildMenuTile(
            icon: Icons.person_outline_rounded,
            title: 'ตั้งค่าโปรไฟล์',
            subtitle: 'แก้ไขข้อมูล รูปภาพ และสิ่งที่คุณสนใจ',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
              );
            },
          ),
          const SizedBox(height: 16),

          // 🌟 ── เพิ่มเมนูใหม่แบบกระชับ (ต่อจากตั้งค่าโปรไฟล์ตามบรีฟ) ──
          
          // 2. เมนูค้นหา
          _buildMenuTile(
            icon: Icons.explore_outlined,
            title: 'ค้นหา',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DiscoverScreen()),
              );
            },
          ),
          const SizedBox(height: 16),

          // 3. เมนูโปรไฟล์สมาชิก
          _buildMenuTile(
            icon: Icons.account_box_outlined,
            title: 'โปรไฟล์สมาชิก',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemberProfileScreen(
                    memberId: '00000000-0000-0000-0000-000000000000', 
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // 4. เมนูถูกใจล่าสุด
          _buildMenuTile(
            icon: Icons.stars_outlined,
            title: 'ถูกใจล่าสุด',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DiscoverScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // ───────────────────────────────────────────────

          // 5. เมนูออกจากระบบเดิม
          _buildMenuTile(
            icon: Icons.logout_rounded,
            title: 'ออกจากระบบ',
            textColor: AppColors.destructive,
            iconColor: AppColors.destructive,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.brandPink).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor ?? AppColors.brandPink),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: textColor ?? AppColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 16,
          color: AppColors.textSecondary.withOpacity(0.5),
        ),
        onTap: onTap,
      ),
    );
  }
}