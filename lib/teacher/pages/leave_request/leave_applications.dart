import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../../admin/services/admin_api_service.dart';
import '../../appbar/desktop_appbar.dart';
import '../../appbar/mobile_appbar.dart';
import '../staff_dashboard.dart';

class LeaveApplications extends StatefulWidget {
  const LeaveApplications({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;
  @override
  State<LeaveApplications> createState() => _LeaveApplicationsState();
}

class _LeaveApplicationsState extends State<LeaveApplications> {
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

      final filteredRequests =
          allRequests
              .where(
                (req) =>
                    (req['role'] ?? '').toString().toLowerCase() == 'staff' &&
                    (req['username'] ?? '').toString().toLowerCase() ==
                        widget.username,
              )
              .toList();

      if (mounted) {
        setState(() {
          leaveRequest = filteredRequests;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching leave requests: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
            isMobile
                ? MobileAppbar(
                  title: 'Leave Status',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    StaffDashboardState.selectedIndex = 0;
                    Navigator.push(
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
                : const DesktopAppbar(title: 'Leave Approve Status'),
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
              ? const Center(child: Text("No leave applications found"))
              : ListView.builder(
                itemCount: leaveRequest.length,
                itemBuilder: (context, index) {
                  final req = leaveRequest[index];

                  // Parse and format dates safely
                  String formatDate(String? dateStr) {
                    if (dateStr == null || dateStr.isEmpty) return "";
                    try {
                      final date = DateTime.parse(dateStr);
                      return DateFormat("dd MMM yyyy").format(date);
                    } catch (_) {
                      return dateStr; // fallback if parsing fails
                    }
                  }

                  final fromDate = formatDate(req['from_date']);
                  final toDate = formatDate(req['to_date']);

                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(
                        "Reason: ${req['reason'] ?? 'N/A'}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("From: $fromDate"),
                          Text("To: $toDate"),
                          Text("Status: ${req['status'] ?? ''}"),
                        ],
                      ),
                      trailing: Icon(
                        req['status'] == "approved"
                            ? Icons.check_circle
                            : req['status'] == "rejected"
                            ? Icons.cancel
                            : Icons.hourglass_bottom,
                        color:
                            req['status'] == "approved"
                                ? Colors.green
                                : req['status'] == "rejected"
                                ? Colors.red
                                : Colors.orange,
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
