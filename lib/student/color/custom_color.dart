import 'package:flutter/material.dart';

LinearGradient appbarColor = LinearGradient(
  colors: [Colors.indigo, Colors.blueAccent],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
Decoration appbarDecoration = BoxDecoration(
  gradient: appbarColor,
  borderRadius: const BorderRadius.only(
    bottomLeft: Radius.circular(30),
    bottomRight: Radius.circular(30),
  ),
);
Color bgLight = Colors.white;
Color bgDark = Colors.black12;
Color textDark = Colors.white;
Color textLight = Colors.black;
Color textMedium = Colors.grey;
