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

  final List<String> _allAudioFiles = [
    "A_major.mp3",
    "A_minor.mp3",
    "B_major.mp3",
    "B_minor.mp3",
    "C#_major.mp3",
    "C_major.mp3",
    "C_minor.mp3",
    "D_major.mp3",
    "D_minor.mp3",
    "E_major.mp3",
    "E_minor.mp3",
    "F_major.mp3",
    "F_minor.mp3",
    "G_major.mp3",
    "G_minor.mp3",
    "C#_minor.mp3",
    "D#_major.mp3",
    "F#_major.mp3",
    "G#_major.mp3",
    "G#_minor.mp3",
  ];

  @override
  void initState() {
    super.initState();
    _listenToShake();
  }

  String _getFileName(String chordName) {
    List<String> parts = chordName.split(" ");
    if (parts.length != 2) return chordName.replaceAll(" ", "_") + ".mp3";
    String first = parts[0];
    String second = parts[1].toLowerCase();
    return "$first\_$second.mp3";
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
    String fileName = _getFileName(widget.name);

    if (!_allAudioFiles.contains(fileName)) {
      debugPrint("Audio file not found: $fileName");
      return;
    }

    try {
      setState(() => _isPlaying = true);
      await _audioPlayer.play(AssetSource("audio/$fileName"));
      await Future.delayed(const Duration(seconds: 5));
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
      backgroundColor: Colors.white,

      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF003B73),
                Color(0xFF002D62)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Place your fingers on the guitar as shown below!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF003B73),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 18),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? const Color(0xFF0D47A1)
                        : Colors.white,
                    border: Border.all(
                      color: _isPlaying
                          ? Colors.white
                          : const Color(0xFF003B73),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                      if (_isPlaying)
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withOpacity(0.55),
                          blurRadius: 32,
                          spreadRadius: 6,
                        ),
                    ],
                  ),

                  padding: const EdgeInsets.all(18),

                  child: Image.network(
                    widget.imageUrl,
                    height: 260,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, loading) =>
                        loading == null
                            ? child
                            : const CircularProgressIndicator(),
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 100,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                AnimatedOpacity(
                  duration: const Duration(milliseconds: 600),
                  opacity: _isPlaying ? 1 : 0.85,
                  child: Text(
                    _isPlaying
                        ? "Playing ${widget.name}..."
                        : "Shake your phone or press the button to play the chord!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _isPlaying
                          ? const Color(0xFF0D47A1)
                          : const Color(0xFF003B73),
                      fontSize: 17,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: _isPlaying
                        ? const Color(0xFF0D47A1)
                        : const Color(0xFF003B73),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      if (_isPlaying)
                        BoxShadow(
                          color: const Color(0xFF0D47A1).withOpacity(0.45),
                          blurRadius: 24,
                          spreadRadius: 3,
                        ),
                    ],
                  ),

                  child: ElevatedButton(
                    onPressed: _isPlaying ? null : _playChordSound,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 34,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPlaying
                              ? Icons.music_note
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isPlaying ? "Playing..." : "Play Chord",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
