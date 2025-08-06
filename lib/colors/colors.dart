import 'package:flutter/material.dart';

class AppColors {
  static LinearGradient appbarColor = LinearGradient(
    colors: [Colors.cyanAccent.shade700, Colors.cyanAccent.shade700],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient buttonColor = LinearGradient(
    colors: [Colors.blue.shade50, Colors.blue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
