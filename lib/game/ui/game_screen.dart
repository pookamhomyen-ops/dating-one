import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/game_providers.dart';
import 'map_tab.dart';
import 'building_tab.dart';
import 'troop_tab.dart';
import 'caravan_tab.dart';
import 'notification_tab.dart';


class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int _currentTab = 0;

  final _tabs = const [
    _TabItem(label: 'แผนที่',    icon: Icons.map_outlined),
    _TabItem(label: 'อาคาร',     icon: Icons.home_work_outlined),
    _TabItem(label: 'ทหาร',      icon: Icons.shield_outlined),
    _TabItem(label: 'คาราวาน',   icon: Icons.local_shipping_outlined),
    _TabItem(label: 'แจ้งเตือน', icon: Icons.notifications_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final settlementAsync = ref.watch(settlementProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar ทรัพยากร
            settlementAsync.when(
              data: (s) => s != null
                  ? _ResourceBar(settlement: s)
                  : const SizedBox.shrink(),
              loading: () => const _ResourceBarSkeleton(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Tab bar
            _TabBar(
              tabs: _tabs,
              currentIndex: _currentTab,
              onTap: (i) => setState(() => _currentTab = i),
            ),

            // Content
            Expanded(
              child: IndexedStack(
                index: _currentTab,
                children: const [
                  MapTab(),
                  BuildingTab(),
                  TroopTab(),
                  CaravanTab(),
                  NotificationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Resource bar ด้านบน
class _ResourceBar extends StatelessWidget {
  final settlement;
  const _ResourceBar({required this.settlement});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF3C2810),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            settlement.name,
            style: const TextStyle(
              color: Color(0xFFFAC775),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          _ResChip(icon: '🪵', value: settlement.wood),
          const SizedBox(width: 6),
          _ResChip(icon: '⚙️', value: settlement.iron),
          const SizedBox(width: 6),
          _ResChip(icon: '🌾', value: settlement.rice),
          const SizedBox(width: 6),
          _ResChip(icon: '🍶', value: settlement.liquor),
        ],
      ),
    );
  }
}

class _ResChip extends StatelessWidget {
  final String icon;
  final int value;
  const _ResChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$icon $value',
        style: const TextStyle(
          color: Color(0xFFFAC775),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ResourceBarSkeleton extends StatelessWidget {
  const _ResourceBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: const Color(0xFF3C2810),
    );
  }
}

// Tab bar
class _TabBar extends StatelessWidget {
  final List<_TabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _TabBar({
    required this.tabs,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      color: const Color(0xFFF5EFE6),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF3C2810)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? const Color(0xFF854F0B)
                        : Colors.transparent,
                    width: 0.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      tabs[i].icon,
                      size: 16,
                      color: selected
                          ? const Color(0xFFFAC775)
                          : const Color(0xFF888780),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tabs[i].label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: selected
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: selected
                            ? const Color(0xFFFAC775)
                            : const Color(0xFF888780),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem({required this.label, required this.icon});
}