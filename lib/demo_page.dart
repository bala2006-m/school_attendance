import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'admin/pages/dashboard/admin_dashboard.dart';

class DemoIdsPage extends StatelessWidget {
  const DemoIdsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F6FB),
      body: Column(
        children: [
          const _Header(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: const [
                DemoIdCard(
                  title: 'ADMIN',
                  hospitalId: '1',
                  userId: '1',
                  password: 'abc123',
                  icon: Icons.admin_panel_settings,
                  color: Color(0xff6C63FF),
                ),
                DemoIdCard(
                  title: 'STAFF',
                  hospitalId: '1',
                  userId: '2',
                  password: 'abc123',

                  icon: Icons.person,
                  color: Color(0xff00A8A8),
                ),

                DemoIdCard(
                  title: 'STUDENT',
                  hospitalId: '1',
                  userId: '1001',
                  password: 'abc123',

                  icon: Icons.people,
                  color: Color(0xffE53935),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 25),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2B7CA8), Color(0xFF2B7CA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Text Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                    ),
                    const Text(
                      "Demo Accounts",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Text(
                  "Use these accounts to explore the hospital system.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          /// Decorative Icon / Illustration
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_circle_outlined,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }
}

class DemoIdCard extends StatelessWidget {
  final String hospitalId;
  final String title;
  final String userId;
  final String password;

  final IconData icon;
  final Color color;

  const DemoIdCard({
    super.key,
    required this.hospitalId,
    required this.title,
    required this.userId,
    required this.password,

    required this.icon,
    required this.color,
  });

  void copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget infoRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text("$label : $value", style: const TextStyle(fontSize: 14)),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => copy(context, value),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.copy, size: 18),
          ),
        ),
      ],
    );
  }

  Future<void> login({
    required String usernameController,
    required String schoolIdController,
    required String passwordController,
    required BuildContext context,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final enteredUsername = usernameController;
    final enteredPassword = passwordController;
    final schoolIdText = schoolIdController;

    // Validate inputs
    if (schoolIdText.isEmpty ||
        enteredUsername.isEmpty ||
        enteredPassword.isEmpty) {
      showError("Please fill in all fields", context);

      return;
    }

    final schoolId = int.tryParse(schoolIdText);
    if (schoolId == null) {
      showError("School ID must be a number", context);

      return;
    }

    try {
      final loginResult = await ApiService.login(
        username: enteredUsername,
        password: enteredPassword,
        schoolId: schoolId,
      );

      if (loginResult['status'] != 'success') {
        showError(
          loginResult['message'] ?? "Invalid user Id or password",
          context,
        );

        return;
      }

      final user = loginResult['user'];
      final foundRole = user['role'];

      // Save login info
      await prefs.setString('role', foundRole);
      await prefs.setBool('rememberMe', false);
      await prefs.setString('username', user['username']);
      await prefs.setString('schoolId', '$schoolId');

      // Trigger sync after successful login (only for admin and staff)
      if (foundRole == 'admin' || foundRole == 'staff') {
        try {
          await ApiService.triggerInitialSync(
            schoolId: schoolId,
            userId: user['username'].toString(),
          );
        } catch (e) {
          // Log error but don't block login
          debugPrint('Sync trigger failed: $e');
        }
      }

      // Navigate by role
      switch (foundRole) {
        case 'student':
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (_) => StudentDashboard(
                      username: user?['username'],
                      schoolId: schoolId,
                    ),
              ),
            );
          }
          break;
        case 'staff':
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => StaffDashboard(
                      username: user!['username'].toString(),
                      schoolId: '$schoolId',
                    ),
              ),
            );
          }
          break;
        case 'admin':
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => AdminDashboard(
                      username: user?['username'],
                      schoolId: '${user?['school_id']}',
                    ),
              ),
            );
          }
          break;
        // case 'administrator':
        //   if (mounted) {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder:
        //             (_) => AdministratorDashboard(userName: user?['username']),
        //       ),
        //     );
        //   }
        //   break;
      }
    } catch (e) {
      showError("Login failed. Please try again. $e", context);
      print("Login failed. Please try again. $e");
    }
  }

  void showError(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          /// Top color strip
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "DEMO",
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Divider(height: 22),

                infoRow(context, "School ID", hospitalId),
                infoRow(context, "User ID", userId),
                infoRow(context, "Password", password),

                const SizedBox(height: 10),

                /// Login Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      // Navigator.pop(context, {
                      //   "hospitalId": hospitalId,
                      //   "userId": userId,
                      //   "password": password,
                      // });
                      login(
                        usernameController: userId,
                        schoolIdController: hospitalId,
                        passwordController: password,
                        context: context,
                      );
                    },
                    child: const Text(
                      "Use This Account",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
