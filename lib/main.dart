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

  const _AuroraFluidBackground({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg.png',
              fit: BoxFit.cover,
            ),
          ),

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