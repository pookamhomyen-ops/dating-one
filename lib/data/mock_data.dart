import '../models/chat_message.dart';
import '../models/chat_thread.dart';
import '../models/feed_post.dart';
import '../models/gender.dart';
import '../models/member.dart';
import '../models/user_profile.dart';

class MockData {
  MockData._();

  static String avatarUrl(String seed, {int size = 200}) =>
      'https://i.pravatar.cc/$size?u=$seed';

  static String photoUrl(String seed, {int w = 600, int h = 800}) =>
      'https://picsum.photos/seed/$seed/$w/$h';

  static final currentUser = UserProfile(
    id: 'me',
    name: 'ณัฐพล สุขใจ',
    gender: Gender.male,
    age: 26,
    province: 'กรุงเทพมหานคร',
    district: 'บางรัก',
    bio: 'ชอบกาแฟ ชอบเดินทาง และชอบคุยกับคนใหม่ๆ ☕✈️',
    interests: ['กาแฟ', 'ท่องเที่ยว', 'ถ่ายรูป', 'ฟิตเนส'],
    profileViews: 1284,
    likesReceived: 342,
    lineId: '@nattapol_s',
    instagram: '@nattapol.photo',
    xHandle: '@nattapol_th',
    facebook: 'Nattapol Sukjai',
    photoUrls: [
      avatarUrl('me1', size: 400),
      photoUrl('me2'),
      photoUrl('me3'),
    ],
  );

  static List<Member> members = [
    Member(
      id: '1',
      name: 'มายด์',
      gender: Gender.female,
      age: 26,
      province: 'กรุงเทพมหานคร',
      district: 'สาทร',
      distanceKm: 2,
      photoUrl: photoUrl('mild'),
      university: 'จุฬาลงกรณ์มหาวิทยาลัย',
      occupation: 'UX Designer',
      interests: ['คาเฟ่', 'ท่องเที่ยว', 'ฟังเพลง'],
      isOnline: true,
      isVerified: true,
    ),
    Member(
      id: '2',
      name: 'เฟิร์น',
      gender: Gender.female,
      age: 24,
      province: 'กรุงเทพมหานคร',
      district: 'อารีย์',
      distanceKm: 3,
      photoUrl: photoUrl('fern'),
      university: 'มหิดล University',
      occupation: 'Graphic Designer',
      interests: ['ถ่ายรูป', 'ศิลปะ', 'แมว'],
      lastActiveMinutes: 15,
      isVerified: true,
    ),
    Member(
      id: '3',
      name: 'ภูมิ',
      gender: Gender.male,
      age: 28,
      province: 'กรุงเทพมหานคร',
      district: 'ลาดพร้าว',
      distanceKm: 5,
      photoUrl: photoUrl('phoom2'),
      university: 'เกษตรศาสตร์',
      occupation: 'Software Engineer',
      interests: ['เกม', 'ฟิตเนส', 'กาแฟ'],
      isOnline: true,
      isVerified: true,
    ),
    Member(
      id: '4',
      name: 'อารี',
      gender: Gender.other,
      age: 25,
      province: 'นนทบุรี',
      district: 'เมืองนนทบุรี',
      distanceKm: 6,
      photoUrl: photoUrl('aree'),
      university: 'ศิลปากร',
      occupation: 'ศิลปินอิสระ',
      interests: ['วาดรูป', 'ดนตรี', 'คาเฟ่'],
      lastActiveMinutes: 45,
    ),
    Member(
      id: '5',
      name: 'พิมพ์ชนก',
      gender: Gender.female,
      age: 24,
      province: 'กรุงเทพมหานคร',
      district: 'สาทร',
      distanceKm: 0.8,
      photoUrl: photoUrl('pim'),
      university: 'ธรรมศาสตร์',
      occupation: 'Marketing',
      interests: ['อ่านหนังสือ', 'ถ่ายรูป'],
      lastActiveMinutes: 30,
      isVerified: true,
    ),
    Member(
      id: '6',
      name: 'ธนกร',
      gender: Gender.male,
      age: 27,
      province: 'กรุงเทพมหานคร',
      district: 'คลองเตย',
      distanceKm: 1.2,
      photoUrl: photoUrl('than'),
      university: 'มหาวิทยาลัยกรุงเทพ',
      occupation: 'Product Manager',
      interests: ['วิ่ง', 'กาแฟ'],
      isOnline: true,
    ),
  ];

