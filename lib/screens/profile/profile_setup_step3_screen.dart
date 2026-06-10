import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/gender.dart';
import '../../theme/app_colors.dart';
import '../main_shell.dart';

class ProfileSetupStep3Screen extends StatefulWidget {
  final String name;
  final Gender gender;
  final DateTime birthDate;
  final String province;
  final String district;
  final String status;
  final int brokenHeartDays;
  final String activity;
  final String bio;

  const ProfileSetupStep3Screen({
    super.key,
    required this.name,
    required this.gender,
    required this.birthDate,
    required this.province,
    required this.district,
    required this.status,
    required this.brokenHeartDays,
    required this.activity,
    required this.bio,
  });

  @override
  State<ProfileSetupStep3Screen> createState() => _ProfileSetupStep3ScreenState();
}

class _ProfileSetupStep3ScreenState extends State<ProfileSetupStep3Screen> {
  final _hatedCtrl = TextEditingController();
  final _lineCtrl = TextEditingController();
  final _igCtrl = TextEditingController();
  final _xCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();
  
  bool _loading = false;

  // รายการความสนใจตัวเลือกสไตล์วัยรุ่น
  final List<String> _interestsList = [
    '☕ คาเฟ่ฮอปปิ้ง', '🎮 เล่นเกม', '🎧 ฟังเพลง', '🐱 ทาสแมว', 
    '🐶 ทาสหมา', '🎬 ดูหนังซีรีส์', '📸 ถ่ายรูป', '✈️ เที่ยวต่างจังหวัด', 
    '🏋️ ออกกำลังกาย', '🎤 ร้องเพลง', '🛹 สเก็ตบอร์ด', '🎨 วาดรูป'
  ];
  
  final Set<String> _selectedInterests = {};

  @override
  void dispose() {
    _hatedCtrl.dispose();
    _lineCtrl.dispose();
    _igCtrl.dispose();
    _xCtrl.dispose();
    _fbCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกความสนใจอย่างน้อย 3 อย่างค่ะ/ครับ')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // บันทึกข้อมูลทั้งหมดลงฐานข้อมูลตาราง profiles
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'display_name': widget.name,
        'gender': widget.gender.name,
        'birthday': widget.birthDate.toIso8601String(),
        'province': widget.province,
        'district': widget.district,
        'relationship_status': widget.status,
        'broken_heart_days': widget.brokenHeartDays,
        'current_activity': widget.activity,
        'bio': widget.bio,
        'hated_type': _hatedCtrl.text,
        'interests': _selectedInterests.toList(),
        'line_id': _lineCtrl.text,
        'instagram': _igCtrl.text,
        'twitter': _xCtrl.text,
        'facebook': _fbCtrl.text,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainShell()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
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
      appBar: AppBar(title: const Text('ทัศนคติและโซเชียล (3/3)'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. คุณเกลียดคนแบบไหน
              const Text(
                'คุณเกลียดคนแบบไหน? (เช่น คนโกหก, คนเห็นแก่ตัว)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _hatedCtrl,
                maxLength: 60,
                decoration: InputDecoration(
                  hintText: 'พิมพ์สิ่งที่คุณไม่ชอบตรงนี้...',
                  prefixIcon: const Icon(Icons.sentiment_very_dissatisfied_rounded, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. ความสนใจของคุณ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ความสนใจของคุณ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    '(${_selectedInterests.length}/5)',
                    style: TextStyle(
                      color: (_selectedInterests.length >= 3 && _selectedInterests.length <= 5)
                          ? Colors.green
                          : AppColors.brandPink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Text('เลือกสิ่งที่คุณอิน 3 - 5 อย่างเพื่อแมตช์คนที่ใช่', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _interestsList.map((interest) {
                  final isSelected = _selectedInterests.contains(interest);
                  return ChoiceChip(
                    label: Text(interest),
                    selected: isSelected,
                    selectedColor: AppColors.brandPink.withOpacity(0.15),
                    checkmarkColor: AppColors.brandPink,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.brandPink : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: isSelected ? AppColors.brandPink : AppColors.border),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (_selectedInterests.length < 5) {
                            _selectedInterests.add(interest);
                          }
                        } else {
                          _selectedInterests.remove(interest);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 3. โซเชียลมีเดีย
              const Text(
                'ช่องทางการติดต่อส่วนตัว',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lineCtrl,
                decoration: const InputDecoration(labelText: 'Line ID', prefixIcon: Icon(Icons.chat_bubble_outline_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _igCtrl,
                decoration: const InputDecoration(labelText: 'Instagram', prefixIcon: Icon(Icons.camera_alt_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _xCtrl,
                decoration: const InputDecoration(labelText: 'X (Twitter)', prefixIcon: Icon(Icons.close_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fbCtrl,
                decoration: const InputDecoration(labelText: 'Facebook', prefixIcon: Icon(Icons.facebook_outlined)),
              ),
              const SizedBox(height: 32),

              // 4. ปุ่ม Submit บันทึกโปรไฟล์
              ElevatedButton(
                onPressed: _loading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPink,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('บันทึกโปรไฟล์สำเร็จ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}