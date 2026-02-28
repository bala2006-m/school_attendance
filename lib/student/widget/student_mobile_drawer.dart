import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login_page.dart';
import '../../services/api_service.dart';
import '../color/custom_color.dart';
import '../pages/change_password.dart';
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
    required this.onSave,
    required this.community,
    required this.fatherName,
    required this.dob,
    required this.route,
    required this.gender,
    required this.address,
    required this.joinDate,
  });
  final VoidCallback onSave;
  final String schoolId;
  final String classId;
  final String name;
  final String email;
  final Uint8List photo;
  final String mobile;
  final String username;
  final String schoolName;
  final String className;
  final String community;
  final String fatherName;
  final String dob;
  final String route;
  final String gender;
  final String address;
  final String joinDate;
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
                  username,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
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
                      "community": community,
                      "father_name": fatherName,
                      "DOB": dob,
                      "route": route,
                      "gender": gender,
                      "address": address,
                      "date_of_join": joinDate,
                    },
                    username: username,
                    schoolId: int.parse(schoolId),
                  ),
                ),
                // _buildListTile(
                //   context,
                //   icon: Icons.edit_note,
                //   text: 'Edit Profile',
                //   page: EditProfile(
                //     username: username,
                //     onSave: onSave,
                //     schoolId: int.parse(schoolId),
                //   ),
                // ),
                _buildListTile(
                  context,
                  icon: Icons.edit,
                  text: 'Change Password',
                  page: EditPassword(
                    username: username,
                    schoolId: int.parse(schoolId),
                  ),
                ),
                // _buildListTile(
                //   context,
                //   icon: Icons.feedback,
                //   text: 'Feedback',
                //   page: FeedbackPage(
                //     username: username,
                //     schoolId: schoolId,
                //     classId: classId,
                //   ),
                // ),
                const Divider(thickness: 1, indent: 16, endIndent: 16),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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

                  final String? userRole = prefs.getString('role');

                  // Trigger logout sync before clearing preferences (only for admin and staff)
                  if (userRole == 'admin' || userRole == 'staff') {
                    try {
                      await ApiService.triggerUserLogout(
                        schoolId: int.parse(schoolId),
                        userId: username,
                      );
                    } catch (e) {
                      // Log error but don't block logout
                      debugPrint('Logout sync failed: $e');
                    }
                  }

                  await prefs.remove('role');
                  await prefs.remove('username');
                  await prefs.remove('rememberMe');
                  await prefs.clear();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
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
