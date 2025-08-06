import 'package:flutter/material.dart';

Color bgLight = Colors.white;
Color bgDark = Colors.grey;
Color? bdMid = Colors.grey[100];
Color buttonLight = Colors.white60;
Color buttonDark = Colors.black;
Color textLight = Colors.white;
Color textDark = Colors.black;
Color appbar = Colors.blue;
Color appbarText = Colors.white;
Color appbarDark = Colors.blue.shade500;
Decoration appbarDecoration = BoxDecoration(
  color: appbar,
  borderRadius: const BorderRadius.only(
    bottomLeft: Radius.circular(30),
    bottomRight: Radius.circular(30),
  ),
);

LinearGradient containerGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Colors.blue, Colors.blue.shade900],
);
