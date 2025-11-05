import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.blueAccent;
  static const Color background = Color(0xFFF8F9FA);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 190, 44, 206),
      Colors.indigo,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
