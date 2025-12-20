import 'package:flutter/material.dart';

Widget buildInfoTile(String label, String value) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        "$label: ",
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.teal,
        ),
      ),
    ],
  );
}

Widget buildHeaderSection({
  required String className,
  required String section,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withAlpha(40),
          blurRadius: 5,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildInfoTile("Class", className),
        buildInfoTile("Section", section),
      ],
    ),
  );
}
