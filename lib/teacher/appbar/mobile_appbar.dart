import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MobileAppbar extends StatefulWidget {
  const MobileAppbar({
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
  State<MobileAppbar> createState() => _MobileAppbarState();
}

class _MobileAppbarState extends State<MobileAppbar> {
  String username = 'Staff';
  ImageProvider? staffPhoto;

  final ImageProvider defaultImage = const NetworkImage(
    'https://siscomsystems.com/mpng.png',
  );

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = prefs.getString('staffName');
    final photoBase64 = prefs.getString('staffPhoto');
    setState(() {
      username =
          (storedUsername!.length < 15
              ? storedUsername
              : '${storedUsername.substring(0, 15)}...');
      if (photoBase64 != null && photoBase64.isNotEmpty) {
        try {
          Uint8List bytes = base64Decode(photoBase64);
          staffPhoto = MemoryImage(bytes);
        } catch (e) {
          debugPrint('Failed to decode base64 image: $e');
          staffPhoto = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM d, y').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  backgroundImage: staffPhoto ?? defaultImage,
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
