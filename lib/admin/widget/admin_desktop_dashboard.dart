import 'package:flutter/material.dart';
import 'package:school_attendance/admin/widget/admin_desktop_drawer_small.dart';

import '../components/build_home_page.dart';
import '../pages/admin_management.dart';
import '../pages/admin_student.dart';
import 'admin_desktop_drawer.dart';

class AdminDesktopDashboard extends StatelessWidget {
  const AdminDesktopDashboard({
    super.key,
    required this.schoolId,
    required this.username,
    required this.adminName,
    required this.adminDesignation,
    this.adminPhoto,
    required this.schoolName,
    required this.schoolAddress,
    required this.totalStudents,
    required this.totalStaff,
    required this.presentStaffFN,
    required this.presentStaffAN,
    required this.presentStudentFN,
    required this.presentStudentAN,
    required this.selectedIndex,
    required this.mobile,
    required this.attendanceStatusMapFn,
    required this.message,
    required this.attendanceStatusMapAn,
    this.schoolPhoto,
  });
  final String message;
  final String schoolId;
  final String username;
  final String adminName;
  final String adminDesignation;
  final Image? adminPhoto;
  final Image? schoolPhoto;
  final String schoolName;
  final String schoolAddress;
  final int totalStudents;
  final int totalStaff;
  final int presentStaffFN;
  final int presentStaffAN;
  final int presentStudentFN;
  final int presentStudentAN;
  final int selectedIndex;
  final String mobile;
  final Map<String, bool> attendanceStatusMapFn;
  final Map<String, bool> attendanceStatusMapAn;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallHeight = screenHeight < 600;
    final drawerWidth = screenWidth * 0.22;

    Widget drawer =
        isSmallHeight
            ? AdminDesktopDrawerSmall(
              width: drawerWidth,
              height: screenHeight / 2,
              username: username,
              name: adminName,
              designation: adminDesignation,
              photo: adminPhoto,
              schoolName: schoolName,
              schoolAddress: schoolAddress,
              mobileNumber: mobile,
              schoolId: schoolId,
            )
            : AdminDesktopDrawer(
              width: drawerWidth,
              height: double.infinity,
              username: username,
              name: adminName,
              designation: adminDesignation,
              photo: adminPhoto,
              schoolName: schoolName,
              schoolAddress: schoolAddress,
              mobileNumber: mobile,
              schoolId: schoolId,
            );

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Row(
        children: [
          // Sidebar drawer
          Padding(
            padding: const EdgeInsets.only(top: 13, left: 10),
            child: Container(
              width: drawerWidth,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: drawer,
            ),
          ),

          // Main content
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 1),
              child: IndexedStack(
                index: selectedIndex,
                children: [
                  AdminStudent(
                    school_id: schoolId,
                    adminUsername: username,
                    adminName: adminName,
                    adminDesignation: adminDesignation,
                    adminPhoto: adminPhoto,
                    schoolName: schoolName,
                    schoolAddress: schoolAddress,
                  ),
                  BuildHomePage.buildHomePage(
                    message: message,
                    context: context,
                    totalStudents: '$totalStudents',
                    presentStudentFN: '$presentStudentFN',
                    totalStaff: '$totalStaff',
                    presentStaffFN: '$presentStaffFN',
                    presentStudentAN: '$presentStudentAN',
                    presentStaffAN: '$presentStaffAN',
                    adminName: adminName,
                    adminDesignation: adminDesignation,
                    adminPhoto: adminPhoto,
                    schoolName: schoolName,
                    schoolAddress: schoolAddress,
                    schoolPhoto: schoolPhoto,
                    attendanceStatusMapFn: attendanceStatusMapFn,
                    attendanceStatusMapAn: attendanceStatusMapAn,
                  ),
                  AdminManagement(
                    adminUsername: username,
                    schoolId: schoolId,
                    schoolAddress: schoolAddress,
                    schoolName: schoolName,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
