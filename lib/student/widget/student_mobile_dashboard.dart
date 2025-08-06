import 'package:flutter/material.dart';

import '../pages/attendance_page.dart';
import '../pages/holiday_page.dart';
import '../pages/timetable_page.dart';

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
  });

  final String username;
  final String name;
  final String email;
  final String schoolId;
  final String classId;
  final String gender;
  final String schoolName;
  final String className;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          dashboardTile(
            context: context,
            icon: Icons.access_time,
            title: 'Attendance',
            page: AttendancePage(
              username: username,
              name: name,
              schoolId: schoolId,
              classId: classId,
              email: email,
              gender: gender,
            ),
          ),
          const SizedBox(height: 20),
          dashboardTile(
            context: context,
            icon: Icons.calendar_today,
            title: 'Timetable',
            page: TimeTablePage(schoolId: schoolId, classId: classId),
          ),
          const SizedBox(height: 20),
          dashboardTile(
            context: context,
            icon: Icons.beach_access,
            title: 'Holidays',
            page: HolidayPage(schoolId: schoolId, classId: classId),
          ),
        ],
      ),
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
