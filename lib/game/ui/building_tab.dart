import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import '../models/building.dart';
import '../models/settlement.dart';
import '../services/building_service.dart';

// ── รูปอาคารจาก OpenGameArt / public domain pixel art ──────────
// ใช้ emoji แทนก่อน จนกว่าจะมี asset จริง
// เมื่อมี asset ให้แทนที่ _BuildingArt ด้วย Image.asset(...)
const _buildingEmoji = {
  'town_hall':      '🏛️',
  'sawmill':        '🪵',
  'smelter':        '⚒️',
  'rice_farm':      '🌾',
  'distillery':     '🍶',
  'house':          '🏠',
  'tavern':         '🍺',
  'shrine':         '⛩️',
  'barracks':       '🪖',
  'elephant_camp':  '🐘',
  'smithy':         '🔨',
  'wall':           '🧱',
  'watchtower':     '🗼',
};

// สีธีมของแต่ละประเภทอาคาร
const _buildingColor = {
  'town_hall':      Color(0xFF7B5EA7),
  'sawmill':        Color(0xFF6D8B3A),
  'smelter':        Color(0xFFB85C2C),
  'rice_farm':      Color(0xFF5B9B6B),
  'distillery':     Color(0xFF8B6B3D),
  'house':          Color(0xFF5B8DB8),
  'tavern':         Color(0xFFB87333),
  'shrine':         Color(0xFFD4A843),
  'barracks':       Color(0xFF8B3A3A),
  'elephant_camp':  Color(0xFF4A7B6B),
  'smithy':         Color(0xFF7B6B3A),
  'wall':           Color(0xFF6B7B8B),
  'watchtower':     Color(0xFF8B7B4A),
};

Color _colorFor(String type) =>
    _buildingColor[type] ?? const Color(0xFF854F0B);

// ────────────────────────────────────────────────────────────────
class BuildingTab extends ConsumerWidget {
  const BuildingTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlementAsync = ref.watch(settlementProvider);
    final buildingsAsync = ref.watch(buildingsProvider);

    return settlementAsync.when(
      data: (settlement) => buildingsAsync.when(
        data: (buildings) => settlement != null
            ? _BuildingView(settlement: settlement, buildings: buildings)
            : const SizedBox.shrink(),
        loading: () => const _BuildingSkeleton(),
        error: (e, _) => Center(child: Text('$e')),
      ),
      loading: () => const _BuildingSkeleton(),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

// ─── Main View ───────────────────────────────────────────────────
class _BuildingView extends ConsumerWidget {
  final Settlement settlement;
  final List<Building> buildings;
  const _BuildingView(
      {required this.settlement, required this.buildings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thLevel = ref.watch(townHallLevelProvider);
    final maxSlots = Building.maxBuildingSlots(thLevel);
    final upgrading = buildings.where((b) => b.isUpgrading).toList();

    return CustomScrollView(
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: _BuildingHeader(
            settlement: settlement,
            buildings: buildings,
            maxSlots: maxSlots,
            upgrading: upgrading,
          ),
        ),

        // ── Section label ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text('🏗️',
                    style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                const Text('อาคารของคุณ',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3C2810))),
                const SizedBox(width: 6),
                Text('${buildings.length}/$maxSlots',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF888780))),
              ],
            ),
          ),
        ),

        // ── Building cards ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _BuildingCard(
                building: buildings[i],
                settlement: settlement,
              ),
              childCount: buildings.length,
            ),
          ),
        ),

        // ── Add building ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _AddBuildingCard(
              settlement: settlement,
              buildings: buildings,
              maxSlots: maxSlots,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────
class _BuildingHeader extends StatelessWidget {
  final Settlement settlement;
  final List<Building> buildings;
  final int maxSlots;
  final List<Building> upgrading;

