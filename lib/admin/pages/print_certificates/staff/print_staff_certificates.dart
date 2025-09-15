// import 'package:flutter/material.dart';
// import 'package:flutter_spinkit/flutter_spinkit.dart';
// import 'package:school_attendance/admin/pages/print_certificates/staff/staff_certificates.dart';
// import 'package:school_attendance/admin/services/admin_api_service.dart';
//
// import '../../../appbar/admin_appbar_desktop.dart';
// import '../../../appbar/admin_appbar_mobile.dart';
// import '../../dashboard/admin_dashboard.dart';
//
// class PrintStaffCertificates extends StatefulWidget {
//   const PrintStaffCertificates({
//     super.key,
//     required this.username,
//     required this.schoolId,
//   });
//   final String username;
//   final String schoolId;
//   @override
//   State<PrintStaffCertificates> createState() => _PrintStaffCertificatesState();
// }
//
// class _PrintStaffCertificatesState extends State<PrintStaffCertificates> {
//   List<Map<String, dynamic>> staffs = [];
//   bool isLoading = true;
//   @override
//   void initState() {
//     init();
//     super.initState();
//   }
//
//   Future<void> init() async {
//     staffs = await AdminApiService.fetchStaffData(widget.schoolId);
//     setState(() {
//       isLoading = false;
//     });
//     if (staffs.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("No Staffs Found")));
//     }
//   }
//
//   Future<bool> onWillPop() async {
//     AdminDashboardState.selectedIndex = 2;
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => AdminDashboard(
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
//
//     // Group staff by designation
//     final Map<String, List<Map<String, dynamic>>> groupedStaffs = {};
//     for (var staff in staffs) {
//       final designation = staff['designation'] ?? 'Unknown';
//       if (!groupedStaffs.containsKey(designation)) {
//         groupedStaffs[designation] = [];
//       }
//       groupedStaffs[designation]!.add(staff);
//     }
//
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
//                     title: 'Staff Certificates',
//                     enableDrawer: false,
//                     enableBack: true,
//                     onBack: () {
//                       AdminDashboardState.selectedIndex = 2;
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder:
//                               (context) => AdminDashboard(
//                                 schoolId: widget.schoolId,
//                                 username: widget.username,
//                               ),
//                         ),
//                       );
//                     },
//                   )
//                   : const AdminAppbarDesktop(title: 'Staff Certificates'),
//         ),
//         body:
//             isLoading
//                 ? const Center(
//                   child: SpinKitFadingCircle(
//                     color: Colors.blueAccent,
//                     size: 60.0,
//                   ),
//                 )
//                 : ListView(
//                   padding: const EdgeInsets.all(12),
//                   children:
//                       groupedStaffs.entries.map((entry) {
//                         final designation = entry.key;
//                         final staffList = entry.value;
//
//                         return Card(
//                           elevation: 3,
//                           margin: const EdgeInsets.symmetric(vertical: 8),
//                           child: Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   designation,
//                                   style: const TextStyle(
//                                     fontSize: 18,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 const Divider(),
//                                 Column(
//                                   children:
//                                       staffList.map((staff) {
//                                         return InkWell(
//                                           onTap: () {
//                                             Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder:
//                                                     (
//                                                       context,
//                                                     ) => StaffCertificates(
//                                                       schoolId: widget.schoolId,
//                                                       username: widget.username,
//                                                       staffUsername:
//                                                           staff['username'],
//                                                     ),
//                                               ),
//                                             );
//                                           },
//                                           child: ListTile(
//                                             leading: const CircleAvatar(
//                                               child: Icon(Icons.person),
//                                             ),
//                                             title: Text(staff['name'] ?? ''),
//                                             subtitle: Text(
//                                               staff['email'] ?? '',
//                                             ),
//                                             trailing: Text(
//                                               staff['mobile'] ?? '',
//                                             ),
//                                           ),
//                                         );
//                                       }).toList(),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                 ),
//       ),
//     );
//   }
// }
