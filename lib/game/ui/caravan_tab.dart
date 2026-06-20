import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../models/settlement.dart';
import '../models/caravan.dart';

class CaravanTab extends ConsumerWidget {
  const CaravanTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync     = ref.watch(settlementProvider);
    final matchSettlementAsync = ref.watch(matchSettlementProvider);
    final caravansAsync       = ref.watch(caravansProvider);

    return settlementAsync.when(
      data: (settlement) => settlement != null
          ? _CaravanView(
              settlement: settlement,
              matchSettlement: matchSettlementAsync.valueOrNull,
              caravans: caravansAsync.valueOrNull ?? [],
            )
          : const SizedBox.shrink(),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _CaravanView extends ConsumerStatefulWidget {
  final Settlement settlement;
  final Map<String, dynamic>? matchSettlement;
  final List<Caravan> caravans;

  const _CaravanView({
    required this.settlement,
    required this.matchSettlement,
    required this.caravans,
  });

  @override
  ConsumerState<_CaravanView> createState() => _CaravanViewState();
}

class _CaravanViewState extends ConsumerState<_CaravanView> {
  int _wood = 0, _iron = 0, _rice = 0, _liquor = 0;
  final _messageController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      !_sending &&
      widget.matchSettlement != null &&
      (_wood > 0 || _iron > 0 || _rice > 0 || _liquor > 0);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // แสดงคู่แมทช์
        _MatchBanner(matchSettlement: widget.matchSettlement),
        const SizedBox(height: 10),

        // ส่งคาราวาน
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFAEEDA),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFAC775), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💌 ส่งคาราวาน',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    color: Color(0xFF633806))),
              const SizedBox(height: 2),
              const Text('จะถึงในประมาณ 15 นาทีหลังส่ง',
                style: TextStyle(fontSize: 11, color: Color(0xFF854F0B))),
              const SizedBox(height: 12),
              _ResourceSlider(icon: '🪵', label: 'ไม้',  value: _wood,
                max: widget.settlement.wood,
                onChanged: (v) => setState(() => _wood = v)),
              _ResourceSlider(icon: '⚙️', label: 'เหล็ก', value: _iron,
                max: widget.settlement.iron,
                onChanged: (v) => setState(() => _iron = v)),
              _ResourceSlider(icon: '🌾', label: 'ข้าว', value: _rice,
                max: widget.settlement.rice,
                onChanged: (v) => setState(() => _rice = v)),
              _ResourceSlider(icon: '🍶', label: 'สุรา', value: _liquor,
                max: widget.settlement.liquor,
                onChanged: (v) => setState(() => _liquor = v)),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'ข้อความ (ไม่บังคับ)',
                  hintStyle: const TextStyle(fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFFFAC775), width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: Color(0xFFFAC775), width: 0.5),
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
                    backgroundColor: _canSend
                        ? const Color(0xFF854F0B)
                        : Colors.grey[300],
                    foregroundColor: _canSend
                        ? const Color(0xFFFAEEDA)
                        : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _canSend ? _sendCaravan : null,
                  child: _sending
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(widget.matchSettlement == null
                          ? 'ยังไม่มีแมทช์'
                          : 'ส่งคาราวาน 🚢'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // คาราวานที่กำลังเดินทาง
        if (widget.caravans.isNotEmpty) ...[
          const Text('🚢 คาราวานที่กำลังเดินทาง',
            style: TextStyle(fontSize: 11, color: Color(0xFF888780))),
          const SizedBox(height: 6),
          ...widget.caravans.map((c) => _CaravanCard(
            caravan: c,
            mySettlementId: widget.settlement.id,
          )),
        ],
      ],
    );
  }

  Future<void> _sendCaravan() async {
    final toSettlement = widget.matchSettlement!;
    setState(() => _sending = true);
    try {
      final gameClient = ref.read(gameSupabaseProvider);
      final now = DateTime.now();
      final arriveAt = now.add(const Duration(minutes: 15));

      await gameClient.from('caravans').insert({
        'from_settlement_id': widget.settlement.id,
        'to_settlement_id': toSettlement['id'],
        'payload': {
          if (_wood   > 0) 'wood':   _wood,
          if (_iron   > 0) 'iron':   _iron,
          if (_rice   > 0) 'rice':   _rice,
          if (_liquor > 0) 'liquor': _liquor,
        },
        'message': _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
        'depart_at': now.toIso8601String(),
        'arrive_at': arriveAt.toIso8601String(),
        'status': 'traveling',
      });

      // หักทรัพยากร
      await gameClient.from('settlements').update({
        'wood':   widget.settlement.wood   - _wood,
        'iron':   widget.settlement.iron   - _iron,
        'rice':   widget.settlement.rice   - _rice,
        'liquor': widget.settlement.liquor - _liquor,
      }).eq('id', widget.settlement.id);

      if (mounted) {
        setState(() { _wood = 0; _iron = 0; _rice = 0; _liquor = 0; });
        _messageController.clear();
        ref.invalidate(settlementProvider);
        ref.invalidate(caravansProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งคาราวานแล้ว! 🚢')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งไม่ได้: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _MatchBanner extends StatelessWidget {
  final Map<String, dynamic>? matchSettlement;
  const _MatchBanner({required this.matchSettlement});

  @override
  Widget build(BuildContext context) {
    if (matchSettlement == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.5),
        ),
        child: Row(
          children: [
            const Text('💔', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('ยังไม่มีแมทช์ — จับคู่ก่อนแล้วค่อยส่งคาราวาน',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB3C6), width: 0.5),
      ),
      child: Row(
        children: [
          const Text('💕', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ส่งให้แมทช์ของคุณ',
                style: TextStyle(fontSize: 11, color: Color(0xFF888780))),
              Text('🏯 ${matchSettlement!['name']}',
                style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w500, color: Color(0xFF633806))),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaravanCard extends StatelessWidget {
  final Caravan caravan;
  final String mySettlementId;
  const _CaravanCard({required this.caravan, required this.mySettlementId});

  @override
  Widget build(BuildContext context) {
    final isOutgoing = caravan.fromSettlementId == mySettlementId;
    final timeLeft = caravan.timeRemaining;
    final payload = caravan.payload;
    final payloadText = payload.entries
        .map((e) => '${_icon(e.key)}${e.value}')
        .join(' ');

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.08), width: 0.5),
      ),
      child: Row(
        children: [
          Text(isOutgoing ? '🚢' : '📦',
            style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isOutgoing ? 'ส่งออก: $payloadText' : 'รับเข้า: $payloadText',
                  style: const TextStyle(fontSize: 12)),
                if (caravan.message != null)
                  Text('💬 ${caravan.message}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Text(_fmt(timeLeft),
            style: const TextStyle(fontSize: 11, color: Color(0xFF854F0B))),
        ],
      ),
    );
  }

  String _icon(String res) {
    const icons = {'wood':'🪵','iron':'⚙️','rice':'🌾','liquor':'🍶'};
    return icons[res] ?? res;
  }

  String _fmt(Duration d) {
    if (d.inMinutes > 0) return '${d.inMinutes}นาที';
    return '${d.inSeconds}วินาที';
  }
}

class _ResourceSlider extends StatelessWidget {
  final String icon, label;
  final int value, max;
  final ValueChanged<int> onChanged;

  const _ResourceSlider({
    required this.icon, required this.label,
    required this.value, required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (max == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 50,
            child: Text('$icon $label',
              style: const TextStyle(fontSize: 11, color: Color(0xFF633806)))),
          Expanded(
            child: Slider(
              value: value.toDouble(),
              min: 0, max: max.toDouble(),
              divisions: max > 0 ? max : 1,
              activeColor: const Color(0xFF854F0B),
              inactiveColor: const Color(0xFFFAC775),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          SizedBox(width: 32,
            child: Text('$value',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                  color: Color(0xFF633806)),
              textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}