import 'package:flutter/material.dart';

Color getAvatarColor(String name) {
  final hash = name.hashCode;
  final colors = [
    // Colors.red,
    // Colors.blue,
    // Colors.green,
    // Colors.purple,
    Colors.teal,
  ];
  return colors[hash % colors.length].shade100;
}
