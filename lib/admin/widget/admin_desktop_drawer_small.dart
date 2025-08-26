import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login_page.dart';
import '../../teacher/color/teacher_custom_color.dart' as AdminCustomColor;
import '../pages/admin_dashboard.dart';
import '../pages/edit_profile.dart';
import '../pages/profile.dart';

class AdminDesktopDrawerSmall extends StatelessWidget {
  const AdminDesktopDrawerSmall({
    super.key,
    required this.width,
    required this.height,
    required this.username,
    required this.name,
    required this.designation,
    this.photo,
    required this.schoolName,
    required this.schoolAddress,
    required this.mobileNumber,
    required this.schoolId,
  });

  final double width;
  final double height;
  final String username;
  final String name;
  final String designation;
  final Image? photo;
  final String schoolName;
  final String schoolAddress;
  final String mobileNumber;
  final String schoolId;
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        width: width,
        height: MediaQuery.sizeOf(context).height / 1.6,
        decoration: BoxDecoration(
          color: AdminCustomColor.appbar,
          borderRadius: BorderRadius.circular(12),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                "Menu",
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
              const SizedBox(height: 20),

              _buildMenuButton(
                context,
                label: 'Profile',
                padding: const EdgeInsets.symmetric(
                  horizontal: 37,
                  vertical: 10,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => Profile(
                            username: username,
                            schoolName: schoolName,
                            schoolAddress: schoolAddress,
                            schoolId: schoolId,
                          ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              _buildMenuButton(
                context,
                label: 'Edit Profile',
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => EditProfile(
                            username: username,
                            schoolName: schoolName,
                            schoolAddress: schoolAddress,
                            schoolId: schoolId,
                            onBack: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => AdminDashboard(
                                        schoolId: schoolId,
                                        username: username,
                                      ),
                                ),
                              );
                            },
                          ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              _buildMenuButton(
                context,
                label: 'Logout',
                padding: const EdgeInsets.symmetric(
                  horizontal: 33,
                  vertical: 10,
                ),
                textColor: Colors.red,
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.remove('role');
                  await prefs.remove('username');
                  await prefs.remove('rememberMe');

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required EdgeInsets padding,
    required VoidCallback onPressed,
    Color textColor = const Color(0xFF1565C0), // default appbar color
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 18)),
    );
  }
}
