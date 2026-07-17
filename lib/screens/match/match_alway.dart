import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../chat/chat_detail_screen.dart';
import '../../models/chat_thread.dart';
import '../../theme/app_colors.dart';

void main() {
  runApp(const _DemoApp());
}

class _DemoApp extends StatelessWidget {
  const _DemoApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Dating Feed Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const DatingFeedPage(),
    );
  }
}

// ============================================================
// MODELS
// ============================================================

enum Gender { male, female, lgbtq }

enum OnlineStatus { onlineNow, within24h, all }

class Comment {
  final String id;
  final String author;
  final String avatarColorHex;
  final String text;
  final String timeAgo;

  Comment({
    required this.id,
    required this.author,
    required this.avatarColorHex,
    required this.text,
    required this.timeAgo,
  });
}

class UserProfile {
  final String id;
  final String name;
  final int age;
  final String district;
  final String province;
  final String shortBio;
  final List<String> tags;
  final List<String> photos;
  final Gender gender;
  final String occupation;
  final String education;
  final String fullBio;
  final int followers;
  final int followingCount;
  final bool isOnline;
  final bool onlineWithin24h;
  final double distanceKm;
  final Color themeColor;
  int likeCount;
  bool isLiked;
  bool isFavorited;
  bool isFollowing;
  final List<Comment> comments;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.district,
    required this.province,
    required this.shortBio,
    required this.tags,
    required this.photos,
    required this.gender,
    required this.occupation,
    required this.education,
    required this.fullBio,
    required this.followers,
    required this.followingCount,
    required this.isOnline,
    required this.onlineWithin24h,
    required this.distanceKm,
    required this.themeColor,
    required this.likeCount,
    this.isLiked = false,
    this.isFavorited = false,
    this.isFollowing = false,
    List<Comment>? comments,
  }) : comments = comments ?? <Comment>[];
}

class FilterOptions {
  Set<Gender> genders;
  RangeValues ageRange;
  String province;
  String district;
  double maxDistanceKm;
  OnlineStatus onlineStatus;

  FilterOptions({
    Set<Gender>? genders,
    RangeValues? ageRange,
    this.province = 'ทั้งหมด',
    this.district = 'ทั้งหมด',
    this.maxDistanceKm = 999,
    this.onlineStatus = OnlineStatus.all,
  })  : genders = genders ?? {Gender.male, Gender.female, Gender.lgbtq},
        ageRange = ageRange ?? const RangeValues(18, 60);

  FilterOptions copy() {
    return FilterOptions(
      genders: Set<Gender>.of(genders),
      ageRange: ageRange,
      province: province,
      district: district,
      maxDistanceKm: maxDistanceKm,
      onlineStatus: onlineStatus,
    );
  }
}

// ============================================================
// MOCK DATA
// ============================================================

