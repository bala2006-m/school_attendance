import 'package:flutter/material.dart';

import '../components/staff_components.dart';
import '../pages/change_password_screen.dart';
import '../pages/class_list.dart';
import '../pages/timetable_screen.dart';

class StaffDashboardMobile extends StatelessWidget {
  const StaffDashboardMobile({super.key,
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StaffCompoents.buildDashboardItemMobile(
              context,
              icon: Icons.check_circle_outline,
              label: 'Take Attendance',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClassList(schoolId: schoolId,username: username,),
                  ),
                );
              },
            ),
            SizedBox(height: 10),
            StaffCompoents.buildDashboardItem(
              context,
              icon: Icons.calendar_today,
              label: 'Manage Timetable',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TimetableScreen(schoolId: schoolId,username: username,),
                  ),
                );
              },
            ),
            SizedBox(height: 10),
            StaffCompoents.buildDashboardItem(
              context,
              icon: Icons.lock_reset,
              label: 'Change Password',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangePasswordScreen(username: username,),
                  ),
                );
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
