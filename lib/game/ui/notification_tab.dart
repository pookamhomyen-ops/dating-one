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
          ? _EmptyState()
          : _NotifList(notifs: notifs),
      loading: () => const _LoadingSkeleton(),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

// ─── Empty State ────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFFAEEDA),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFAC775), width: 1.5),
            ),
            child: const Center(
              child: Text('🔔', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('ยังไม่มีการแจ้งเตือน',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3C2810),
            )),
          const SizedBox(height: 6),
          const Text('เมื่อมีเหตุการณ์ในเกม\nจะแสดงที่นี่',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF888780))),
        ],
      ),
    );
  }
}

// ─── Notification List ──────────────────────────────────────────
class _NotifList extends ConsumerWidget {
  final List<Map<String, dynamic>> notifs;
  const _NotifList({required this.notifs});

  // จัดกลุ่มตามวัน
  Map<String, List<Map<String, dynamic>>> _groupByDay(
      List<Map<String, dynamic>> notifs) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final n in notifs) {
      final dt = DateTime.parse(n['created_at']).toLocal();
      final now = DateTime.now();
      String label;
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        label = 'วันนี้';
      } else if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day - 1) {
        label = 'เมื่อวาน';
      } else {
        label = '${dt.day}/${dt.month}/${dt.year}';
      }
      grouped.putIfAbsent(label, () => []).add(n);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grouped = _groupByDay(notifs);
    final unreadCount = notifs.where((n) => n['is_read'] == false).length;

    return Column(
      children: [
        // Header
        _NotifHeader(
          total: notifs.length,
          unread: unreadCount,
          onMarkAll: () async {
            final settlement =
                ref.read(settlementProvider).valueOrNull;
            if (settlement == null) return;
            final gameClient = ref.read(gameSupabaseProvider);
            await gameClient
                .from('notifications')
                .update({'is_read': true})
                .eq('settlement_id', settlement.id)
                .eq('is_read', false);
            ref.invalidate(notificationsProvider);
          },
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            itemCount: grouped.length,
            itemBuilder: (_, gi) {
              final day = grouped.keys.elementAt(gi);
              final items = grouped[day]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DayLabel(label: day),
                  ...items.map((n) => _NotifCard(data: n)),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────
class _NotifHeader extends StatelessWidget {
  final int total, unread;
  final VoidCallback onMarkAll;
  const _NotifHeader(
      {required this.total,
      required this.unread,
      required this.onMarkAll});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFF5EFE6),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8DDD0), width: 1),
        ),
      ),
      child: Row(
        children: [
          const Text('🔔 การแจ้งเตือน',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3C2810))),
          if (unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF993C1D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('$unread ใหม่',
                  style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ],
          const Spacer(),
          if (unread > 0)
            GestureDetector(
              onTap: onMarkAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFFAC775), width: 0.8),
                ),
                child: const Text('อ่านทั้งหมด',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF854F0B),
                        fontWeight: FontWeight.w500)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Day Label ───────────────────────────────────────────────────
class _DayLabel extends StatelessWidget {
  final String label;
  const _DayLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF888780),
                  letterSpacing: 0.3)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(height: 0.5, color: const Color(0xFFE0D5C5)),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Card ───────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _NotifCard({required this.data});

  Color _parseColor(String? hex) {
    try {
      return Color(int.parse((hex ?? '#FAC775').replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFFAC775);
    }
  }

  String _timeAgo(String createdAt) {
    final dt = DateTime.parse(createdAt).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'เมื่อกี้';
    if (diff.inMinutes < 60) return '${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return '${diff.inHours} ชั่วโมงที่แล้ว';
    return '${diff.inDays} วันที่แล้ว';
  }

  // แปลง icon string → widget (รองรับ emoji + url)
  Widget _iconWidget(String icon, Color accent) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(icon, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = _parseColor(data['accent_color']);
    final isRead = data['is_read'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead
              ? Colors.black.withValues(alpha: 0.06)
              : accent.withValues(alpha: 0.4),
          width: isRead ? 0.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent bar ซ้าย
          Container(
            width: 4,
            height: 60,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Icon
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: _iconWidget(data['icon'] ?? '🔔', accent),
          ),
          const SizedBox(width: 10),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['text'] ?? '',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.5,
                      color: const Color(0xFF2C1A05),
                      fontWeight: isRead
                          ? FontWeight.w400
                          : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeAgo(data['created_at']),
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
          // Unread dot
          if (!isRead)
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 12),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Loading Skeleton ────────────────────────────────────────────
class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 5,
      itemBuilder: (_, i) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.black.withValues(alpha: 0.06), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
                width: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0D5C5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                )),
            const SizedBox(width: 10),
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEEE8DF),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEE8DF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 8,
                    width: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEE8DF),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}