List<UserProfile> generateMockProfiles() {
  return [
    UserProfile(
      id: 'u1',
      name: 'มายด์',
      age: 24,
      district: 'เมืองเชียงใหม่',
      province: 'เชียงใหม่',
      shortBio: 'ชอบคาเฟ่ ท่องเที่ยว ถ่ายรูป มองหาคนคุยเรื่องเที่ยวด้วยกัน',
      tags: const ['คาเฟ่', 'แมว', 'เที่ยว'],
      photos: const [
        'https://picsum.photos/seed/mind1/900/1600',
        'https://picsum.photos/seed/mind2/900/1600',
        'https://picsum.photos/seed/mind3/900/1600',
      ],
      gender: Gender.female,
      occupation: 'กราฟิกดีไซเนอร์',
      education: 'มหาวิทยาลัยเชียงใหม่',
      fullBio:
          'รักการเดินทางสายชิล ชอบนั่งคาเฟ่ทำงานตอนเช้า เสาร์-อาทิตย์มักหนีไปดอยใกล้เชียงใหม่ '
          'มองหาคนที่พูดคุยกันได้สนุก จริงใจ และพร้อมออกไปเที่ยวด้วยกัน',
      followers: 1240,
      followingCount: 86,
      isOnline: true,
      onlineWithin24h: true,
      distanceKm: 2.4,
      themeColor: const Color(0xFFFF7A8A),
      likeCount: 312,
      comments: [
        Comment(id: 'c1', author: 'แบงค์', avatarColorHex: '#5B8DEF', text: 'น่ารักจังครับ', timeAgo: '2 ชม.'),
        Comment(id: 'c2', author: 'เจมส์', avatarColorHex: '#34C77B', text: 'ชอบเที่ยวเหมือนกันเลย', timeAgo: '5 ชม.'),
        Comment(id: 'c3', author: 'ปอนด์', avatarColorHex: '#FFB648', text: 'คาเฟ่นี้อยู่ที่ไหนครับ', timeAgo: '1 วัน'),
      ],
    ),
    UserProfile(
      id: 'u2',
      name: 'พีช',
      age: 27,
      district: 'สันทราย',
      province: 'เชียงใหม่',
      shortBio: 'รักการออกกำลังกาย วิ่งเทรล ปั่นจักรยานรอบดอยสุเทพ',
      tags: const ['วิ่งเทรล', 'จักรยาน', 'สุขภาพ'],
      photos: const [
        'https://picsum.photos/seed/peach1/900/1600',
        'https://picsum.photos/seed/peach2/900/1600',
      ],
      gender: Gender.male,
      occupation: 'เทรนเนอร์ฟิตเนส',
      education: 'มหาวิทยาลัยแม่โจ้',
      fullBio:
          'ใช้ชีวิตติดธรรมชาติ ชอบวิ่งเทรลตอนเช้าตรู่ มองหาคู่ที่ดูแลสุขภาพเหมือนกัน '
          'หรืออย่างน้อยอยากลองออกไปวิ่งด้วยกันสักครั้ง',
      followers: 860,
      followingCount: 120,
      isOnline: false,
      onlineWithin24h: true,
      distanceKm: 7.8,
      themeColor: const Color(0xFF5B8DEF),
      likeCount: 198,
      isFollowing: true,
      comments: [
        Comment(id: 'c4', author: 'นุ่น', avatarColorHex: '#FF7A8A', text: 'เส้นทางวิ่งสวยมากเลย', timeAgo: '3 ชม.'),
      ],
    ),
    UserProfile(
      id: 'u3',
      name: 'ฟ้า',
      age: 22,
      district: 'หางดง',
      province: 'เชียงใหม่',
      shortBio: 'นักศึกษาปีสุดท้าย ชอบวาดรูปและฟังเพลงอินดี้',
      tags: const ['วาดรูป', 'อินดี้', 'หนังสือ'],
      photos: const [
        'https://picsum.photos/seed/fah1/900/1600',
        'https://picsum.photos/seed/fah2/900/1600',
        'https://picsum.photos/seed/fah3/900/1600',
        'https://picsum.photos/seed/fah4/900/1600',
      ],
      gender: Gender.lgbtq,
      occupation: 'นักศึกษา',
      education: 'มหาวิทยาลัยเชียงใหม่',
      fullBio:
          'เรียนศิลปะอยู่ปีสุดท้าย ชอบนั่งวาดรูปในร้านกาแฟเงียบ ๆ ฟังเพลงอินดี้ '
          'มองหาคนที่เปิดใจคุยเรื่องศิลปะและความรู้สึกได้',
      followers: 430,
      followingCount: 210,
      isOnline: true,
      onlineWithin24h: true,
      distanceKm: 12.1,
      themeColor: const Color(0xFFB07CFF),
      likeCount: 87,
    ),
    UserProfile(
      id: 'u4',
      name: 'เจมส์',
      age: 30,
      district: 'แม่ริม',
      province: 'เชียงใหม่',
      shortBio: 'ทำงานสายไอที ชอบทำอาหาร เลี้ยงแมว 2 ตัว',
      tags: const ['ทำอาหาร', 'แมว', 'หนัง'],
      photos: const [
        'https://picsum.photos/seed/james1/900/1600',
        'https://picsum.photos/seed/james2/900/1600',
      ],
      gender: Gender.male,
      occupation: 'นักพัฒนาซอฟต์แวร์',
      education: 'สถาบันเทคโนโลยีพระจอมเกล้า',
      fullBio:
          'ทำงาน remote สาย dev ชอบทำกับข้าวให้คนที่รักกินตอนเย็น มีแมวสองตัวชื่อก้อนเมฆกับก้อนหิน '
          'มองหาคนที่ชอบความสงบเหมือนกัน',
      followers: 690,
      followingCount: 95,
      isOnline: false,
      onlineWithin24h: false,
      distanceKm: 18.6,
      themeColor: const Color(0xFF34C77B),
      likeCount: 142,
      isFavorited: true,
    ),
    UserProfile(
      id: 'u5',
      name: 'ปอนด์',
      age: 26,
      district: 'เมืองเชียงราย',
      province: 'เชียงราย',
      shortBio: 'ไกด์นำเที่ยวท้องถิ่น รักธรรมชาติและภูเขา',
      tags: const ['ภูเขา', 'แคมป์ปิ้ง', 'ถ่ายรูป'],
      photos: const [
        'https://picsum.photos/seed/pond1/900/1600',
        'https://picsum.photos/seed/pond2/900/1600',
        'https://picsum.photos/seed/pond3/900/1600',
      ],
      gender: Gender.female,
      occupation: 'ไกด์นำเที่ยว',
      education: 'มหาวิทยาลัยราชภัฏเชียงราย',
      fullBio:
          'พาทัวร์นักท่องเที่ยวขึ้นดอยเป็นงานประจำ ชอบกางเต็นท์นอนดูดาว '
          'มองหาคนที่ชอบธรรมชาติและพร้อมลุยไปกับเรา',
      followers: 2100,
      followingCount: 64,
      isOnline: true,
      onlineWithin24h: true,
      distanceKm: 145.0,
      themeColor: const Color(0xFFFFB648),
      likeCount: 530,
    ),
    UserProfile(
      id: 'u6',
      name: 'บีม',
      age: 29,
      district: 'เมืองลำพูน',
      province: 'ลำพูน',
      shortBio: 'เจ้าของร้านขนมเล็ก ๆ ชอบงานคราฟต์และตลาดนัด',
      tags: const ['ขนม', 'คราฟต์', 'ตลาดนัด'],
      photos: const [
        'https://picsum.photos/seed/beam1/900/1600',
        'https://picsum.photos/seed/beam2/900/1600',
      ],
      gender: Gender.female,
      occupation: 'เจ้าของร้านขนม',
      education: 'มหาวิทยาลัยพายัพ',
      fullBio:
          'เปิดร้านขนมเล็ก ๆ ในลำพูน ชอบไปเดินตลาดนัดงานคราฟต์ทุกสุดสัปดาห์ '
          'มองหาคนที่ชอบกินขนมและชิลไปกับเรา',
      followers: 980,
      followingCount: 150,
      isOnline: false,
      onlineWithin24h: true,
      distanceKm: 26.3,
      themeColor: const Color(0xFFFF9F4D),
      likeCount: 256,
      isFollowing: true,
    ),
  ];
}

