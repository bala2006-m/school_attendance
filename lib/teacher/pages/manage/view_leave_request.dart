import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/student/services/student_api_services.dart';
import 'package:school_attendance/teacher/appbar/desktop_appbar.dart';
import 'package:school_attendance/teacher/appbar/mobile_appbar.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../admin/services/admin_api_service.dart';

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
      final allRequests = await AdminApiService.fetchLeaveRequest(
        widget.schoolId,
      );

      // Keep only student requests
      leaveRequest =
          allRequests
              .where(
                (req) =>
                    (req['role'] ?? '').toString().toLowerCase() == 'student',
              )
              .toList();

      await Future.wait(
        leaveRequest.map((request) async {
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
          }
        }),
      );
    } catch (e) {
      debugPrint("Error fetching leave requests: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> onWillPop() async {
    StaffDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => StaffDashboard(
              username: widget.username,
              schoolId: widget.schoolId,
            ),
      ),
    );
    return false;
  }

  String formatDate(String? dateStr, {String format = 'MMM d, yyyy'}) {
    if (dateStr == null || dateStr.isEmpty) return 'Unknown';
    try {
      return DateFormat(format).format(DateTime.parse(dateStr));
    } catch (_) {
      return 'Invalid date';
    }
  }

  Widget buildLeaveCard(Map<String, dynamic> request) {
    final username = request['username'] ?? 'Unknown';
    final int id = int.tryParse(request['id']?.toString() ?? '') ?? 0;
    final role = (request['role'] ?? '').toString();
    final fromDate = formatDate(request['from_date']);
    final toDate = formatDate(request['to_date']);
    final reason = request['reason'] ?? 'No reason provided';
    final status = (request['status'] ?? 'pending').toString();
    final createdAt = formatDate(
      request['created_at'],
      format: 'MMM d, yyyy • hh:mm a',
    );
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
            /// Header
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

            /// If student, show class info
            if (role.toLowerCase() == 'student')
              Text(
                "Class: $className  |  Section: $section",
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            if (role.toLowerCase() == 'student') const SizedBox(height: 6),

            /// Date Range
            Text(
              "From: $fromDate  →  To: $toDate",
              style: const TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 6),

            /// Reason
            Text("Reason: $reason", style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 10),

            /// Status Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: statusColor,
                elevation: 0,
                side: BorderSide(color: statusColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onPressed:
                  status.toLowerCase() == 'pending'
                      ? () => _showApproveRejectDialog(context, id)
                      : null,
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

  void _showApproveRejectDialog(BuildContext context, int id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Update Status'),
            content: const Text(
              'Do you want to approve or reject this request?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateLeaveStatus('approved', id);
                },
                child: const Text(
                  'Approve',
                  style: TextStyle(color: Colors.green),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updateLeaveStatus('rejected', id);
                },
                child: const Text(
                  'Reject',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _updateLeaveStatus(String newStatus, int leaveId) async {
    try {
      final res = await TeacherApiServices.updateLeaveStatus(
        leaveId,
        newStatus,
      );

      if (!mounted) return; // Widget no longer exists

      if (!mounted) return; // Double-check before showing SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave status updated to $newStatus')),
      );
      init();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
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
                  ? MobileAppbar(
                    title: 'View Leave Request',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      StaffDashboardState.selectedIndex = 2;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => StaffDashboard(
                                username: widget.username,
                                schoolId: widget.schoolId,
                              ),
                        ),
                      );
                    },
                  )
                  : const DesktopAppbar(title: 'View Leave Request'),
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
                : ListView.builder(
                  itemCount: leaveRequest.length,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemBuilder:
                      (context, index) => buildLeaveCard(leaveRequest[index]),
                ),
      ),
    );
  }
}
