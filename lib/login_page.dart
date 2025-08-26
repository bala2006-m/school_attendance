import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/admin_dashboard.dart';
import 'package:school_attendance/administrator/pages/dashboard.dart';
import 'package:school_attendance/administrator/services/administrator_api_service.dart';
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
  final TextEditingController _schoolIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  bool _obscurePassword = true;
  bool isLoading = false;
  bool rememberMe = true;
  bool isBlocked = false;
  String? reason;
  bool _isFormValid = false;

  /// Validate if form is complete and school is not blocked
  void _validateForm() {
    final schoolIdText = _schoolIdController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final isFilled =
        schoolIdText.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

    setState(() {
      _isFormValid = isFilled && !isBlocked;
    });
  }

  Future<void> _checkBlocked(int schoolId) async {
    try {
      final result = await AdministratorApiService.isSchoolBlocked(schoolId);

      setState(() {
        isBlocked = result['isBlocked'] ?? false;
        reason = result['reason'];
      });

      if (isBlocked) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('School Blocked'),
                content: Text(reason ?? "This school is blocked."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() {
        isBlocked = false;
      });
    } finally {
      _validateForm(); // recheck validity after block check
    }
  }

  Future<void> login() async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final enteredUsername = _usernameController.text.trim();
    final enteredPassword = _passwordController.text.trim();
    final schoolIdText = _schoolIdController.text.trim();

    // Validate inputs
    if (schoolIdText.isEmpty ||
        enteredUsername.isEmpty ||
        enteredPassword.isEmpty) {
      showError("Please fill in all fields");
      setState(() => isLoading = false);
      return;
    }

    final schoolId = int.tryParse(schoolIdText);
    if (schoolId == null) {
      showError("School ID must be a number");
      setState(() => isLoading = false);
      return;
    }

    try {
      List<String> roles = ['student', 'staff', 'admin', 'administrator'];
      Map<String, dynamic>? user;
      String foundRole = '';

      for (String role in roles) {
        final users = await ApiService.getUsersByRole(
          role: role,
          schoolId: schoolId,
        );
        user = users.cast<Map<String, dynamic>?>().firstWhere(
          (u) => u?['username']?.toString() == enteredUsername,
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

      // Save login info
      await prefs.setString('role', foundRole);
      await prefs.setBool('rememberMe', rememberMe);
      await prefs.setString('username', user['username']);
      await prefs.setInt('schoolId', schoolId);

      // Navigate by role
      switch (foundRole) {
        case 'student':
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
          break;
        case 'staff':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => StaffDashboard(
                    username: user?['username'],
                    schoolId: '$schoolId',
                  ),
            ),
          );
          break;
        case 'admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AdminDashboard(
                    username: user?['username'],
                    schoolId: '${user?['school_id']}',
                  ),
            ),
          );
          break;
        case 'administrator':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (_) => AdministratorDashboard(userName: user?['username']),
            ),
          );
          break;
      }
    } catch (e) {
      showError("Login failed. Please try again. $e");
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
    return Scaffold(
      backgroundColor: const Color(0xFF2B7CA8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.jpg', height: 100, width: 100),
                const SizedBox(height: 50),

                // School ID
                _buildInputField(
                  controller: _schoolIdController,
                  hint: "School ID",
                  icon: Icons.school,
                  inputType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Username
                _buildInputField(
                  controller: _usernameController,
                  hint: "Username",
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),

                // Password
                _buildInputField(
                  controller: _passwordController,
                  hint: "Password",
                  icon: Icons.lock,
                  obscure: _obscurePassword,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Remember Me
                Row(
                  children: [
                    Checkbox(
                      value: rememberMe,
                      activeColor: Colors.white,
                      checkColor: const Color(0xFF2B7CA8),
                      onChanged: (value) {
                        setState(() {
                          rememberMe = value ?? true;
                        });
                      },
                    ),
                    const Text(
                      "Remember Me",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Login Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color:
                        _isFormValid
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                  ),
                  child: TextButton(
                    onPressed: (_isFormValid && !isLoading) ? login : null,
                    child:
                        isLoading
                            ? const SpinKitFadingCircle(
                              color: Colors.blueAccent,
                              size: 40.0,
                            )
                            : Text(
                              'Login',
                              style: TextStyle(
                                color:
                                    _isFormValid
                                        ? const Color(0xFF2B7CA8)
                                        : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text("Or", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 8),

                // Forgot Password
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
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        onChanged: (val) async {
          if (hint == "School ID") {
            final schoolId = int.tryParse(val);
            if (schoolId != null) {
              await _checkBlocked(schoolId);
            }
          }
          _validateForm();
        },
        controller: controller,
        obscureText: obscure,
        keyboardType: inputType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white70),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20,
          ),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
