import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login_page.dart';
import '../color/custom_color.dart';
import '../pages/feedback_page.dart';
import '../pages/profile_page.dart';

class StudentMobileDrawer extends StatelessWidget {
  const StudentMobileDrawer({
    super.key,
    required this.name,
    required this.email,
    required this.schoolId,
    required this.classId,
    required this.photo,
    required this.mobile,
    required this.username,
    required this.schoolName,
    required this.className,
  });

  final String schoolId;
  final String classId;
  final String name;
  final String email;
  final Uint8List photo;
  final String mobile;
  final String username;
  final String schoolName;
  final String className;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
            decoration: appbarDecoration,
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                photo.isNotEmpty
                    ? CircleAvatar(
                      radius: 40,
                      backgroundImage: MemoryImage(photo),
                    )
                    : const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, size: 50, color: Colors.indigo),
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
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    "Menu",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                _buildListTile(
                  context,
                  icon: Icons.person,
                  text: 'Profile',
                  page: ProfilePage(
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
                    }, username: username,
                  ),
                ),
                _buildListTile(
                  context,
                  icon: Icons.feedback,
                  text: 'Feedback',
                  page: FeedbackPage(username:username,schoolId: schoolId, classId: classId),
                ),
                const Divider(thickness: 1, indent: 16, endIndent: 16),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: ListTile(
              tileColor: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('role');
                await prefs.remove('username');
                await prefs.remove('rememberMe');

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String text,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(text),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
    );
  }
}
