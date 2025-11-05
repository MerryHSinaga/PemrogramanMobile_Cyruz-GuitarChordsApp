import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'chords_screen.dart';
import 'convert_screen.dart';
import 'schedule_screen.dart';
import 'profile_screen.dart';


class HomeScreen extends StatefulWidget {
  final String username;
  const HomeScreen({super.key, required this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    NotificationService.init();
    NotificationService.requestPermissionIfNeeded();

    //Notifikasi
    Future.delayed(const Duration(seconds: 1), () {
      NotificationService.showInstant(
        id: 111,
        title: "Cyruz",
        body: "Sudah siap bermain gitar bersama Cyruz hari ini?",
      );
    });

    _screens = [
      const ChordsScreen(),
      const ConvertScreen(),
      ScheduleScreen(userId: widget.username),
      ProfileScreen(username: widget.username),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Cyruz',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 8,
        shadowColor: Colors.purpleAccent,
        backgroundColor: Colors.black.withOpacity(0),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.purpleAccent.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
          child: BottomNavigationBar(
            backgroundColor: Colors.transparent,
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            selectedItemColor: Colors.purpleAccent,
            unselectedItemColor: Colors.white54,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Chords',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.money),
                label: 'Price Check',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule),
                label: 'Schedule',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
