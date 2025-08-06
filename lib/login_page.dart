import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/admin_dashboard.dart';
import 'package:school_attendance/administrator/pages/dashboard.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  bool _obscurePassword = true;
  bool isLoading = false;

  Future<void> login() async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final enteredUsername = _usernameController.text.trim();
    final enteredPassword = _passwordController.text.trim();

    if (enteredUsername.isEmpty || enteredPassword.isEmpty) {
      showError("Please enter both username and password");
      setState(() => isLoading = false);
      return;
    }

    try {
      List<String> roles = ['student', 'staff', 'admin', 'administrator'];
      Map<String, dynamic>? user;
      String foundRole = '';

      for (String role in roles) {
        final users = await ApiService.getUsersByRole(role);
        user = users.firstWhere(
          (u) => u['username'].toString() == enteredUsername,
          orElse: () => null,
        );

        if (user != null) {
          foundRole = role;
          break;
        }
      }

      if (user == null) {
        showError("Invalid username or password");
        return;
      }

      final hashedPassword = user['password'].toString();
      final isPasswordValid = BCrypt.checkpw(enteredPassword, hashedPassword);

      if (!isPasswordValid) {
        showError("Invalid username or password");
        return;
      }

      await prefs.setString('role', foundRole);
      await prefs.setBool('rememberMe', true);
      await prefs.setString('username', user['username']);

      switch (foundRole) {
        case 'student':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentDashboard(username: user!['username']),
            ),
          );
          break;
        case 'staff':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StaffDashboard(username: user!['username']),
            ),
          );
          break;
        case 'admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AdminDashboard(
                    username: user!['username'],
                    schoolId: '${user['school_id']}',
                  ),
            ),
          );
          break;
        case 'administrator':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AdministratorDashboard(
                    schoolId: '',
                    name: '',
                    address: '',
                    photo: Uint8List(1),
                  ),
            ),
          );
          break;
      }
    } catch (e) {
      showError("Error during login: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        exit(0);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2B7CA8),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person, color: Colors.white),
                        hintText: 'Username',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock, color: Colors.white),
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 20,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Colors.white,
                    ),
                    child: TextButton(
                      onPressed: isLoading ? null : login,
                      child:
                          isLoading
                              ? const SpinKitFadingCircle(
                                color: Colors.blueAccent,
                                size: 50.0,
                              )
                              : const Text(
                                'Login',
                                style: TextStyle(
                                  color: Color(0xFF2B7CA8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("Or", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Copyright © 2025 Ramchin Technologies Private Limited',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
