import 'package:flutter/material.dart';

import '../components/staff_components.dart';
import '../pages/change_password_screen.dart';
import '../pages/class_list.dart';
import '../pages/timetable_screen.dart';

class StaffDashboardMobile extends StatelessWidget {
  const StaffDashboardMobile({super.key, required this.schoolId});
  final String schoolId;
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
                    builder: (_) => ClassList(schoolId: schoolId),
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
                    builder: (_) => TimetableScreen(schoolId: schoolId),
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
                    builder: (_) => const ChangePasswordScreen(),
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
