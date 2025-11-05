import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'utils/session_manager.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService.init();
    await NotificationService.requestPermissionIfNeeded();
  } catch (e) {
    debugPrint('Gagal inisialisasi notifikasi: $e');
  }

  final session = SessionManager();
  String? username;
  try {
    username = await session.getUser();
  } catch (e) {
    debugPrint('Gagal memuat sesi pengguna: $e');
  }

  runApp(MyApp(initialUsername: username));
}

class MyApp extends StatelessWidget {
  final String? initialUsername;
  const MyApp({super.key, this.initialUsername});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cyruz',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purpleAccent,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),

      home: SplashScreen(initialUsername: initialUsername),
    );
  }
}
