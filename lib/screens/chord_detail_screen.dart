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
  bool _isPlaying = false;

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
      setState(() => _isPlaying = true);
      await _audioPlayer.play(AssetSource("audio/$fileName.mp3"));
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _isPlaying = false);
    } catch (e) {
      debugPrint("Error playing audio: $e");
      setState(() => _isPlaying = false);
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
          style: const TextStyle(
            color: Colors.purpleAccent,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.purpleAccent),
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
            child: Container(color: Colors.black.withOpacity(0.4)),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _isPlaying
                              ? Colors.purpleAccent
                              : Colors.white24,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (_isPlaying)
                            BoxShadow(
                              color: Colors.purpleAccent.withOpacity(0.6),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Image.network(
                        widget.imageUrl,
                        height: 250,
                        fit: BoxFit.contain,
                        loadingBuilder: (_, child, loading) =>
                            loading == null
                                ? child
                                : const CircularProgressIndicator(
                                    color: Colors.purpleAccent,
                                  ),
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.broken_image,
                          color: Colors.white38,
                          size: 100,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: _isPlaying ? 1 : 0.8,
                      child: Text(
                        _isPlaying
                            ? "Playing ${widget.name}..."
                            : "Shake your phone to play the chord!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isPlaying
                              ? Colors.purpleAccent
                              : Colors.white70,
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          shadows: [
                            if (_isPlaying)
                              const Shadow(
                                color: Colors.purpleAccent,
                                blurRadius: 12,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Cyruz • Guitar Chord Companion",
                      style: TextStyle(
                        color: Colors.white24,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
