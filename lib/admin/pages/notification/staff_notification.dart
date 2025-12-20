// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
//
// import '../../../teacher/services/teacher_api_service.dart';
// import 'notifications.dart';
//
// class StaffNotification extends StatefulWidget {
//   const StaffNotification({super.key, required this.leaveRequests});
//   final List<dynamic> leaveRequests;
//   @override
//   State<StaffNotification> createState() => _StaffNotificationState();
// }
//
// class _StaffNotificationState extends State<StaffNotification> {
//   List<dynamic> staffLeaveRequests = [];
//   bool isLoading = true;
//
//   @override
//   void initState() {
//     init();
//     super.initState();
//   }
//
//   Future<void> init() async {
//     staffLeaveRequests =
//         widget.leaveRequests
//             .where((leave) => leave['role'] == 'staff')
//             .toList();
//
//     for (int i = 0; i < staffLeaveRequests.length; i++) {
//       final studentData = await TeacherApiServices.fetchStaffDataUsername(
//         username: staffLeaveRequests[i]['username'],
//         schoolId: staffLeaveRequests[i]['school_id'],
//       );
//       setState(() {
//         staffLeaveRequests[i]['name'] = studentData!['name'];
//         isLoading = false;
//       });
//     }
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
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.center,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: const Text(
//               "Leave Requests",
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//           ),
//           if (staffLeaveRequests.isNotEmpty)
//             ...staffLeaveRequests.map(
//               (leave) => Card(
//                 margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 child: ListTile(
//                   title: Text(
//                     "Name : ${leave['name']}\nUsername : ${leave['username']}",
//                   ),
//                   subtitle: Text(
//                     "Reason: ${leave['reason']}\nFrom: ${NotificationsState.formatDate(
//                       leave['from_date'],
//                       format: 'MMM d, yyyy', //• hh:mm a',
//                     )} To: ${NotificationsState.formatDate(
//                       leave['to_date'],
//                       format: 'MMM d, yyyy', //• hh:mm a',
//                     )}",
//                   ),
//                   trailing: Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       if ((leave['status'] ?? 'pending')
//                               .toString()
//                               .toLowerCase() ==
//                           'pending') ...[
//                         IconButton(
//                           icon: const Icon(
//                             Icons.check_circle,
//                             color: Colors.green,
//                           ),
//                           onPressed:
//                               () => NotificationsState.updateLeaveStatus(
//                                 'approved',
//                                 leave['id'],
//                                 context,
//                               ),
//                         ),
//                         IconButton(
//                           icon: const Icon(Icons.cancel, color: Colors.red),
//                           onPressed:
//                               () => NotificationsState.updateLeaveStatus(
//                                 'rejected',
//                                 leave['id'],
//                                 context,
//                               ),
//                         ),
//                       ] else
//                         GestureDetector(
//                           onTap:
//                               () => NotificationsState.markLeaveSeen(
//                                 leave['id'],
//                               ), // ✅ tap marks seen
//                           child: Text(
//                             leave['status'].toString().toUpperCase(),
//                             style: TextStyle(
//                               fontWeight: FontWeight.bold,
//                               color:
//                                   leave['status'] == "approved"
//                                       ? Colors.green
//                                       : Colors.red,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
