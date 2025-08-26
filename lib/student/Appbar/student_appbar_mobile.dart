import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentAppbarMobile extends StatefulWidget {
  const StudentAppbarMobile({
    super.key,
    required this.title,
    required this.enableDrawer,
    required this.enableBack,
    required this.onBack,
  });

  final String title;
  final bool enableDrawer;
  final bool enableBack;
  final VoidCallback onBack;

  @override
  State<StudentAppbarMobile> createState() => _StudentAppbarMobileState();
}

class _StudentAppbarMobileState extends State<StudentAppbarMobile> {
  String username = 'Student';
  ImageProvider? adminPhoto;

  final ImageProvider defaultImage = const NetworkImage(
    'https://img.favpng.com/9/16/11/student-cartoon-avatar-png-favpng-T0KuPNVPyfp00uNTwQVK2yk7D.jpg',
  );

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = prefs.getString('studentName');
    final photoJson = prefs.getString('studentPhoto');
    setState(() {
      username =
          (storedUsername != null && storedUsername.length < 15)
              ? storedUsername
              : '${storedUsername?.substring(0, 15) ?? 'Student'}...';
    });

    if (photoJson != null &&
        photoJson.isNotEmpty &&
        photoJson.toString() != '[]') {
      try {
        List<dynamic> byteListDynamic = json.decode(photoJson);

        List<int> byteList = byteListDynamic.cast<int>();

        Uint8List imageBytes = Uint8List.fromList(byteList);

        setState(() {
          adminPhoto = MemoryImage(imageBytes);
        });
      } catch (e) {
        debugPrint('Failed to decode stored image: $e');
        setState(() => adminPhoto = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM d, y').format(DateTime.now());
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Color(0xFF2B7CA8),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (widget.enableDrawer || widget.enableBack)
                Padding(
                  padding: const EdgeInsets.only(top: 30, left: 10),
                  child: Builder(
                    builder:
                        (context) => InkWell(
                          onTap: () async {
                            if (widget.enableDrawer) {
                              Scaffold.of(context).openDrawer();
                            } else if (widget.enableBack) {
                              widget.onBack();
                            }
                          },
                          child: Icon(
                            size: 40,
                            widget.enableDrawer ? Icons.menu : Icons.arrow_back,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 30,
                  backgroundImage: adminPhoto ?? defaultImage,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  formattedDate,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
