import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/gender.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import 'match_popup.dart';

class SwipeScreen extends StatefulWidget {
  const SwipeScreen({super.key});

  @override
  State<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;
  int _currentIndex = 0;

  // Drag state
  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;
  bool _isDragging = false;

  late AnimationController _swipeOutController;
  late Animation<Offset> _swipeOutAnimation;
  bool _isSwipingOut = false;
  bool _swipeRight = false;

  @override
  void initState() {
    super.initState();
    _swipeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _loadProfiles();
  }

  @override
  void dispose() {
    _swipeOutController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final me = client.auth.currentUser;
      if (me == null) return;

      final likesData = await client
          .from('profile_likes')
          .select('liked_id')
          .eq('liker_id', me.id);

      final passesData = await client
          .from('profile_passes')
          .select('passed_id')
          .eq('passer_id', me.id);

      final excludedIds = <String>{};

      for (final row in likesData as List) {
        excludedIds.add(row['liked_id'] as String);
      }

      for (final row in passesData as List) {
        excludedIds.add(row['passed_id'] as String);
      }

      final blockedData = await client
          .from('blocked_users')
          .select('blocker_id, blocked_id')
          .or('blocker_id.eq.${me.id},blocked_id.eq.${me.id}');

      final Set<String> blockedIds = {};
      for (final row in blockedData as List) {
        if (row['blocker_id'] == me.id) {
          blockedIds.add(row['blocked_id'] as String);
        } else {
          blockedIds.add(row['blocker_id'] as String);
        }
      }

      final response = await client
          .from('profiles')
          .select('id, display_name, gender, birth_date, province, district, bio, is_online, is_verified, profile_photos(public_url, is_primary, sort_order)')
          .neq('id', me.id)
          .limit(30);

      if (!mounted) return;
      final List<Map<String, dynamic>> loaded = [];
      for (var row in response as List) {
        if (excludedIds.contains(row['id'])) {
          continue;
        }
        if (blockedIds.contains(row['id'])) {
          continue;
        }
        final photos = List<Map<String, dynamic>>.from(row['profile_photos'] ?? []);
        photos.sort((a, b) {
          if (a['is_primary'] == true) return -1;
          if (b['is_primary'] == true) return 1;
          return (a['sort_order'] ?? 999).compareTo(b['sort_order'] ?? 999);
        });
        final photoUrl = photos.isNotEmpty ? (photos.first['public_url'] ?? '') : '';

        int age = 0;
        if (row['birth_date'] != null) {
          final bd = DateTime.parse(row['birth_date']);
          age = DateTime.now().year - bd.year;
          if (DateTime.now().month < bd.month ||
              (DateTime.now().month == bd.month && DateTime.now().day < bd.day)) {
            age--;
          }
        }

        loaded.add({
          ...row,
          'photo_url': photoUrl,
          'age': age,
        });
      }

      setState(() {
        _profiles = loaded;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SwipeScreen error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLike() async {
    if (_currentIndex >= _profiles.length) return;
    final target = _profiles[_currentIndex];
    await _doSwipeOut(right: true);
    await _sendLike(target['id']);
  }

  Future<void> _handlePass() async {
    if (_currentIndex >= _profiles.length) return;
    await _doSwipeOut(right: false);
  }

  Future<void> _doSwipeOut({required bool right}) async {
    if (!mounted) return;
    setState(() {
      _isSwipingOut = true;
      _swipeRight = right;
    });

    final endX = right ? 500.0 : -500.0;
    _swipeOutAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(endX, _dragOffset.dy - 50),
    ).animate(CurvedAnimation(parent: _swipeOutController, curve: Curves.easeOut));

    _swipeOutController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 350));

    if (mounted) {
      setState(() {
        _currentIndex++;
        _dragOffset = Offset.zero;
        _dragAngle = 0;
        _isDragging = false;
        _isSwipingOut = false;
      });
    }
  }

