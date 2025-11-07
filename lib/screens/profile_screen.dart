import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String username;
  const ProfileScreen({super.key, required this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String kesanPesan = "Mata kuliah ini membantu saya menambah portofolio saya.";
  bool isEditing = false;
  final TextEditingController controller = TextEditingController();

  static const Color primaryColor = Colors.purpleAccent;

  @override
  void initState() {
    super.initState();
    _loadSavedMessage();
  }

  Future<void> _loadSavedMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'kesanPesan_${widget.username}';
    final saved = prefs.getString(key);
    setState(() {
      kesanPesan = saved ?? kesanPesan;
      controller.text = kesanPesan;
    });
  }

  Future<void> _saveMessage() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'kesanPesan_${widget.username}';
    await prefs.setString(key, controller.text);
    setState(() {
      kesanPesan = controller.text;
      isEditing = false;
    });

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: primaryColor, size: 40),
                  const SizedBox(height: 15),
                  const Text(
                    "Berhasil Disimpan!",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Kesan dan pesan kamu telah diperbarui.",
                    style: TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "OK",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ Hitam polos
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "Cyruz is glad to have you here, let’s keep your profile in tune.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.purpleAccent,
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            _buildProfileHeader(),
            const SizedBox(height: 40),
            _buildMessageCard(),
            const SizedBox(height: 40),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withOpacity(0.6), width: 3),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: const CircleAvatar(
            radius: 65,
            backgroundImage: AssetImage('assets/cyruz.png'),
            backgroundColor: Colors.black54,
          ),
        ),
        const SizedBox(height: 20),
        // ✅ Hanya teks username tanpa kotak
        Text(
          widget.username,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMessageCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.grey[900], // ✅ Warna abu gelap seperti input field
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "Kesan dan Pesan",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                _buildEditButton(),
              ],
            ),
            const Divider(color: Colors.white38, height: 30),
            if (isEditing) _buildEditingSection() else _buildMessageText(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageText() => Text(
        kesanPesan,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          height: 1.5,
        ),
      );

  Widget _buildEditButton() {
    return IconButton(
      icon: Icon(
        isEditing ? Icons.close_rounded : Icons.edit_note_rounded,
        color: isEditing ? Colors.redAccent : primaryColor,
        size: 30,
      ),
      onPressed: () {
        setState(() {
          isEditing = !isEditing;
          if (!isEditing) controller.text = kesanPesan;
        });
      },
      splashRadius: 28,
    );
  }

  Widget _buildEditingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[850], // ✅ abu gelap seperti halaman lain
            hintText: "Tulis kesan dan pesan!",
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _saveMessage,
          icon: const Icon(Icons.send_rounded, color: Colors.white),
          label: const Text("Simpan"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return ElevatedButton.icon(
      onPressed: _logout,
      icon: const Icon(Icons.logout, color: Colors.white),
      label: const Text(
        "Log Out",
        style: TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
