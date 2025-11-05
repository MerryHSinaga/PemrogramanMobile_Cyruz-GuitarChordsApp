import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

typedef ShakeCallback = void Function();

class ChordSensor {
  final double threshold;
  final int minDelay;
  final ShakeCallback onShake;
  StreamSubscription? _subscription;
  DateTime _lastShake = DateTime.now();

  ChordSensor({
    required this.onShake,
    this.threshold = 15.0,
    this.minDelay = 1500,
  });

  void start() {
    _subscription = accelerometerEvents.listen((AccelerometerEvent event) {
      double acceleration =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      if (acceleration > threshold) {
        final now = DateTime.now();
        if (now.difference(_lastShake).inMilliseconds > minDelay) {
          _lastShake = now;
          onShake();
        }
      }
    });
  }

  void stop() {
    _subscription?.cancel();
  }
}
