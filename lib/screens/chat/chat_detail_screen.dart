import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String age;
  final String image;

  const ChatDetailScreen({
    super.key,
    required this.name,
    required this.age,
    required this.image,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'หวัดดีครับ ทำอะไรอยู่เอ่ย? 😊', 'isMe': true, 'time': '12:40'},
    {'text': 'หวัดดีค่ะ กำลังหาของกินอยู่เลย เธอมีร้านแนะนำไหม', 'isMe': false, 'time': '12:42'},
    {'text': 'วันนี้ไปคาเฟ่แถวอารีย์กันไหมเธอ? ☕️', 'isMe': true, 'time': '12:45'},
  ];

  late AnimationController _btnCtrl;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _btnCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _btnScale = Tween<double>(begin: 1.0, end: 0.9).animate(_btnCtrl);
  }

  @override
  void dispose() {
    _textController.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;
    
    _btnCtrl.forward().then((_) => _btnCtrl.reverse());
    
    setState(() {
      _messages.add({
        'text': _textController.text.trim(),
        'isMe': true,
        'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB), // ขาวคลีนสไตล์สตรีทมินิมอล
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_sharp), // ไอคอนทรงเหลี่ยมคม
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            // รูปโปรไฟล์สี่เหลี่ยมจัตุรัสตามคอนเซปต์
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Image.network(
                widget.image,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.grey[200]),
              ),
            ),
            const SizedBox(width: 12),
            // ชื่อและอายุ ไม่มีคอมม่าคั่น
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.name.toUpperCase()} ${widget.age}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                Row( // ✅ เอา const ออกแล้ว
  children: [
    Container(
      width: 6,
      height: 6,
      color: const Color(0xFF00E676), // ใส่ const ที่สีแทน (ถ้าต้องการ)
    ),
    const SizedBox(width: 4), // ใส่ const ที่นี่แทน
    const Text('ONLINE', style: TextStyle(fontSize: 10, color: Colors.black38, fontWeight: FontWeight.bold)), // ใส่ const ที่นี่แทน
  ],
),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_sharp, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_sharp, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const Divider(color: Colors.black, thickness: 1, height: 1),
          
          // 1. พื้นที่แสดงข้อความแชท
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['isMe'] as bool;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe) ...[
                        Text(
                          msg['time'],
                          style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                      ],
                      
                      // กล่องข้อความทรงเหลี่ยมจัด (No Border Radius)
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe ? AppColors.brandPink : Colors.white,
                            borderRadius: BorderRadius.zero, // 🛑 ลบขอบมนออกทั้งหมด เป็นทรงเหลี่ยมคม
                            border: Border.all(
                              color: isMe ? Colors.transparent : Colors.black,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isMe 
                                    ? AppColors.brandPink.withValues(alpha: 0.2) 
                                    : Colors.black.withValues(alpha: 0.05),
                                blurRadius: 0,
                                offset: const Offset(4, 4), // เงา Hard Shadow สไตล์งานกราฟิกสตรีท
                              )
                            ],
                          ),
                          child: Text(
                            msg['text'],
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black,
                              fontSize: 14,
                              fontWeight: isMe ? FontWeight.w600 : Alignment.centerLeft != null ? FontWeight.w500 : FontWeight.normal,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                      
                      if (isMe) ...[
                        const SizedBox(width: 8),
                        Text(
                          msg['time'],
                          style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // 2. แถบพิมพ์ข้อความด้านล่าง (Input Bar) ดีไซน์บล็อกเหลี่ยมสตรีท
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black, width: 2)),
            ),
            child: Row(
              children: [
                // ช่องกรอกข้อความขอบเหลี่ยม
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: Colors.black12, width: 1),
                    ),
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'พิมพ์ข้อความแทงใจที่นี่...',
                        hintStyle: TextStyle(color: Colors.black38, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // ปุ่มส่ง (Send Button) ทรงสี่เหลี่ยมจัตุรัสสีดำดุดัน พร้อมอนิเมชั่นยุบตัวตอนกด
                ScaleTransition(
                  scale: _btnScale,
                  child: GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.zero, // เหลี่ยมฉาก 90 องศา
                      ),
                      child: const Icon(
                        Icons.send_sharp, // ไอคอนส่งทรงเหลี่ยมคม
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}