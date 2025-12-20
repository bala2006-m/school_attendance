import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/pages/dashboard/admin_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../pages/notification/notifications.dart';
import '../services/admin_api_service.dart';

class AdminAppbarMobile extends StatefulWidget {
  const AdminAppbarMobile({
    super.key,
    required this.title,
    required this.enableDrawer,
    required this.enableBack,
    required this.onBack,
    required this.schoolId,
    required this.username,
  });

  final String title;
  final bool enableDrawer;
  final bool enableBack;
  final VoidCallback onBack;
  final String schoolId;
  final String username;

  @override
  State<AdminAppbarMobile> createState() => _AdminAppbarMobileState();
}

class _AdminAppbarMobileState extends State<AdminAppbarMobile> {
  List<Map<String, dynamic>> schoolDatas = [];
  String username = 'Admin';
  Uint8List? photoBytes;
  final ImageProvider defaultImage = const NetworkImage(
    'https://th.bing.com/th?q=Admin+Icon.png&w=120&h=120&c=1&rs=1&qlt=70&r=0&o=7&cb=1&pid=InlineBlock&rm=3&mkt=en-IN&cc=IN&setlang=en&adlt=moderate&t=1&mw=247',
  );

  int unseenCount = 0;
  bool hasUpcomingDue = false; // 👈 new flag for due notification indicator

  @override
  void initState() {
    super.initState();
    fetchData();
    _loadUnseenCount();
    if (widget.title == "Admin Dashboard") {
      fetchSchoolInfo();
    }
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      bool upcomingFound = false;

      for (var school in schoolData) {
        if (school['dueDate'] != null) {
          // Parse and normalize both times to local date only (ignore time zone offset)
          final dueDate = DateTime.parse(school['dueDate']).toLocal();
          final today = DateTime.now();

          // Remove time part to compare only by date
          final dueDateOnly = DateTime(
            dueDate.year,
            dueDate.month,
            dueDate.day,
          );
          final todayOnly = DateTime(today.year, today.month, today.day);

          final diffDays = dueDateOnly.difference(todayOnly).inDays;
          // ✅ Mark as upcoming if overdue or more than 5 days away
          if (diffDays < 6) {
            upcomingFound = true;
            break;
          }
        }
      }

      setState(() {
        schoolDatas = schoolData;
        hasUpcomingDue = upcomingFound;
      });
    } catch (e) {
      debugPrint("Error fetching school info: $e");
    }
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
        feed.isNotEmpty
            ? feed.where((item) => !seenFeedbackIds.contains(item['id'])).length
            : 0;

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

    final formattedDate = formatCustomDate(DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2B7CA8),
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
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                  ),
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  overflow: TextOverflow.ellipsis,
                  widget.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),

              // ✅ Notification or Home icon with dot indicator
              Padding(
                padding: const EdgeInsets.only(top: 20, right: 6),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: () {
                        if (widget.title != 'Admin Dashboard') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AdminDashboard(
                                    schoolId: widget.schoolId,
                                    username: widget.username,
                                  ),
                            ),
                          );
                        } else {
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
                        }
                      },
                      icon: Icon(
                        widget.title != 'Admin Dashboard'
                            ? Icons.home
                            : Icons.notifications,
                        color: Colors.white,
                      ),
                    ),

                    // 🔴 Dot indicator (shows if upcoming due or unseen notifications)
                    if (widget.title == 'Admin Dashboard' &&
                        (hasUpcomingDue || unseenCount > 0))
                      Positioned(
                        right: 10,
                        top: 12,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
                  backgroundImage:
                      photoBytes != null
                          ? MemoryImage(photoBytes!)
                          : defaultImage,
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
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
