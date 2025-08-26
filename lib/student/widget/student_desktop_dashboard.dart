import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login_page.dart';
import '../color/custom_color.dart';
import '../pages/attendance_page.dart';
import '../pages/feedback_page.dart';
import '../pages/holiday_page.dart';
import '../pages/profile_page.dart';
import '../pages/timetable_page.dart';

class StudentDesktopDashboard extends StatelessWidget {
  const StudentDesktopDashboard({
    super.key,
    required this.username,
    required this.name,
    required this.email,
    required this.schoolId,
    required this.classId,
    required this.gender,
    required this.photo,
    required this.mobile,
    required this.schoolName,
    required this.className,
    required this.Message,
    required this.SchoolAddress,
    required this.SchoolPhoto,
  });

  final String username;
  final String name;
  final String email;
  final String schoolId;
  final String classId;
  final String gender;
  final Uint8List photo;
  final String mobile;
  final String schoolName;
  final String className;
  final String Message;
  final String SchoolAddress;
  final Image? SchoolPhoto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 50),
          // Left Sidebar
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.indigo,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 30,
                    horizontal: 16,
                  ),
                  decoration: appbarDecoration,
                  child: Column(
                    children: [
                      photo.isNotEmpty
                          ? CircleAvatar(
                            radius: 40,
                            backgroundImage: MemoryImage(photo),
                          )
                          : const CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.indigo,
                            ),
                          ),
                      const SizedBox(height: 10),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Menu List
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8,
                        ),
                        child: Text(
                          "Menu",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      _menuItem(
                        context,
                        Icons.person,
                        'Profile',
                        ProfilePage(
                          userData: {
                            "name": name,
                            "email": email,
                            "phone": mobile,
                            "department": "Class $classId",
                            "rollNumber": username,
                            "role": "Student",
                            "schoolName": schoolName,
                            "className": className,
                            "photo": photo,
                          },
                          username: username,
                          schoolId: int.parse(schoolId),
                        ),
                      ),
                      _menuItem(
                        context,
                        Icons.feedback,
                        'Feedback',
                        FeedbackPage(
                          username: username,
                          schoolId: schoolId,
                          classId: classId,
                        ),
                      ),
                      const Divider(
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),

                // Logout
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ListTile(
                    tileColor: Colors.red.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      await prefs.remove('role');
                      await prefs.remove('username');

                      await prefs.remove('rememberMe');
                      await prefs.clear();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          // Right Dashboard Tiles
          Expanded(
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
                    schoolPhoto: SchoolPhoto,
                    schoolName: schoolName,
                    schoolAddress: SchoolAddress,
                    message: Message,
                  ),
                ),
                const SizedBox(height: 20),
                dashboardTile(
                  context: context,
                  icon: Icons.calendar_today,
                  title: 'Timetable',
                  page: TimeTablePage(
                    username: username,
                    schoolId: schoolId,
                    classId: classId,
                  ),
                ),
                const SizedBox(height: 20),
                dashboardTile(
                  context: context,
                  icon: Icons.beach_access,
                  title: 'Holidays',
                  page: HolidayPage(
                    username: username,
                    classId: classId,
                    schoolId: schoolId,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Menu Items
  Widget _menuItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget page,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () => navigateTo(context, page),
    );
  }

  // Dashboard Tile Widget
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
          mainAxisAlignment: MainAxisAlignment.start,
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
