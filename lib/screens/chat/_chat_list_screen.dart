import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'chat_detail_screen.dart'; // 👈 นำเข้าหน้าต่างแชทส่วนตัวเรียบร้อย

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  // จำลองข้อมูลคู่ Match ใหม่ที่ยังไม่ได้เริ่มคุย (ทรงเหลี่ยมสตรีท)
  final List<Map<String, String>> _newMatches = [
    {'name': 'ARADA', 'age': '22', 'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200'},
    {'name': 'PIM', 'age': '24', 'image': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=200'},
    {'name': 'NATTY', 'age': '21', 'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200'},
    {'name': 'BOW', 'age': '23', 'image': 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=200'},
  ];

  // จำลองข้อมูลรายการแชทปัจจุบัน
  final List<Map<String, dynamic>> _chatRooms = [
    {
      'name': 'ARADA',
      'age': '22',
      'lastMessage': 'วันนี้ไปคาเฟ่แถวอารีย์กันไหมเธอ? ☕️',
      'time': '12:45',
      'unreadCount': 2,
      'isOnline': true,
      'image': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=200'
    },
    {
      'name': 'PIM',
      'age': '24',
      'lastMessage': '555+ ตลกจัง ไว้วันหลังคุยกันใหม่นะ',
      'time': 'เมื่อวาน',
      'unreadCount': 0,
      'isOnline': false,
      'image': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=200'
    },
    {
      'name': 'NATTY',
      'age': '21',
      'lastMessage': 'ส่งสติ๊กเกอร์หาคุณ',
      'time': '3 วันก่อน',
      'unreadCount': 0,
      'isOnline': true,
      'image': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB), // ขาวสว่างคลีนๆ เข้าคู่กับหน้า Swipe
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'MESSAGES',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_sharp, color: Colors.black), // ไอคอนปรับแต่งทรงเหลี่ยม
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. กล่องค้นหา (Search Bar) ดีไซน์เหลี่ยมตัดเส้นสีดำเท่ๆ สไตล์สตรีท
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero, // เหลี่ยมจัด
                border: Border.all(color: Colors.black, width: 2), // เส้นขอบดำชัดเจน
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 0,
                    offset: Offset(3, 3), // เงา Hard Shadow เยื้องๆ
                  )
                ],
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'ค้นหาคนรู้ใจหรือข้อความ...',
                  hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                  prefixIcon: Icon(Icons.search_sharp, color: Colors.black),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // 2. ส่วนของ NEW MATCHES (คู่แมตช์ใหม่รูปทรงเหลี่ยมคม)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'NEW MATCHES ✨',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.black45),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 115,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _newMatches.length,
              itemBuilder: (context, index) {
                final match = _newMatches[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    children: [
                      // รูปคู่แมตช์สี่เหลี่ยมจัตุรัส ชิดขอบเหลี่ยมคมตามบรีฟหน้าสไลด์
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.zero, // ทรงเหลี่ยมจัด
                          border: Border.all(color: AppColors.brandPink, width: 2),
                        ),
                        child: Image.network(
                          match['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(color: Colors.grey[200]),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${match['name']} ${match['age']}', // ไม่มีคอมม่าตามที่สั่ง
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.black),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),
          const Divider(color: Colors.black12, thickness: 1, indent: 16, endIndent: 16),
          const SizedBox(height: 8),

          // 3. รายการกล่องข้อความแชท (CHAT ROOMS)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
            child: Text(
              'RECENT CHATS',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.black45),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _chatRooms.length,
              padding: const EdgeInsets.only(top: 8),
              itemBuilder: (context, index) {
                final chat = _chatRooms[index];
                final hasUnread = chat['unreadCount'] > 0;

                return InkWell(
                  onTap: () {
                    // 🛑 ลิงก์ข้ามหน้าไปยังห้องแชทส่วนตัว พร้อมส่ง Parameter ไปแสดงผลจริง
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatDetailScreen(
                          name: chat['name'] ?? '',
                          age: chat['age'] ?? '',
                          image: chat['image'] ?? '',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      // ไฮไลท์ห้องที่ยังไม่ได้อ่านด้วยสีชมพูอ่อนจางๆ แบบโมเดิร์น
                      color: hasUnread ? AppColors.brandPink.withValues(alpha: 0.03) : Colors.transparent,
                      border: const Border(bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1)),
                    ),
                    child: Row(
                      children: [
                        // รูปโปรไฟล์คนคุย (ทรงสี่เหลี่ยมคมสลัดความจืดชืด)
                        Stack(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.zero, // ทรงเหลี่ยมสตรีทเด่นๆ
                                border: Border.all(
                                  color: hasUnread ? AppColors.brandPink : Colors.black12,
                                  width: 1.5,
                                ),
                              ),
                              child: Image.network(
                                chat['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(color: Colors.grey[200]),
                              ),
                            ),
                            // จุดสี่เหลี่ยมแสดงสถานะออนไลน์ที่มุมล่างขวาของรูป
                            if (chat['isOnline'])
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E676), // สีเขียวมะนาวสว่างกระแทกตา
                                    borderRadius: BorderRadius.zero, // เหลี่ยมให้สุดแนว
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // ชื่อย่อยและข้อความล่าสุด
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${chat['name']} ${chat['age']}', // ไม่มีคอมม่าตามคอนเซปต์
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: hasUnread ? FontWeight.w900 : FontWeight.w700,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                chat['lastMessage'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                  color: hasUnread ? Colors.black87 : Colors.black45, 
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // เวลา และ วงกลมจำนวนข้อความที่ยังไม่ได้อ่าน
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              chat['time'],
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                                  color: hasUnread ? AppColors.brandPink : Colors.black26),
                            ),
                            const SizedBox(height: 6),
                            if (hasUnread)
                              // ข้อความที่ยังไม่ได้อ่านใช้ทรงกลมเพื่อความนุ่มนวลและเด่นสะดุดตาเวลาแจ้งเตือน
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: const BoxDecoration(
                                  color: AppColors.brandPink,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${chat['unreadCount']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}