import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import 'chords_screen.dart';
import 'convert_screen.dart';
import 'schedule_screen.dart';
import 'profile_screen.dart' as profile;

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

    Future.delayed(const Duration(seconds: 1), () {
      NotificationService.showInstant(
        id: 111,
        title: "Cyruz",
        body: "Sudah siap bermain gitar bersama Cyruz hari ini?",
      );
    });

    _screens = [
      const ChordsScreen(),
      ConvertScreen(),
      ScheduleScreen(userId: widget.username),
      profile.ProfileScreen(username: widget.username), 
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Cyruz',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 15, 100, 185),
              Color(0xFF1A2B5B),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: _screens[_currentIndex],

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color.fromARGB(255, 15, 100, 185),
              Color(0xFF1A2B5B),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 32, 67, 127).withOpacity(0.35),
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
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Chords',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.note_add_outlined),
                label: 'Guitars',
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
