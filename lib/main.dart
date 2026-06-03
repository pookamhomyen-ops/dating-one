import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_shell.dart';
import 'screens/profile/profile_setup_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th');
  
  await Supabase.initialize(
    url: SupabaseConstants.url,
    anonKey: SupabaseConstants.anonKey,
  );
  
  runApp(const DatingOneApp());
}

class DatingOneApp extends StatelessWidget {
  const DatingOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soulive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthWrapper(),
      // ห่อหุ้มแอปทั้งหมดด้วยดีไซน์ ท้องฟ้าออโรร่าพาสเทล Fluid
      builder: (context, child) {
        return _AuroraFluidBackground(child: child ?? const SizedBox());
      },
    );
  }
}

// วิดเจ็ตสร้างพื้นหลังท้องฟ้าออโรร่าพาสเทล พร้อมลวดลายโค้งมน Fluid พริ้วไหวท้ายจอ
class _AuroraFluidBackground extends StatelessWidget {
  final Widget child;
  const _AuroraFluidBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      resizeToAvoidBottomInset: false, // ป้องกันพื้นหลังบีบเบี้ยวเวลาคีย์บอร์ดเด้ง
      body: Stack(
        children: [
          // เลเยอร์ 1: ไล่เฉดสีท้องฟ้าออโรร่าพาสเทลหลัก (Linear Gradient) จากบนลงล่าง
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.auroraStart,
                  AppColors.auroraMid,
                  AppColors.auroraEnd,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // เลเยอร์ 2: แสงออโรร่าเรืองแสงฟุ้งจางๆ (Radial Glow) สีชมพูที่มุมขวาบนเพิ่มลูกเล่นท้องฟ้า
          Positioned(
            top: -size.height * 0.12,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 1.0,
              height: size.width * 1.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.auroraGlow.withOpacity(0.45),
                    AppColors.auroraGlow.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          // เลเยอร์ 3: ลวดลายส่วนโค้งมน Fluid ชิ้นหลัก (Organic Wave) พริ้วไหวสวยงามที่ฝั่งซ้ายล่าง
          Positioned(
            bottom: size.height * 0.1,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.85,
              height: size.height * 0.24,
              decoration: BoxDecoration(
                color: AppColors.fluidShape.withOpacity(0.35),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.elliptical(320, 200),
                  bottomRight: Radius.elliptical(220, 120),
                  topLeft: Radius.circular(160),
                  bottomLeft: Radius.circular(160),
                ),
              ),
            ),
          ),
          
          // เลเยอร์ 4: ลวดลาย Fluid ชิ้นเล็ก ซ้อนทับเลเยอร์ท้ายจอเพิ่มมิติเลเยอร์ตื้นลึกแบบมินิมอลไม่รกตา
          Positioned(
            bottom: size.height * 0.02,
            left: size.width * 0.05,
            child: Container(
              width: size.width * 0.72,
              height: size.height * 0.16,
              decoration: BoxDecoration(
                color: AppColors.auroraMid.withOpacity(0.4),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.elliptical(200, 130),
                  topRight: Radius.elliptical(240, 160),
                  bottomLeft: Radius.circular(100),
                  bottomRight: Radius.circular(100),
                ),
              ),
            ),
          ),
          
          // ตัวเนื้อหาของแอปจะอยู่ชั้นบนสุด
          child,
        ],
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _handleInitialSession();
    _listenToAuthChanges();
  }

  void _handleInitialSession() {
    Future.microtask(() async {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        _navigateToLogin();
      } else {
        await _navigateToCorrectScreen(session.user.id);
      }
    });
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.signedOut || session == null) {
        _navigateToLogin();
      } else if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
        await _navigateToCorrectScreen(session.user.id);
      }
    });
  }

  Future<void> _navigateToCorrectScreen(String userId) async {
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (profile == null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    } catch (e) {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}