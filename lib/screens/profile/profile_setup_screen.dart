import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/gender.dart';
import '../../theme/app_colors.dart';
import 'package:dating_one/screens/main_shell.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _universityCtrl = TextEditingController();
  final _occupationCtrl = TextEditingController();
  final _lineCtrl = TextEditingController();
  final _igCtrl = TextEditingController();
  final _xCtrl = TextEditingController();
  final _fbCtrl = TextEditingController();
  
  Gender _gender = Gender.other;
  DateTime? _birthDate;
  bool _loading = false;
  bool _isNewUser = true;

  List<Map<String, dynamic>> _allInterests = [];
  Set<String> _selectedInterestIds = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Load all interests
      final interestsData = await Supabase.instance.client
          .from('interests')
          .select()
          .order('name');
      
      _allInterests = List<Map<String, dynamic>>.from(interestsData);

      // 2. Load profile
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        // 3. Load selected interests
        final selectedData = await Supabase.instance.client
            .from('profile_interests')
            .select('interest_id')
            .eq('profile_id', user.id);
        
        _selectedInterestIds = (selectedData as List)
            .map((e) => e['interest_id'].toString())
            .toSet();

        setState(() {
          _isNewUser = false;
          _nameCtrl.text = data['display_name'] ?? '';
          _bioCtrl.text = data['bio'] ?? '';
          _provinceCtrl.text = data['province'] ?? '';
          _districtCtrl.text = data['district'] ?? '';
          _universityCtrl.text = data['university'] ?? '';
          _occupationCtrl.text = data['occupation'] ?? '';
          _lineCtrl.text = data['line_id'] ?? '';
          _igCtrl.text = data['instagram'] ?? '';
          _xCtrl.text = data['x_handle'] ?? '';
          _fbCtrl.text = data['facebook'] ?? '';
          
          if (data['gender'] != null) {
            _gender = Gender.values.firstWhere(
              (e) => e.name == data['gender'],
              orElse: () => Gender.other,
            );
          }
          
          if (data['birth_date'] != null) {
            _birthDate = DateTime.parse(data['birth_date']);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _provinceCtrl.dispose();
    _districtCtrl.dispose();
    _universityCtrl.dispose();
    _occupationCtrl.dispose();
    _lineCtrl.dispose();
    _igCtrl.dispose();
    _xCtrl.dispose();
    _fbCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.isEmpty || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อและวันเกิด')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'display_name': _nameCtrl.text.trim(),
        'gender': _gender.name,
        'birth_date': _birthDate!.toIso8601String().split('T')[0],
        'bio': _bioCtrl.text.trim(),
        'province': _provinceCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'university': _universityCtrl.text.trim(),
        'occupation': _occupationCtrl.text.trim(),
        'line_id': _lineCtrl.text.trim(),
        'instagram': _igCtrl.text.trim(),
        'x_handle': _xCtrl.text.trim(),
        'facebook': _fbCtrl.text.trim(),
      });

      // Save interests
      // 1. Delete existing
      await Supabase.instance.client
          .from('profile_interests')
          .delete()
          .eq('profile_id', user.id);

      // 2. Insert new
      if (_selectedInterestIds.isNotEmpty) {
        final inserts = _selectedInterestIds.map((id) => {
              'profile_id': user.id,
              'interest_id': id,
            }).toList();
        await Supabase.instance.client.from('profile_interests').insert(inserts);
      }

      if (mounted) {
        if (_isNewUser) {
          // ใช้ pushReplacement แทน pushAndRemoveUntil เพื่อลดปัญหาหน้าจอดำหาก stack ผิดพลาด
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainShell()),
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e'), backgroundColor: AppColors.destructive),
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
        automaticallyImplyLeading: !_isNewUser,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isNewUser)
              const Text(
                'ยินดีต้อนรับ! กรุณากรอกข้อมูลส่วนตัวของคุณ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'ชื่อที่แสดง'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Gender>(
              value: _gender,
              decoration: const InputDecoration(labelText: 'เพศ'),
              items: Gender.values
                  .map((g) => DropdownMenuItem(value: g, child: Text(g.labelTh)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _gender = v);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(
                text: _birthDate == null 
                  ? '' 
                  : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
              ),
              readOnly: true,
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _birthDate ?? DateTime(2000),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _birthDate = picked;
                  });
                }
              },
              decoration: const InputDecoration(
                labelText: 'วันเกิด',
                hintText: 'เลือกวันเกิด',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _provinceCtrl,
              decoration: const InputDecoration(labelText: 'จังหวัด'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _districtCtrl,
              decoration: const InputDecoration(labelText: 'อำเภอ/เขต'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _universityCtrl,
              decoration: const InputDecoration(labelText: 'มหาวิทยาลัย (ถ้ามี)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _occupationCtrl,
              decoration: const InputDecoration(labelText: 'อาชีพ'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioCtrl,
              decoration: const InputDecoration(labelText: 'แนะนำตัวสั้นๆ'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'ความสนใจของคุณ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _allInterests.map((interest) {
                final id = interest['id'].toString();
                final name = interest['name'] ?? '';
                final isSelected = _selectedInterestIds.contains(id);
                return FilterChip(
                  label: Text(name, style: const TextStyle(fontSize: 13)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedInterestIds.add(id);
                      } else {
                        _selectedInterestIds.remove(id);
                      }
                    });
                  },
                  selectedColor: AppColors.accentSoft,
                  checkmarkColor: AppColors.brandPink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? AppColors.brandPink : AppColors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text(
              'โซเชียลมีเดีย',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lineCtrl,
              decoration: const InputDecoration(labelText: 'Line ID', prefixIcon: Icon(Icons.chat_bubble_outline)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _igCtrl,
              decoration: const InputDecoration(labelText: 'Instagram', prefixIcon: Icon(Icons.camera_alt_outlined)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _xCtrl,
              decoration: const InputDecoration(labelText: 'X (Twitter)', prefixIcon: Icon(Icons.close)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fbCtrl,
              decoration: const InputDecoration(labelText: 'Facebook', prefixIcon: Icon(Icons.facebook_outlined)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPink,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading 
                ? const CircularProgressIndicator(color: AppColors.background)
                : const Text('บันทึกโปรไฟล์', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }
}
