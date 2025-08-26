import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';

class Notifications extends StatefulWidget {
  const Notifications({
    super.key,
    required this.schoolId,
    required this.username,
  });
  final String schoolId;
  final String username;

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  List<dynamic> leaveRequests = [];
  List<dynamic> feedbacks = [];
  Set<int> seenFeedbackIds = {};
  Set<int> seenLeaveIds = {}; // ✅ new
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
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

    setState(() {
      // Only show unseen ones
      leaveRequests =
          leave.where((item) => !seenLeaveIds.contains(item['id'])).toList();
      feedbacks =
          feed.where((item) => !seenFeedbackIds.contains(item['id'])).toList();
      isLoading = false;
    });
  }

  Future<void> markFeedbackSeen(int id) async {
    final prefs = await SharedPreferences.getInstance();
    seenFeedbackIds.add(id);
    await prefs.setStringList(
      "seenFeedbackIds",
      seenFeedbackIds.map((e) => e.toString()).toList(),
    );
    setState(() {
      feedbacks.removeWhere((item) => item['id'] == id);
    });
  }

  Future<void> markLeaveSeen(int id) async {
    final prefs = await SharedPreferences.getInstance();
    seenLeaveIds.add(id);
    await prefs.setStringList(
      "seenLeaveIds",
      seenLeaveIds.map((e) => e.toString()).toList(),
    );
    setState(() {
      leaveRequests.removeWhere((item) => item['id'] == id);
    });
  }

  Future<void> _updateLeaveStatus(String newStatus, int leaveId) async {
    // Optimistic UI update
    setState(() {
      final index = leaveRequests.indexWhere((r) => r['id'] == leaveId);
      if (index != -1) leaveRequests[index]['status'] = newStatus;
    });

    try {
      await TeacherApiServices.updateLeaveStatus(leaveId, newStatus);
      // ✅ once updated, mark as seen
      await markLeaveSeen(leaveId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave status updated to $newStatus')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      init(); // rollback
    }
  }

  Future<bool> onWillPop() async {
    // Mark all remaining feedbacks as seen before leaving
    for (int i = 0; i < feedbacks.length; i++) {
      await markFeedbackSeen(feedbacks[i]['id']);
    }
    // Mark all non-pending leave requests as seen
    for (int i = 0; i < leaveRequests.length; i++) {
      if (leaveRequests[i]['status'] != 'pending') {
        await markLeaveSeen(leaveRequests[i]['id']);
      }
    }
    Navigator.pop(context);
    return false;
  }

  String formatDate(dynamic date, {String format = 'MMM d, yyyy'}) {
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
                    onBack: () async {
                      await onWillPop();
                    },
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
                : ListView(
                  children: [
                    if (leaveRequests.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Leave Requests",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ...leaveRequests.map(
                      (leave) => Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(
                            "${leave['username']} (${leave['role']})",
                          ),
                          subtitle: Text(
                            "Reason: ${leave['reason']}\nFrom: ${formatDate(
                              leave['from_date'],
                              format: 'MMM d, yyyy', //• hh:mm a',
                            )} To: ${formatDate(
                              leave['to_date'],
                              format: 'MMM d, yyyy', //• hh:mm a',
                            )}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if ((leave['status'] ?? 'pending')
                                      .toString()
                                      .toLowerCase() ==
                                  'pending') ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed:
                                      () => _updateLeaveStatus(
                                        'approved',
                                        leave['id'],
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => _updateLeaveStatus(
                                        'rejected',
                                        leave['id'],
                                      ),
                                ),
                              ] else
                                GestureDetector(
                                  onTap:
                                      () => markLeaveSeen(
                                        leave['id'],
                                      ), // ✅ tap marks seen
                                  child: Text(
                                    leave['status'].toString().toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          leave['status'] == "approved"
                                              ? Colors.green
                                              : Colors.red,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (feedbacks.isNotEmpty) const Divider(),
                    if (feedbacks.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Feedbacks",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ...feedbacks.map(
                      (fb) => Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          title: Text(fb['name'] ?? "Unknown"),
                          subtitle: Text(fb['feedback']),
                          trailing: Text(
                            fb['created_at'].toString().split("T")[0],
                          ),
                          onTap: () => markFeedbackSeen(fb['id']),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
