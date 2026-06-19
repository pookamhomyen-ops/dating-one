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
  postgrestOptions: const PostgrestClientOptions(
    schema: 'public',
  ),
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

// วิดเจ็ตจัดการพื้นหลังหลักของแอป
class _AuroraFluidBackground extends StatelessWidget {
  final Widget child;

  const _AuroraFluidBackground({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: child,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isNavigating = false;
  bool _showTimeoutAction = false;

  @override
  void initState() {
    super.initState();
    debugPrint('AuthWrapper: initState');
    _startTimeoutTimer();
  }

  void _startTimeoutTimer() {
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && !_isNavigating) {
        setState(() => _showTimeoutAction = true);
      }
    });
  }

  Future<void> _handleNavigation(AuthState data) async {
    if (!mounted || _isNavigating) return;

    final session = data.session;
    final event = data.event;
    
    debugPrint('AuthWrapper: Handling Auth Event: $event, Session: ${session != null}');

    // กรณีที่ไม่ได้ล็อกอิน หรือ ล็อกเอาท์
    if (session == null) {
      _navigateToLogin();
      return;
    }

    // กรณีที่มีเซสชั่น (SignedIn, TokenRefreshed, InitialSession)
    if (event == AuthChangeEvent.signedIn || 
        event == AuthChangeEvent.tokenRefreshed || 
        event == AuthChangeEvent.initialSession) {
      await _navigateToCorrectScreen(session.user.id);
    }
  }

  Future<void> _navigateToCorrectScreen(String userId) async {
    if (_isNavigating) return;
    _isNavigating = true;
    
    debugPrint('AuthWrapper: Fetching profile for $userId');
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      debugPrint('AuthWrapper: Profile fetch result: ${profile != null ? 'Found' : 'Not Found'}');

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
      debugPrint('AuthWrapper: Error in _navigateToCorrectScreen: $e');
      _isNavigating = false;
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (_isNavigating) return;
    if (!mounted) return;
    _isNavigating = true;
    
    debugPrint('AuthWrapper: Navigating to LoginScreen');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // ใช้ Future.microtask เพื่อหลีกเลี่ยงการนำทางระหว่าง Build
          Future.microtask(() => _handleNavigation(snapshot.data!));
        }

        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                if (_showTimeoutAction) ...[
                  const SizedBox(height: 24),
                  const Text('ดูเหมือนจะใช้เวลานานผิดปกติ'),
                  TextButton(
                    onPressed: () {
                      _isNavigating = false;
                      _navigateToLogin();
                    },
                    child: const Text('ไปหน้าล็อกอิน'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
