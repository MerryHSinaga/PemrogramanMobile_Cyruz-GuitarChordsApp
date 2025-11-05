import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../utils/session_manager.dart';

class SplashScreen extends StatefulWidget {
  final String? initialUsername;

  const SplashScreen({super.key, this.initialUsername});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  final SessionManager _session = SessionManager();

  @override
  void initState() {
    super.initState();

  
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnim = Tween<double>(begin: 0.95, end: 1.02).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();
    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), _checkAndNavigate);
      }
    });
  }

  Future<void> _checkAndNavigate() async {
    try {
      String? username = widget.initialUsername;

      if (username == null) {
        username = await _session.getUser();
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, animation, secondaryAnimation) {
            return username != null
                ? HomeScreen(username: username)
                : const LoginScreen();
          },
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            final fade =
                Tween<double>(begin: 0.0, end: 1.0).animate(animation);
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: SizedBox.expand(
            child: Image.asset(
              'assets/cyruz.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
