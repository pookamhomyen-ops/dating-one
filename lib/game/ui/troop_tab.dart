import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../models/troop.dart';
import '../models/building.dart';
import '../models/settlement.dart';
import '../services/troop_service.dart';

class TroopTab extends ConsumerWidget {
  const TroopTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementProvider);
    final troopsAsync     = ref.watch(troopsProvider);

    return settlementAsync.when(
      data: (settlement) => troopsAsync.when(
        data: (troops) => settlement != null
            ? _TroopList(settlement: settlement, troops: troops)
            : const SizedBox.shrink(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _TroopList extends StatelessWidget {
  final Settlement settlement;
  final List<Troop> troops;

  const _TroopList({
    required this.settlement,
    required this.troops,
  });

  @override
  Widget build(BuildContext context) {
    final totalTroops = troops.fold(0, (sum, t) => sum + t.count);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Population & troop cap
        _StatRow(
          label: 'ประชาชน',
          value: '${settlement.population}/${settlement.maxPopulation}',
          status: settlement.happinessEmoji,
        ),
        const SizedBox(height: 6),
        Consumer(
          builder: (_, ref, __) {
            final thLevel  = ref.watch(townHallLevelProvider);
            final troopCap = Building.maxTroopCap(thLevel);
            return _StatRow(
              label: 'ทหารปัจจุบัน',
              value: '$totalTroops/$troopCap',
              status: totalTroops < troopCap ? '✅' : '🔴',
            );
          },
        ),
        const SizedBox(height: 12),

        const Text(
          'ผลิตทหาร',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFF888780),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),

        ...troops.map((t) => _TroopCard(
              troop: t,
              settlement: settlement,
              allTroops: troops,
            )),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label, value, status;
  const _StatRow({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF5F5E5A),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Text(status, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}

class _TroopCard extends ConsumerWidget {
  final Troop troop;
  final Settlement settlement;
  final List<Troop> allTroops;

  const _TroopCard({
    required this.troop,
    required this.settlement,
    required this.allTroops,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black.withOpacity(0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Text(troop.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  troop.displayName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'มีอยู่ ${troop.count} คน',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF5F5E5A),
                  ),
                ),
                Text(
                  '🪵${troop.costPerUnit['wood']} ⚙️${troop.costPerUnit['iron']} ต่อคน',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF888780),
                  ),
                ),
                if (troop.isTraining && troop.trainingTimeRemaining != null)
                  Text(
                    '⏱ ฝึก ${troop.trainingCount} คน — ${_fmt(troop.trainingTimeRemaining!)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF0F6E56),
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _train(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 5,
              ),
              decoration: BoxDecoration(
                color: troop.isTraining
                    ? const Color(0xFFF1EFE8)
                    : const Color(0xFFE1F5EE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: troop.isTraining
                      ? const Color(0xFFB4B2A9)
                      : const Color(0xFF9FE1CB),
                  width: 0.5,
                ),
              ),
              child: Text(
                troop.isTraining ? 'กำลังฝึก' : 'ฝึก +10',
                style: TextStyle(
                  fontSize: 11,
                  color: troop.isTraining
                      ? const Color(0xFF888780)
                      : const Color(0xFF0F6E56),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    if (d.inMinutes > 0) return '${d.inMinutes}นาที';
    return '${d.inSeconds}วินาที';
  }

  Future<void> _train(BuildContext context, WidgetRef ref) async {
    if (troop.isTraining) return;

    final service = TroopService(ref.read(gameSupabaseProvider));
    try {
      await service.trainTroops(
        troop: troop,
        settlement: settlement,
        allTroops: allTroops,
        amount: 10,
      );
      ref.invalidate(troopsProvider);
      ref.invalidate(settlementProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}