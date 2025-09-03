import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/pages/notification/staff_notification.dart';
import 'package:school_attendance/admin/pages/notification/student_notification.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../dashboard/admin_dashboard.dart';

class Notifications extends StatefulWidget {
  const Notifications({
    super.key,
    required this.schoolId,
    required this.username,
  });
  final String schoolId;
  final String username;

  @override
  State<Notifications> createState() => NotificationsState();
}

class NotificationsState extends State<Notifications> {
  // 🔴 Shared across all Notifications widgets
  static List<dynamic> leaveRequests = [];
  static List<dynamic> feedbacks = [];
  static Set<int> seenFeedbackIds = {};
  static Set<int> seenLeaveIds = {};
  static bool isLoading = true;
  static int selectedIndex = 1;

  // 🔴 Keep reference to current state (to call setState in static methods)
  static NotificationsState? _instance;

  @override
  void initState() {
    super.initState();
    _instance = this;
    init();
  }

  @override
  void dispose() {
    if (_instance == this) _instance = null;
    super.dispose();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load seen IDs
    seenFeedbackIds =
        (prefs.getStringList("seenFeedbackIds") ?? []).map(int.parse).toSet();
    seenLeaveIds =
        (prefs.getStringList("seenLeaveIds") ?? []).map(int.parse).toSet();

    final leave = await AdminApiService.fetchLeaveRequest(widget.schoolId);
    final feed = await AdminApiService.fetchFeedback(widget.schoolId);

    _instance?.setState(() {
      leaveRequests =
          leave.where((item) => !seenLeaveIds.contains(item['id'])).toList();
      feedbacks =
          feed.where((item) => !seenFeedbackIds.contains(item['id'])).toList();
      isLoading = false;
    });
  }

  static Future<void> markFeedbackSeen(int id) async {
    final prefs = await SharedPreferences.getInstance();
    seenFeedbackIds.add(id);
    await prefs.setStringList(
      "seenFeedbackIds",
      seenFeedbackIds.map((e) => e.toString()).toList(),
    );

    _instance?.setState(() {
      feedbacks.removeWhere((item) => item['id'] == id);
    });
  }

  static Future<void> markLeaveSeen(int id) async {
    final prefs = await SharedPreferences.getInstance();
    seenLeaveIds.add(id);
    await prefs.setStringList(
      "seenLeaveIds",
      seenLeaveIds.map((e) => e.toString()).toList(),
    );

    _instance?.setState(() {
      leaveRequests.removeWhere((item) => item['id'] == id);
    });
  }

  static Future<void> updateLeaveStatus(
    String newStatus,
    int leaveId,
    BuildContext context,
  ) async {
    // Optimistic UI update
    final index = leaveRequests.indexWhere((r) => r['id'] == leaveId);
    if (index != -1) {
      _instance?.setState(() {
        leaveRequests[index]['status'] = newStatus;
      });
    }

    try {
      await TeacherApiServices.updateLeaveStatus(leaveId, newStatus);

      // ✅ once updated, mark as seen
      await markLeaveSeen(leaveId);

      if (_instance?.mounted ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (_instance?.mounted ?? false) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
      await _instance?.init(); // rollback
    }
  }

  Future<bool> onWillPop() async {
    _goBack();
    for (final fb in feedbacks) {
      await markFeedbackSeen(fb['id']);
    }
    for (final leave in leaveRequests) {
      if (leave['status'] != 'pending') {
        await markLeaveSeen(leave['id']);
      }
    }

    return true;
  }

  void _goBack() {
    AdminDashboardState.selectedIndex = 1;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
  }

  static String formatDate(dynamic date, {String format = 'MMM d, yyyy'}) {
    if (date == null) return '';
    try {
      final parsed = DateTime.tryParse(date.toString());
      if (parsed != null) {
        return DateFormat(format).format(parsed);
      }
    } catch (_) {}
    return date.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Notifications',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: _goBack,
                  )
                  : const AdminAppbarDesktop(title: 'Notifications'),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : (leaveRequests.isEmpty && feedbacks.isEmpty)
                ? const Center(child: Text("No new notifications 🎉"))
                : IndexedStack(
                  index: selectedIndex,
                  children: [
                    StaffNotification(leaveRequests: leaveRequests),
                    StudentNotification(
                      leaveRequests: leaveRequests,
                      feedbacks: feedbacks,
                    ),
                  ],
                ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          onTap: (index) => _instance?.setState(() => selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person, size: 30),
              label: 'Staff',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people, size: 30),
              label: 'Student',
            ),
          ],
        ),
      ),
    );
  }
}
