import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../models/building.dart';
import '../models/settlement.dart';
import '../services/building_service.dart';

class BuildingTab extends ConsumerWidget {
  const BuildingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementProvider);
    final buildingsAsync  = ref.watch(buildingsProvider);

    return settlementAsync.when(
      data: (settlement) => buildingsAsync.when(
        data: (buildings) => settlement != null
            ? _BuildingList(
                settlement: settlement,
                buildings: buildings,
              )
            : const SizedBox.shrink(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

class _BuildingList extends StatelessWidget {
  final Settlement settlement;
  final List<Building> buildings;

  const _BuildingList({
    required this.settlement,
    required this.buildings,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Grid อาคารที่มีแล้ว
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
          ),
          itemCount: buildings.length + 1,
          itemBuilder: (context, i) {
            if (i == buildings.length) {
              return _AddBuildingCard(settlement: settlement);
            }
            return _BuildingCard(
              building: buildings[i],
              settlement: settlement,
            );
          },
        ),
      ],
    );
  }
}

class _BuildingCard extends ConsumerWidget {
  final Building building;
  final Settlement settlement;

  const _BuildingCard({
    required this.building,
    required this.settlement,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpgrading = building.isUpgrading;
    final timeLeft   = building.upgradeTimeRemaining;

    return GestureDetector(
      onTap: () => _showUpgradeDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    building.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Lv.${building.level}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF854F0B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (building.productionPerTick.isNotEmpty)
              Text(
                _prodText(building),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF5F5E5A),
                ),
              ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: isUpgrading
                    ? _upgradeProgress(building)
                    : building.level / 5,
                backgroundColor: Colors.black.withOpacity(0.06),
                valueColor: AlwaysStoppedAnimation(
                  isUpgrading
                      ? const Color(0xFFF0997B)
                      : const Color(0xFF5DCAA5),
                ),
                minHeight: 3,
              ),
            ),
            if (isUpgrading && timeLeft != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '⏱ ${_formatDuration(timeLeft)}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: Color(0xFF5F5E5A),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _prodText(Building building) {
    const icons = {
      'wood': '🪵', 'iron': '⚙️', 'rice': '🌾', 'liquor': '🍶'
    };
    return building.productionPerTick.entries
        .map((e) => '${icons[e.key]}+${e.value}/5นาที')
        .join(' ');
  }

  double _upgradeProgress(Building building) {
    if (building.upgradeFinishAt == null) return 0;
    final total = building.upgradeSeconds.toDouble();
    final elapsed = total -
        (building.upgradeFinishAt!
                .difference(DateTime.now())
                .inSeconds
                .toDouble())
            .clamp(0, total);
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}ชม. ${d.inMinutes.remainder(60)}นาที';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}นาที ${d.inSeconds.remainder(60)}วินาที';
    }
    return '${d.inSeconds}วินาที';
  }

  void _showUpgradeDialog(BuildContext context, WidgetRef ref) {
    if (building.level >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อาคารนี้ถึงระดับสูงสุดแล้ว')),
      );
      return;
    }
    if (building.isUpgrading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'กำลัง upgrade อยู่ เหลือ ${_formatDuration(building.upgradeTimeRemaining!)}',
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5EFE6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _UpgradeSheet(
        building: building,
        settlement: settlement,
        onUpgrade: () async {
          final service = BuildingService(
            ref.read(supabaseProvider),
          );
          try {
            await service.startUpgrade(
              building: building,
              settlement: settlement,
            );
            ref.invalidate(buildingsProvider);
            ref.invalidate(settlementProvider);
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$e')),
              );
            }
          }
        },
      ),
    );
  }
}

class _UpgradeSheet extends StatelessWidget {
  final Building building;
  final Settlement settlement;
  final VoidCallback onUpgrade;

  const _UpgradeSheet({
    required this.building,
    required this.settlement,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final cost = building.upgradeCost;
    final canAfford = settlement.wood >= (cost['wood'] ?? 0) &&
        settlement.iron >= (cost['iron'] ?? 0);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'อัปเกรด ${building.displayName}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Lv.${building.level} → Lv.${building.level + 1}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _CostChip(
                icon: '🪵',
                need: cost['wood'] ?? 0,
                have: settlement.wood,
              ),
              const SizedBox(width: 8),
              _CostChip(
                icon: '⚙️',
                need: cost['iron'] ?? 0,
                have: settlement.iron,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '⏱ ใช้เวลา ${_fmt(building.upgradeSeconds)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford
                    ? const Color(0xFF3C2810)
                    : Colors.grey[300],
                foregroundColor: canAfford
                    ? const Color(0xFFFAC775)
                    : Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: canAfford ? onUpgrade : null,
              child: Text(canAfford ? 'อัปเกรด' : 'ทรัพยากรไม่พอ'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _fmt(int seconds) {
    final d = Duration(seconds: seconds);
    if (d.inHours > 0) return '${d.inHours}ชม. ${d.inMinutes.remainder(60)}นาที';
    if (d.inMinutes > 0) return '${d.inMinutes}นาที';
    return '${d.inSeconds}วินาที';
  }
}

class _CostChip extends StatelessWidget {
  final String icon;
  final int need, have;

  const _CostChip({
    required this.icon,
    required this.need,
    required this.have,
  });

  @override
  Widget build(BuildContext context) {
    final enough = have >= need;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: enough
            ? const Color(0xFFE1F5EE)
            : const Color(0xFFFCEBEB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$icon $need',
        style: TextStyle(
          fontSize: 13,
          color: enough
              ? const Color(0xFF0F6E56)
              : const Color(0xFFA32D2D),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _AddBuildingCard extends StatelessWidget {
  final Settlement settlement;
  const _AddBuildingCard({required this.settlement});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.black.withOpacity(0.12),
            width: 0.5,
            style: BorderStyle.none,
          ),
        ),
        child: DottedBorder(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: Colors.grey[400], size: 20),
                const SizedBox(height: 2),
                Text(
                  'สร้างอาคาร',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// dotted border ง่ายๆ ไม่ต้องติดตั้ง package เพิ่ม
class DottedBorder extends StatelessWidget {
  final Widget child;
  const DottedBorder({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}