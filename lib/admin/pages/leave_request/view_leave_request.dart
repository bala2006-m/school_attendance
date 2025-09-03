import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/admin/pages/leave_request/staff_leave_request.dart';
import 'package:school_attendance/admin/pages/leave_request/student_leave_request.dart';
import 'package:school_attendance/student/services/student_api_services.dart';

import '../../../teacher/services/teacher_api_service.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
import '../dashboard/admin_dashboard.dart';

class ViewLeaveRequest extends StatefulWidget {
  final String schoolId;
  final String username;
  const ViewLeaveRequest({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<ViewLeaveRequest> createState() => ViewLeaveRequestState();
}

class ViewLeaveRequestState extends State<ViewLeaveRequest> {
  /// 🔑 Static state variables
  static List<Map<String, dynamic>> leaveRequest = [];
  static bool isLoading = true;
  static int selectedIndex = 1;

  /// 🔑 Reference to the current mounted instance
  static ViewLeaveRequestState? _instance;

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

  /// 🔄 Fetch leave requests
  Future<void> init() async {
    _instance?.setState(() => isLoading = true);
    try {
      leaveRequest = await AdminApiService.fetchLeaveRequest(widget.schoolId);

      await Future.wait(
        leaveRequest.map((request) async {
          final roleLower = (request['role'] ?? '').toString().toLowerCase();
          if (roleLower == 'student' &&
              request['class_id'] != null &&
              request['class_id'].toString().isNotEmpty) {
            try {
              final classInfo = await StudentApiServices.fetchClassDatas(
                widget.schoolId,
                '${request['class_id']}',
              );
              request['class_name'] = classInfo?['class'] ?? '';
              request['section'] = classInfo?['section'] ?? '';
            } catch (e) {
              request['class_name'] = '';
              request['section'] = '';
              debugPrint('Error fetching class for ${request['username']}: $e');
            }
          }
        }),
      );
    } catch (e) {
      debugPrint("Error fetching leave requests: $e");
    } finally {
      if (_instance?.mounted ?? false) {
        _instance?.setState(() {
          isLoading = false;
        });
      }
    }
  }

  /// ⬅️ Back button handler
  Future<bool> onWillPop() async {
    _goBack();
    return false;
  }

  void _goBack() {
    AdminDashboardState.selectedIndex = 2;
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

  /// 📅 Date formatting
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

  /// 📝 Leave card widget
  static Widget buildLeaveCard(Map<String, dynamic> request) {
    final username = request['username'] ?? 'Unknown';
    final int id = int.tryParse(request['id']?.toString() ?? '') ?? 0;
    final role = (request['role'] ?? '').toString();
    final roleLower = role.toLowerCase();
    final name = request['name'] ?? 'Unknown';
    final fromDate = formatDate(request['from_date'], format: 'yyyy-MM-dd');
    final toDate = formatDate(request['to_date'], format: 'yyyy-MM-dd');
    final reason = request['reason'] ?? 'No reason provided';
    final status = (request['status'] ?? 'pending').toString();
    final createdAt = formatDate(request['created_at'], format: 'MMM d, yyyy');
    final className = request['class_name'] ?? '';
    final section = request['section'] ?? '';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header: Role + Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Spacer(),
                Text(
                  createdAt,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Name : ${name.length > 16 ? name.substring(0, 16) + '...' : name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            /// Username
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Username : ${username.length > 16 ? username.substring(0, 16) + '...' : username}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            /// Class + Section
            if (roleLower == 'student') ...[
              const SizedBox(height: 6),
              Text(
                "Class: $className  |  Section: $section",
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ],

            const SizedBox(height: 10),

            /// Date Range
            Row(
              children: [
                Text("From: $fromDate", style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                const SizedBox(width: 16),
                Text("To: $toDate", style: const TextStyle(fontSize: 15)),
              ],
            ),

            const SizedBox(height: 10),

            /// Reason
            const Text(
              'Reason',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reason,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// Status & Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  backgroundColor: statusColor.withValues(alpha: 0.1),
                  side: BorderSide(color: statusColor),
                ),
                if (status.toLowerCase() == 'pending')
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        tooltip: "Approve",
                        onPressed: () => updateLeaveStatus('approved', id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: "Reject",
                        onPressed: () => updateLeaveStatus('rejected', id),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Update leave status (static, but works with _instance)
  static void updateLeaveStatus(String newStatus, int leaveId) async {
    _instance?.setState(() {
      final index = leaveRequest.indexWhere((r) => r['id'] == leaveId);
      if (index != -1) leaveRequest[index]['status'] = newStatus;
    });

    try {
      await TeacherApiServices.updateLeaveStatus(leaveId, newStatus);

      if (_instance?.mounted ?? false) {
        ScaffoldMessenger.of(_instance!.context).showSnackBar(
          SnackBar(content: Text('Leave status updated to $newStatus')),
        );
      }
    } catch (e) {
      if (_instance?.mounted ?? false) {
        ScaffoldMessenger.of(
          _instance!.context,
        ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
      }
      await _instance?.init(); // rollback
    }
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
                    title: 'View Leave Request',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: _goBack,
                  )
                  : const AdminAppbarDesktop(title: 'View Leave Request'),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60.0,
                  ),
                )
                : leaveRequest.isEmpty
                ? const Center(child: Text('No leave requests found.'))
                // : ListView.builder(
                //   itemCount: leaveRequest.length,
                //   padding: const EdgeInsets.only(bottom: 24),
                //   itemBuilder: (context, index) {
                //     return buildLeaveCard(leaveRequest[index]);
                //   },
                // ),
                : IndexedStack(
                  index: selectedIndex,
                  children: [
                    StaffLeaveRequest(
                      leaveRequests:
                          leaveRequest
                              .where((r) => r['role'] == 'staff')
                              .toList(),
                    ),
                    StudentLeaveRequest(
                      leaveRequests:
                          leaveRequest
                              .where((r) => r['role'] == 'student')
                              .toList(),
                    ),
                  ],
                ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => selectedIndex = index),
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
