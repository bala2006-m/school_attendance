import 'package:flutter/material.dart';

import '../components/staff_components.dart';
import '../pages/change_password_screen.dart';
import '../pages/class_list.dart';
import '../pages/timetable_screen.dart';
import 'desktop_drawer.dart';

class StaffDashboardDesktop extends StatelessWidget {
  const StaffDashboardDesktop({
    super.key,
    required this.name,
    required this.schoolId,
    required this.username,
  });

  final String name;
  final String schoolId;
  final String username;
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Row(
        children: [
          /// Sidebar drawer
          DesktopDrawer(
            name: name,
            width: screenWidth,
            height: screenHeight,
            username: username,
          ),

          /// Main dashboard content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount =
                        constraints.maxWidth > 900
                            ? 3
                            : constraints.maxWidth > 600
                            ? 2
                            : 1;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      children: [
                        StaffCompoents.buildDashboardItem(
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
                        StaffCompoents.buildDashboardItem(
                          context,
                          icon: Icons.calendar_today,
                          label: 'Manage Timetable',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => TimetableScreen(schoolId: schoolId),
                              ),
                            );
                          },
                        ),
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
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
