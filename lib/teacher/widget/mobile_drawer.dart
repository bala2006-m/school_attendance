import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login_page.dart';
import '../pages/edit_profile_screen.dart';
import '../pages/staff_profile_screen.dart';

class MobileDrawer extends StatelessWidget {
  const MobileDrawer({super.key, required this.name, required this.username, this.photo, this.schoolName, this.schoolAddress, this.mobile, this.email, this.classId, this.schoolId});

  final String name;
  final String username;
  final Uint8List? photo;
  final String? schoolName;
  final String? schoolAddress;
  final String? mobile;
  final String? email;
  final String? classId;
  final String? schoolId;
  static int selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Drawer(

      shape: const RoundedRectangleBorder(
        side: BorderSide(color: Colors.black12, width: 6),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),width: MediaQuery.sizeOf(context).width / 1.5,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF2B7CA8)),
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              height: 150, // You can adjust this
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  photo != null
                      ? CircleAvatar(radius: 30, backgroundImage: MemoryImage(photo!))
                      : const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Welcome, $name',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('My Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => StaffProfileScreen(username: username),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfileScreen(username: username),
                ),
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ListTile(
              tileColor: Colors.red.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
              onTap: () {
                final rootContext =
                    Navigator.of(context, rootNavigator: true).context;

                Navigator.pop(context); // Close drawer

                Future.delayed(const Duration(milliseconds: 200), () {
                  showDialog(
                    context: rootContext,
                    builder: (BuildContext dialogContext) {
                      return AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text(
                          'Are you sure you want to log out?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              Navigator.pop(dialogContext);

                              SharedPreferences prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.remove('role');
                              await prefs.remove('username');
                              await prefs.remove('rememberMe');

                              Navigator.pushAndRemoveUntil(
                                rootContext,
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                                (route) => false,
                              );
                            },
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                });
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