const Map<String, List<String>> kProvinceDistricts = {
  'ทั้งหมด': ['ทั้งหมด'],
  'เชียงใหม่': ['ทั้งหมด', 'เมืองเชียงใหม่', 'สันทราย', 'แม่ริม', 'หางดง', 'สารภี'],
  'เชียงราย': ['ทั้งหมด', 'เมืองเชียงราย', 'แม่สาย'],
  'ลำพูน': ['ทั้งหมด', 'เมืองลำพูน', 'ป่าซาง'],
};

const Color kAccentColor = Color(0xFFFF4D67);
const Color kCardBackground = Color(0xFF1F1F1F);
const Color kSheetBackground = Color(0xFF161616);

Color hexToColor(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}

Gender _genderFromString(String? gender) {
  switch (gender) {
    case 'male':
      return Gender.male;
    case 'female':
      return Gender.female;
    default:
      return Gender.lgbtq;
  }
}

Color _themeColorForProfile(String profileId) {
  const colors = [
    Color(0xFFFF7A8A),
    Color(0xFF5B8DEF),
    Color(0xFFB07CFF),
    Color(0xFFFFB648),
    Color(0xFF34C77B),
    Color(0xFFFF9F4D),
  ];
  final index = profileId.hashCode.abs() % colors.length;
  return colors[index];
}