  Future<void> _sendLike(String targetId) async {
    try {
      final client = Supabase.instance.client;
      final me = client.auth.currentUser!;

      await client.from('profile_likes').upsert({
        'liker_id': me.id,
        'liked_id': targetId,
      });

      final mutual = await client
          .from('profile_likes')
          .select()
          .eq('liker_id', targetId)
          .eq('liked_id', me.id)
          .maybeSingle();

      if (mutual != null) {
        final ids = [me.id, targetId]..sort();
        await client.from('matches').upsert({
          'user_a_id': ids[0],
          'user_b_id': ids[1],
          'matched_at': DateTime.now().toIso8601String(),
        });

        await client.from('conversations').upsert({
          'user_low_id': ids[0],
          'user_high_id': ids[1],
        });

        if (mounted) {
          final matchedProfile = _profiles.firstWhere((p) => p['id'] == targetId);
          await showDialog(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withValues(alpha: 0.85),
            builder: (_) => MatchPopup(
              myPhotoUrl: '',
              matchPhotoUrl: matchedProfile['photo_url'] ?? '',
              matchName: matchedProfile['display_name'] ?? '',
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Like error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // ขาวสว่างแบบมินิมอลสตูดิโอ
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grid_view_sharp, color: Colors.black26, size: 20), // ไอคอนทรงเหลี่ยม
            SizedBox(width: 8),
            Text('DISCOVER', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandPink))
          : _profiles.isEmpty || _currentIndex >= _profiles.length
              ? _buildEmpty()
              : _buildSwipeArea(),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.refresh_sharp, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          const Text('หมดคิวสำหรับตอนนี้แล้ว', style: TextStyle(color: Colors.black45, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () { setState(() { _currentIndex = 0; }); _loadProfiles(); },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black,
              side: const BorderSide(color: Colors.black, width: 2),
              shape: const LinearBorder(), // ปุ่มเหลี่ยมสนิท
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text('RELOAD', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeArea() {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        // Next card (ขยายเต็มจอขึ้น ปรับ Padding เหลือแค่ 8 และเว้นด้านล่างน้อยลง)
        if (_currentIndex + 1 < _profiles.length)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 40),
              child: Transform.scale(
                scale: 0.98,
                child: _buildCard(_profiles[_currentIndex + 1], isBack: true),
              ),
            ),
          ),

        // Current card (รูปใหญ่เกือบเต็มพื้นที่จอ)
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 40),
            child: GestureDetector(
              onPanStart: (_) => setState(() => _isDragging = true),
              onPanUpdate: (d) {
                if (!mounted) return;
                setState(() {
                  _dragOffset += d.delta;
                  _dragAngle = _dragOffset.dx / size.width * 0.3;
                });
              },
              onPanEnd: (_) {
                if (!mounted) return;
                setState(() => _isDragging = false);
                final threshold = size.width * 0.35;
                if (_dragOffset.dx > threshold) {
                  _handleLike();
                } else if (_dragOffset.dx < -threshold) {
                  _handlePass();
                } else {
                  if (mounted) {
                    setState(() { _dragOffset = Offset.zero; _dragAngle = 0; });
                  }
                }
              },
              child: AnimatedBuilder(
                animation: _swipeOutController,
                builder: (context, child) {
                  Offset offset = _isDragging || !_isSwipingOut ? _dragOffset : _swipeOutAnimation.value;
                  double angle = _isDragging || !_isSwipingOut ? _dragAngle : (_swipeRight ? 0.2 : -0.2);
                  return Transform.translate(
                    offset: offset,
                    child: Transform.rotate(
                      angle: angle,
                      child: child,
                    ),
                  );
                },
                child: Stack(
                  children: [
                    _buildCard(_profiles[_currentIndex], isBack: false),
                    // Like Stamp ทรงเหลี่ยมคม
                    if (_dragOffset.dx > 30)
                      Positioned(
                        top: 40,
                        left: 24,
                        child: _buildStamp('LIKE', AppColors.brandPink, _dragOffset.dx / 150),
                      ),
                    // Nope Stamp ทรงเหลี่ยมคม
                    if (_dragOffset.dx < -30)
                      Positioned(
                        top: 40,
                        right: 24,
                        child: _buildStamp('NOPE', Colors.black, (-_dragOffset.dx) / 150),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Action buttons (ปรับให้ลอยทับอยู่บนตัวการ์ดรูปภาพด้านล่างเพื่อประหยัดพื้นที่ ขยายรูปให้ใหญ่ขึ้นอีก)
        Positioned(
          bottom: 70,
          left: 0,
          right: 0,
          child: _buildActionButtons(),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> profile, {required bool isBack}) {
    final photoUrl = profile['photo_url'] as String? ?? '';
    final name = profile['display_name'] as String? ?? '';
    final age = profile['age'] as int? ?? 0;
    final district = profile['district'] as String? ?? '';
    final province = profile['province'] as String? ?? '';
    final bio = profile['bio'] as String? ?? '';
    final isVerified = profile['is_verified'] as bool? ?? false;
    final isOnline = profile['is_online'] as bool? ?? false;

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.zero, // 🛑 ลบขอบมนออกทั้งหมด เป็นทรงเหลี่ยมคม
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.zero, // 🛑 ลบขอบมนออกทั้งหมด
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo เต็มกรอบเหลี่ยม
            photoUrl.isNotEmpty
                ? Image.network(photoUrl, fit: BoxFit.cover)
                : Container(
                    color: const Color(0xFFEEEEEE),
                    child: const Icon(Icons.person_sharp, size: 100, color: Colors.black12),
                  ),

            // ไล่เฉดสีดำคมๆ ด้านล่างเพื่อให้ข้อความอ่านง่าย
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                    stops: const [0.0, 0.4, 0.65, 1.0],
                  ),
                ),
              ),
            ),

            if (!isBack) ...[
              // สถานะออนไลน์เหลี่ยมๆ แบบมินิมอล สตรีท
              if (isOnline)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.green, // สี่เหลี่ยมผืนผ้าทึบสีเขียว ไม่มีขอบมน
                    child: const Text(
                      'ONLINE',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),

              // ข้อมูลโปรไฟล์ด้านล่าง (ดันลงมาต่ำสุด และใช้ดีไซน์โมเดิร์นหนาๆ)
              Positioned(
                bottom: 110, // เผื่อพื้นที่ให้ปุ่มกดที่ลอยทับด้านบน
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${name.toUpperCase()} $age',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.verified_sharp, color: Colors.blueAccent, size: 24),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_sharp, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          (district.isNotEmpty ? '$district, $province' : province).toUpperCase(),
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    if (bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        bio,
                        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStamp(String text, Color color, double opacity) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.rotate(
        angle: text == 'LIKE' ? -0.15 : 0.15,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 4),
            borderRadius: BorderRadius.zero, // 🛑 สแตมป์เหลี่ยมสนิท
          ),
          child: Text(
            text,
            style: TextStyle(color: color, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 3),
          ),
        ),
      ),
    );
  }

  // แผงปุ่มกดทรงสี่เหลี่ยมจัตุรัสแบบสตรีท
  // 🛑 เปลี่ยนฟังก์ชัน _buildActionButtons() เดิม เป็นแบบนี้
Widget _buildActionButtons() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      // ปุ่มกากบาท (ขนาดใหญ่ 64)
      _ActionBtn(
        icon: Icons.close_sharp,
        color: Colors.black,
        bgColor: Colors.white,
        size: 64, // ขยายใหญ่ขึ้น
        onTap: _handlePass,
        btnType: 'pass',
      ),
      const SizedBox(width: 24),
      // ปุ่มดาว (ขนาดเล็ก 48)
      _ActionBtn(
        icon: Icons.star_sharp,
        color: const Color(0xFF00E5FF),
        bgColor: Colors.white,
        size: 48, // ขนาดเล็กกว่าปุ่มอื่น
        onTap: () {},
        btnType: 'star',
      ),
      const SizedBox(width: 24),
      // ปุ่มหัวใจ (ขนาดใหญ่ 64 + ใช้สี Gradient)
      _ActionBtn(
        icon: Icons.favorite_sharp,
        color: Colors.white,
        bgColor: AppColors.brandPink,
        size: 64, // ขยายใหญ่ขึ้น
        onTap: _handleLike,
        btnType: 'like',
      ),
      // 🛑 ลบปุ่มสายฟ้า (Bolt) ออกเรียบร้อยแล้ว
    ],
  );
}
}

// 🛑 เปลี่ยนคลาส _ActionBtn และ State ด้านล่างสุดของไฟล์ เป็นตัวนี้ทั้งหมดได้เลยครับ

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final double size;
  final VoidCallback onTap;
  final String btnType; // 'pass', 'star', 'like'

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.size,
    required this.onTap,
    required this.btnType,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _rotation; // อนิเมชั่นหมุนสำหรับปุ่มดาว

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    
    // อนิเมชั่นย่อขยายแบบนุ่มนวล
    _scale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.1), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    // อนิเมชั่นหมุน 180 องศาเฉพาะปุ่มดาว
    _rotation = Tween<double>(begin: 0.0, end: 0.5).animate(
  CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack), //  เปลี่ยนเป็น easeOutBack
);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLike = widget.btnType == 'like';
    final isPass = widget.btnType == 'pass';

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: () {
          _ctrl.forward(from: 0);
          widget.onTap();
        },
        child: RotationTransition(
          // ถ้าเป็นปุ่มดาว ให้กดแล้วหมุน ถ้าไม่ใช่ให้คงเดิม (0)
          turns: widget.btnType == 'star' ? _rotation : const AlwaysStoppedAnimation(0),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              // ⭕️ เปลี่ยนเป็นวงกลมตามบรีฟ สวยคลีนวัยรุ่นชอบ
              shape: BoxShape.circle, 
              color: isLike ? null : widget.bgColor,
              // ปุ่ม Like ใช้ไล่เฉดสีชมพูส้มสดใส ส่วนปุ่ม Pass ใช้ขอบนีออนแดงจางๆ
              gradient: isLike ? const LinearGradient(
                colors: [AppColors.brandPink, Color(0xFFFF7A5A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              border: Border.all(
                color: isLike ? Colors.transparent : (isPass ? Colors.red.withValues(alpha: 0.3) : widget.color.withValues(alpha: 0.2)),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isLike 
                      ? AppColors.brandPink.withValues(alpha: 0.4) 
                      : (isPass ? Colors.red.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Icon(widget.icon, color: widget.color, size: widget.size * 0.45),
          ),
        ),
      ),
    );
  }
}