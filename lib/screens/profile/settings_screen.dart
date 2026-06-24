import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/gender.dart';
import '../../models/user_profile.dart';
import '../../theme/app_colors.dart';
import '../discover/discover_screen.dart';
import '../discover/member_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _provinceCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _lineCtrl;
  late final TextEditingController _igCtrl;
  late final TextEditingController _xCtrl;
  late final TextEditingController _fbCtrl;
  late final TextEditingController _interestCtrl;

  late Gender _gender;
  late int _age;
  late List<String> _interests;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _bioCtrl = TextEditingController(text: p.bio);
    _provinceCtrl = TextEditingController(text: p.province);
    _districtCtrl = TextEditingController(text: p.district);
    _lineCtrl = TextEditingController(text: p.lineId);
    _igCtrl = TextEditingController(text: p.instagram);
    _xCtrl = TextEditingController(text: p.xHandle);
    _fbCtrl = TextEditingController(text: p.facebook);
    _interestCtrl = TextEditingController();
    _gender = p.gender;
    _age = p.age;
    _interests = List.of(p.interests);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _provinceCtrl.dispose();
    _districtCtrl.dispose();
    _lineCtrl.dispose();
    _igCtrl.dispose();
    _xCtrl.dispose();
    _fbCtrl.dispose();
    _interestCtrl.dispose();
    super.dispose();
  }

  void _addInterest() {
    final tag = _interestCtrl.text.trim();
    if (tag.isEmpty) return;
    setState(() {
      if (!_interests.contains(tag)) {
        _interests.add(tag);
      }
      _interestCtrl.clear();
    });
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('profiles').update({
        'display_name': _nameCtrl.text.trim(),
        'gender': _gender.name,
        'birth_date': DateTime(DateTime.now().year - _age).toIso8601String().split('T')[0],
        'bio': _bioCtrl.text.trim(),
        'province': _provinceCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'line_id': _lineCtrl.text.trim(),
        'instagram': _igCtrl.text.trim(),
        'x_handle': _xCtrl.text.trim(),
        'facebook': _fbCtrl.text.trim(),
      }).eq('id', user.id);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ตั้งค่าโปรไฟล์'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _saveProfile,
            child: const Text(
              'บันทึก',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.brandPink,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field('ชื่อ', _nameCtrl),
          const SizedBox(height: 14),
          DropdownButtonFormField<Gender>(
            initialValue: _gender,
            decoration: const InputDecoration(labelText: 'เพศ'),
            items: Gender.values
                .map(
                  (g) => DropdownMenuItem(
                    value: g,
                    child: Text(g.labelTh),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _gender = v);
            },
          ),
          const SizedBox(height: 14),
          Text('อายุ: $_age ปี'),
          Slider(
            value: _age.toDouble(),
            min: 18,
            max: 60,
            divisions: 42,
            label: '$_age',
            activeColor: AppColors.brandPink,
            onChanged: (v) => setState(() => _age = v.round()),
          ),
          const SizedBox(height: 8),
          _field('จังหวัด', _provinceCtrl),
          const SizedBox(height: 14),
          _field('อำเภอ/เขต', _districtCtrl),
          const SizedBox(height: 20),
          const Text(
            'โซเชียลมีเดีย',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          const SizedBox(height: 10),
          _field('💬 Line ID', _lineCtrl, hint: '@username'),
          const SizedBox(height: 14),
          _field('📸 Instagram', _igCtrl, hint: '@username'),
          const SizedBox(height: 14),
          _field('✖️ X (Twitter)', _xCtrl, hint: '@username'),
          const SizedBox(height: 14),
          _field('📘 Facebook', _fbCtrl, hint: 'ชื่อเพจหรือโปรไฟล์'),
          const SizedBox(height: 14),
          _field('เกี่ยวกับฉัน', _bioCtrl, maxLines: 3),
          const SizedBox(height: 20),
          const Text(
            'ความสนใจ',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _interestCtrl,
                  decoration: const InputDecoration(
                    hintText: 'เพิ่มความสนใจ',
                  ),
                ),
              ),
              IconButton(
                onPressed: _addInterest,
                icon: const Icon(Icons.add_circle, color: AppColors.brandPink),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interests
                .map(
                  (tag) => InputChip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() => _interests.remove(tag));
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 40),

          // ── ปุ่มบันทึกเดิม ──
          ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandPink,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('บันทึกตั้งค่าโปรไฟล์', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 20),

          // ── เริ่มต้นเมนูทางลัดที่เพิ่มใหม่สำหรับนักพัฒนา ──
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'เมนูทดสอบระบบ (Developer Shortcuts)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DiscoverScreen()),
                    );
                  },
                  icon: const Icon(Icons.explore_outlined, color: AppColors.brandPink),
                  label: const Text('หน้าค้นหา', style: TextStyle(color: AppColors.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MemberProfileScreen(
                          memberId: '00000000-0000-0000-0000-000000000000', // ใส่ UUID ตัวอย่างสำหรับทดสอบในระบบของคุณ
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.account_box_outlined, color: AppColors.brandPink),
                  label: const Text('ดูโปรไฟล์', style: TextStyle(color: AppColors.textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          // ── สิ้นสุดเมนูทางลัดที่เพิ่มใหม่ ──

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ยืนยันการออกจากระบบ'),
                  content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('ยกเลิก'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('ออกจากระบบ', style: TextStyle(color: AppColors.destructive)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await Supabase.instance.client.auth.signOut();
              }
            },
            icon: const Icon(Icons.logout, color: AppColors.destructive),
            label: const Text('ออกจากระบบ', style: TextStyle(color: AppColors.destructive, fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppColors.destructive),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}
