import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'match_popup.dart';
import '../../models/gender.dart';
import '../../models/chat_thread.dart';
import '../chat/chat_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';
import '../../game/ui/game_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MemberProfileScreen extends StatefulWidget {
  final String memberId;

  const MemberProfileScreen({super.key, required this.memberId});

  @override
  State<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends State<MemberProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  List<String> _photoUrls = [];
  List<String> _interests = [];
  List<String> _secretPhotoUrls = [];
  int _currentImageIndex = 0;
  bool _isLiked = false; // สำหรับสถานะกดใจเบื้องต้น
  bool _isPassed = false;
  bool _isBlocked = false;
  bool _isBlockedByThem = false;
  bool _isFollowing = false;
  Map<String, dynamic>? _goWhereData;

  @override
  void initState() {
    super.initState();
    _fetchMemberDetails();
  }

  Future<void> _fetchMemberDetails() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;

      final response = await client
          .from('profiles')
          .select('''
  id, display_name, gender, birth_date, bio, province, district, occupation, relationship_status, current_activity, is_verified, line_id, instagram,
  profile_photos(public_url, is_primary, sort_order),
  profile_interests(interests:interest_id(name)) 
''')
          .eq('id', widget.memberId)
          .single();

      final photos = List<Map<String, dynamic>>.from(
        response['profile_photos'] ?? [],
      );
      photos.sort((a, b) {
        if (a['is_primary'] == true && b['is_primary'] != true) return -1;
        if (a['is_primary'] != true && b['is_primary'] == true) return 1;
        return (a['sort_order'] as int? ?? 999).compareTo(
          b['sort_order'] as int? ?? 999,
        );
      });

      final List<String> loadedInterests = [];
      for (var pi in (response['profile_interests'] as List? ?? [])) {
        final name = pi['interests']?['name'];
        if (name != null) loadedInterests.add(name as String);
      }

      final me = client.auth.currentUser;
      bool isBlocked = false;
      bool isBlockedByThem = false;
      bool isFollowing = false;
      if (me != null) {
        final blockCheck = await client
            .from('blocked_users')
            .select('blocker_id, blocked_id')
            .or('and(blocker_id.eq.${me.id},blocked_id.eq.${widget.memberId}),and(blocker_id.eq.${widget.memberId},blocked_id.eq.${me.id})');
        for (final row in blockCheck as List) {
          if (row['blocker_id'] == me.id) isBlocked = true;
          if (row['blocker_id'] == widget.memberId) isBlockedByThem = true;
        }

        final followCheck = await client
            .from('follows')
            .select('follower_id')
            .eq('follower_id', me.id)
            .eq('followed_id', widget.memberId)
            .maybeSingle();
        isFollowing = followCheck != null;
      }

      final secretData = await client
          .from('secret_photos')
          .select()
          .eq('profile_id', widget.memberId)
          .order('sort_order');

      final secretUrls = (secretData as List)
          .map((p) => p['public_url'] as String)
          .where((url) => url.isNotEmpty)
          .toList();

      final goWhereData = await client
          .from('gowhere')
          .select()
          .eq('profile_id', widget.memberId)
          .maybeSingle();

      setState(() {
        _profileData = response;
        _photoUrls = photos.map((p) => p['public_url'] as String).toList();
        _interests = loadedInterests;
        _secretPhotoUrls = secretUrls;
        _isLoading = false;
        _isBlocked = isBlocked;
        _isBlockedByThem = isBlockedByThem;
        _isFollowing = isFollowing;
        _goWhereData = goWhereData;
      });
    } catch (e) {
      debugPrint('🔴 Supabase Detail Error: $e');
    }
  }

  final PageController _profileImageController = PageController();

  int _calculateAge(String? birthDateStr) {
    if (birthDateStr == null) return 0;
    final birthDate = DateTime.parse(birthDateStr);
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  bool _isNavigatingToChat = false;

  Future<void> _navigateToChat() async {
    if (_isNavigatingToChat) return;
    _isNavigatingToChat = true;
    try {
      final me = Supabase.instance.client.auth.currentUser;
      if (me == null) return;
      final ids = [me.id, widget.memberId]..sort();

      // เช็คก่อนว่ามี conversation อยู่แล้วหรือยัง
      final existing = await Supabase.instance.client
          .from('conversations')
          .select('id')
          .eq('user_low_id', ids[0])
          .eq('user_high_id', ids[1])
          .maybeSingle();

      String convId;
      if (existing != null) {
        // มีอยู่แล้ว ใช้อันเดิม
        convId = existing['id'] as String;
      } else {
        // ยังไม่มี สร้างใหม่
        final created = await Supabase.instance.client
            .from('conversations')
            .insert({
              'user_low_id': ids[0],
              'user_high_id': ids[1],
            })
            .select('id')
            .single();
        convId = created['id'] as String;
      }

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            thread: ChatThread(
              id: convId,
              partnerName: _profileData!['display_name'] as String? ?? '',
              partnerPhotoUrl: _photoUrls.isNotEmpty ? _photoUrls.first : '',
              lastMessage: '',
              lastMessageAt: DateTime.now(),
              isOnline: _profileData!['is_online'] as bool? ?? false,
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Chat nav error: $e');
    } finally {
      _isNavigatingToChat = false;
    }
  }

  Future<void> _toggleFollow() async {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) return;
    final wasFollowing = _isFollowing;
    setState(() => _isFollowing = !wasFollowing);
    try {
      if (wasFollowing) {
        await Supabase.instance.client
            .from('follows')
            .delete()
            .eq('follower_id', me.id)
            .eq('followed_id', widget.memberId);
      } else {
        await Supabase.instance.client.from('follows').upsert({
          'follower_id': me.id,
          'followed_id': widget.memberId,
        });
      }
    } catch (e) {
      debugPrint('Follow error: $e');
      if (mounted) setState(() => _isFollowing = wasFollowing);
    }
  }

  void _handleImageTap(TapDownDetails details, double screenWidth) {
    if (_photoUrls.length <= 1) return;

    final double tapX = details.globalPosition.dx;
    final bool isTapOnRight = tapX > (screenWidth / 2);

    if (isTapOnRight) {
      if (_currentImageIndex < _photoUrls.length - 1) {
        final nextIndex = _currentImageIndex + 1;
        setState(() => _currentImageIndex = nextIndex);
        _profileImageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
        );
      }
    } else {
      if (_currentImageIndex > 0) {
        final prevIndex = _currentImageIndex - 1;
        setState(() => _currentImageIndex = prevIndex);
        _profileImageController.animateToPage(
          prevIndex,
          duration: const Duration(milliseconds: 50),
          curve: Curves.linear,
        );
      }
    }
  }

  void _openFullScreenGallery(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          int localIndex = initialIndex;
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Scaffold(
                backgroundColor: AppColors.textPrimary,
                body: Stack(
                  children: [
                    PageView.builder(
                      itemCount: _photoUrls.length,
                      controller: PageController(initialPage: initialIndex),
                      onPageChanged: (index) =>
                          setModalState(() => localIndex = index),
                      itemBuilder: (context, index) => Center(
                        child: InteractiveViewer(
                          maxScale: 4.0,
                          child: Image.network(
                            _photoUrls[index],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 20,
                      child: IconButton(
                        icon: const CircleAvatar(
                          backgroundColor: AppColors.textPrimary,
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.background,
                            size: 22,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openImageCommentsDialog(String imageUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: Image.network(imageUrl, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.brandPink,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ความคิดเห็น',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCommentTile(
                        name: 'มิลค์คาร์เมล ✨',
                        comment: 'งู้ยยยยย ลุคนี้คือน่ารักใจเจ็บมากเลยค่าาา 🥰',
                        time: '10 นาทีที่แล้ว',
                        isFemale: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentTile({
    required String name,
    required String comment,
    required String time,
    required bool isFemale,
  }) {
    final themeColor = isFemale ? AppColors.iconPink : AppColors.iconBlue;
    final bgColor = isFemale
        ? AppColors.iconPink.withValues(alpha: 0.1)
        : AppColors.iconBlue.withValues(alpha: 0.1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: bgColor,
          child: Icon(
            isFemale ? Icons.female_rounded : Icons.male_rounded,
            color: themeColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: themeColor,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showReportBlockMenu() {
    final name = _profileData?['display_name'] ?? '';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: AppColors.destructive),
                title: Text('รายงาน $name', style: const TextStyle(color: AppColors.destructive)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showReportReasonSheet();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: AppColors.destructive),
                title: Text('บล็อก $name', style: const TextStyle(color: AppColors.destructive)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmBlock();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportReasonSheet() {
    String? selectedReason;
    String? selectedSubtype;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final reasons = [
            {'value': 'scam_money', 'label': 'หลอกโอนเงิน'},
            {'value': 'rude_language', 'label': 'พูดจาหยาบคาย'},
            {'value': 'nudity', 'label': 'ภาพโป๊เปลือย'},
            {'value': 'just_block', 'label': 'อยากบล็อกเฉยๆ'},
            {'value': 'gender_mismatch', 'label': 'เพศไม่ตรงตามจริง'},
          ];
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'เลือกเหตุผลในการรายงาน',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    ...reasons.map((r) => RadioListTile<String>(
                          value: r['value']!,
                          groupValue: selectedReason,
                          title: Text(r['label']!),
                          activeColor: AppColors.brandPink,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (v) => setSheetState(() => selectedReason = v),
                        )),
                    if (selectedReason == 'gender_mismatch') ...[
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 4, bottom: 4),
                        child: Text('ระบุเพิ่มเติม', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ),
                      RadioListTile<String>(
                        value: 'is_ladyboy',
                        groupValue: selectedSubtype,
                        title: const Text('เขาเป็นกระเทย'),
                        activeColor: AppColors.brandPink,
                        contentPadding: const EdgeInsets.only(left: 16),
                        onChanged: (v) => setSheetState(() => selectedSubtype = v),
                      ),
                      RadioListTile<String>(
                        value: 'not_sure',
                        groupValue: selectedSubtype,
                        title: const Text('ไม่แน่ใจ'),
                        activeColor: AppColors.brandPink,
                        contentPadding: const EdgeInsets.only(left: 16),
                        onChanged: (v) => setSheetState(() => selectedSubtype = v),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: selectedReason == null
                            ? null
                            : () {
                                Navigator.pop(ctx);
                                _submitReport(selectedReason!, selectedSubtype);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('ส่งรายงาน'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitReport(String reason, String? subtype) async {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) return;
    try {
      await Supabase.instance.client.from('reports').insert({
        'reporter_id': me.id,
        'reported_id': widget.memberId,
        'reason': reason,
        'gender_mismatch_subtype': ?subtype,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ส่งรายงานเรียบร้อยแล้ว')),
        );
      }
    } catch (e) {
      debugPrint('Report error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ส่งรายงานไม่สำเร็จ: $e'), backgroundColor: AppColors.destructive),
        );
      }
    }
  }

  void _confirmBlock() {
    final name = _profileData?['display_name'] ?? '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการบล็อก'),
        content: Text('คุณต้องการบล็อก $name ใช่หรือไม่? คุณจะไม่เห็นกันอีกต่อไป'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('บล็อก', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    ).then((confirm) {
      if (confirm == true) _doBlock();
    });
  }

  Future<void> _doBlock() async {
    final me = Supabase.instance.client.auth.currentUser;
    if (me == null) return;
    try {
      await Supabase.instance.client.from('blocked_users').insert({
        'blocker_id': me.id,
        'blocked_id': widget.memberId,
      });
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Block error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บล็อกไม่สำเร็จ: $e'), backgroundColor: AppColors.destructive),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profileData == null) {
      return const Scaffold(body: Center(child: Text('ไม่พบข้อมูลสมาชิก')));
    }

    final age = _calculateAge(_profileData!['birth_date']);
    final isVerified = _profileData!['is_verified'] ?? false;
    final screenHeight = MediaQuery.of(context).size.height;

    Gender gender;
    switch (_profileData!['gender']) {
      case 'female':
        gender = Gender.female;
        break;
      case 'male':
        gender = Gender.male;
        break;
      default:
        gender = Gender.other;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double screenWidth = constraints.maxWidth;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTapDown: (details) =>
                          _handleImageTap(details, screenWidth),
                      onLongPress: () => _openFullScreenGallery(
                        _currentImageIndex,
                      ),
                      child: SizedBox(
                        height: screenHeight * 0.65,
                        width: double.infinity,
                        child: _photoUrls.isEmpty
                            ? Container(
                                color: AppColors.textSecondary,
                                child: const Icon(Icons.person, size: 100),
                              )
                            : PageView.builder(
                                controller: _profileImageController,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _photoUrls.length,
                                onPageChanged: (index) =>
                                    setState(() => _currentImageIndex = index),
                                itemBuilder: (context, index) =>
                                    NetworkImageBox(
                                      url: _photoUrls[index],
                                      borderRadius: 0,
                                    ),
                              ),
                      ),
                    ),
                    if (_photoUrls.length > 1)
                      Positioned(
                        top: 50,
                        left: 20,
                        right: 20,
                        child: Row(
                          children: List.generate(
                            _photoUrls.length,
                            (index) => Expanded(
                              child: Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _currentImageIndex == index
                                      ? AppColors.background
                                      : AppColors.background.withValues(
                                          alpha: 0.3,
                                        ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 60,
                      left: 10,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const CircleAvatar(
                          backgroundColor: AppColors.textPrimary,
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.background,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 60,
                      right: 10,
                      child: IconButton(
                        onPressed: _showReportBlockMenu,
                        icon: const CircleAvatar(
                          backgroundColor: AppColors.textPrimary,
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: AppColors.background,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -32,
                      right: 16,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AnimatedActionButton(
                            icon: Icons.close_rounded,
                            color: AppColors.textSecondary,
                            size: 64,
                            onTap: () async {
                              setState(() => _isPassed = true);
                              final me =
                                  Supabase.instance.client.auth.currentUser;
                              if (me != null) {
                                try {
                                  await Supabase.instance.client
                                      .from('profile_passes')
                                      .upsert({
                                    'passer_id': me.id,
                                    'passed_id': widget.memberId,
                                  });
                                } catch (_) {}
                              }
                              if (mounted) Navigator.pop(context, 'passed');
                            },
                          ),
                          const SizedBox(width: 12),
                          _AnimatedActionButton(
                            icon: _isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: AppColors.brandPink,
                            isFilled: _isLiked,
                            size: 64,
                            onTap: () async {
                              if (_isLiked) return;
                              setState(() => _isLiked = true);
                              final me =
                                  Supabase.instance.client.auth.currentUser;
                              if (me == null) return;
                              try {
                                await Supabase.instance.client
                                    .from('profile_likes')
                                    .upsert({
                                  'liker_id': me.id,
                                  'liked_id': widget.memberId,
                                });
                                final ids = [me.id, widget.memberId]..sort();
                                await Supabase.instance.client
                                    .from('conversations')
                                    .upsert({
                                  'user_low_id': ids[0],
                                  'user_high_id': ids[1],
                                });
                                final mutual = await Supabase.instance.client
                                    .from('profile_likes')
                                    .select()
                                    .eq('liker_id', widget.memberId)
                                    .eq('liked_id', me.id)
                                    .maybeSingle();
                                if (mutual != null && mounted) {
                                  await Supabase.instance.client
                                      .from('matches')
                                      .upsert({
                                    'user_a_id': ids[0],
                                    'user_b_id': ids[1],
                                    'matched_at':
                                        DateTime.now().toIso8601String(),
                                  });
                                  await showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    barrierColor:
                                        Colors.black.withValues(alpha: 0.85),
                                    builder: (_) => MatchPopup(
                                      myPhotoUrl: '',
                                      matchPhotoUrl: _photoUrls.isNotEmpty
                                          ? _photoUrls.first
                                          : '',
                                      matchName:
                                          _profileData!['display_name'] ?? '',
                                    ),
                                  );
                                }
                              } catch (_) {}
                              if (mounted) Navigator.pop(context, 'liked');
                            },
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 44,
                      left: 20,
                      right: 100,
                      child: Text(
                        _profileData!['bio'] ?? 'ไม่มีข้อมูลประวัติ',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.background.withValues(alpha: 0.92),
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.9),
                              blurRadius: 6,
                              offset: Offset(0, 1),
                            ),
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -32, 0),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                '${_profileData!['display_name']}, $age',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isVerified)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.verified,
                                  color: AppColors.verified,
                                  size: 24,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _InfoLine(
                              icon: gender == Gender.female
                                  ? Icons.female_rounded
                                  : Icons.male_rounded,
                              text: gender.labelTh,
                              iconColor: gender == Gender.female
                                  ? AppColors.iconPink
                                  : AppColors.iconBlue,
                            ),
                            const SizedBox(height: 12),
                            _InfoLine(
                              icon: Icons.location_on_rounded,
                              text:
                                  '${_profileData!['district']}, ${_profileData!['province']}',
                              iconColor: AppColors.iconOrange,
                            ),
                            Builder(builder: (context) {
                              final relStatus =
                                  _profileData!['relationship_status']
                                      as String?;
                              final activity =
                                  _profileData!['current_activity'] as String?;
                              if (relStatus == null && activity == null) {
                                return const SizedBox.shrink();
                              }
                              final parts = [
                                ?relStatus,
                                ?activity
                              ];
                              return Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: _InfoLine(
                                  icon: Icons.favorite_border_rounded,
                                  text: parts.join(' · '),
                                  iconColor: AppColors.iconPink,
                                ),
                              );
                            }),
                            if (_interests.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _interests
                                    .map(
                                      (interest) =>
                                          _InterestChip(label: interest),
                                    )
                                    .toList(),
                              ),
                            ],
                            const SizedBox(height: 24),
                            const Text(
                              'ช่องทางติดต่อ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if ((_profileData!['line_id'] ?? '')
                                .toString()
                                .isNotEmpty)
                              _SocialInfoTile(
                                label: 'Line ID',
                                value: _profileData!['line_id'],
                                color: AppColors.iconGreen,
                                badgeText: 'LINE',
                              ),
                            if ((_profileData!['instagram'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _SocialInfoTile(
                                label: 'Instagram',
                                value: _profileData!['instagram'],
                                color: AppColors.iconPink,
                                badgeText: 'IG',
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _VerticalActionButtons(
                        isFollowing: _isFollowing,
                        onFollowTap: _toggleFollow,
                        goWhereData: _goWhereData,
                        onChatTap: () {
                          _navigateToChat();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'รูปของ ${_profileData!['display_name']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photoUrls.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => GestureDetector(
                    onTap: () => _openImageCommentsDialog(_photoUrls[index]),
                    child: NetworkImageBox(
                      url: _photoUrls[index],
                      width: (MediaQuery.of(context).size.width - 68) / 3,
                      height: 160,
                      borderRadius: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_secretPhotoUrls.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'รูปส่วนตัว 🔒',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _secretPhotoUrls.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (context, index) => ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            width: (MediaQuery.of(context).size.width - 68) / 3,
                            height: 160,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  _secretPhotoUrls[index],
                                  fit: BoxFit.cover,
                                ),
                                BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 12,
                                    sigmaY: 12,
                                  ),
                                  child: Container(
                                    color: AppColors.textPrimary
                                        .withValues(alpha: 0.15),
                                  ),
                                ),
                                const Center(
                                  child: Icon(
                                    Icons.lock_rounded,
                                    color: AppColors.background,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isFilled;
  final double size;

  const _AnimatedActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isFilled = false,
    this.size = 56,
  });

  @override
  State<_AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<_AnimatedActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: () {
          _controller.forward(from: 0.0);
          widget.onTap();
        },
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.isFilled ? widget.color : AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isFilled ? Colors.transparent : AppColors.border,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: widget.isFilled ? AppColors.background : widget.color,
            size: widget.size * 0.5,
          ),
        ),
      ),
    );
  }
}

class _VerticalActionButtons extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback? onFollowTap;
  final VoidCallback? onLeafTap;
  final VoidCallback? onChatTap;
  final Map<String, dynamic>? goWhereData;

  const _VerticalActionButtons({
    this.isFollowing = false,
    this.onFollowTap,
    this.onChatTap,
    this.goWhereData,
  }) : onLeafTap = null;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimatedSideBarButton(
          icon: Icons.chat_bubble_rounded,
          label: 'แชท',
          color: const Color(0xFF00BCD4),
          animType: _SideBarAnimType.bounce,
          onTap: onChatTap ?? () {},
        ),
        const SizedBox(height: 12),
        _AnimatedSideBarButton(
          icon: isFollowing ? Icons.check_circle_rounded : Icons.add_circle_rounded,
          label: 'ติดตาม',
          color: AppColors.iconPurple,
          labelColor: isFollowing ? const Color(0xFFB39DDB) : null,
          iconColor: isFollowing ? AppColors.iconGreen : null,
          animType: _SideBarAnimType.spin,
          onTap: onFollowTap ?? () {},
        ),
        const SizedBox(height: 12),
        _GoToButton(data: goWhereData),
        const SizedBox(height: 12),
        _LeafButton(onTap: onLeafTap ?? () {}),
        const SizedBox(height: 12),
        _AnimatedSideBarButton(
  icon: Icons.shield_rounded,
  label: 'บรรลัยวอร์',
  color: const Color(0xFFB91C1C),
  animType: _SideBarAnimType.shake,
  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProviderScope(
        child: GameScreen(),
      ),
    ),
  );
},
),
      ],
    );
  }
}

enum _SideBarAnimType { bounce, spin, shake }

class _AnimatedSideBarButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color? labelColor;
  final Color? iconColor;
  final _SideBarAnimType animType;
  final VoidCallback onTap;

  const _AnimatedSideBarButton({
    required this.icon,
    required this.label,
    required this.color,
    this.labelColor,
    this.iconColor,
    required this.animType,
    required this.onTap,
  });

  @override
  State<_AnimatedSideBarButton> createState() => _AnimatedSideBarButtonState();
}

class _AnimatedSideBarButtonState extends State<_AnimatedSideBarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    switch (widget.animType) {
      case _SideBarAnimType.bounce:
        _anim = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 1.4, end: 0.85), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.1), weight: 25),
          TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 20),
        ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
        break;
      case _SideBarAnimType.spin:
        _anim = Tween<double>(begin: 0.0, end: 1.0)
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
        break;
      case _SideBarAnimType.shake:
        _anim = TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.15), weight: 20),
          TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.15), weight: 30),
          TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.1), weight: 25),
          TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0), weight: 25),
        ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
        break;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _buildAnimatedIcon() {
    switch (widget.animType) {
      case _SideBarAnimType.bounce:
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, child) =>
              Transform.scale(scale: _anim.value, child: child),
          child: Icon(widget.icon, color: widget.color, size: 20),
        );
      case _SideBarAnimType.spin:
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, child) => Transform.rotate(
            angle: _anim.value * 2 * 3.14159,
            child: child,
          ),
          child: Icon(widget.icon, color: widget.iconColor ?? widget.color, size: 20),
        );
      case _SideBarAnimType.shake:
        return AnimatedBuilder(
          animation: _anim,
          builder: (_, child) =>
              Transform.rotate(angle: _anim.value, child: child),
          child: Icon(widget.icon, color: widget.color, size: 20),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _ctrl.forward(from: 0.0);
        widget.onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: _buildAnimatedIcon(),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: widget.labelColor ?? widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoToButton extends StatefulWidget {
  final Map<String, dynamic>? data;
  const _GoToButton({this.data});

  @override
  State<_GoToButton> createState() => _GoToButtonState();
}

class _GoToButtonState extends State<_GoToButton>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late AnimationController _popupCtrl;
  late Animation<double> _iconAnim;
  late Animation<double> _popupAnim;
  bool _showPopup = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _btnKey = GlobalKey();

  static const Color _goColor = Color(0xFFFF7043);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _popupCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _iconAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _popupAnim = CurvedAnimation(parent: _popupCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _removeOverlay();
    _ctrl.dispose();
    _popupCtrl.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showPopup = false;
  }

  String _placeLine(Map<String, dynamic> data) {
    final place = data['place'] as String? ?? '';
    final period = data['period'] as String? ?? '';
    final dateStr = data['go_date'] as String?;
    String dayLabel = '';
    if (dateStr != null) {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDay = DateTime(date.year, date.month, date.day);
      final diffDays = targetDay.difference(today).inDays;
      if (diffDays == 0) {
        dayLabel = 'วันนี้';
      } else if (diffDays == 1) {
        dayLabel = 'พรุ่งนี้';
      } else if (diffDays == 2) {
        dayLabel = 'มะรืนนี้';
      } else {
        dayLabel = '${date.day}/${date.month}/${date.year}';
      }
    }
    return [place, dayLabel, period].where((s) => s.isNotEmpty).join(' ');
  }

  String _timeLine(Map<String, dynamic> data) {
    final dateStr = data['go_date'] as String?;
    final timeStr = data['go_time'] as String?;
    if (dateStr == null || timeStr == null) return '';
    final dateParts = dateStr.split('-');
    final timeParts = timeStr.split(':');
    final target = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
    final hh = timeParts[0].padLeft(2, '0');
    final mm = timeParts[1].padLeft(2, '0');
    final diff = target.difference(DateTime.now());
    String countdown;
    if (diff.isNegative) {
      countdown = 'ถึงเวลานี้แล้ว';
    } else {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      countdown = days > 0
          ? 'อีก $days วัน $hours ชั่วโมง'
          : 'อีก $hours ชั่วโมง $minutes นาที';
    }
    return '$hh.$mm น. ($countdown)';
  }

  void _togglePopup() {
    if (_showPopup) {
      _popupCtrl.reverse().then((_) => _removeOverlay());
      return;
    }

    _ctrl.forward(from: 0.0);
    _popupCtrl.forward(from: 0.0);
    _showPopup = true;

    final box = _btnKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final data = widget.data;

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _popupCtrl.reverse().then((_) => _removeOverlay()),
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: pos.dy + box.size.height / 2 - 28,
            left: pos.dx - 290,
            child: AnimatedBuilder(
              animation: _popupAnim,
              builder: (_, child) => Transform.scale(
                scale: _popupAnim.value,
                alignment: Alignment.centerRight,
                child: Opacity(
                    opacity: (_popupAnim.value).clamp(0.0, 1.0), child: child),
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 280,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _goColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.directions_walk_rounded,
                                color: _goColor, size: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'สถานที่จะไป',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (data == null)
                        const Text(
                          'ยังไม่ได้ระบุสถานะจะไป',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else ...[
                        Text(
                          _placeLine(data),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF20212B),
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _timeLine(data),
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(_btnKey.currentContext!).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: _btnKey,
      onTap: _togglePopup,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _goColor.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _goColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: AnimatedBuilder(
                animation: _iconAnim,
                builder: (_, child) => Transform.scale(
                  scale: _iconAnim.value,
                  child: child,
                ),
                child: Icon(Icons.directions_walk_rounded,
                    color: _goColor, size: 20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'จะไป',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _goColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeafButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LeafButton({required this.onTap});

  @override
  State<_LeafButton> createState() => _LeafButtonState();
}

class _LeafButtonState extends State<_LeafButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _iconAnim;
  late Animation<double> _popupAnim;
  bool _showPopup = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _btnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _iconAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 35),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _popupAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _removeOverlay();
    _ctrl.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showPopup = false;
  }

  void _togglePopup() {
    if (_showPopup) {
      _ctrl.reverse().then((_) => _removeOverlay());
      return;
    }

    _ctrl.forward(from: 0.0);
    _showPopup = true;

    final box = _btnKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          // พื้นที่โปร่งใส กดปิด popup
          Positioned.fill(
            child: GestureDetector(
              onTap: () => _ctrl.reverse().then((_) => _removeOverlay()),
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: pos.dy + box.size.height / 2 - 28,
            left: pos.dx - 230,
            child: AnimatedBuilder(
              animation: _popupAnim,
              builder: (_, child) => Transform.scale(
                scale: _popupAnim.value,
                alignment: Alignment.centerRight,
                child: Opacity(
                    opacity: (_popupAnim.value).clamp(0.0, 1.0), child: child),
              ),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 220,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.iconGreen.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.eco_rounded,
                                color: AppColors.iconGreen, size: 14),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'สถานะใบไม้',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'จะไป บิ๊กซี เอ็กส์ต้าส์\nตอน บ่ายโมงครึ่ง\nและกลับตอนหัวค่ำ',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF20212B),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(_btnKey.currentContext!).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: _btnKey,
      onTap: _togglePopup,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.iconGreen.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.iconGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: AnimatedBuilder(
                animation: _iconAnim,
                builder: (_, child) => Transform.scale(
                  scale: _showPopup ? 1.0 : _iconAnim.value,
                  child: child,
                ),
                child: Icon(Icons.eco_rounded,
                    color: AppColors.iconGreen, size: 20),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ใบไม้',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.iconGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;

  const _InfoLine({
    required this.icon,
    required this.text,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  const _InterestChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.iconPurple.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.iconPurple.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
          color: AppColors.iconPurple,
        ),
      ),
    );
  }
}

class _SocialInfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String badgeText;

  const _SocialInfoTile({
    required this.label,
    required this.value,
    required this.color,
    required this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
