import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../models/settlement.dart';

class CaravanTab extends ConsumerWidget {
  const CaravanTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementProvider);

    return settlementAsync.when(
      data: (settlement) => settlement != null
          ? _CaravanView(settlement: settlement)
          : const SizedBox.shrink(),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _CaravanView extends StatefulWidget {
  final Settlement settlement;
  const _CaravanView({required this.settlement});

  @override
  State<_CaravanView> createState() => _CaravanViewState();
}

class _CaravanViewState extends State<_CaravanView> {
  int _wood = 0, _iron = 0, _rice = 0, _liquor = 0;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAEEDA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFFAC775),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '💌 ส่งคาราวาน',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF633806),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'จะถึงในประมาณ 15 นาทีหลังส่ง',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF854F0B),
                ),
              ),
              const SizedBox(height: 12),

              // เลือกของ
              _ResourceSlider(
                icon: '🪵',
                label: 'ไม้',
                value: _wood,
                max: widget.settlement.wood,
                onChanged: (v) => setState(() => _wood = v),
              ),
              _ResourceSlider(
                icon: '⚙️',
                label: 'เหล็ก',
                value: _iron,
                max: widget.settlement.iron,
                onChanged: (v) => setState(() => _iron = v),
              ),
              _ResourceSlider(
                icon: '🌾',
                label: 'ข้าว',
                value: _rice,
                max: widget.settlement.rice,
                onChanged: (v) => setState(() => _rice = v),
              ),
              _ResourceSlider(
                icon: '🍶',
                label: 'สุรา',
                value: _liquor,
                max: widget.settlement.liquor,
                onChanged: (v) => setState(() => _liquor = v),
              ),

              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'ข้อความ (ไม่บังคับ)',
                  hintStyle: const TextStyle(fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFFAC775),
                      width: 0.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFFAC775),
                      width: 0.5,
                    ),
                  ),
                ),
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF854F0B),
                    foregroundColor: const Color(0xFFFAEEDA),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _canSend ? _sendCaravan : null,
                  child: const Text('ส่งคาราวาน 🚢'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // กองหนุน
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.black.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🛡️ ส่งกองหนุน',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ส่งทหารไปช่วยป้องกันชุมนุมแมทช์',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.grey.withOpacity(0.4),
                      width: 0.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text(
                    'เลือกหน่วยที่จะส่ง',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _canSend =>
      _wood > 0 || _iron > 0 || _rice > 0 || _liquor > 0;

  void _sendCaravan() {
    // TODO: เชื่อมกับ dating system เพื่อดึง match settlement id
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งคาราวานแล้ว! 🚢')),
    );
  }
}

class _ResourceSlider extends StatelessWidget {
  final String icon, label;
  final int value, max;
  final ValueChanged<int> onChanged;

  const _ResourceSlider({
    required this.icon,
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (max == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '$icon $label',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF633806),
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: max.toDouble(),
              divisions: max > 0 ? max : 1,
              activeColor: const Color(0xFF854F0B),
              inactiveColor: const Color(0xFFFAC775),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF633806),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}