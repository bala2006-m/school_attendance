import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentAppbarDesktop extends StatefulWidget
    implements PreferredSizeWidget {
  const StudentAppbarDesktop({
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
  State<StudentAppbarDesktop> createState() => _StudentAppbarDesktopState();

  @override
  Size get preferredSize => const Size.fromHeight(150.0); // match your height
}

class _StudentAppbarDesktopState extends State<StudentAppbarDesktop> {
  String username = 'Student';
  ImageProvider? adminPhoto;

  final ImageProvider defaultImage = const AssetImage('assets/favicon.png');

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
        setState(() => adminPhoto = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String formatCustomDate(DateTime date) {
      final monthMap = {
        "Jan": "Jan",
        "Feb": "Feb",
        "Mar": "Mar",
        "Apr": "Apr",
        "May": "May",
        "Jun": "Jun",
        "Jul": "Jul",
        "Aug": "Aug",
        "Sep": "Sept",
        "Oct": "Oct",
        "Nov": "Nov",
        "Dec": "Dec",
      };

      final month = DateFormat('MMM').format(date);
      final day = DateFormat('d').format(date);
      final year = DateFormat('y').format(date);

      return "${monthMap[month]} $day $year";
    }

    // Usage
    final formattedDate = formatCustomDate(DateTime.now());
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
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
                  padding: const EdgeInsets.only(left: 10),
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
                            color: Colors.white.withValues(alpha: 0.7),
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
                    username.length < 10
                        ? username
                        : '${username.substring(0, 10)}...',
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
