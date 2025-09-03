import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/leave_request/view_leave_request.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

class StaffLeaveRequest extends StatefulWidget {
  const StaffLeaveRequest({super.key, required this.leaveRequests});
  final List<dynamic> leaveRequests;
  @override
  State<StaffLeaveRequest> createState() => _StaffLeaveRequestState();
}

class _StaffLeaveRequestState extends State<StaffLeaveRequest> {
  List<dynamic> staffLeaveRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    staffLeaveRequests =
        widget.leaveRequests
            .where((leave) => leave['role'] == 'staff')
            .toList();

    for (int i = 0; i < staffLeaveRequests.length; i++) {
      final studentData = await TeacherApiServices.fetchStaffDataUsername(
        username: staffLeaveRequests[i]['username'],
        schoolId: staffLeaveRequests[i]['school_id'],
      );
      setState(() {
        staffLeaveRequests[i]['name'] = studentData!['name'];
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
      );
    }

    if (staffLeaveRequests.isEmpty) {
      return const Center(child: Text("No student leave requests"));
    }
    return ListView.builder(
      itemCount: staffLeaveRequests.length,
      padding: const EdgeInsets.only(bottom: 24),
      itemBuilder: (context, index) {
        return ViewLeaveRequestState.buildLeaveCard(staffLeaveRequests[index]);
      },
    );
  }
}