double _calculateDistanceKm(
  double lat1,
  double lon1,
  double lat2,
  double lon2,
) {
  const r = 6371;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(lat1 * math.pi / 180) *
              math.cos(lat2 * math.pi / 180) *
              math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

String _truncateBio(String bio) {
  if (bio.length <= 120) return bio;
  return '${bio.substring(0, 117).trim()}...';
}

// ============================================================
// MAIN FEED PAGE
// ============================================================

class DatingFeedPage extends StatefulWidget {
  const DatingFeedPage({super.key});

  @override
  State<DatingFeedPage> createState() => _DatingFeedPageState();
}

class _DatingFeedPageState extends State<DatingFeedPage> {
  List<UserProfile> _allProfiles = [];
  int _tabIndex = 0;
  FilterOptions _filters = FilterOptions();
  final PageController _verticalController = PageController();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final me = client.auth.currentUser;
      if (me == null) {
        setState(() {
          _allProfiles = [];
          _error = 'กรุณาเข้าสู่ระบบเพื่อดูหน้า feed';
          _isLoading = false;
        });
        return;
      }

      final currentProfile = await client
          .from('profiles')
          .select('latitude, longitude')
          .eq('id', me.id)
          .maybeSingle();

      final myLat = (currentProfile?['latitude'] as num?)?.toDouble() ?? 0.0;
      final myLon = (currentProfile?['longitude'] as num?)?.toDouble() ?? 0.0;

      final likedRows = await client
          .from('profile_likes')
          .select('liked_id')
          .eq('liker_id', me.id);
      final likedIds = <String>{};
      for (final row in (likedRows as List)) {
        likedIds.add(row['liked_id'] as String);
      }

      final followingRows = await client
          .from('follows')
          .select('followed_id')
          .eq('follower_id', me.id);
      final followingIds = <String>{};
      for (final row in (followingRows as List)) {
        followingIds.add(row['followed_id'] as String);
      }

      final response = await client.from('profiles').select('''
        id,
        display_name,
        gender,
        birth_date,
        bio,
        province,
        district,
        university,
        occupation,
        is_verified,
        is_online,
        last_seen_at,
        latitude,
        longitude,
        likes_received_count,
        profile_photos(public_url, is_primary, sort_order),
        profile_interests(interest_id(name))
      ''')
        .neq('id', me.id)
        .limit(80);

      final loaded = <UserProfile>[];
      for (final row in (response as List)) {
        final photos = List<Map<String, dynamic>>.from(row['profile_photos'] ?? []);
        photos.sort((a, b) {
          if (a['is_primary'] == true && b['is_primary'] != true) return -1;
          if (a['is_primary'] != true && b['is_primary'] == true) return 1;
          return (a['sort_order'] as int? ?? 999).compareTo(b['sort_order'] as int? ?? 999);
        });

        final photoUrls = photos
            .map((item) => item['public_url'] as String?)
            .whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList();

        final interests = <String>[];
        for (final pi in (row['profile_interests'] as List? ?? [])) {
          final name = pi['interest_id']?['name'];
          if (name is String) interests.add(name);
        }

        final age = _calculateAge(row['birth_date'] as String?);
        final bool isOnline = row['is_online'] == true;
        final lastSeenAt = row['last_seen_at'] as String?;
        final bool onlineWithin24h = lastSeenAt != null
            ? DateTime.now().difference(DateTime.parse(lastSeenAt)).inHours <= 24
            : isOnline;
        final lat = (row['latitude'] as num?)?.toDouble() ?? 0.0;
        final lon = (row['longitude'] as num?)?.toDouble() ?? 0.0;
        final distanceKm = myLat != 0.0 || myLon != 0.0
            ? _calculateDistanceKm(myLat, myLon, lat, lon)
            : 0.0;

        loaded.add(UserProfile(
          id: row['id'] as String,
          name: row['display_name'] as String? ?? 'ไม่มีชื่อ',
          age: age,
          district: row['district'] as String? ?? '',
          province: row['province'] as String? ?? '',
          shortBio: _truncateBio(row['bio'] as String? ?? ''),
          tags: interests,
          photos: photoUrls.isNotEmpty ? photoUrls : <String>[''],
          gender: _genderFromString(row['gender'] as String?),
          occupation: row['occupation'] as String? ?? '',
          education: row['university'] as String? ?? '',
          fullBio: row['bio'] as String? ?? '',
          followers: (row['likes_received_count'] as int?) ?? 0,
          followingCount: followingIds.contains(row['id'] as String) ? 1 : 0,
          isOnline: isOnline,
          onlineWithin24h: onlineWithin24h,
          distanceKm: distanceKm,
          themeColor: _themeColorForProfile(row['id'] as String),
          likeCount: (row['likes_received_count'] as int?) ?? 0,
          isLiked: likedIds.contains(row['id'] as String),
          isFavorited: false,
          isFollowing: followingIds.contains(row['id'] as String),
        ));
      }

      setState(() {
        _allProfiles = loaded;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('DatingFeedPage load error: $e');
      if (mounted) {
        setState(() {
          _error = 'เกิดข้อผิดพลาดในการโหลดข้อมูล';
          _allProfiles = [];
          _isLoading = false;
        });
      }
    }
  }

  int _calculateAge(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return 0;
    final date = DateTime.tryParse(birthDate);
    if (date == null) return 0;
    final now = DateTime.now();
    var age = now.year - date.year;
    if (now.month < date.month || (now.month == date.month && now.day < date.day)) {
      age--;
    }
    return age;
  }

  List<UserProfile> get _filteredProfiles {
    var list = _allProfiles.where((p) {
      if (!_filters.genders.contains(p.gender)) return false;
      if (p.age < _filters.ageRange.start || p.age > _filters.ageRange.end) return false;
      if (_filters.province != 'ทั้งหมด' && p.province != _filters.province) return false;
      if (_filters.district != 'ทั้งหมด' && p.district != _filters.district) return false;
      if (p.distanceKm > _filters.maxDistanceKm) return false;
      if (_filters.onlineStatus == OnlineStatus.onlineNow && !p.isOnline) return false;
      if (_filters.onlineStatus == OnlineStatus.within24h && !p.isOnline && !p.onlineWithin24h) {
        return false;
      }
      return true;
    }).toList();

    if (_tabIndex == 1) {
      list = list.where((p) => p.isFollowing).toList();
    } else if (_tabIndex == 2) {
      list = list.where((p) => p.distanceKm <= 10).toList()
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    }

    return list;
  }

  void _resetToFirstPage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verticalController.hasClients) {
        _verticalController.jumpToPage(0);
      }
    });
  }

  void _onTabTap(int index) {
    setState(() => _tabIndex = index);
    _resetToFirstPage();
  }

  Future<void> _openFilterSheet() async {
    final result = await showModalBottomSheet<FilterOptions>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSheetBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _FilterSheet(initial: _filters.copy()),
    );
    if (result != null) {
      setState(() => _filters = result);
      _resetToFirstPage();
    }
  }

  void _openProfileDetail(UserProfile profile) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ProfileDetailPage(profile: profile)))
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _toggleLike(UserProfile profile) async {
    final previousLiked = profile.isLiked;
    final previousCount = profile.likeCount;
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      profile.isLiked = !profile.isLiked;
      profile.likeCount += profile.isLiked ? 1 : -1;
    });

    try {
      final client = Supabase.instance.client;
      final me = client.auth.currentUser;
      if (me == null) throw Exception('ยังไม่ได้ล็อกอิน');

      if (profile.isLiked) {
        await client.from('profile_likes').upsert({
          'liker_id': me.id,
          'liked_id': profile.id,
        });
      } else {
        await client.from('profile_likes').delete().eq('liker_id', me.id).eq('liked_id', profile.id);
      }
    } catch (e) {
      debugPrint('Like update failed: $e');
      if (mounted) {
        setState(() {
          profile.isLiked = previousLiked;
          profile.likeCount = previousCount;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('ไม่สามารถอัปเดตสถานะถูกใจได้')),
        );
      }
    }
  }

  void _toggleFavorite(UserProfile profile) {
    setState(() => profile.isFavorited = !profile.isFavorited);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text(
          profile.isFavorited ? 'บันทึก ${profile.name} แล้ว' : 'นำ ${profile.name} ออกจากรายการบันทึก',
        ),
      ),
    );
  }

  Future<void> _openChatPlaceholder(UserProfile profile) async {
    final client = Supabase.instance.client;
    final me = client.auth.currentUser;
    if (me == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนเริ่มแชท')),
        );
      }
      return;
    }

    try {
      final ids = [me.id, profile.id]..sort();
      final existing = await client
          .from('conversations')
          .select('id')
          .eq('user_low_id', ids[0])
          .eq('user_high_id', ids[1])
          .maybeSingle();

      String convId;
      if (existing != null) {
        convId = existing['id'] as String;
      } else {
        final created = await client
            .from('conversations')
            .insert({'user_low_id': ids[0], 'user_high_id': ids[1]})
            .select('id')
            .single();
        convId = created['id'] as String;
      }

      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          thread: ChatThread(
            id: convId,
            partnerName: profile.name,
            partnerPhotoUrl: profile.photos.isNotEmpty ? profile.photos.first : '',
            lastMessage: '',
            lastMessageAt: DateTime.now(),
            isOnline: profile.isOnline,
          ),
        ),
      ));
    } catch (e) {
      debugPrint('Chat navigation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่สามารถเข้าแชทได้ขณะนี้')),
        );
      }
    }
  }

  void _openComments(UserProfile profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kSheetBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => _CommentsSheet(
        profile: profile,
        onAdd: (text) {
          setState(() {
            profile.comments.insert(
              0,
              Comment(
                id: DateTime.now().microsecondsSinceEpoch.toString(),
                author: 'คุณ',
                avatarColorHex: '#7C6AFF',
                text: text,
                timeAgo: 'เมื่อสักครู่',
              ),
            );
          });
        },
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _filters = FilterOptions();
      _tabIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profiles = _filteredProfiles;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white70, size: 64),
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProfiles,
                      style: ElevatedButton.styleFrom(backgroundColor: kAccentColor),
                      child: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              ),
            )
          else if (profiles.isEmpty)
            _EmptyState(onReset: _resetFilters)
          else
            PageView.builder(
              key: ValueKey('feed-$_tabIndex-${profiles.length}'),
              controller: _verticalController,
              scrollDirection: Axis.vertical,
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return _ProfileCard(
                  key: ValueKey(profile.id),
                  profile: profile,
                  onAvatarTap: () => _openProfileDetail(profile),
                  onLikeTap: () => _toggleLike(profile),
                  onFavoriteTap: () => _toggleFavorite(profile),
                  onCommentTap: () => _openComments(profile),
                  onChatTap: () => _openChatPlaceholder(profile),
                );
              },
            ),
          _TopBar(
            tabIndex: _tabIndex,
            onTabTap: _onTabTap,
            onFilterTap: _openFilterSheet,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PROFILE CARD (full-screen feed item)
// ============================================================

class _ProfileCard extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onAvatarTap;
  final VoidCallback onLikeTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onCommentTap;
  final VoidCallback onChatTap;

  const _ProfileCard({
    super.key,
    required this.profile,
    required this.onAvatarTap,
    required this.onLikeTap,
    required this.onFavoriteTap,
    required this.onCommentTap,
    required this.onChatTap,
  });

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> with SingleTickerProviderStateMixin {
  final PageController _photoController = PageController();
  final TransformationController _photoTransform = TransformationController();
  TapDownDetails? _lastPhotoTapDown;
  int _photoIndex = 0;
  late AnimationController _heartController;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _photoController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    if (!widget.profile.isLiked) {
      widget.onLikeTap();
    }
    setState(() => _showHeart = true);
    _heartController.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _showHeart = false);
    });
  }

  void _handlePhotoTapDown(TapDownDetails details) {
    _lastPhotoTapDown = details;
  }

  void _handlePhotoTap(BuildContext context) {
    if (_lastPhotoTapDown == null || widget.profile.photos.length <= 1) return;
    final width = MediaQuery.of(context).size.width;
    final isRight = _lastPhotoTapDown!.localPosition.dx > width / 2;
    if (isRight && _photoIndex < widget.profile.photos.length - 1) {
      _photoController.nextPage(duration: const Duration(milliseconds: 160), curve: Curves.easeInOut);
    } else if (!isRight && _photoIndex > 0) {
      _photoController.previousPage(duration: const Duration(milliseconds: 160), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _handlePhotoTapDown,
          onTap: () => _handlePhotoTap(context),
          onDoubleTap: _handleDoubleTap,
          child: PageView.builder(
            controller: _photoController,
            itemCount: profile.photos.length,
            onPageChanged: (i) {
              setState(() => _photoIndex = i);
              _photoTransform.value = Matrix4.identity();
            },
            itemBuilder: (context, i) {
              return InteractiveViewer(
                transformationController: _photoTransform,
                minScale: 1.0,
                maxScale: 4.0,
                panEnabled: true,
                scaleEnabled: true,
                onInteractionEnd: (_) {
                  _photoTransform.value = Matrix4.identity();
                },
                child: Image.network(
                  profile.photos[i],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: kCardBackground,
                      child: const Center(child: CircularProgressIndicator(color: Colors.white54)),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [profile.themeColor.withValues(alpha: 0.9), Colors.black],
                        ),
                      ),
                      child: const Center(child: Icon(Icons.person, size: 96, color: Colors.white38)),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (profile.photos.length > 1)
          Positioned(
            top: 100,
            left: 12,
            right: 72,
            child: Row(
              children: List.generate(profile.photos.length, (i) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == _photoIndex ? Colors.white : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 260,
          child: IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 88,
          bottom: 28,
          child: _ProfileInfoOverlay(profile: profile, onTapBio: widget.onAvatarTap),
        ),
        Positioned(
          right: 12,
          bottom: 28,
          child: _ActionButtonsColumn(
            profile: profile,
            onAvatarTap: widget.onAvatarTap,
            onLikeTap: widget.onLikeTap,
            onFavoriteTap: widget.onFavoriteTap,
            onCommentTap: widget.onCommentTap,
            onChatTap: widget.onChatTap,
          ),
        ),
        if (_showHeart)
          Center(
            child: ScaleTransition(
              scale: CurvedAnimation(parent: _heartController, curve: Curves.elasticOut),
              child: const Icon(Icons.favorite, color: kAccentColor, size: 120),
            ),
          ),
      ],
    );
  }
}

class _ProfileInfoOverlay extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onTapBio;

  const _ProfileInfoOverlay({required this.profile, required this.onTapBio});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapBio,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  profile.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${profile.age}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                ),
              ),
              if (profile.isOnline) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('ออนไลน์', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, size: 15, color: Colors.white),
                const SizedBox(width: 4),
                Text('${profile.district}, ${profile.province}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            profile.shortBio,
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.35, fontWeight: FontWeight.w400),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (profile.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(color: profile.themeColor, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButtonsColumn extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onAvatarTap;
  final VoidCallback onLikeTap;
  final VoidCallback onFavoriteTap;
  final VoidCallback onCommentTap;
  final VoidCallback onChatTap;

  const _ActionButtonsColumn({
    required this.profile,
    required this.onAvatarTap,
    required this.onLikeTap,
    required this.onFavoriteTap,
    required this.onCommentTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: ClipOval(
              child: Image.network(
                profile.photos.first,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: profile.themeColor, child: const Icon(Icons.person, color: Colors.white)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _ActionIconButton(
          icon: profile.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          iconColor: AppColors.brandPink,
          label: '${profile.likeCount}',
          onTap: onLikeTap,
        ),
        const SizedBox(height: 20),
        _ActionIconButton(
          icon: Icons.mode_comment_rounded,
          iconColor: AppColors.iconPurple,
          label: '${profile.comments.length}',
          onTap: onCommentTap,
        ),
        const SizedBox(height: 20),
        _ActionIconButton(
          icon: profile.isFavorited ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          iconColor: AppColors.iconOrange,
          label: 'บันทึก',
          onTap: onFavoriteTap,
        ),
        const SizedBox(height: 20),
        _ActionIconButton(
          icon: Icons.send_rounded,
          iconColor: AppColors.iconTeal,
          label: 'แชท',
          onTap: onChatTap,
        ),
      ],
    );
  }
}

class _ActionIconButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  State<_ActionIconButton> createState() => _ActionIconButtonState();
}

class _ActionIconButtonState extends State<_ActionIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _ctrl.forward(from: 0);
        widget.onTap();
      },
      child: Column(
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 26),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 6, color: Colors.black45)]),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onTabTap;
  final VoidCallback onFilterTap;

  const _TopBar({required this.tabIndex, required this.onTabTap, required this.onFilterTap});

  static const List<_TabInfo> _tabs = [
    _TabInfo('สำหรับคุณ', Icons.auto_awesome_rounded),
    _TabInfo('กำลังติดตาม', Icons.favorite_rounded),
    _TabInfo('ใกล้ฉัน', Icons.near_me_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: topPadding + 10, bottom: 14, left: 12, right: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.85),
              Colors.white.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final selected = i == tabIndex;
                    final tab = _tabs[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onTabTap(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: selected
                                ? [
                                    BoxShadow(
                                      color: kAccentColor.withValues(alpha: 0.25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(tab.icon, size: 15, color: selected ? kAccentColor : Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                tab.label,
                                style: TextStyle(
                                  color: selected ? kAccentColor : Colors.white,
                                  fontSize: 13,
                                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onFilterTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Icon(Icons.tune_rounded, size: 18, color: kAccentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabInfo {
  final String label;
  final IconData icon;
  const _TabInfo(this.label, this.icon);
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onReset;

  const _EmptyState({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: Colors.white38, size: 64),
            const SizedBox(height: 16),
            const Text(
              'ไม่พบโปรไฟล์ที่ตรงกับเงื่อนไข',
              style: TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onReset,
              style: ElevatedButton.styleFrom(backgroundColor: kAccentColor),
              child: const Text('ล้างตัวกรอง'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// FILTER BOTTOM SHEET
// ============================================================

class _FilterSheet extends StatefulWidget {
  final FilterOptions initial;

  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late FilterOptions _options;

  static const List<double> _distanceOptions = [5, 10, 20, 50, 999];
  static const List<String> _distanceLabels = ['5 กม.', '10 กม.', '20 กม.', '50 กม.', 'ไม่จำกัด'];

  @override
  void initState() {
    super.initState();
    _options = widget.initial.copy();
  }

  String get _districtValue {
    final list = kProvinceDistricts[_options.province] ?? const ['ทั้งหมด'];
    if (!list.contains(_options.district)) return list.first;
    return _options.district;
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: kCardBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }

  Widget _genderChip(String label, Gender g) {
    final selected = _options.genders.contains(g);
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: kAccentColor,
      backgroundColor: kCardBackground,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
      onSelected: (v) {
        setState(() {
          if (v) {
            _options.genders.add(g);
          } else if (_options.genders.length > 1) {
            _options.genders.remove(g);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final districts = kProvinceDistricts[_options.province] ?? const ['ทั้งหมด'];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('ตัวกรอง', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () => setState(() => _options = FilterOptions()),
                    child: const Text('ล้างทั้งหมด', style: TextStyle(color: Colors.white60)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('เพศ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _genderChip('ชาย', Gender.male),
                  _genderChip('หญิง', Gender.female),
                  _genderChip('LGBTQ+', Gender.lgbtq),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'อายุ ${_options.ageRange.start.round()} - ${_options.ageRange.end.round()} ปี',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              RangeSlider(
                values: _options.ageRange,
                min: 18,
                max: 60,
                divisions: 42,
                activeColor: kAccentColor,
                labels: RangeLabels(
                  _options.ageRange.start.round().toString(),
                  _options.ageRange.end.round().toString(),
                ),
                onChanged: (v) => setState(() => _options.ageRange = v),
              ),
              const SizedBox(height: 8),
              const Text('จังหวัด', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _options.province,
                dropdownColor: kCardBackground,
                decoration: _dropdownDecoration(),
                style: const TextStyle(color: Colors.white),
                items: kProvinceDistricts.keys.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _options.province = v;
                    _options.district = 'ทั้งหมด';
                  });
                },
              ),
              const SizedBox(height: 12),
              const Text('อำเภอ', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _districtValue,
                dropdownColor: kCardBackground,
                decoration: _dropdownDecoration(),
                style: const TextStyle(color: Colors.white),
                items: districts.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _options.district = v);
                },
              ),
              const SizedBox(height: 16),
              const Text('ระยะทาง', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(_distanceOptions.length, (i) {
                  final selected = _options.maxDistanceKm == _distanceOptions[i];
                  return ChoiceChip(
                    label: Text(_distanceLabels[i]),
                    selected: selected,
                    selectedColor: kAccentColor,
                    backgroundColor: kCardBackground,
                    labelStyle: TextStyle(color: selected ? Colors.white : Colors.white70),
                    onSelected: (_) => setState(() => _options.maxDistanceKm = _distanceOptions[i]),
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text('สถานะออนไลน์', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              _OnlineStatusOption(
                label: 'ออนไลน์ตอนนี้',
                selected: _options.onlineStatus == OnlineStatus.onlineNow,
                onTap: () => setState(() => _options.onlineStatus = OnlineStatus.onlineNow),
              ),
              _OnlineStatusOption(
                label: 'ออนไลน์ภายใน 24 ชั่วโมง',
                selected: _options.onlineStatus == OnlineStatus.within24h,
                onTap: () => setState(() => _options.onlineStatus = OnlineStatus.within24h),
              ),
              _OnlineStatusOption(
                label: 'ทั้งหมด',
                selected: _options.onlineStatus == OnlineStatus.all,
                onTap: () => setState(() => _options.onlineStatus = OnlineStatus.all),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(_options),
                  child: const Text('ใช้ตัวกรอง', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineStatusOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OnlineStatusOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? kAccentColor : kCardBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// COMMENTS BOTTOM SHEET
// ============================================================

class _CommentsSheet extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<String> onAdd;

  const _CommentsSheet({required this.profile, required this.onAdd});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAdd(text);
    _controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),
              Text('คอมเมนต์ (${widget.profile.comments.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white12, height: 16),
              Expanded(
                child: widget.profile.comments.isEmpty
                    ? const Center(child: Text('ยังไม่มีคอมเมนต์ ลองเป็นคนแรกสิ!', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: widget.profile.comments.length,
                        itemBuilder: (context, i) {
                          final c = widget.profile.comments[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: hexToColor(c.avatarColorHex),
                                  child: Text(
                                    c.author.isNotEmpty ? c.author[0] : '?',
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(c.author, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                          const SizedBox(width: 8),
                                          Text(c.timeAgo, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(c.text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'เขียนคอมเมนต์...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: kCardBackground,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(icon: const Icon(Icons.send, color: kAccentColor), onPressed: _submit),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PROFILE DETAIL PAGE
// ============================================================

class ProfileDetailPage extends StatefulWidget {
  final UserProfile profile;

  const ProfileDetailPage({super.key, required this.profile});

  @override
  State<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends State<ProfileDetailPage> {
  void _toggleFollow() {
    setState(() => widget.profile.isFollowing = !widget.profile.isFollowing);
  }

  void _toggleLike() {
    setState(() {
      widget.profile.isLiked = !widget.profile.isLiked;
      widget.profile.likeCount += widget.profile.isLiked ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(profile.name),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Center(
            child: ClipOval(
              child: Image.network(
                profile.photos.first,
                width: 112,
                height: 112,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 112,
                  height: 112,
                  color: profile.themeColor.withValues(alpha: 0.3),
                  child: const Icon(Icons.person, size: 56, color: Colors.white70),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              '${profile.name} • ${profile.age}',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text('${profile.district}, ${profile.province}', style: const TextStyle(color: Colors.white60)),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBlock(label: 'ผู้ติดตาม', value: profile.followers.toString()),
              const SizedBox(width: 32),
              _StatBlock(label: 'ติดตามกลับ', value: profile.followingCount.toString()),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionPillButton(
                  label: profile.isLiked ? 'ถูกใจแล้ว' : 'ถูกใจ',
                  icon: profile.isLiked ? Icons.favorite : Icons.favorite_border,
                  active: profile.isLiked,
                  onTap: _toggleLike,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionPillButton(
                  label: profile.isFollowing ? 'กำลังติดตาม' : 'ติดตาม',
                  icon: profile.isFollowing ? Icons.check : Icons.person_add_alt,
                  active: profile.isFollowing,
                  onTap: _toggleFollow,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionPillButton(
                  label: 'ส่งข้อความ',
                  icon: Icons.chat_bubble_outline,
                  active: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('เปิดแชทกับ ${profile.name} (mock - ยังไม่เชื่อมระบบจริง)')),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('แกลเลอรี', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: profile.photos.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
            ),
            itemBuilder: (context, i) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                profile.photos[i],
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: const Color(0xFF222222),
                  child: const Icon(Icons.image_not_supported, color: Colors.white24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('เกี่ยวกับฉัน', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(profile.fullBio, style: const TextStyle(color: Colors.white70, height: 1.5)),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.work_outline, label: profile.occupation),
          _InfoRow(icon: Icons.school_outlined, label: profile.education),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: profile.tags
                .map((t) => Chip(
                      label: Text('#$t', style: const TextStyle(color: Colors.white)),
                      backgroundColor: const Color(0xFF262626),
                      side: BorderSide.none,
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ActionPillButton({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? kAccentColor : const Color(0xFF262626),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }
}
