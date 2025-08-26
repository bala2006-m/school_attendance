import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login_page.dart';
import '../pages/edit_password.dart';

class MobileDrawer extends StatelessWidget {
  const MobileDrawer({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final int schoolId;

  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Colors.black12, width: 6),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),

      width: MediaQuery.sizeOf(context).width / 1.5,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: const Color(0xFF2B7CA8)),
            child: const Center(
              child: Text(
                'Menu',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text(
              'Change Password',
              style: TextStyle(fontSize: 18),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          EditPassword(username: username, schoolId: schoolId),
                ),
              );
            },
          ),
          // ListTile(
          //   leading: const Icon(Icons.edit),
          //   title: const Text('Edit Profile', style: TextStyle(fontSize: 18)),
          // onTap: () {
          //   Navigator.pop(context); // Close drawer
          //   Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //       builder:
          //           (_) => EditProfile(
          //         username: username,
          //         schoolName: schoolName,
          //         schoolAddress: schoolAddress,
          //         schoolId: schoolId,
          //       ),
          //     ),
          //   );
          // },
          //),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: InkWell(
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pop(context); // Close drawer
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
