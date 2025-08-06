import 'package:flutter/material.dart';

import '../../teacher/color/teacher_custom_color.dart' as AdminCustomColor;

class AdminAppbarDesktop extends StatelessWidget {
  const AdminAppbarDesktop({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    final String currentDate =
        "${DateTime.now().day.toString().padLeft(2, '0')}/"
        "${DateTime.now().month.toString().padLeft(2, '0')}/"
        "${DateTime.now().year}";

    return AppBar(
      leading: IconButton(
        onPressed: () {
          Navigator.pop(context);
        },
        icon: Icon(Icons.arrow_back),
      ),
      title: Padding(
        padding: const EdgeInsets.only(top: 25.0),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
      centerTitle: false, // Set to false to allow manual centering
      elevation: 4,
      shadowColor: Colors.black26,
      backgroundColor: AdminCustomColor.appbar,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            // Wrap Text with Center widget
            child: Text(
              currentDate,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.blueAccent,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
