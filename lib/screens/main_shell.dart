import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import 'chat/chat_list_screen.dart';
import 'discover/discover_screen.dart';
import 'feed/feed_screen.dart';
import 'match/match_alway.dart';
import 'profile/profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _index = 0;
  final _profileKey = GlobalKey<ProfileScreenState>();
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scaleAnims;
  late final List<Animation<double>> _rotateAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      5,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      ),
    );
    _scaleAnims = _controllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
      ]).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
    }).toList();
    _rotateAnims = [
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.18), weight: 30),
        TweenSequenceItem(tween: Tween(begin: -0.18, end: 0.12), weight: 30),
        TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.0), weight: 40),
      ]).animate(
        CurvedAnimation(parent: _controllers[0], curve: Curves.easeInOut),
      ),
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 100),
      ]).animate(_controllers[1]),
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.08), weight: 35),
        TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.06), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 0.06, end: 0.0), weight: 30),
      ]).animate(
        CurvedAnimation(parent: _controllers[2], curve: Curves.easeInOut),
      ),
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.25), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.0), weight: 50),
      ]).animate(
        CurvedAnimation(parent: _controllers[3], curve: Curves.easeInOut),
      ),
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.2), weight: 35),
        TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.1), weight: 30),
        TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0), weight: 35),
      ]).animate(
        CurvedAnimation(parent: _controllers[4], curve: Curves.easeInOut),
      ),
    ];
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTap(int i) {
    setState(() => _index = i);
    _controllers[i].forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const DiscoverScreen(),
      const FeedScreen(),
      const DatingFeedPage(),
      const ChatListScreen(),
      ProfileScreen(key: _profileKey),
    ];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: _IslandNavBar(
        selectedIndex: _index,
        onTap: _onTap,
        scaleAnims: _scaleAnims,
        rotateAnims: _rotateAnims,
        controllers: _controllers,
      ),
    );
  }
}

class _NavData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;

  const _NavData({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.color,
  });
}

