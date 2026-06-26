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
            ? _BuildingList(settlement: settlement, buildings: buildings)
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
  const _BuildingList({required this.settlement, required this.buildings});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
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
              return _AddBuildingCard(
                settlement: settlement,
                buildings: buildings,
              );
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
  const _BuildingCard({required this.building, required this.settlement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isUpgrading = building.isUpgrading;
    final timeLeft    = building.upgradeTimeRemaining;

    return GestureDetector(
      onTap: () => _showUpgradeDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(building.displayName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('Lv.${building.level}',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF854F0B))),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (building.productionPerTick.isNotEmpty)
              Text(_prodText(building),
                style: const TextStyle(fontSize: 11, color: Color(0xFF5F5E5A))),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: isUpgrading ? _upgradeProgress(building) : building.level / 5,
                backgroundColor: Colors.black.withValues(alpha: 0.06),
                valueColor: AlwaysStoppedAnimation(
                  isUpgrading ? const Color(0xFFF0997B) : const Color(0xFF5DCAA5)),
                minHeight: 3,
              ),
            ),
            if (isUpgrading && timeLeft != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text('⏱ ${_fmt(timeLeft)}',
                  style: const TextStyle(fontSize: 9, color: Color(0xFF5F5E5A))),
              ),
          ],
        ),
      ),
    );
  }

  String _prodText(Building b) {
    const icons = {'wood':'🪵','iron':'⚙️','rice':'🌾','liquor':'🍶'};
    return b.productionPerTick.entries
        .map((e) => '${icons[e.key]}+${e.value}/5นาที').join(' ');
  }

  double _upgradeProgress(Building b) {
    if (b.upgradeFinishAt == null) return 0;
    final total = b.upgradeSeconds.toDouble();
    final elapsed = total -
        b.upgradeFinishAt!.difference(DateTime.now()).inSeconds.toDouble().clamp(0, total);
    return (elapsed / total).clamp(0.0, 1.0);
  }

  String _fmt(Duration d) {
    if (d.inHours > 0) return '${d.inHours}ชม. ${d.inMinutes.remainder(60)}นาที';
    if (d.inMinutes > 0) return '${d.inMinutes}นาที ${d.inSeconds.remainder(60)}วินาที';
    return '${d.inSeconds}วินาที';
  }

  void _showUpgradeDialog(BuildContext context, WidgetRef ref) {
    if (building.level >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อาคารนี้ถึงระดับสูงสุดแล้ว')));
      return;
    }
    if (building.isUpgrading) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('กำลัง upgrade อยู่ เหลือ ${_fmt(building.upgradeTimeRemaining!)}')));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5EFE6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _UpgradeSheet(
        building: building,
        settlement: settlement,
        onUpgrade: () async {
          final service = BuildingService(ref.read(gameSupabaseProvider));
          try {
            await service.startUpgrade(building: building, settlement: settlement);
            ref.invalidate(buildingsProvider);
            ref.invalidate(settlementProvider);
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$e')));
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
          Text('อัปเกรด ${building.displayName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text('Lv.${building.level} → Lv.${building.level + 1}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 16),
          Row(
            children: [
              _CostChip(icon: '🪵', need: cost['wood'] ?? 0, have: settlement.wood),
              const SizedBox(width: 8),
              _CostChip(icon: '⚙️', need: cost['iron'] ?? 0, have: settlement.iron),
            ],
          ),
          const SizedBox(height: 8),
          Text('⏱ ใช้เวลา ${_fmtSec(building.upgradeSeconds)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? const Color(0xFF3C2810) : Colors.grey[300],
                foregroundColor: canAfford ? const Color(0xFFFAC775) : Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  String _fmtSec(int seconds) {
    final d = Duration(seconds: seconds);
    if (d.inHours > 0) return '${d.inHours}ชม. ${d.inMinutes.remainder(60)}นาที';
    if (d.inMinutes > 0) return '${d.inMinutes}นาที';
    return '${d.inSeconds}วินาที';
  }
}

class _AddBuildingCard extends ConsumerWidget {
  final Settlement settlement;
  final List<Building> buildings;
  const _AddBuildingCard({required this.settlement, required this.buildings});

  static const _buildable = [
    'sawmill', 'smelter', 'rice_farm', 'distillery',
    'house', 'tavern', 'shrine', 'barracks',
    'elephant_camp', 'smithy', 'wall', 'watchtower',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thLevel  = ref.watch(townHallLevelProvider);
    final maxSlots = Building.maxBuildingSlots(thLevel);
    final isFull   = buildings.length >= maxSlots;

    if (isFull) {
      return _DottedBorder(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏛️', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 2),
              Text('อัพ Town Hall\nเพื่อสร้างเพิ่ม',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showBuildSheet(context, ref),
      child: _DottedBorder(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: Colors.grey[400], size: 20),
              const SizedBox(height: 2),
              Text('สร้างอาคาร\n(${buildings.length}/$maxSlots)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }

  void _showBuildSheet(BuildContext context, WidgetRef ref) {
    final existing = buildings
        .where((b) => b.buildingType != 'house')
        .map((b) => b.buildingType)
        .toSet();
    final available = _buildable.where((t) => !existing.contains(t)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สร้างอาคารครบทุกประเภทแล้ว')));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5EFE6),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _BuildSheet(
        available: available,
        settlement: settlement,
        onBuild: (type) async {
          final service = BuildingService(ref.read(gameSupabaseProvider));
          try {
            await service.constructBuilding(
              settlement: settlement, buildingType: type);
            ref.invalidate(buildingsProvider);
            ref.invalidate(settlementProvider);
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$e')));
            }
          }
        },
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  final String icon;
  final int need;
  final int have;
  const _CostChip({required this.icon, required this.need, required this.have});

  @override
  Widget build(BuildContext context) {
    final ok = have >= need;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ok ? const Color(0xFFD4F5E8) : const Color(0xFFFFD9D9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text('$icon$have/${ok ? '✓' : '✗'}$need',
        style: TextStyle(fontSize: 9, color: ok ? const Color(0xFF2D7D5E) : const Color(0xFFB02E2E))),
    );
  }
}

class _DottedBorder extends StatelessWidget {
  final Widget child;
  const _DottedBorder({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: child,
    );
  }
}

class _BuildSheet extends ConsumerWidget {
  final List<String> available;
  final Settlement settlement;
  final Function(String) onBuild;
  const _BuildSheet({
    required this.available,
    required this.settlement,
    required this.onBuild,
  });

  static const _costs = {
    'sawmill': {'wood': 100, 'iron': 50},
    'smelter': {'wood': 150, 'iron': 100},
    'rice_farm': {'wood': 80, 'iron': 40},
    'distillery': {'wood': 120, 'iron': 80},
    'house': {'wood': 50, 'iron': 25},
    'tavern': {'wood': 100, 'iron': 60},
    'shrine': {'wood': 110, 'iron': 70},
    'barracks': {'wood': 200, 'iron': 150},
    'elephant_camp': {'wood': 250, 'iron': 180},
    'smithy': {'wood': 160, 'iron': 120},
    'wall': {'wood': 180, 'iron': 100},
    'watchtower': {'wood': 140, 'iron': 90},
  };

  static const _displayNames = {
    'sawmill': 'โรงไม้',
    'smelter': 'โรงหลอม',
    'rice_farm': 'นาข้าว',
    'distillery': 'โรงกลั่น',
    'house': 'บ้านเรือน',
    'tavern': 'ร้านเหล้าตอง',
    'shrine': 'ศาลเจ้า',
    'barracks': 'ค่ายทหาร',
    'elephant_camp': 'โรงช้าง',
    'smithy': 'โรงตีเหล็ก',
    'wall': 'กำแพงเมือง',
    'watchtower': 'หอสังเกตการณ์',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('เลือกอาคารที่ต้องการสร้าง',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final type in available)
                  _buildBuildingOption(context, type),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingOption(BuildContext context, String type) {
    final cost = _costs[type] ?? {};
    final canAfford = settlement.wood >= (cost['wood'] ?? 0) &&
        settlement.iron >= (cost['iron'] ?? 0);

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFAEEDA), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.home_work, size: 24, color: Color(0xFFAA7A4A)),
          ),
          title: Text(_displayNames[type] ?? type,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          trailing: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canAfford ? const Color(0xFF3C2810) : Colors.grey[300],
              foregroundColor: canAfford ? const Color(0xFFFAC775) : Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: canAfford ? () async {
              await onBuild(type);
            } : null,
            child: const Text('สร้าง', style: TextStyle(fontSize: 11)),
          ),
          onTap: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(left: 56, bottom: 8),
          child: Row(
            children: [
              _CostChip(icon: '🪵', need: cost['wood'] ?? 0, have: settlement.wood),
              const SizedBox(width: 8),
              _CostChip(icon: '⚙️', need: cost['iron'] ?? 0, have: settlement.iron),
            ],
          ),
        ),
      ],
    );
  }
}
