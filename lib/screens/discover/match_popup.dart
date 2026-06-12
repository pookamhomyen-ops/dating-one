import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

class MatchPopup extends StatelessWidget {
  final String myPhotoUrl;
  final String matchPhotoUrl;
  final String matchName;

  const MatchPopup({
    super.key,
    required this.myPhotoUrl,
    required this.matchPhotoUrl,
    required this.matchName,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E), // ธีมมืดเข้ากับหน้าหลัก
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.brandPink.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPink.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // เอฟเฟกต์ไอคอนรูปหัวใจดึงดูดสายตา
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF2A1A2E),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.brandPink,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'It\'s a Match!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              
              Text(
                'คุณและ $matchName ถูกใจซึ่งกันและกัน',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 24),

              // แสดงรูปภาพโปรไฟล์แมตช์ (เนื่องจาก myPhotoUrl ส่งมาเป็นค่าว่าง จึงเน้นแสดงรูปคู่กรณีใหญ่ขึ้น)
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brandPink, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(65),
                    child: matchPhotoUrl.isNotEmpty
                        ? Image.network(matchPhotoUrl, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFF2A2A3A),
                            child: const Icon(Icons.person, size: 60, color: Colors.white30),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ปุ่มแอคชั่น
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Popup เพื่อไปแชทหรือปัดต่อ
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'ส่งข้อความเลย',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white38,
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: const Text(
                  'ไว้ทีหลัง',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}