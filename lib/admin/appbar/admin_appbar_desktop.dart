import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/notification/notifications.dart';
import '../services/admin_api_service.dart';

class AdminAppbarDesktop extends StatefulWidget {
  const AdminAppbarDesktop({
    super.key,
    required this.title,
    required this.onBack,
    required this.schoolId,
    required this.username,
  });
  final String title;
  final VoidCallback onBack;
  final String schoolId;
  final String username;

  @override
  State<AdminAppbarDesktop> createState() => _AdminAppbarDesktopState();
}

class _AdminAppbarDesktopState extends State<AdminAppbarDesktop> {
  String username = 'Admin';
  // ImageProvider? adminPhoto;
  Uint8List? photoBytes;
  final ImageProvider defaultImage = const NetworkImage(
    'https://th.bing.com/th?q=Admin+Icon.png&w=120&h=120&c=1&rs=1&qlt=70&r=0&o=7&cb=1&pid=InlineBlock&rm=3&mkt=en-IN&cc=IN&setlang=en&adlt=moderate&t=1&mw=247',
  );
  int unseenCount = 0;
  @override
  void initState() {
    super.initState();
    fetchData();
    _loadUnseenCount();
  }

  Future<void> _loadUnseenCount() async {
    final prefs = await SharedPreferences.getInstance();

    final seenLeaveIds =
        (prefs.getStringList("seenLeaveIds") ?? []).map(int.parse).toSet();
    final seenFeedbackIds =
        (prefs.getStringList("seenFeedbackIds") ?? []).map(int.parse).toSet();

    // Fetch latest data
    final leave = await AdminApiService.fetchLeaveRequest(widget.schoolId);
    final feed = await AdminApiService.fetchFeedback(widget.schoolId);

    // Filter unseen
    final unseenLeave =
        leave.where((item) => !seenLeaveIds.contains(item['id'])).length;
    final unseenFeedback =
        feed.where((item) => !seenFeedbackIds.contains(item['id'])).length;

    setState(() {
      unseenCount = unseenLeave + unseenFeedback;
    });
  }

  Future<void> fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUsername = prefs.getString('adminName');
    final base64Photo = prefs.getString('adminPhoto');

    if (base64Photo != null && base64Photo.isNotEmpty) {
      try {
        photoBytes = base64Decode(base64Photo);
        photoBytes!.length < 5 ? photoBytes = null : null;
      } catch (e) {
        photoBytes = null;
      }
    }

    setState(() {
      username =
          (storedUsername!.length < 15
              ? storedUsername
              : '${storedUsername.substring(0, 15)}...');
      // if (photoBase64 != null && photoBase64.isNotEmpty) {
      //   try {
      //     Uint8List bytes = base64Decode(photoBase64);
      //     adminPhoto = MemoryImage(bytes);
      //   } catch (e) {
      //
      //     adminPhoto = null;
      //   }
      // }
    });
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
        "Sep": "Sept", // 👈 force "Sept"
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
      constraints: BoxConstraints(minWidth: 600),
      alignment: Alignment.center,
      //padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: widget.onBack,
                icon: Icon(
                  Icons.arrow_back,
                  size: 40,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Spacer(),
              Text(
                textAlign: TextAlign.center,
                widget.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => Notifications(
                            schoolId: widget.schoolId,
                            username: widget.username,
                          ),
                    ),
                  );
                  _loadUnseenCount();
                },
                icon: Badge(
                  isLabelVisible: unseenCount > 0,
                  label: Text(unseenCount.toString()),
                  child: const Icon(Icons.notifications, color: Colors.white),
                ),
              ),
              SizedBox(width: 20),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 30,
                  backgroundImage:
                      photoBytes.toString() != 'null'
                          // photoBytes != [] ||
                          // photoBytes != null
                          ? MemoryImage(photoBytes!)
                          : NetworkImage(
                            'https://tse1.explicit.bing.net/th/id/OIP.KW8WUwEuVpHgCw5jZ2rTJgHaHa?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
                          ),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 20),
            ],
          ),
        ],
      ),
    );
  }
}