  static List<FeedPost> initialPosts = [
    FeedPost(
      id: 'p1',
      authorId: '1',
      authorName: 'มายด์',
      authorGender: Gender.female,
      authorPhotoUrl: avatarUrl('mild'),
      content: 'วันนี้ไปคาเฟ่ใหม่แถวสาทร บรรยากาศดีมาก ใครอยากไปด้วยกันบ้าง? ☕',
      postedAt: DateTime.now().subtract(const Duration(minutes: 25)),
      imageUrl: photoUrl('cafe1', w: 800, h: 500),
      likes: 42,
      comments: 8,
    ),
    FeedPost(
      id: 'p2',
      authorId: '3',
      authorName: 'ภูมิ',
      authorGender: Gender.male,
      authorPhotoUrl: avatarUrl('phoom2'),
      content: 'วิ่งเช้า 5 กม. เสร็จแล้ว! ใครวิ่งด้วยกันได้ทักมา 🏃',
      postedAt: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 18,
      comments: 3,
    ),
    FeedPost(
      id: 'p3',
      authorId: '4',
      authorName: 'อารี',
      authorGender: Gender.other,
      authorPhotoUrl: avatarUrl('aree'),
      content: 'ผลงานใหม่จากสตูดิโอ สีสันที่ชอบที่สุดในฤดูนี้ 🎨',
      postedAt: DateTime.now().subtract(const Duration(hours: 5)),
      imageUrl: photoUrl('art1', w: 800, h: 600),
      likes: 67,
      comments: 15,
    ),
    FeedPost(
      id: 'p4',
      authorId: '2',
      authorName: 'เฟิร์น',
      authorGender: Gender.female,
      authorPhotoUrl: avatarUrl('fern'),
      content: 'หมาใหม่ของเพื่อน น่ารักมากจนอยากเลี้ยงตาม 🐕',
      postedAt: DateTime.now().subtract(const Duration(hours: 8)),
      imageUrl: photoUrl('dog1', w: 800, h: 500),
      likes: 95,
      comments: 22,
    ),
  ];

  static List<ChatThread> chatThreads = [
    ChatThread(
      id: 'c1',
      partnerName: 'มายด์',
      partnerPhotoUrl: avatarUrl('mild'),
      lastMessage: 'เจอกันที่คาเฟ่ได้เลยนะ 😊',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 12)),
      unreadCount: 2,
      isOnline: true,
    ),
    ChatThread(
      id: 'c2',
      partnerName: 'ภูมิ',
      partnerPhotoUrl: avatarUrl('phoom2'),
      lastMessage: 'พรุ่งนี้วิ่งด้วยกันไหม?',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 3)),
      unreadCount: 0,
    ),
    ChatThread(
      id: 'c3',
      partnerName: 'เฟิร์น',
      partnerPhotoUrl: avatarUrl('fern'),
      lastMessage: 'ขอบคุณที่ชอบผลงานนะ',
      lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 1,
    ),
  ];

  static Map<String, List<ChatMessage>> chatMessages = {
    'c1': [
      ChatMessage(
        id: 'm1',
        text: 'สวัสดีค่ะ เห็นโพสต์คาเฟ่แล้วน่าสนใจมาก',
        sentAt: DateTime.now().subtract(const Duration(hours: 1)),
        isMine: false,
      ),
      ChatMessage(
        id: 'm2',
        text: 'สวัสดีครับ ขอบคุณมากเลย ร้านนี้ดีจริงๆ',
        sentAt: DateTime.now().subtract(const Duration(minutes: 55)),
        isMine: true,
      ),
      ChatMessage(
        id: 'm3',
        text: 'เจอกันที่คาเฟ่ได้เลยนะ 😊',
        sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
        isMine: false,
      ),
    ],
    'c2': [
      ChatMessage(
        id: 'm4',
        text: 'พรุ่งนี้วิ่งด้วยกันไหม?',
        sentAt: DateTime.now().subtract(const Duration(hours: 3)),
        isMine: false,
      ),
    ],
    'c3': [
      ChatMessage(
        id: 'm5',
        text: 'ขอบคุณที่ชอบผลงานนะ',
        sentAt: DateTime.now().subtract(const Duration(days: 1)),
        isMine: false,
      ),
    ],
  };
}
