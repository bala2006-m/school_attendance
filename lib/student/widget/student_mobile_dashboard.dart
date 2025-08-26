import 'package:flutter/material.dart';
import 'package:school_attendance/student/widget/student_attendance_page.dart';
import 'package:school_attendance/student/widget/student_home_page.dart';
import 'package:school_attendance/student/widget/student_manage_page.dart';

class StudentMobileDashboard extends StatelessWidget {
  const StudentMobileDashboard({
    super.key,
    required this.username,
    required this.name,
    required this.email,
    required this.schoolId,
    required this.classId,
    required this.gender,
    required this.schoolName,
    required this.className,
    required this.selectedIndex,
    required this.schoolAddress,
    required this.message,
    required this.timetable,
    this.schoolPhoto,
  });
  final List<String> timetable;
  final String username;
  final String name;
  final String email;
  final String schoolId;
  final String classId;
  final String gender;
  final String schoolName;
  final String className;
  final int selectedIndex;
  final String schoolAddress;
  final String message;
  final Image? schoolPhoto;
  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: selectedIndex,
      children: [
        StudentAttendancePage(
          username: username,
          name: name,
          email: email,
          schoolId: schoolId,
          classId: classId,
          gender: gender,
          schoolName: schoolName,
          schoolAddress: schoolAddress,
          message: message,
          schoolPhoto: schoolPhoto,
        ),
        StudentHomePage(
          timetable: timetable,
          schoolId: schoolId,
          classId: classId,
          username: username,
          schoolName: schoolName,
          schoolAddress: schoolAddress,
          message: message,
          schoolPhoto: schoolPhoto,
        ),
        StudentManagePage(
          schoolId: schoolId,
          classId: classId,
          username: username,
          schoolName: schoolName,
          schoolAddress: schoolAddress,
          message: message,
          schoolPhoto: schoolPhoto,
        ),
      ],
    );
  }

  Widget dashboardTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return InkWell(
      onTap: () => navigateTo(context, page),
      borderRadius: BorderRadius.circular(25),
      splashColor: Colors.indigo.withOpacity(0.3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Icon(icon, size: 50, color: Colors.indigo),
            const SizedBox(width: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void navigateTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
