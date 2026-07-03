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
  final bool isEditMode;

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
    this.isEditMode = false,
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
  bool _isLoadingInterests = true;
  List<Map<String, dynamic>> _allInterests = [];
  Map<String, dynamic> _snapshot = {};
  
  final Set<String> _selectedInterests = {}; // เก็บ interest id

  @override
  void dispose() {
    _hatedCtrl.dispose();
    _lineCtrl.dispose();
    _igCtrl.dispose();
    _xCtrl.dispose();
    _fbCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadInterests();
    if (widget.isEditMode) _loadFromDb();
  }

  Future<void> _loadFromDb() async {
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
          _hatedCtrl.text = data['hated_type'] ?? '';
          _lineCtrl.text = data['line_id'] ?? '';
          _igCtrl.text = data['instagram'] ?? '';
          _xCtrl.text = data['x_handle'] ?? '';
          _fbCtrl.text = data['facebook'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Load step3 profile error: $e');
    }
  }

  Future<void> _loadInterests() async {
    try {
      final allData = await Supabase.instance.client
          .from('interests')
          .select('id, name')
          .order('created_at');

      Set<String> preSelected = {};
      if (widget.isEditMode) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final mineData = await Supabase.instance.client
              .from('profile_interests')
              .select('interest_id')
              .eq('profile_id', user.id);
          preSelected = (mineData as List)
              .map((e) => e['interest_id'].toString())
              .toSet();
        }
      }

      if (mounted) {
        setState(() {
          _allInterests = List<Map<String, dynamic>>.from(allData);
          _selectedInterests.addAll(preSelected);
          _isLoadingInterests = false;
        });
      }
    } catch (e) {
      debugPrint('Load interests error: $e');
      if (mounted) setState(() => _isLoadingInterests = false);
    }
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

      Map<String, dynamic> payload;
      if (widget.isEditMode) {
        payload = Map<String, dynamic>.from(_snapshot);
        payload['id'] = user.id;
        payload['hated_type'] = _hatedCtrl.text;
        payload['line_id'] = _lineCtrl.text;
        payload['instagram'] = _igCtrl.text;
        payload['x_handle'] = _xCtrl.text;
        payload['facebook'] = _fbCtrl.text;
        payload.remove('created_at');
        payload.remove('updated_at');
        payload['updated_at'] = DateTime.now().toIso8601String();
      } else {
        payload = {
          'id': user.id,
          'display_name': widget.name,
          'gender': widget.gender.name,
          'birth_date': widget.birthDate.toIso8601String().split('T')[0],
          'province': widget.province,
          'district': widget.district,
          'relationship_status': widget.status,
          'broken_heart_days': widget.brokenHeartDays,
          'current_activity': widget.activity,
          'bio': widget.bio,
          'hated_type': _hatedCtrl.text,
          'line_id': _lineCtrl.text,
          'instagram': _igCtrl.text,
          'x_handle': _xCtrl.text,
          'facebook': _fbCtrl.text,
          'updated_at': DateTime.now().toIso8601String(),
        };
      }

      await Supabase.instance.client.from('profiles').upsert(payload);

      await Supabase.instance.client
          .from('profile_interests')
          .delete()
          .eq('profile_id', user.id);

      if (_selectedInterests.isNotEmpty) {
        await Supabase.instance.client.from('profile_interests').insert(
          _selectedInterests
              .map((id) => {'profile_id': user.id, 'interest_id': id})
              .toList(),
        );
      }

      if (mounted) {
        if (widget.isEditMode) {
          Navigator.pop(context);
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainShell()),
            (route) => false,
          );
        }
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
              if (_isLoadingInterests)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: AppColors.brandPink),
                  ),
                )
              else
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _allInterests.map((interest) {
                    final id = interest['id'].toString();
                    final label = interest['name'] as String;
                    final isSelected = _selectedInterests.contains(id);
                    return _AnimatedInterestChip(
                      key: ValueKey(id),
                      label: label,
                      isSelected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (_selectedInterests.length < 5) {
                              _selectedInterests.add(id);
                            }
                          } else {
                            _selectedInterests.remove(id);
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
              if (widget.isEditMode)
                OutlinedButton(
                  onPressed: _loading ? null : _saveProfile,
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

class _AnimatedInterestChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _AnimatedInterestChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  State<_AnimatedInterestChip> createState() => _AnimatedInterestChipState();
}

class _AnimatedInterestChipState extends State<_AnimatedInterestChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: ChoiceChip(
        label: Text(widget.label),
        selected: widget.isSelected,
        selectedColor: AppColors.brandPink.withValues(alpha: 0.15),
        checkmarkColor: AppColors.brandPink,
        labelStyle: TextStyle(
          color: widget.isSelected ? AppColors.brandPink : Colors.black87,
          fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: widget.isSelected ? AppColors.brandPink : AppColors.border),
        ),
        onSelected: (selected) {
          _ctrl.forward(from: 0);
          widget.onSelected(selected);
        },
      ),
    );
  }
}
