import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'favorites_screen.dart';
import 'map_music_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryColor = Color(0xFF1A2B5B);

  bool showKesan = false;
  bool showPesan = false;

  final String kesanText =
      "Mata kuliah ini sangat membantu saya dalam menambah portofolio dan keterampilan mobile development saya. "
      "Meskipun baru pertama kali menyentuh pemrograman aplikasi mobile, menurut saya mata kuliah ini cukup "
      "menantang dan menarik (menarik jam tidur saya maksudnya).";

  final String pesanText =
      "Semoga kedepannya aplikasi ini bisa lebih dikembangkan karena masih terbilang cukup sederhana. "
      "Semangat buat adik-adik tingkat yang akan menghadapi mata kuliah pemrograman aplikasi mobile dan semua "
      "gebrakan tak terduga yang terjadi. Mungkin lain kali bisa menyicil project akhir agar bisa tidur nyenyak 24 jam hehe.";

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Gradient? gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient ??
              const LinearGradient(
                colors: [Color(0xFF324D7A), Color(0xFF182447)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.16),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _expandableCard({
    required IconData icon,
    required String title,
    required String text,
    required bool expanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF324D7A), Color(0xFF182447)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.16),
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Text(
                text,
                textAlign: TextAlign.justify,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  height: 1.5,
                ),
              ),
            ),
            crossFadeState: expanded
                .toCrossFadeState(),
            duration: const Duration(milliseconds: 250),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 6),
              Text(
                "Cyruz is glad to have you here, let’s keep your profile in tune.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.95),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.35),
                        blurRadius: 26,
                        spreadRadius: 3,
                      )
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 64,
                    backgroundImage: AssetImage('assets/cyruz.png'),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                widget.username,
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 22),

              _menuCard(
                icon: Icons.star_rounded,
                title: "Favorite",
                subtitle: "Daftar gitar favorit Anda",
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FavoriteScreen())),
              ),
              _menuCard(
                icon: Icons.location_on_rounded,
                title: "Toko Musik Terdekat",
                subtitle: "Cari toko musik di sekitar Anda",
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MapMusicScreen())),
              ),

              _expandableCard(
                icon: Icons.message_rounded,
                title: "Kesan",
                text: kesanText,
                expanded: showKesan,
                onToggle: () {
                  setState(() => showKesan = !showKesan);
                },
              ),
              _expandableCard(
                icon: Icons.mark_chat_read_rounded,
                title: "Pesan",
                text: pesanText,
                expanded: showPesan,
                onToggle: () {
                  setState(() => showPesan = !showPesan);
                },
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1A2B5B),
                      Color.fromARGB(255, 39, 77, 149),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF1A2B5B).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Log Out",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}

extension _ on bool {
  CrossFadeState toCrossFadeState() =>
      this ? CrossFadeState.showSecond : CrossFadeState.showFirst;
}
