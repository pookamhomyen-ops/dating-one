import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/gender.dart';
import '../../theme/app_colors.dart';
import 'profile_setup_step2_screen.dart';

class ProfileSetupStep1Screen extends StatefulWidget {
  final bool isEditMode;
  const ProfileSetupStep1Screen({super.key, this.isEditMode = false});

  @override
  State<ProfileSetupStep1Screen> createState() => _ProfileSetupStep1ScreenState();
}

class _ProfileSetupStep1ScreenState extends State<ProfileSetupStep1Screen> {
  final _nameCtrl = TextEditingController();
  Gender _gender = Gender.other;
  DateTime? _birthDate;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ข้อมูลเบื้องต้น (1/3)'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),
              const Icon(Icons.favorite_rounded, size: 80, color: AppColors.brandPink),
              const SizedBox(height: 24),
              const Text(
                'ยินดีต้อนรับ! มารู้จักกันหน่อย',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              
              // แถวที่ 1: ชื่อ และ เพศ
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อที่แสดง',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<Gender>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'เพศ'),
                      items: Gender.values
                          .map((g) => DropdownMenuItem(value: g, child: Text(g.labelTh)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _gender = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // แถวที่ 2: วันเกิด
              TextField(
                controller: TextEditingController(
                  text: _birthDate == null
                      ? ''
                      : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                ),
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate ?? DateTime(2000),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _birthDate = picked);
                },
                decoration: const InputDecoration(
                  labelText: 'วันเกิด',
                  hintText: 'เลือกวันเกิดของคุณ',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
              ),
              
              const Spacer(flex: 2),
              if (widget.isEditMode)
                OutlinedButton(
                  onPressed: () async {
                    if (_nameCtrl.text.isEmpty || _birthDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกชื่อและเลือกวันเกิด')),
                      );
                      return;
                    }
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) return;
                    await Supabase.instance.client.from('profiles').upsert({
                      'id': user.id,
                      'display_name': _nameCtrl.text.trim(),
                      'gender': _gender.name,
                      'birth_date': _birthDate!.toIso8601String().split('T')[0],
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.brandPink),
                    foregroundColor: AppColors.brandPink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('บันทึก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    if (_nameCtrl.text.isEmpty || _birthDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกชื่อและเลือกวันเกิด')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileSetupStep2Screen(
                          name: _nameCtrl.text,
                          gender: _gender,
                          birthDate: _birthDate!,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPink,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ถัดไป', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
