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
  bool _loading = false;
  Map<String, dynamic> _snapshot = {};

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode) _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    setState(() => _loading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final data = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _snapshot = data;
          _nameCtrl.text = data['display_name'] ?? '';
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
      debugPrint('Load step1 error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveEdit() async {
    if (_nameCtrl.text.isEmpty || _birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อและเลือกวันเกิด')),
      );
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final payload = Map<String, dynamic>.from(_snapshot);
      payload['id'] = user.id;
      payload['display_name'] = _nameCtrl.text.trim();
      payload['gender'] = _gender.name;
      payload['birth_date'] = _birthDate!.toIso8601String().split('T')[0];
      payload.remove('created_at');
      payload.remove('updated_at');
      payload['updated_at'] = DateTime.now().toIso8601String();
      await Supabase.instance.client.from('profiles').upsert(payload);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
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
      appBar: AppBar(title: const Text('ข้อมูลเบื้องต้น (1/3)'), centerTitle: true),
      body: SafeArea(
        child: _loading && widget.isEditMode && _snapshot.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Padding(
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
                  onPressed: _loading ? null : _saveEdit,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.brandPink),
                    foregroundColor: AppColors.brandPink,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppColors.brandPink, strokeWidth: 2))
                      : const Text('บันทึก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
