import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';

class NotificationTab extends ConsumerWidget {
  const NotificationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: ดึงจาก Supabase realtime
    const notifications = [
      _NotifData(
        icon: '🚢',
        text: 'คาราวานมาถึงแล้ว! ได้รับ 🪵50 🌾20',
        time: '5 นาทีที่แล้ว',
        accentColor: Color(0xFF5DCAA5),
      ),
      _NotifData(
        icon: '⚔️',
        text: 'กองทัพกลับจากโหนดโจรแล้ว ได้รับ ⚙️30 🪵20',
        time: '22 นาทีที่แล้ว',
        accentColor: Color(0xFFF0997B),
      ),
      _NotifData(
        icon: '🔔',
        text: 'โรงกลั่นสุราหยุดผลิต — ข้าวสารในคลังหมดแล้ว',
        time: '1 ชั่วโมงที่แล้ว',
        accentColor: Color(0xFFFAC775),
      ),
      _NotifData(
        icon: '🏯',
        text: 'อัปเกรดค่ายทหาร → Lv.3 เสร็จแล้ว',
        time: '2 ชั่วโมงที่แล้ว',
        accentColor: Color(0xFFAFA9EC),
      ),
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) => _NotifCard(data: notifications[i]),
    );
  }
}

class _NotifData {
  final String icon, text, time;
  final Color accentColor;
  const _NotifData({
    required this.icon,
    required this.text,
    required this.time,
    required this.accentColor,
  });
}

class _NotifCard extends StatelessWidget {
  final _NotifData data;
  const _NotifCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: data.accentColor, width: 3),
          top: BorderSide(
            color: Colors.black.withOpacity(0.06),
            width: 0.5,
          ),
          right: BorderSide(
            color: Colors.black.withOpacity(0.06),
            width: 0.5,
          ),
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.text,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 2),
                Text(
                  data.time,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}