import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';

// ── Provider ────────────────────────────────────────────────────
final leaderboardProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final gameClient = ref.watch(gameSupabaseProvider);
  final data = await gameClient.rpc('get_leaderboard', params: {'p_limit': 20});
  return List<Map<String, dynamic>>.from(data ?? []);
});

// ── Main Widget ──────────────────────────────────────────────────
class LeaderboardTab extends ConsumerWidget {
  const LeaderboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaderboardProvider);
    final mySettlement = ref.watch(settlementProvider).valueOrNull;

    return async.when(
      data: (rows) => _LeaderboardView(rows: rows, myId: mySettlement?.id),
      loading: () => const _Skeleton(),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text('$e', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ── View ────────────────────────────────────────────────────────
class _LeaderboardView extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final String? myId;
  const _LeaderboardView({required this.rows, this.myId});

  @override
  Widget build(BuildContext context) {
    final myRank = rows.indexWhere((r) => r['settlement_id'] == myId) + 1;

    return CustomScrollView(
      slivers: [
        // ── Header ──
        SliverToBoxAdapter(
          child: _Header(myRank: myRank, total: rows.length),
        ),

        // ── Top 3 podium ──
        if (rows.length >= 3)
          SliverToBoxAdapter(
            child: _Podium(rows: rows.take(3).toList()),
          ),

        // ── List ──
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final row = rows[i];
                final isMe = row['settlement_id'] == myId;
                return _LeaderRow(
                  rank: i + 1,
                  row: row,
                  isMe: isMe,
                );
              },
              childCount: rows.length,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Header ──────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final int myRank, total;
  const _Header({required this.myRank, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2A2A), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2A2A).withValues(alpha: 0.35),
            blurRadius: 10, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('กระดานอันดับ',
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700,
                    color: Color(0xFF5EEAD4))),
                Text('ผู้เล่นทั้งหมด $total คน',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
          if (myRank > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF5EEAD4).withValues(alpha: 0.4)),
              ),
              child: Text(
                'คุณ #$myRank',
                style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFF5EEAD4)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Podium Top 3 ────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _Podium({required this.rows});

  @override
  Widget build(BuildContext context) {
    // เรียง: 2nd, 1st, 3rd
    final order = [1, 0, 2];
    final heights = [80.0, 100.0, 60.0];
    final medals = ['🥈', '🥇', '🥉'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final row = rows[order[i]];
          final name = row['settlement_name'] as String? ?? '???';
          final score = row['score'] as int? ?? 0;
          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(medals[i], style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  name.length > 8 ? '${name.substring(0, 8)}…' : name,
                  style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: Color(0xFF0F2A2A)),
                  textAlign: TextAlign.center,
                ),
                Text('$score pts',
                  style: const TextStyle(
                    fontSize: 10, color: Color(0xFF0D9488))),
                const SizedBox(height: 4),
                Container(
                  height: heights[i],
                  decoration: BoxDecoration(
                    color: i == 1
                        ? const Color(0xFF0D9488)
                        : const Color(0xFF0D9488).withValues(alpha: 0.4),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8)),
                  ),
                  child: Center(
                    child: Text('${order[i] + 1}',
                      style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900,
                        color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Row ──────────────────────────────────────────────────────────
class _LeaderRow extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> row;
  final bool isMe;
  const _LeaderRow({required this.rank, required this.row, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    final name       = row['settlement_name'] as String? ?? '???';
    final score      = row['score'] as int? ?? 0;
    final wins       = row['wins'] as int? ?? 0;
    final troops     = row['troop_count'] as int? ?? 0;
    final rankLabel  = row['rank_label'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFCCFBF1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? const Color(0xFF0D9488)
              : Colors.black.withValues(alpha: 0.06),
          width: isMe ? 1.2 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4, offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // rank badge
          SizedBox(
            width: 32,
            child: Text(
              rank <= 3
                  ? ['🥇', '🥈', '🥉'][rank - 1]
                  : '#$rank',
              style: TextStyle(
                fontSize: rank <= 3 ? 20 : 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F2A2A)),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F2A2A)),
                        overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 6),
                    if (isMe)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('คุณ',
                          style: TextStyle(
                            fontSize: 9, color: Colors.white,
                            fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('$rankLabel  •  ⚔️$wins ชนะ  •  🪖$troops ทหาร',
                  style: const TextStyle(
                    fontSize: 10, color: Color(0xFF888780))),
              ],
            ),
          ),

          // score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$score',
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800,
                  color: Color(0xFF0D9488))),
              const Text('pts',
                style: TextStyle(fontSize: 9, color: Color(0xFF888780))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Skeleton ─────────────────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFFD1EAE8),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(5, (i) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.black.withValues(alpha: 0.06), width: 0.5),
          ),
        )),
      ],
    );
  }
}