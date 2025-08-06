import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login_page.dart';
import '../../teacher/color/teacher_custom_color.dart' as AdminCustomColor;
import '../pages/edit_profile.dart';
import '../pages/profile.dart';

class AdminDesktopDrawer extends StatelessWidget {
  const AdminDesktopDrawer({
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
    final screen = MediaQuery.sizeOf(context);
    final width1 = screen.width;
    final height1 = screen.height;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AdminCustomColor.appbar,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AdminCustomColor.appbar, AdminCustomColor.appbar],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: width / 2,
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AdminCustomColor.appbar, Colors.blue.shade800],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Menu',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 50),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundColor: AdminCustomColor.appbar,
              padding: EdgeInsets.symmetric(horizontal: 37, vertical: 10),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => Profile(
                        username: username,
                        schoolName: schoolName,
                        schoolAddress: schoolAddress,
                        schoolId: schoolId,
                      ),
                ),
              );
            },
            child: Text('Profile', style: TextStyle(fontSize: 18)),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundColor: AdminCustomColor.appbar,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => EditProfile(
                        username: username,
                        schoolName: schoolName,
                        schoolAddress: schoolAddress,
                        schoolId: schoolId,
                      ),
                ),
              );
            },
            child: Text('Edit Profile', style: TextStyle(fontSize: 18)),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              foregroundColor: AdminCustomColor.appbar,
              padding: EdgeInsets.symmetric(horizontal: 33, vertical: 10),
            ),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('role');
              await prefs.remove('username');

              await prefs.remove('rememberMe');

              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(fontSize: 20, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
