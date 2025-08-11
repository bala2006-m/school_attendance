import 'package:flutter/material.dart';
import 'package:school_attendance/teacher/widget/home_page.dart';

import '../widget/attendance_page.dart';
import 'manage_page.dart';

class StaffDashboardMobile extends StatelessWidget {
  const StaffDashboardMobile({
    super.key,
    required this.schoolId,
    required this.username,
    required this.name,
    required this.email,
    required this.classId,
    required this.gender,
    required this.schoolName,
    required this.message,
    required this.schoolAddress,
    required this.selectedIndex,
    required this.totalStudents,
    required this.presentStudentFN,
    required this.presentStudentAN,
    required this.classIds,
  });

  final String schoolId;
  final String username;
  final String name;
  final String email;
  final String classId;
  final String gender;
  final String schoolName;
  final String message;
  final String schoolAddress;
  final int selectedIndex;
  final String totalStudents;
  final String presentStudentFN;
  final String presentStudentAN;
  final List<dynamic> classIds;
  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: selectedIndex,
      children: [
        AttendancePage(
          schoolId: schoolId,
          username: username,
          classIds: classIds,
        ),
        HomePage(
          schoolId: schoolId,
          username: username,
          message: message,
          totalStudents: totalStudents,
          presentStudentFN: presentStudentFN,
          presentStudentAN: presentStudentAN,
          classIds: classIds,
        ),
        ManagePage(schoolId: schoolId, username: username, classIds: classIds),
      ],
    );
  }
}
