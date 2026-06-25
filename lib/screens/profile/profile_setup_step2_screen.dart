import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/gender.dart';
import '../../theme/app_colors.dart';
import 'profile_setup_step3_screen.dart';

class ProfileSetupStep2Screen extends StatefulWidget {
  final String name;
  final Gender gender;
  final DateTime birthDate;
  final bool isEditMode;

  const ProfileSetupStep2Screen({
    super.key,
    required this.name,
    required this.gender,
    required this.birthDate,
    this.isEditMode = false,
  });

  @override
  State<ProfileSetupStep2Screen> createState() => _ProfileSetupStep2ScreenState();
}

class _ProfileSetupStep2ScreenState extends State<ProfileSetupStep2Screen> {
  final _provinceCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  
  String _status = 'โสด';
  double _brokenHeartDays = 30; // ค่าเริ่มต้น 30 วัน
  String _activity = 'ทำงาน';
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
          _provinceCtrl.text = data['province'] ?? '';
          _districtCtrl.text = data['district'] ?? '';
          _bioCtrl.text = data['bio'] ?? '';
          _status = data['relationship_status'] ?? 'โสด';
          _brokenHeartDays = (data['broken_heart_days'] ?? 30).toDouble();
          _activity = data['current_activity'] ?? 'ทำงาน';
        });
      }
    } catch (e) {
      debugPrint('Load step2 profile error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveEdit() async {
    if (_provinceCtrl.text.isEmpty || _districtCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกจังหวัดและอำเภอ')),
      );
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final payload = Map<String, dynamic>.from(_snapshot);
      payload['id'] = user.id;
      payload['province'] = _provinceCtrl.text.trim();
      payload['district'] = _districtCtrl.text.trim();
      payload['relationship_status'] = _status;
      payload['broken_heart_days'] = _status == 'อกหัก' ? _brokenHeartDays.round() : 0;
      payload['current_activity'] = _activity;
      payload['bio'] = _bioCtrl.text.trim();
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
  void dispose() {
    _provinceCtrl.dispose();
    _districtCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  // ฟังก์ชันแปลงจำนวนวันเป็นข้อความ ปี เดือน วัน
  String _formatBrokenHeartDuration(double totalDays) {
    int days = totalDays.round();
    if (days < 30) return '$days วัน';
    
    int years = days ~/ 365;
    int remainingDaysAfterYears = days % 365;
    int months = remainingDaysAfterYears ~/ 30;
    int finalDays = remainingDaysAfterYears % 30;

    String result = '';
    if (years > 0) result += '$years ปี ';
    if (months > 0) result += '$months เดือน ';
    if (finalDays > 0 && years == 0) result += '$finalDays วัน'; // ถ้ามีปีแล้วไม่ต้องโชว์เศษวันให้รก
    
    return result.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ไลฟ์สไตล์และสถานะ (2/3)'), centerTitle: true),
      body: SafeArea(
        child: _loading && widget.isEditMode && _snapshot.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // แถวที่ 1: จังหวัด และ อำเภอ
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _provinceCtrl,
                      decoration: const InputDecoration(
                        labelText: 'จังหวัด',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _districtCtrl,
                      decoration: const InputDecoration(
                        labelText: 'อำเภอ',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // แถวที่ 2: สถานะความสัมพันธ์
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'สถานะหัวใจ',
                  prefixIcon: Icon(Icons.favorite_border_rounded),
                ),
                items: ['โสด', 'มีแฟนแล้ว', 'อกหัก']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              
              // ตรวจสอบเงื่อนไขแสดง Slider เมื่อเลือก "อกหัก"
              if (_status == 'อกหัก') ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('อกหักมานานแค่ไหนแล้ว?', style: TextStyle(color: Colors.grey)),
                            Text(
                              _formatBrokenHeartDuration(_brokenHeartDays),
                              style: const TextStyle(
                                color: AppColors.brandPink,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _brokenHeartDays,
                          min: 1,
                          max: 1825, // สูงสุด 5 ปี (365 * 5)
                          activeColor: AppColors.brandPink,
                          inactiveColor: AppColors.border,
                          onChanged: (val) => setState(() => _brokenHeartDays = val),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1 วัน', style: TextStyle(fontSize: 12, color: Colors.grey)),
                              Text('5 ปี', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ตัวเลือก ทำอะไร
              DropdownButtonFormField<String>(
                initialValue: _activity,
                decoration: const InputDecoration(
                  labelText: 'ตอนนี้ทำอะไรอยู่',
                  prefixIcon: Icon(Icons.work_outline_rounded),
                ),
                items: ['ทำงาน', 'เรียน', 'อยู่บ้าน']
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _activity = v);
                },
              ),
              const SizedBox(height: 24),

              // แถวสาม: แนะนำตัวสั้นๆ
              TextField(
                controller: _bioCtrl,
                maxLines: 3,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'แนะนำตัวสั้นๆ',
                  hintText: 'บอกความเป็นตัวเองให้โลกจำ...',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 40),

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
                    if (_provinceCtrl.text.isEmpty || _districtCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('กรุณากรอกจังหวัดและอำเภอ')),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileSetupStep3Screen(
                          name: widget.name,
                          gender: widget.gender,
                          birthDate: widget.birthDate,
                          province: _provinceCtrl.text,
                          district: _districtCtrl.text,
                          status: _status,
                          brokenHeartDays: _status == 'อกหัก' ? _brokenHeartDays.round() : 0,
                          activity: _activity,
                          bio: _bioCtrl.text,
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

