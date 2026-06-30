import 'dart:async';
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
    final troopsAsync = ref.watch(troopsProvider);

    return settlementAsync.when(
      data: (settlement) => troopsAsync.when(
        data: (troops) => settlement != null
            ? _TroopView(settlement: settlement, troops: troops)
            : const SizedBox.shrink(),
        loading: () => const _TroopSkeleton(),
        error: (e, _) => Center(child: Text('$e')),
      ),
      loading: () => const _TroopSkeleton(),
      error: (e, _) => Center(child: Text('$e')),
    );
  }
}

// ─── Main View ───────────────────────────────────────────────────
class _TroopView extends StatelessWidget {
  final Settlement settlement;
  final List<Troop> troops;
  const _TroopView({required this.settlement, required this.troops});

  @override
  Widget build(BuildContext context) {
    final totalTroops = troops.fold(0, (sum, t) => sum + t.count);
    final trainingTroops = troops.where((t) => t.isTraining).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ── Stats Header ──
        _StatsHeader(settlement: settlement, totalTroops: totalTroops),
        const SizedBox(height: 10),

        // ── Training in progress banner ──
        if (trainingTroops.isNotEmpty) ...[
          _TrainingBanner(troops: trainingTroops),
          const SizedBox(height: 10),
        ],

        // ── Section label ──
        _SectionLabel(
          icon: '⚔️',
          label: 'กองทัพของคุณ',
          sub: '${troops.length} ประเภท',
        ),
        const SizedBox(height: 8),

        // ── Troop cards ──
        ...troops.map((t) => _TroopCard(
              troop: t,
              settlement: settlement,
              allTroops: troops,
            )),
      ],
    );
  }
}

// ─── Stats Header ─────────────────────────────────────────────────
class _StatsHeader extends ConsumerWidget {
  final Settlement settlement;
  final int totalTroops;
  const _StatsHeader(
      {required this.settlement, required this.totalTroops});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thLevel = ref.watch(townHallLevelProvider);
    final troopCap = Building.maxTroopCap(thLevel);
    final troopFull = totalTroops >= troopCap;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2A2A), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2A2A).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Population
          Expanded(
            child: _HeaderStat(
              emoji: '👥',
              label: 'ประชาชน',
              value: '${settlement.population}',
              sub: 'สูงสุด ${settlement.maxPopulation}',
              valueColor: const Color(0xFFCCFBF1),
            ),
          ),
          Container(
              width: 1,
              height: 40,
              color: Colors.white.withValues(alpha: 0.15)),
          // Troops
          Expanded(
            child: _HeaderStat(
              emoji: '⚔️',
              label: 'ทหารทั้งหมด',
              value: '$totalTroops',
              sub: 'cap $troopCap',
              valueColor:
                  troopFull ? const Color(0xFFF0997B) : const Color(0xFFFAEEDA),
            ),
          ),
          Container(
              width: 1,
              height: 40,
              color: Colors.white.withValues(alpha: 0.15)),
          // Happiness
          Expanded(
            child: _HeaderStat(
              emoji: settlement.happinessEmoji,
              label: 'ความสุข',
              value: '${settlement.happiness}%',
              sub: settlement.happiness >= 40 ? 'ปกติ' : 'ต่ำ!',
              valueColor: settlement.happiness >= 40
                  ? const Color(0xFF5DCAA5)
                  : const Color(0xFFF0997B),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String emoji, label, value, sub;
  final Color valueColor;
  const _HeaderStat({
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: valueColor)),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.6))),
        Text(sub,
            style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.4))),
      ],
    );
  }
}

// ─── Training Banner ──────────────────────────────────────────────
class _TrainingBanner extends StatefulWidget {
  final List<Troop> troops;
  const _TrainingBanner({required this.troops});

  @override
  State<_TrainingBanner> createState() => _TrainingBannerState();
}

class _TrainingBannerState extends State<_TrainingBanner> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF9FE1CB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F6E56),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text('กำลังฝึกทหาร',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F6E56))),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.troops.map((t) => _TrainingProgress(troop: t)),
        ],
      ),
    );
  }
}

class _TrainingProgress extends StatelessWidget {
  final Troop troop;
  const _TrainingProgress({required this.troop});

