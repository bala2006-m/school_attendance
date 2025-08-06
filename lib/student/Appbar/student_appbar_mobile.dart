import 'package:flutter/material.dart';

import '../color/custom_color.dart';

class StudentAppbarMobile extends StatelessWidget
    implements PreferredSizeWidget {
  const StudentAppbarMobile({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(100.0); // match your height

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: appbarDecoration,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
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
