import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/dashboard/admin_dashboard.dart';
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
  bool rememberMe = false;
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

      if (isBlocked && mounted) {
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
      final loginResult = await ApiService.login(
        username: enteredUsername,
        password: enteredPassword,
        schoolId: schoolId,
      );

      if (loginResult['status'] != 'success') {
        showError(loginResult['message'] ?? "Invalid user Id or password");
        setState(() => isLoading = false);
        return;
      }

      final user = loginResult['user'];
      final foundRole = user['role'];


      // Save login info
      await prefs.setString('role', foundRole);
      await prefs.setBool('rememberMe', rememberMe);
      await prefs.setString('username', user['username']);
      await prefs.setInt('schoolId', schoolId);

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
          if (mounted) {
            Navigator.push(
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
          if (mounted) {
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
          if (mounted) {
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
        case 'administrator':
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => AdministratorDashboard(userName: user?['username']),
              ),
            );
          }
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2B7CA8), Color(0xFF4FAFD6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center, // 👈 Centers vertically
                  children: [
                    // 🏫 Logo
                    AnimatedOpacity(
                      duration: const Duration(seconds: 1),
                      opacity: 1.0,
                      child: Column(
                        children: [
                          // const SizedBox(height: 12),
                          // Image.asset(
                          //   'assets/favicon.png',
                          //   height: 100,
                          //   fit: BoxFit.contain,
                          // ),
                          const SizedBox(height: 12),
                          SizedBox(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                textAlign: TextAlign.center,
                                softWrap: true,
                                'Smart School App',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Good Times',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 👇 Centered Login Box
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 80,
                            color: Color(0xFF2B7CA8),
                          ),
                          SizedBox(height: 10),
                          const Text(
                            "Welcome",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 20),
                          _buildInputField(
                            controller: _schoolIdController,
                            hint: "School ID",
                            icon: Icons.school,
                            inputType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          _buildInputField(
                            controller: _usernameController,
                            hint: "User ID",
                            icon: Icons.person,
                          ),
                          const SizedBox(height: 16),
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
                                color: const Color(0xFF2B7CA8),
                              ),
                              onPressed:
                                  () => setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  }),
                            ),
                          ),
                          const SizedBox(height: 20),

                          Row(
                            children: [
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Forgot Password?",
                                  style: TextStyle(color: Color(0xFF2B7CA8)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _isFormValid
                                        ? const Color(0xFF2B7CA8)
                                        : Colors.grey,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed:
                                  (_isFormValid && !isLoading) ? login : null,
                              child:
                                  isLoading
                                      ? const SpinKitThreeBounce(
                                        color: Colors.white,
                                        size: 20,
                                      )
                                      : Text(
                                        'Login',
                                        style: TextStyle(
                                          color:
                                              _isFormValid
                                                  ? Colors.white
                                                  : Colors.grey,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),

                    Text(
                      '© ${DateTime.now().year.toString()} Ramchin Technologies Pvt. Ltd.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
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
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(20),
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
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF2B7CA8)),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black),
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
