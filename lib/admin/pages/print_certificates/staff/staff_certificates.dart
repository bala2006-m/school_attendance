// import 'package:flutter/material.dart';
// import 'package:school_attendance/admin/pages/print_certificates/staff/print_staff_certificates.dart';
// import 'package:school_attendance/teacher/services/teacher_api_service.dart';
//
// import '../../../appbar/admin_appbar_desktop.dart';
// import '../../../appbar/admin_appbar_mobile.dart';
//
// class StaffCertificates extends StatefulWidget {
//   const StaffCertificates({
//     super.key,
//     required this.username,
//     required this.schoolId,
//     required this.staffUsername,
//   });
//   final String username;
//   final String schoolId;
//
//   final String staffUsername;
//   @override
//   State<StaffCertificates> createState() => _StaffCertificatesState();
// }
//
// class _StaffCertificatesState extends State<StaffCertificates> {
//   Map<String, dynamic>? staffData;
//   @override
//   void initState() {
//     fetchStaffData();
//     super.initState();
//   }
//
//   Future<void> fetchStaffData() async {
//     try {
//       staffData = await TeacherApiServices.fetchStaffDataUsername(
//         username: widget.staffUsername,
//         schoolId: int.parse(widget.schoolId),
//       );
//       print(staffData);
//     } catch (e) {
//       debugPrint('Error fetching staff data: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Failed to load staff data")),
//       );
//     }
//   }
//
//   Future<void> fetchMonthlyAttendance() async {}
//   Future<void> fetchPeriodicAttendance() async {}
//   Future<void> fetchYearlyAttendance() async {}
//   Future<bool> onWillPop() async {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => PrintStaffCertificates(
//               schoolId: widget.schoolId,
//               username: widget.username,
//             ),
//       ),
//     );
//     return false;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isMobile = MediaQuery.of(context).size.width < 600;
//     return WillPopScope(
//       onWillPop: onWillPop,
//       child: Scaffold(
//         appBar: PreferredSize(
//           preferredSize: Size.fromHeight(isMobile ? 190 : 150),
//           child:
//               isMobile
//                   ? AdminAppbarMobile(
//                     schoolId: widget.schoolId,
//                     username: widget.username,
//                     title: 'Download Certificates',
//                     enableDrawer: false,
//                     enableBack: true,
//                     onBack: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (context) => PrintStaffCertificates(
//                                 schoolId: widget.schoolId,
//                                 username: widget.username,
//                               ),
//                         ),
//                       );
//                     },
//                   )
//                   : const AdminAppbarDesktop(title: 'Download Certificates'),
//         ),
//         body: SingleChildScrollView(
//           child: Center(
//             child: Column(
//               children: [
//                 const SizedBox(height: 20),
//
//                 // --- Staff Profile Card ---
//                 if (staffData != null)
//                   Card(
//                     elevation: 3,
//                     margin: const EdgeInsets.all(12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.all(16.0),
//                       child: Column(
//                         children: [
//                           CircleAvatar(
//                             radius: 40,
//                             backgroundColor: Colors.grey[300],
//                             child: const Icon(Icons.person, size: 40),
//                           ),
//                           const SizedBox(height: 12),
//                           Text(
//                             staffData!['name'] ?? '',
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             staffData!['designation'] ?? '',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.grey[600],
//                             ),
//                           ),
//                           const Divider(height: 30),
//                           ListTile(
//                             leading: const Icon(Icons.email),
//                             title: Text(staffData!['email'] ?? ''),
//                           ),
//                           ListTile(
//                             leading: const Icon(Icons.phone),
//                             title: Text(staffData!['mobile'] ?? ''),
//                           ),
//                           ListTile(
//                             leading: Icon(
//                               staffData!['gender'] == 'F'
//                                   ? Icons.female
//                                   : Icons.male,
//                             ),
//                             title: Text(staffData!['gender'] ?? ''),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//
//                 const SizedBox(height: 40),
//
//                 // --- Certificates Section ---
//                 Text(
//                   'Do you want to download the Staff Monthly Attendance Certificate as a PDF?',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 18, color: Colors.grey[700]),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(Icons.download_rounded),
//                   label: const Text('Download PDF'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 30,
//                       vertical: 15,
//                     ),
//                     textStyle: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 40),
//                 Text(
//                   'Do you want to download the Staff Periodic Attendance Certificate as a PDF?',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 18, color: Colors.grey[700]),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(Icons.download_rounded),
//                   label: const Text('Download PDF'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 30,
//                       vertical: 15,
//                     ),
//                     textStyle: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//
//                 const SizedBox(height: 40),
//                 Text(
//                   'Do you want to download the Staff Attendance Certificate for the whole year as a PDF?',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(fontSize: 18, color: Colors.grey[700]),
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton.icon(
//                   onPressed: () {},
//                   icon: const Icon(Icons.download_rounded),
//                   label: const Text('Download PDF'),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blueAccent,
//                     foregroundColor: Colors.white,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 30,
//                       vertical: 15,
//                     ),
//                     textStyle: const TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 30),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