  const _BuildingHeader({
    required this.settlement,
    required this.buildings,
    required this.maxSlots,
    required this.upgrading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3C2810), Color(0xFF6B3F1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C2810).withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏯',
                  style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(settlement.name,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFAC775))),
                  Text(
                      'ที่ดิน ${buildings.length}/$maxSlots • happiness ${settlement.happiness}%',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.6))),
                ],
              ),
              const Spacer(),
              // Resources compact
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MiniRes(icon: '🪵', value: settlement.wood),
                  const SizedBox(height: 2),
                  _MiniRes(icon: '⚙️', value: settlement.iron),
                ],
              ),
            ],
          ),
          if (upgrading.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('🏗️',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    'กำลังอัปเกรด ${upgrading.map((b) => b.displayName).join(", ")}',
                    style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFFAC775)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniRes extends StatelessWidget {
  final String icon;
  final int value;
  const _MiniRes({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text('$icon $value',
        style: const TextStyle(
            fontSize: 11,
            color: Color(0xFFFAEEDA),
            fontWeight: FontWeight.w500));
  }
}

// ─── Building Card (กิมมิก: รูปอาคารล้นขอบบน) ────────────────────
class _BuildingCard extends ConsumerStatefulWidget {
  final Building building;
  final Settlement settlement;
  const _BuildingCard(
      {required this.building, required this.settlement});

  @override
  ConsumerState<_BuildingCard> createState() => _BuildingCardState();
}

class _BuildingCardState extends ConsumerState<_BuildingCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.building.isUpgrading) {
      _timer =
          Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _upgradeProgress() {
    final b = widget.building;
    if (b.upgradeFinishAt == null) return 0;
    final total = b.upgradeSeconds.toDouble();
    final remaining =
        b.upgradeFinishAt!.difference(DateTime.now()).inSeconds.toDouble();
    return ((total - remaining.clamp(0, total)) / total).clamp(0.0, 1.0);
  }

  String _fmt(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}ชม. ${d.inMinutes.remainder(60)}นาที';
    }
    if (d.inMinutes > 0) {
      return '${d.inMinutes}นาที ${d.inSeconds.remainder(60)}วิ';
    }
    return '${d.inSeconds}วิ';
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.building;
    final color = _colorFor(b.buildingType);
    final isUpgrading = b.isUpgrading;
    final timeLeft = b.upgradeTimeRemaining;
    final isMaxLevel = b.level >= 5;
    final emoji = _buildingEmoji[b.buildingType] ?? '🏠';

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Card body ──
            Container(
              margin: const EdgeInsets.only(top: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isUpgrading
                      ? color.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.06),
                  width: isUpgrading ? 1.2 : 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(70, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Name + level ──
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(b.displayName,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C1A05))),
                        ),
                        // Level badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isMaxLevel
                                ? const Color(0xFFFFD700)
                                    .withValues(alpha: 0.15)
                                : color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isMaxLevel ? '⭐ MAX' : 'Lv.${b.level}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isMaxLevel
                                    ? const Color(0xFFB8860B)
                                    : color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // ── Production ──
                    if (b.productionPerTick.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: b.productionPerTick.entries
                            .map((e) => _ProdChip(
                                res: e.key, amount: e.value))
                            .toList(),
                      ),

                    // ── Special bonuses ──
                    if (b.defenseBonus > 0 || b.populationBonus > 0) ...[
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: [
                          if (b.defenseBonus > 0)
                            _BonusChip(
                                label: '🛡️ +${b.defenseBonus}',
                                color: const Color(0xFF7BAFD4)),
                          if (b.populationBonus > 0)
                            _BonusChip(
                                label: '👥 +${b.populationBonus}',
                                color: const Color(0xFF5DCAA5)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // ── Progress bar ──
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: isUpgrading
                            ? _upgradeProgress()
                            : b.level / 5,
                        minHeight: 5,
                        backgroundColor:
                            Colors.black.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation(
                          isUpgrading
                              ? const Color(0xFFF0997B)
                              : color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),

                    // ── Status row ──
                    Row(
                      children: [
                        if (isUpgrading && timeLeft != null) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF0997B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text('อัปเกรด • ${_fmt(timeLeft)}',
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF993C1D),
                                  fontWeight: FontWeight.w500)),
                        ] else if (isMaxLevel) ...[
                          const Text('⭐ ระดับสูงสุด',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFFB8860B),
                                  fontWeight: FontWeight.w500)),
                        ] else ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text('กดเพื่ออัปเกรด',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[500])),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── อาคารล้นขอบ (กิมมิก!) ──
            Positioned(
              left: 10,
              top: 0,
              child: _BuildingArt(
                buildingType: b.buildingType,
                emoji: emoji,
                color: color,
                level: b.level,
                isUpgrading: isUpgrading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    final b = widget.building;
    if (b.level >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⭐ อาคารนี้ถึงระดับสูงสุดแล้ว'),
          backgroundColor: const Color(0xFFB8860B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    if (b.isUpgrading) {
      final t = b.upgradeTimeRemaining;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🏗️ กำลัง upgrade อยู่ • เหลือ ${t != null ? _fmt(t) : '...'}'),
          backgroundColor: const Color(0xFF993C1D),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _UpgradeSheet(
        building: b,
        settlement: widget.settlement,
        onUpgrade: () async {
          final service =
              BuildingService(ref.read(gameSupabaseProvider));
          try {
            await service.startUpgrade(
                building: b, settlement: widget.settlement);
            ref.invalidate(buildingsProvider);
            ref.invalidate(settlementProvider);
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$e'),
                  backgroundColor: const Color(0xFF993C1D),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ─── Building Art (รูปอาคารล้นขอบ) ──────────────────────────────
class _BuildingArt extends StatelessWidget {
  final String buildingType;
  final String emoji;
  final Color color;
  final int level;
  final bool isUpgrading;

  const _BuildingArt({
    required this.buildingType,
    required this.emoji,
    required this.color,
    required this.level,
    required this.isUpgrading,
  });

  @override
  Widget build(BuildContext context) {
    // ขนาดล้นขอบ: สูง 70px วางที่ top:0 ทำให้ล้นขอบบน 20px
    return SizedBox(
      width: 56,
      height: 70,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // เงากลม
          Positioned(
            bottom: 0,
            child: Container(
              width: 52,
              height: 18,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(26),
              ),
            ),
          ),
          // ตัวอาคาร
          Positioned(
            bottom: 6,
            child: Container(
              width: 50,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: color.withValues(alpha: 0.3), width: 1),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: _emojiFontSize(buildingType, level),
                  ),
                ),
              ),
            ),
          ),
          // กำลัง upgrade กระพริบ
          if (isUpgrading)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0997B),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Center(
                  child: Text('🔨',
                      style: TextStyle(fontSize: 8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _emojiFontSize(String type, int level) {
    // อาคารใหญ่ = emoji ใหญ่
    const big = ['town_hall', 'elephant_camp', 'wall'];
    const mid = ['barracks', 'shrine', 'watchtower'];
    if (big.contains(type)) return 28 + (level * 1.0);
    if (mid.contains(type)) return 24 + (level * 0.8);
    return 22 + (level * 0.6);
  }
}

// ─── Chip widgets ─────────────────────────────────────────────────
class _ProdChip extends StatelessWidget {
  final String res;
  final int amount;
  const _ProdChip({required this.res, required this.amount});

  static const _icons = {
    'wood': '🪵',
    'iron': '⚙️',
    'rice': '🌾',
    'liquor': '🍶'
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF5EFE6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${_icons[res] ?? res}+$amount/5นาที',
        style: const TextStyle(
            fontSize: 9,
            color: Color(0xFF633806),
            fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _BonusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _BonusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Upgrade Bottom Sheet ─────────────────────────────────────────
class _UpgradeSheet extends StatelessWidget {
  final Building building;
  final Settlement settlement;
  final VoidCallback onUpgrade;
  const _UpgradeSheet({
    required this.building,
    required this.settlement,
    required this.onUpgrade,
  });

  String _fmtSec(int seconds) {
    final d = Duration(seconds: seconds);
    if (d.inHours > 0) {
      return '${d.inHours}ชม. ${d.inMinutes.remainder(60)}นาที';
    }
    if (d.inMinutes > 0) return '${d.inMinutes}นาที';
    return '${d.inSeconds}วินาที';
  }

  @override
  Widget build(BuildContext context) {
    final cost = building.upgradeCost;
    final color = _colorFor(building.buildingType);
    final emoji = _buildingEmoji[building.buildingType] ?? '🏠';
    final canAfford = settlement.wood >= (cost['wood'] ?? 0) &&
        settlement.iron >= (cost['iron'] ?? 0);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5EFE6),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFCCC5BB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Building preview (ใหญ่)
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: color.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Center(
                  child: Text(emoji,
                      style: const TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(building.displayName,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2C1A05))),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _LevelBadge(level: building.level, color: color),
                      const Text(' → ',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888780))),
                      _LevelBadge(
                          level: building.level + 1, color: color),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cost card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                  width: 0.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _CostItem(
                      icon: '🪵',
                      label: 'ไม้',
                      need: cost['wood'] ?? 0,
                      have: settlement.wood,
                    ),
                    Container(
                        width: 1,
                        height: 36,
                        color: Colors.black
                            .withValues(alpha: 0.06)),
                    _CostItem(
                      icon: '⚙️',
                      label: 'เหล็ก',
                      need: cost['iron'] ?? 0,
                      have: settlement.iron,
                    ),
                    Container(
                        width: 1,
                        height: 36,
                        color: Colors.black
                            .withValues(alpha: 0.06)),
                    _CostItem(
                      icon: '⏱️',
                      label: 'เวลา',
                      need: building.upgradeSeconds,
                      have: building.upgradeSeconds,
                      isTime: true,
                      timeStr: _fmtSec(building.upgradeSeconds),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    canAfford ? color : Colors.grey[300],
                foregroundColor:
                    canAfford ? Colors.white : Colors.grey[600],
                padding:
                    const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: canAfford ? onUpgrade : null,
              child: Text(
                canAfford
                    ? 'อัปเกรด ${building.displayName} $emoji'
                    : 'ทรัพยากรไม่พอ',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final Color color;
  const _LevelBadge({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('Lv.$level',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color)),
    );
  }
}

class _CostItem extends StatelessWidget {
  final String icon, label;
  final int need, have;
  final bool isTime;
  final String? timeStr;

  const _CostItem({
    required this.icon,
    required this.label,
    required this.need,
    required this.have,
    this.isTime = false,
    this.timeStr,
  });

  @override
  Widget build(BuildContext context) {
    final ok = isTime || have >= need;
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 3),
        Text(
          isTime ? (timeStr ?? '$need') : '$need',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ok
                  ? const Color(0xFF2C1A05)
                  : const Color(0xFF993C1D)),
        ),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF888780))),
        if (!isTime)
          Text('มี $have',
              style: TextStyle(
                  fontSize: 9,
                  color: ok
                      ? const Color(0xFF5DCAA5)
                      : const Color(0xFFF0997B))),
      ],
    );
  }
}

// ─── Add Building Card ────────────────────────────────────────────
class _AddBuildingCard extends ConsumerWidget {
  final Settlement settlement;
  final List<Building> buildings;
  final int maxSlots;

  const _AddBuildingCard({
    required this.settlement,
    required this.buildings,
    required this.maxSlots,
  });

  static const _buildable = [
    'sawmill', 'smelter', 'rice_farm', 'distillery',
    'house', 'tavern', 'shrine', 'barracks',
    'elephant_camp', 'smithy', 'wall', 'watchtower',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFull = buildings.length >= maxSlots;

    if (isFull) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.black.withValues(alpha: 0.06),
              width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF5EFE6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                  child: Text('🏛️',
                      style: TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ที่ดินเต็มแล้ว',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3C2810))),
                  Text(
                      'อัพ Town Hall เพื่อปลดล็อกที่ดินเพิ่ม ($maxSlots slots)',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888780))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showBuildSheet(context, ref),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF3C2810).withValues(alpha: 0.06),
              const Color(0xFF854F0B).withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF854F0B).withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF854F0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF854F0B)
                        .withValues(alpha: 0.3),
                    width: 1),
              ),
              child: const Center(
                child: Icon(Icons.add_rounded,
                    color: Color(0xFF854F0B), size: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('สร้างอาคารใหม่',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF3C2810))),
                  Text(
                      'ช่องว่าง ${buildings.length}/$maxSlots',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888780))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3C2810),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('สร้าง',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFFAC775),
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBuildSheet(BuildContext context, WidgetRef ref) {
    final existing = buildings
        .where((b) => b.buildingType != 'house')
        .map((b) => b.buildingType)
        .toSet();
    final available =
        _buildable.where((t) => !existing.contains(t)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('สร้างอาคารครบทุกประเภทแล้ว'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BuildSheet(
        available: available,
        settlement: settlement,
        onBuild: (type) async {
          final service =
              BuildingService(ref.read(gameSupabaseProvider));
          try {
            await service.constructBuilding(
                settlement: settlement, buildingType: type);
            ref.invalidate(buildingsProvider);
            ref.invalidate(settlementProvider);
            if (context.mounted) Navigator.pop(context);
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$e'),
                  backgroundColor: const Color(0xFF993C1D),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ─── Build Sheet ──────────────────────────────────────────────────
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
    'sawmill':       {'wood': 100, 'iron': 50},
    'smelter':       {'wood': 150, 'iron': 100},
    'rice_farm':     {'wood': 80,  'iron': 40},
    'distillery':    {'wood': 120, 'iron': 80},
    'house':         {'wood': 50,  'iron': 25},
    'tavern':        {'wood': 100, 'iron': 60},
    'shrine':        {'wood': 110, 'iron': 70},
    'barracks':      {'wood': 200, 'iron': 150},
    'elephant_camp': {'wood': 250, 'iron': 180},
    'smithy':        {'wood': 160, 'iron': 120},
    'wall':          {'wood': 180, 'iron': 100},
    'watchtower':    {'wood': 140, 'iron': 90},
  };

  static const _desc = {
    'sawmill':       'ผลิตไม้ต่อ 5 นาที',
    'smelter':       'ผลิตเหล็กต่อ 5 นาที',
    'rice_farm':     'ผลิตข้าวต่อ 5 นาที',
    'distillery':    'ผลิตสุราต่อ 5 นาที',
    'house':         'เพิ่มประชากร +5 ต่อ level',
    'tavern':        'เพิ่มความสุข +2 ต่อ level',
    'shrine':        'เพิ่มความสุขและ buff',
    'barracks':      'ปลดล็อกการฝึกทหาร',
    'elephant_camp': 'ปลดล็อกช้างศึก',
    'smithy':        'เพิ่ม attack power',
    'wall':          'เพิ่ม defense +30 ต่อ level',
    'watchtower':    'เพิ่ม defense +15 ต่อ level',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5EFE6),
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCCC5BB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('เลือกอาคารที่จะสร้าง',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C1A05))),
          const SizedBox(height: 4),
          Text('มีทรัพยากร 🪵${settlement.wood}  ⚙️${settlement.iron}',
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF888780))),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: available.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
              itemBuilder: (_, i) =>
                  _BuildOption(
                    type: available[i],
                    cost: _costs[available[i]] ?? {},
                    desc: _desc[available[i]] ?? '',
                    settlement: settlement,
                    onBuild: onBuild,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildOption extends StatelessWidget {
  final String type;
  final Map<String, int> cost;
  final String desc;
  final Settlement settlement;
  final Function(String) onBuild;

  const _BuildOption({
    required this.type,
    required this.cost,
    required this.desc,
    required this.settlement,
    required this.onBuild,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(type);
    final emoji = _buildingEmoji[type] ?? '🏠';
    final canAfford = settlement.wood >= (cost['wood'] ?? 0) &&
        settlement.iron >= (cost['iron'] ?? 0);

    return GestureDetector(
      onTap: canAfford ? () => onBuild(type) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: canAfford ? Colors.white : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: canAfford
                ? color.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(
                    alpha: canAfford ? 0.12 : 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji,
                    style: const TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Building(
                      id: '',
                      settlementId: '',
                      buildingType: type,
                      level: 1,
                      isUpgrading: false,
                      createdAt: DateTime.now(),
                    ).displayName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: canAfford
                            ? const Color(0xFF2C1A05)
                            : Colors.grey[500]),
                  ),
                  Text(desc,
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _SmallCost(
                          icon: '🪵',
                          need: cost['wood'] ?? 0,
                          have: settlement.wood),
                      const SizedBox(width: 6),
                      _SmallCost(
                          icon: '⚙️',
                          need: cost['iron'] ?? 0,
                          have: settlement.iron),
                    ],
                  ),
                ],
              ),
            ),
            // Build button
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: canAfford
                    ? color
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                canAfford ? 'สร้าง' : 'ไม่พอ',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: canAfford
                        ? Colors.white
                        : Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallCost extends StatelessWidget {
  final String icon;
  final int need, have;
  const _SmallCost(
      {required this.icon, required this.need, required this.have});

  @override
  Widget build(BuildContext context) {
    final ok = have >= need;
    return Text(
      '$icon$need',
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: ok
              ? const Color(0xFF5DCAA5)
              : const Color(0xFF993C1D)),
    );
  }
}

// ─── Skeleton ──────────────────────────────────────────────────────
class _BuildingSkeleton extends StatelessWidget {
  const _BuildingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFE8DDD0),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          3,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                  width: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}
