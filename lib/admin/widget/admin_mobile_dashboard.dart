import 'package:flutter/material.dart';

import '../components/build_home_page.dart';
import '../pages/admin_management.dart';
import '../pages/admin_student.dart';

class AdminMobileDashboard extends StatelessWidget {
  const AdminMobileDashboard({
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
    required this.attendanceStatusMapFn,
    required this.message,
    required this.attendanceStatusMapAn,
    this.schoolPhoto,
  });
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
  final String message;
  final Map<String, bool> attendanceStatusMapFn;
  final Map<String, bool> attendanceStatusMapAn;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
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
          schoolName: schoolName,
          schoolAddress: schoolAddress,
        ),
      ],
    );
  }
}
