import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/gender.dart';
import '../../theme/app_colors.dart';
import '../../widgets/network_image_box.dart';

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
  *,
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

      final secretData = await client
          .from('secret_photos')
          .select()
          .eq('profile_id', widget.memberId)
          .order('sort_order');

      final secretUrls = (secretData as List)
          .map((p) => p['public_url'] as String)
          .where((url) => url.isNotEmpty)
          .toList();

      setState(() {
        _profileData = response;
        _photoUrls = photos.map((p) => p['public_url'] as String).toList();
        _interests = loadedInterests;
        _secretPhotoUrls = secretUrls;
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_profileData == null) {
      return const Scaffold(body: Center(child: Text('ไม่พบข้อมูลสมาชิก')));
    }

    final age = _calculateAge(_profileData!['birth_date']);
    final isOnline = _profileData!['is_online'] ?? false;
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
                      bottom: 5,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.68,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(
                            alpha: 0.3,
                          ),
                          border: Border.all(
                            color: AppColors.background.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _profileData!['bio'] ?? 'ไม่มีข้อมูลประวัติ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.background.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    crossAxisAlignment: CrossAxisAlignment.center, // 🔒 จัดให้ชื่อ อายุ และปุ่มแชท อยู่กึ่งกลางแนวตั้งร่วมกับปุ่มกดใจ/กากบาท
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
                      // ── ส่วนปุ่ม Action ปรับปรุงขนาดและระยะห่างใหม่ ──
                      Padding(
                        padding: const EdgeInsets.only(right: 5), // 📍 เว้นระยะห่างจากขอบรูปภาพด้านขวา 5px ไม่ให้ปุ่มไปชนขอบพอดี
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center, // 🔒 ล็อกปุ่มแชทให้อยู่กึ่งกลางแนวตั้งเดียวกับปุ่มกดใจ/กากบาท
                          children: [
                            _AnimatedActionButton(
                              icon: Icons.close_rounded,
                              color: AppColors.textSecondary,
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                            const SizedBox(width: 8),
                            _AnimatedActionButton(
                              icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: AppColors.brandPink,
                              isFilled: _isLiked,
                              onTap: () {
                                setState(() => _isLiked = !_isLiked);
                              },
                            ),
                            const SizedBox(width: 8),
                            _ModernChatButton(isOnline: isOnline), // 🔒 ขนาดปุ่มแชทเท่าเดิม ไม่ขยายตาม
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
                            if (_profileData!['occupation'] != null) ...[
                              const SizedBox(height: 12),
                              _InfoLine(
                                icon: Icons.work_rounded,
                                text: _profileData!['occupation'],
                                iconColor: AppColors.iconGreen,
                              ),
                            ],
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
                      _VerticalActionButtons(),
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
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
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
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
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

// 🔍 ค้นหาคอมโพเนนต์ _AnimatedActionButton ด้านล่างของไฟล์ แล้วเปลี่ยนเป็นบล็อกนี้ครับ:

class _AnimatedActionButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isFilled;

  const _AnimatedActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isFilled = false,
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
          width: 56,  // ✅ เพิ่มขนาดปุ่มกากบาทและกดใจให้ใหญ่ขึ้นเป็น 56
          height: 56, // ✅ เพิ่มขนาดปุ่มกากบาทและกดใจให้ใหญ่ขึ้นเป็น 56
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
            size: 28, // ✅ เพิ่มขนาดไอคอนข้างในตามขนาดปุ่มเพื่อให้สมดุลสวยงาม
          ),
        ),
      ),
    );
  }
}

// ── ปุ่ม "แชท" ดีไซน์ใหม่ ทันสมัย วัยรุ่นชอบ ──
class _ModernChatButton extends StatefulWidget {
  final bool isOnline;

  const _ModernChatButton({required this.isOnline});

  @override
  State<_ModernChatButton> createState() => _ModernChatButtonState();
}

class _ModernChatButtonState extends State<_ModernChatButton>
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
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.1), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.1, end: 1.0), weight: 50),
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
          // Logic เปิดแชท
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isOnline
                  ? [const Color(0xFF00E676), const Color(0xFF00C853)] // เขียวนีออนวัยรุ่นชอบ
                  : [AppColors.brandPink, const Color(0xFFE91E63)], // ชมพูสดใส
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (widget.isOnline ? const Color(0xFF00C853) : AppColors.brandPink)
                    .withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'แชท',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (widget.isOnline) ...[
                const SizedBox(width: 6),
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalActionButtons extends StatelessWidget {
  final VoidCallback? onFollowTap;
  final VoidCallback? onLeafTap;

  const _VerticalActionButtons({this.onFollowTap, this.onLeafTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SideBarButton(
          icon: Icons.person_pin_rounded,
          label: 'ติดตาม',
          color: AppColors.iconPurple,
          onTap: onFollowTap ?? () {},
        ),
        const SizedBox(height: 12),
        _SideBarButton(
          icon: Icons.favorite_rounded,
          label: 'ส่งใจ',
          color: AppColors.brandPink,
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _SideBarButton(
          icon: Icons.eco_rounded,
          label: 'ใบไม้',
          color: AppColors.iconGreen,
          onTap: onLeafTap ?? () {},
        ),
      ],
    );
  }
}

class _SideBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SideBarButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
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
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
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