  @override
  Widget build(BuildContext context) {
    final remaining = troop.trainingTimeRemaining ?? Duration.zero;
    // trainingSeconds ต่อ 10 คน → scale ตาม trainingCount
    final total = Duration(
        seconds: (troop.trainingSeconds * troop.trainingCount / 10).ceil());
    final fraction =
        total.inSeconds > 0
            ? 1.0 - (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0)
            : 1.0;

    final mm = remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(troop.emoji,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text('${troop.displayName} ×${troop.trainingCount}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A3D2E))),
              const Spacer(),
              Text('$mm:$ss',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F6E56),
                      fontFeatures: [FontFeature.tabularFigures()])),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: const Color(0xFFCCEEE4),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF0F6E56)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Label ────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String icon, label, sub;
  const _SectionLabel(
      {required this.icon, required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F2A2A))),
        const SizedBox(width: 6),
        Text(sub,
            style: const TextStyle(
                fontSize: 11, color: Color(0xFF888780))),
        const Spacer(),
      ],
    );
  }
}

// ─── Troop Card ───────────────────────────────────────────────────
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
    final isTraining = troop.isTraining;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTraining
              ? const Color(0xFF9FE1CB)
              : Colors.black.withValues(alpha: 0.07),
          width: isTraining ? 1 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Emoji + count ──
            Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(troop.emoji,
                        style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(height: 4),
                Text('×${troop.count}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F2A2A))),
              ],
            ),
            const SizedBox(width: 12),

            // ── Info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(troop.displayName,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C1A05))),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _CostChip(label: '🪵 ${troop.costPerUnit['wood']}'),
                      const SizedBox(width: 4),
                      _CostChip(label: '⚙️ ${troop.costPerUnit['iron']}'),
                      const SizedBox(width: 4),
                      _CostChip(label: '⏱ ${troop.trainingSeconds}s'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _StatChip(
                          icon: '🗡️',
                          value: '${troop.attackPower}',
                          color: const Color(0xFFF0997B)),
                      const SizedBox(width: 4),
                      _StatChip(
                          icon: '🛡️',
                          value: '${troop.defensePower}',
                          color: const Color(0xFF7BAFD4)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // ── Train button ──
            _TrainButton(
              troop: troop,
              settlement: settlement,
              allTroops: allTroops,
            ),
          ],
        ),
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  final String label;
  const _CostChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFECF4F4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 10, color: Color(0xFF0F766E))),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon, value;
  final Color color;
  const _StatChip(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$icon $value',
          style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Train Button ─────────────────────────────────────────────────
class _TrainButton extends ConsumerWidget {
  final Troop troop;
  final Settlement settlement;
  final List<Troop> allTroops;

  const _TrainButton({
    required this.troop,
    required this.settlement,
    required this.allTroops,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (troop.isTraining) {
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F8F3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: const Color(0xFF9FE1CB), width: 0.8),
        ),
        child: const Column(
          children: [
            Text('🔄',
                style: TextStyle(fontSize: 14)),
            SizedBox(height: 2),
            Text('กำลังฝึก',
                style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF0F6E56),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showTrainSheet(context, ref),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F6E56), Color(0xFF1A9070)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F6E56).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Column(
          children: [
            Text('⚔️', style: TextStyle(fontSize: 16)),
            SizedBox(height: 2),
            Text('ฝึก',
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showTrainSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TrainSheet(
        troop: troop,
        settlement: settlement,
        allTroops: allTroops,
        onDone: () {
          ref.invalidate(troopsProvider);
          ref.invalidate(settlementProvider);
        },
      ),
    );
  }
}

// ─── Train Bottom Sheet ───────────────────────────────────────────
class _TrainSheet extends ConsumerStatefulWidget {
  final Troop troop;
  final Settlement settlement;
  final List<Troop> allTroops;
  final VoidCallback onDone;

  const _TrainSheet({
    required this.troop,
    required this.settlement,
    required this.allTroops,
    required this.onDone,
  });

  @override
  ConsumerState<_TrainSheet> createState() => _TrainSheetState();
}

class _TrainSheetState extends ConsumerState<_TrainSheet> {
  int _amount = 5;
  bool _loading = false;

  int get _maxAffordable {
    final wood = widget.settlement.wood;
    final iron = widget.settlement.iron;
    final costWood = widget.troop.costPerUnit['wood'] ?? 0;
    final costIron = widget.troop.costPerUnit['iron'] ?? 0;
    final byWood = costWood > 0 ? wood ~/ costWood : 9999;
    final byIron = costIron > 0 ? iron ~/ costIron : 9999;
    final thLevel = ref.read(townHallLevelProvider);
    final troopCap = Building.maxTroopCap(thLevel);
    final totalTroops = widget.allTroops.fold(0, (s, t) => s + t.count);
    final byPop = troopCap - totalTroops;
    return [byWood, byIron, byPop, 50].reduce((a, b) => a < b ? a : b)
        .clamp(0, 50);
  }

  int get _totalWood =>
      (widget.troop.costPerUnit['wood'] ?? 0) * _amount;
  int get _totalIron =>
      (widget.troop.costPerUnit['iron'] ?? 0) * _amount;

  String _fmtDuration(int secondsPer10) {
    // trainingSeconds คือต่อ 10 คน → คำนวณตามจำนวนจริง
    final total = (secondsPer10 * _amount / 10).ceil();
    if (total < 60) return '${total}วิ';
    return '${total ~/ 60}นาที ${total % 60}วิ';
  }

  @override
  Widget build(BuildContext context) {
    final max = _maxAffordable;
    if (_amount > max) _amount = max.clamp(1, 50);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFECF4F4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFB2DFDB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBF1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(widget.troop.emoji,
                      style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ฝึก${widget.troop.displayName}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F2A2A))),
                  Text('มีอยู่ ${widget.troop.count} คน',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF888780))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Amount slider
          Row(
            children: [
              const Text('จำนวน',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF5F5E5A))),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('$_amount คน',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5EEAD4))),
              ),
            ],
          ),
          Slider(
            value: _amount.toDouble(),
            min: 1,
            max: max > 0 ? max.toDouble() : 1,
            divisions: max > 1 ? max - 1 : 1,
            activeColor: const Color(0xFF0F6E56),
            inactiveColor: const Color(0xFFCCEEE4),
            onChanged: max > 0
                ? (v) => setState(() => _amount = v.round())
                : null,
          ),

          // Quick select
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [5, 10, 20, 50]
                .where((v) => v <= max)
                .map((v) => Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _amount = v),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _amount == v
                                ? const Color(0xFF0F6E56)
                                : const Color(0xFFE1F5EE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('+$v',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _amount == v
                                      ? Colors.white
                                      : const Color(0xFF0F6E56))),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),

          // Cost summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.black.withValues(alpha: 0.07),
                  width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                    icon: '🪵',
                    label: 'ไม้',
                    value: '$_totalWood',
                    ok: widget.settlement.wood >= _totalWood),
                _SummaryItem(
                    icon: '⚙️',
                    label: 'เหล็ก',
                    value: '$_totalIron',
                    ok: widget.settlement.iron >= _totalIron),
                _SummaryItem(
                    icon: '⏱',
                    label: 'เวลา',
                    value: _fmtDuration(widget.troop.trainingSeconds),
                    ok: true),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: max > 0
                    ? const Color(0xFF0F6E56)
                    : Colors.grey[300],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: (max > 0 && !_loading) ? _confirm : null,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      max > 0
                          ? 'ฝึกทหาร $_amount คน ⚔️'
                          : 'ทรัพยากรหรือที่พักไม่พอ',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final service =
          TroopService(ref.read(gameSupabaseProvider));
      await service.trainTroops(
        troop: widget.troop,
        settlement: widget.settlement,
        allTroops: widget.allTroops,
        amount: _amount,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onDone();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '⚔️ เริ่มฝึก${widget.troop.displayName} $_amount คนแล้ว!'),
            backgroundColor: const Color(0xFF0F6E56),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String icon, label, value;
  final bool ok;
  const _SummaryItem(
      {required this.icon,
      required this.label,
      required this.value,
      required this.ok});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ok
                    ? const Color(0xFF2C1A05)
                    : const Color(0xFF993C1D))),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF888780))),
      ],
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────
class _TroopSkeleton extends StatelessWidget {
  const _TroopSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFD1EAE8),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 10),
        ...List.generate(
            3,
            (i) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.black.withValues(alpha: 0.06),
                        width: 0.5),
                  ),
                )),
      ],
    );
  }
}