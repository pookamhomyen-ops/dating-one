import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class GoWhereScreen extends StatefulWidget {
  const GoWhereScreen({super.key});

  @override
  State<GoWhereScreen> createState() => _GoWhereScreenState();
}

class _GoWhereScreenState extends State<GoWhereScreen> {
  final _placeCtrl = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _loading = true;
  bool _saving = false;
  bool _hasExisting = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final me = Supabase.instance.client.auth.currentUser;
      if (me == null) return;
      final data = await Supabase.instance.client
          .from('gowhere')
          .select()
          .eq('profile_id', me.id)
          .maybeSingle();
      if (data != null && mounted) {
        final dateParts = (data['go_date'] as String).split('-');
        final timeParts = (data['go_time'] as String).split(':');
        setState(() {
          _hasExisting = true;
          _placeCtrl.text = data['place'] ?? '';
          _selectedDate = DateTime(
            int.parse(dateParts[0]),
            int.parse(dateParts[1]),
            int.parse(dateParts[2]),
          );
          _selectedTime = TimeOfDay(
            hour: int.parse(timeParts[0]),
            minute: int.parse(timeParts[1]),
          );
        });
      }
    } catch (e) {
      debugPrint('Load gowhere error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _periodFromTime(TimeOfDay t) {
    if (t.hour < 12) return 'ช่วงเช้า';
    if (t.hour < 17) return 'ช่วงบ่าย';
    if (t.hour < 21) return 'ช่วงเย็น';
    return 'ช่วงค่ำ';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (_placeCtrl.text.trim().isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกสถานที่ วันที่ และเวลาให้ครบ')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final me = Supabase.instance.client.auth.currentUser;
      if (me == null) return;
      final dateStr =
          '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';
      final timeStr =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00';

      await Supabase.instance.client.from('gowhere').upsert({
        'profile_id': me.id,
        'place': _placeCtrl.text.trim(),
        'go_date': dateStr,
        'go_time': timeStr,
        'period': _periodFromTime(_selectedTime!),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      final me = Supabase.instance.client.auth.currentUser;
      if (me == null) return;
      await Supabase.instance.client.from('gowhere').delete().eq('profile_id', me.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบไม่สำเร็จ: $e'), backgroundColor: AppColors.destructive),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('จะไปไหน'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text(
              'บันทึก',
              style: TextStyle(color: AppColors.brandPink, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'บอกเพื่อนๆว่าคุณจะไปไหน เมื่อไหร่',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _placeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'สถานที่ที่จะไป',
                      hintText: 'เช่น บิ๊กซี',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(
                      text: _selectedDate == null
                          ? ''
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    ),
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'วันที่จะไป',
                      hintText: 'เลือกวันที่',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: TextEditingController(
                      text: _selectedTime == null ? '' : _selectedTime!.format(context),
                    ),
                    readOnly: true,
                    onTap: _pickTime,
                    decoration: const InputDecoration(
                      labelText: 'เวลาที่จะไป',
                      hintText: 'เลือกเวลา',
                      prefixIcon: Icon(Icons.access_time_outlined),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPink,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('บันทึก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                  if (_hasExisting) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _saving ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.destructive),
                        foregroundColor: AppColors.destructive,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('ลบสถานะ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
