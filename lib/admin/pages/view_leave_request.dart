import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/student/services/student_api_services.dart';

import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../services/admin_api_service.dart';
import 'admin_dashboard.dart';

class ViewLeaveRequest extends StatefulWidget {
  final String schoolId;
  final String username;
  const ViewLeaveRequest({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<ViewLeaveRequest> createState() => _ViewLeaveRequestState();
}

class _ViewLeaveRequestState extends State<ViewLeaveRequest> {
  List<Map<String, dynamic>> leaveRequest = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      leaveRequest = await AdminApiService.fetchLeaveRequest(widget.schoolId);

      await Future.wait(
        leaveRequest.map((request) async {
          if ((request['role'] ?? '').toString().toLowerCase() == 'student') {
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
              print('Error fetching class for ${request['username']}: $e');
            }
          }
        }),
      );
    } catch (e) {
      print("Error fetching leave requests: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> onWillPop() async {
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
    return false;
  }

  Widget buildLeaveCard(Map<String, dynamic> request) {
    final username = request['username'] ?? 'Unknown';
    final role = request['role'] ?? '';
    final fromDate = DateFormat(
      'MMM d, yyyy',
    ).format(DateTime.parse(request['from_date']));
    final toDate = DateFormat(
      'MMM d, yyyy',
    ).format(DateTime.parse(request['to_date']));
    final reason = request['reason'] ?? 'No reason provided';
    final status = request['status'] ?? 'pending';
    final createdAt =
        request['created_at'] != null
            ? DateFormat(
              'MMM d, yyyy • hh:mm a',
            ).format(DateTime.parse(request['created_at']))
            : 'Unknown';

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

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Header: Username, role, date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$username (${role.toUpperCase()})",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  createdAt,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 6),

            /// If student, show class name and section
            if (role == 'student')
              Text(
                "Class: $className  |  Section: $section",
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            if (role == 'student') const SizedBox(height: 6),

            /// Date Range
            Text(
              "From: $fromDate  →  To: $toDate",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 6),

            /// Reason
            Text("Reason: $reason", style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 10),

            /// Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                border: Border.all(color: statusColor),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    title: 'View Leave Request',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
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
                    },
                  )
                  : const AdminAppbarDesktop(title: 'View Leave Request'),
        ),
        body:
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : leaveRequest.isEmpty
                ? const Center(child: Text('No leave requests found.'))
                : ListView.builder(
                  itemCount: leaveRequest.length,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder: (context, index) {
                    return buildLeaveCard(leaveRequest[index]);
                  },
                ),
      ),
    );
  }
}
