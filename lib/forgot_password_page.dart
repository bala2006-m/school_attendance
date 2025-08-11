import 'dart:math';

import 'package:flutter/material.dart';
import 'package:school_attendance/admin/services/admin_api_service.dart';
import 'package:school_attendance/services/api_service.dart';
import 'package:school_attendance/student/services/student_api_services.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  TextEditingController username = TextEditingController();
  TextEditingController otpController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String email = '';
  Map<String, dynamic>? adminData;
  Map<String, dynamic>? staffData;
  Map<String, dynamic>? studentData;

  int otp = 000000;
  bool otpSent = false;
  bool isLoading = false;
  bool validOtp = false;

  Future<void> init() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      List<String> roles = ['student', 'staff', 'admin', 'administrator'];
      Map<String, dynamic>? user;
      String foundRole = '';

      for (String role in roles) {
        final users = await ApiService.getUsersByRole(role);
        user = users.firstWhere(
          (u) => u['username'].toString() == username.text,
          orElse: () => null,
        );

        if (user != null) {
          foundRole = role;
          break;
        }
      }

      if (user == null) {
        showSnackBar('User not found');
        return;
      }

      switch (foundRole) {
        case 'student':
          await fetchStudent();
          break;
        case 'staff':
          await fetchStaff();
          break;
        case 'admin':
          await fetchAdmin();
          break;
      }

      await sendOtp();
    } catch (e) {
      print('Error during init: $e');
      showSnackBar('Something went wrong.');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updatePassword() async {
    if (isLoading) return;
    final res = await ApiService.updatePassword(
      username: username.text,
      password: passwordController.text,
    );
    if (res['status'] == 'success') {
      showSnackBar('Password updated successfully!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      showSnackBar('Password update failed');
    }
  }

  Future<void> sendOtp() async {
    otp = Random().nextInt(900000) + 100000;
    print(email);
    final response = await ApiService.sendOtp(email: email, otp: '$otp');
    setState(() => otpSent = true);

    if (response['status'] == 'success') {
      showSnackBar('OTP sent successfully!');
    } else {
      showSnackBar('Failed to send OTP');
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> fetchAdmin() async {
    adminData = await AdminApiService.fetchAdminData(username.text);
    setState(() => email = adminData?['email'] ?? '');
  }

  Future<void> fetchStaff() async {
    staffData = await TeacherApiServices.fetchStaffDataUsername(username.text);
    setState(() => email = staffData?['email'] ?? '');
  }

  Future<void> fetchStudent() async {
    studentData = await StudentApiServices.fetchStudentDataUsername(
      username.text,
    );
    setState(() => email = studentData?['email'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Color(0xFF2B7CA8),
              ),
              const SizedBox(height: 20),
              const Text(
                'Forgot\nPassword?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2B7CA8),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'No worries, we’ll send you\nreset instructions',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF2B7CA8)),
              ),
              const SizedBox(height: 40),

              /// Username
              buildInputField(
                controller: username,
                hint: 'Enter your Username',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              /// Send OTP
              ElevatedButton(
                onPressed: isLoading ? null : () => init(),
                style: elevatedButtonStyle(),
                child:
                    isLoading
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text("Sending OTP..."),
                          ],
                        )
                        : const Text("Send OTP"),
              ),
              const SizedBox(height: 30),

              /// OTP Field
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    otpSent
                        ? Column(
                          key: const ValueKey('otpField'),
                          children: [
                            buildInputField(
                              controller: otpController,
                              hint: 'Enter OTP',
                              icon: Icons.confirmation_num_outlined,
                              maxLength: 6,
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                if (val.length == 6) {
                                  if (val == otp.toString()) {
                                    setState(() => validOtp = true);
                                  } else {
                                    showSnackBar('OTP is incorrect');
                                  }
                                }
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),

              /// Password Field
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child:
                    validOtp
                        ? Column(
                          key: const ValueKey('passwordField'),
                          children: [
                            PasswordInputField(controller: passwordController),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: updatePassword,
                              style: elevatedButtonStyle(),
                              child: const Text("Update Password"),
                            ),
                          ],
                        )
                        : const SizedBox.shrink(),
              ),

              const SizedBox(height: 30),
              TextButton(
                onPressed:
                    () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                child: const Text(
                  "Back to Login",
                  style: TextStyle(color: Colors.black87),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Reusable Input Field
  Widget buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        counterText: "",
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        prefixIcon: Icon(icon),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  /// Reusable Button Style
  ButtonStyle elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2B7CA8),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
    );
  }
}

/// Password Input with Visibility Toggle
class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  const PasswordInputField({super.key, required this.controller});

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: isObscured,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Enter new Password',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => isObscured = !isObscured),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
