import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:audioplayers/audioplayers.dart';

class ChordDetailScreen extends StatefulWidget {
  final String name;
  final String imageUrl;

  const ChordDetailScreen({
    super.key,
    required this.name,
    required this.imageUrl,
  });

  @override
  State<ChordDetailScreen> createState() => _ChordDetailScreenState();
}

class _ChordDetailScreenState extends State<ChordDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  DateTime _lastShakeTime = DateTime.now();
  final double _shakeThreshold = 1.2;

  @override
  void initState() {
    super.initState();
    _listenToShake();
  }

  void _listenToShake() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      double gX = event.x / 9.81;
      double gY = event.y / 9.81;
      double gZ = event.z / 9.81;

      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      if (gForce > _shakeThreshold) {
        final now = DateTime.now();
        if (now.difference(_lastShakeTime).inMilliseconds > 800) {
          _lastShakeTime = now;
          _playChordSound();
        }
      }
    });
  }

  Future<void> _playChordSound() async {
    String chord = widget.name.toLowerCase().replaceAll(" ", "_");
    List<String> accepted = [
      "a_major", "a_minor",
      "b_major", "b_minor",
      "c_major", "c_minor"
    ];

    String fileName = accepted.contains(chord) ? chord : "all";

    try {
      await _audioPlayer.play(AssetSource("audio/$fileName.mp3"));
    } catch (e) {
      debugPrint("Error playing audio: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.name,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/background.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, loading) =>
                      loading == null ? child : const CircularProgressIndicator(color: Colors.purpleAccent),
                  errorBuilder: (_, __, ___) =>
                      const Text("Image Error", style: TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Shake your phone to hear the chord!",
                  style: TextStyle(color: Colors.purpleAccent, fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