class _IslandNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final List<Animation<double>> scaleAnims;
  final List<Animation<double>> rotateAnims;
  final List<AnimationController> controllers;

  const _IslandNavBar({
    required this.selectedIndex,
    required this.onTap,
    required this.scaleAnims,
    required this.rotateAnims,
    required this.controllers,
  });

  static const _inactiveColor = AppColors.textSecondary;
  static const _iconSize = 27.3;
  static const _specialTabDiameter = 38.0;
  static const _specialTabIconSize = 31.5;
  static const _specialTabVerticalOffset = -8.0;
  static const _itemVerticalPadding = 2.0;
  static const _labelSpacing = 3.0;

  static const _items = [
    _NavData(
      icon: Icons.person_search_outlined,
      activeIcon: Icons.person_search_rounded,
      label: 'หาเพื่อน',
      color: AppColors.iconPurple,
    ),
    _NavData(
      icon: Icons.favorite_border,
      activeIcon: Icons.favorite,
      label: 'ฟีด',
      color: AppColors.iconPink,
    ),
    _NavData(
      icon: Icons.auto_awesome_outlined,
      activeIcon: Icons.auto_awesome,
      label: 'สบัด',
      color: Color(0xFFFA9A2D),
    ),
    _NavData(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: 'แชท',
      color: AppColors.iconTeal,
    ),
    _NavData(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'โปรไฟล์',
      color: AppColors.iconBlue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border.withValues(alpha: 0.8)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: List.generate(_items.length, (i) {
                  final selected = selectedIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedBuilder(
                        animation: controllers[i],
                        builder: (context, child) {
                          final translated = Transform.translate(
                            offset: i == 2 ? Offset(0, _specialTabVerticalOffset) : Offset.zero,
                            child: Transform.rotate(
                              angle: rotateAnims[i].value,
                              child: Transform.scale(
                                scale: scaleAnims[i].value,
                                child: child,
                              ),
                            ),
                          );
                          return translated;
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: _itemVerticalPadding),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (i == 2)
                                _buildSpecialTab(selected)
                              else
                                _buildIcon(i, selected),
                              const SizedBox(height: _labelSpacing),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: GoogleFonts.notoSansThai(
                                  fontSize: 10,
                                  fontWeight: selected
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: selected
                                      ? _items[i].color
                                      : _inactiveColor,
                                ),
                                child: Text(_items[i].label),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              if (selectedIndex == 1)
                Positioned.fill(
                  child: IgnorePointer(child: _FeedParticlesOverlay()),
                ),
              if (selectedIndex == 3)
                Positioned.fill(
                  child: IgnorePointer(child: _ChatBubblesOverlay()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(int i, bool selected) {
    final color = selected ? _items[i].color : _inactiveColor;
    if (i == 1 && selected) return _PulsingHeart(color: color);
    return Icon(
      selected ? _items[i].activeIcon : _items[i].icon,
      size: _iconSize,
      color: color,
    );
  }

  Widget _buildSpecialTab(bool selected) {
    return Container(
      width: _specialTabDiameter,
      height: _specialTabDiameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: selected
              ? const [Color(0xFFFCD77F), Color(0xFFF58B23)]
              : const [Color(0xFFFBCB79), Color(0xFFF1892C)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF58B23).withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          selected ? _items[2].activeIcon : _items[2].icon,
          size: _specialTabIconSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PulsingHeart extends StatefulWidget {
  final Color color;
  const _PulsingHeart({required this.color});
  @override
  State<_PulsingHeart> createState() => _PulsingHeartState();
}

class _PulsingHeartState extends State<_PulsingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.15), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _anim,
    child: Icon(Icons.favorite, size: _IslandNavBar._iconSize, color: widget.color),
  );
}

class _ChatBubblesOverlay extends StatefulWidget {
  const _ChatBubblesOverlay();
  @override
  State<_ChatBubblesOverlay> createState() => _ChatBubblesOverlayState();
}

class _ChatBubblesOverlayState extends State<_ChatBubblesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 900),
          )
          ..addListener(() => setState(() {}))
          ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _BubblePainter(_ctrl.value));
}

class _BubblePainter extends CustomPainter {
  final double progress;
  _BubblePainter(this.progress);
  static final _bubbles = [
    [0.55, 0.0, 8.0],
    [0.62, 0.12, 12.0],
    [0.70, 0.06, 7.0],
    [0.58, 0.18, 9.0],
    [0.66, 0.03, 10.0],
  ];
  @override
  void paint(Canvas canvas, Size size) {
    for (final b in _bubbles) {
      final t = ((progress - b[1]) / (1.0 - b[1])).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final opacity = (t < 0.7 ? t / 0.7 : (1.0 - t) / 0.3).clamp(0.0, 1.0);
      final y = size.height - (t * size.height * 1.1);
      final x = b[0] * size.width;
      canvas.drawCircle(
        Offset(x, y),
        b[2] * (1 - t * 0.5),
        Paint()
          ..color = AppColors.iconTeal.withValues(alpha: opacity * 0.7)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        b[2] * (1 - t * 0.5),
        Paint()
          ..color = AppColors.iconTeal.withValues(alpha: opacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.progress != progress;
}

class _FeedParticlesOverlay extends StatefulWidget {
  const _FeedParticlesOverlay();
  @override
  State<_FeedParticlesOverlay> createState() => _FeedParticlesOverlayState();
}

class _FeedParticlesOverlayState extends State<_FeedParticlesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 700),
          )
          ..addListener(() => setState(() {}))
          ..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _ParticlePainter(_ctrl.value));
}

class _ParticlePainter extends CustomPainter {
  final double progress;
  _ParticlePainter(this.progress);
  static final _pts = [
    [-28.0, -24.0, 6.0],
    [28.0, -20.0, 5.0],
    [-20.0, -32.0, 4.0],
    [22.0, -30.0, 4.0],
    [0.0, -36.0, 5.0],
  ];
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.375;
    final cy = size.height * 0.45;
    for (final p in _pts) {
      final opacity = (progress < 0.6 ? progress / 0.6 : (1.0 - progress) / 0.4)
          .clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(cx + p[0] * progress, cy + p[1] * progress),
        p[2] * (1.0 - progress * 0.4),
        Paint()
          ..color = AppColors.destructive.withValues(alpha: opacity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
