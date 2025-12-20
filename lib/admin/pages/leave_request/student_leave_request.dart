// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:school_attendance/admin/pages/leave_request/view_leave_request.dart';
//
// import '../../../student/services/student_api_services.dart';
//
// class StudentLeaveRequest extends StatefulWidget {
//   const StudentLeaveRequest({super.key, required this.leaveRequests});
//   final List<dynamic> leaveRequests;
//
//   @override
//   State<StudentLeaveRequest> createState() => _StudentLeaveRequestState();
// }
//
// class _StudentLeaveRequestState extends State<StudentLeaveRequest> {
//   List<dynamic> studentLeaveRequests = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     init();
//   }
//
//   Future<void> init() async {
//     final filteredRequests =
//         widget.leaveRequests
//             .where((leave) => leave['role'] == 'student')
//             .toList();
//
//     for (int i = 0; i < filteredRequests.length; i++) {
//       final studentData = await StudentApiServices.fetchStudentDataUsername(
//         username: filteredRequests[i]['username'],
//         schoolId: filteredRequests[i]['school_id'],
//       );
//
//       if (studentData != null) {
//         filteredRequests[i]['name'] = studentData['name'];
//       }
//     }
//
//     setState(() {
//       studentLeaveRequests = filteredRequests;
//       isLoading = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (isLoading) {
//       return const Center(
//         child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
//       );
//     }
//
//     if (studentLeaveRequests.isEmpty) {
//       return const Center(child: Text("No student leave requests"));
//     }
//
//     return ListView.builder(
//       itemCount: studentLeaveRequests.length,
//       padding: const EdgeInsets.only(bottom: 24),
//       itemBuilder: (context, index) {
//         return ViewLeaveRequestState.buildLeaveCard(
//           studentLeaveRequests[index],
//         );
//       },
//     );
//   }
// }
