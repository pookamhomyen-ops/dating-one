import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';

class NotificationTab extends ConsumerWidget {
  const NotificationTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return notifsAsync.when(
      data: (notifs) => notifs.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔔', style: TextStyle(fontSize: 40)),
                  SizedBox(height: 12),
                  Text('ยังไม่มีการแจ้งเตือน',
                    style: TextStyle(color: Color(0xFF888780))),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(8),
              itemCount: notifs.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (_, i) => _NotifCard(data: notifs[i]),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NotifCard({required this.data});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFFAC775);
    }
  }

  String _timeAgo(String createdAt) {
    final dt = DateTime.parse(createdAt).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24)   return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _parseColor(data['accent_color'] ?? '#FAC775');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: accent, width: 3),
          top:    BorderSide(color: Colors.black.withValues(alpha: 0.06), width: 0.5),
          right:  BorderSide(color: Colors.black.withValues(alpha: 0.06), width: 0.5),
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06), width: 0.5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['icon'] ?? '🔔',
            style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['text'] ?? '',
                  style: const TextStyle(fontSize: 12, height: 1.5)),
                const SizedBox(height: 2),
                Text(_timeAgo(data['created_at']),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}