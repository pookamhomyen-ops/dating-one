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
  int _currentImageIndex = 0;

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

      setState(() {
        _profileData = response;
        _photoUrls = photos.map((p) => p['public_url'] as String).toList();
        _interests = loadedInterests;
        _isLoading = false;
      });
    } catch (e) {
      // บรรทัดนี้จะพ่นออกมาเลยว่า Supabase บล็อกเพราะอะไร เช่น บล็อก RLS หรือหา Table Relation ไม่เจอ
      debugPrint('🔴 Supabase Detail Error: $e');
      if (e is PostgrestException) {
        debugPrint('🔴 Message: ${e.message}');
        debugPrint('🔴 Hint: ${e.hint}');
        debugPrint('🔴 Details: ${e.details}');
      }
    }
  }

  // ควบคุม PageView รูปภาพ
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

  // ฟังก์ชันจัดการการแตะที่รูปเพื่อเปลี่ยนรูปถัดไป/ก่อนหน้า (ปรับความเร็วให้เปลี่ยนรูปทันทีและอัปเดตค่าเสถียร)
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

  // ฟังก์ชันเปิดดูรูปโปรไฟล์หลักแบบเต็มจอ (เลื่อนซ้ายขวาได้ ซูมได้)
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
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _photoUrls.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: localIndex == index
                                  ? AppColors.background
                                  : AppColors.background24,
                            ),
                          ),
                        ),
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

  // ฟังก์ชันเปิดดูรูปแบบ Popup ขนาดใหญ่ ด้านล่างมีคอมเม้นสวยๆ (เลื่อนซ้ายขวาไม่ได้)
  void _openImageCommentsDialog(String imageUrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ), // ขยับหลบแป้นพิมพ์อัตโนมัติ
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          // แก้ไขบั๊ก No named parameter 'maxHeight' ย้ายมาใส่ใน constraints ตรงนี้เรียบร้อยครับ
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
                      // รูปขนาดใหญ่ดีไซน์ขอบโค้งมนสวยงาม (ไม่เต็มหน้าจอ)
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
                          const SizedBox(width: 6),
                          Text(
                            '(2)',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // คอมเม้นผู้หญิงพาสเทลชมพูหวานฉ่ำ
                      _buildCommentTile(
                        name: 'มิลค์คาร์เมล ✨',
                        comment:
                            'งู้ยยยยย ลุคนี้คือน่ารักใจเจ็บมากเลยค่าาา 🥰 สดใสสุดๆ',
                        time: '10 นาทีที่แล้ว',
                        isFemale: true,
                      ),
                      const SizedBox(height: 14),

                      // คอมเม้นผู้ชายพาสเทลฟ้าคลีนๆ
                      _buildCommentTile(
                        name: 'Napat_โฟล์ค',
                        comment: 'ถ่ายมุมนี้ออกมาดูดีมากเลยครับ เท่มากๆ 📸⚡',
                        time: '1 ชม. ที่แล้ว',
                        isFemale: false,
                      ),
                    ],
                  ),
                ),
              ),
              // ส่วนกล่องพิมพ์ความคิดเห็นพร้อมปุ่ม Submit ด้านขวา
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'พิมพ์ข้อความของคุณที่นี่...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // ปุ่มส่ง (Submit) ทรงกลมไล่เฉดสีสุดหรู
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.brandPink, AppColors.background],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.send_rounded,
                          color: AppColors.background,
                          size: 18,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // วิดเจ็ตย่อยสำหรับคอมเม้นท์ชายหญิงสไตล์โมเดิร์น
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
                        fontWeight: FontWeight.w500,
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
                    fontWeight: FontWeight.w500,
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
          // 1. Header Gallery
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double screenWidth = constraints.maxWidth;
                return Stack(
                  children: [
                    GestureDetector(
                      // เปลี่ยนจากการกดแล้วเปิดเต็มจอ เป็นการแตะเปลี่ยนรูปซ้ายขวา
                      onTapDown: (details) =>
                          _handleImageTap(details, screenWidth),
                      onLongPress: () => _openFullScreenGallery(
                        _currentImageIndex,
                      ), // กดค้างเพื่อดูรูปเต็มหน้าจอเหมือนเดิม
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
                                physics:
                                    const NeverScrollableScrollPhysics(), // ลบการปัดซ้ายขวาออก
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

                    // กล่องประวัติบนรูปภาพ 30% คลีนๆ สไตล์ขอบเหลี่ยม (ปรับแต่งตามบรีฟใหม่ล่าสุด)
                    Positioned(
                      bottom: 5, // ขยับลงมาเกือบติดขอบล่างของภาพ (เว้นไว้ 5px)
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
                          ), // พื้นหลังสีดำโปร่งใส คาปาซิตี้ 30
                          // ไม่เอาขอบโค้ง เป็นขอบเหลี่ยมคมสวยงามมินิมอล (ถอด borderRadius ออกแล้ว)
                          border: Border.all(
                            color: AppColors.background.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        // เอาหัวข้อและไอคอนออกทั้งหมด แสดงเฉพาะตัวรายละเอียด text เท่านั้น
                        child: Text(
                          _profileData!['bio'] ?? 'ไม่มีข้อมูลประวัติ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.background.withValues(alpha: 0.85),
                            height: 1.4,
                          ),
                          maxLines: 2, // รองรับกรณีข้อความยาวได้ 2 บรรทัด
                          overflow: TextOverflow
                              .ellipsis, // หากเกินสองบรรทัด ให้ตัดข้อความที่เหลือออกขึ้น ... ไม่ให้เป็นสามบรรทัด
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // 2. White Container
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
                                  fontWeight: FontWeight.w500,
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
                      _OnlineStatus(isOnline: isOnline),
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
                            if (_profileData!['university'] != null) ...[
                              const SizedBox(height: 12),
                              _InfoLine(
                                icon: Icons.school_rounded,
                                text: _profileData!['university'],
                                iconColor: AppColors.iconPurple,
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
                              if ((_profileData!['line_id'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                const SizedBox(height: 12),
                              _SocialInfoTile(
                                label: 'Instagram',
                                value: _profileData!['instagram'],
                                color: AppColors.iconPink,
                                badgeText: 'IG',
                              ),
                            ],
                            if ((_profileData!['x_handle'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              if ((_profileData!['line_id'] ?? '')
                                      .toString()
                                      .isNotEmpty ||
                                  (_profileData!['instagram'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                const SizedBox(height: 12),
                              _SocialInfoTile(
                                label: 'X (Twitter)',
                                value: _profileData!['x_handle'],
                                color: AppColors.textPrimary,
                                badgeText: 'X',
                              ),
                            ],
                            if ((_profileData!['facebook'] ?? '')
                                .toString()
                                .isNotEmpty) ...[
                              if ((_profileData!['line_id'] ?? '')
                                      .toString()
                                      .isNotEmpty ||
                                  (_profileData!['instagram'] ?? '')
                                      .toString()
                                      .isNotEmpty ||
                                  (_profileData!['x_handle'] ?? '')
                                      .toString()
                                      .isNotEmpty)
                                const SizedBox(height: 12),
                              _SocialInfoTile(
                                label: 'Facebook',
                                value: _profileData!['facebook'],
                                color: AppColors.iconBlue,
                                badgeText: 'FB',
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

          // 3. Grid View สำหรับรูปทั้งหมด
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3 / 4,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => GestureDetector(
                  onTap: () => _openImageCommentsDialog(
                    _photoUrls[index],
                  ), // กดรูปในกริตเพื่อเปิดหน้าต่างคอมเม้นล็อกเฉพาะใบนั้น
                  child: NetworkImageBox(
                    url: _photoUrls[index],
                    borderRadius: 16,
                  ),
                ),
                childCount: _photoUrls.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _OnlineStatus extends StatelessWidget {
  final bool isOnline;
  final VoidCallback? onTap;

  const _OnlineStatus({required this.isOnline, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isOnline
              ? AppColors.iconGreen.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isOnline ? AppColors.iconGreen : AppColors.textSecondary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'แชท',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isOnline ? AppColors.iconGreen : AppColors.textSecondary,
              ),
            ),
          ],
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
