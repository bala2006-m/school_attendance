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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('User not found')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Something went wrong.')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> sendOtp() async {
    otp = Random().nextInt(900000) + 100000;
    print("Generated OTP: $otp");

    setState(() {
      otpSent = true;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('OTP sent successfully! $otp')));
  }

  Future<void> fetchAdmin() async {
    adminData = await AdminApiService.fetchAdminData(username.text);
  }

  Future<void> fetchStaff() async {
    staffData = await TeacherApiServices.fetchStaffDataUsername(username.text);
  }

  Future<void> fetchStudent() async {
    studentData = await StudentApiServices.fetchStudentDataUsername(
      username.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF5F9),
      body: SingleChildScrollView(
        child: SafeArea(
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
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF2B7CA8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    topRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B7CA8),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white),
                      ),
                      child: TextField(
                        controller: username,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Enter your Username',
                          hintStyle: TextStyle(color: Colors.white70),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.white,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: isLoading ? null : () => init(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD6E3DC),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 80,
                          vertical: 15,
                        ),
                      ),
                      child:
                          isLoading
                              ? const CircularProgressIndicator()
                              : const Text("Send OTP"),
                    ),
                    const SizedBox(height: 20),
                    otpSent == true
                        ? Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2B7CA8),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white),
                              ),
                              child: TextField(
                                onChanged: (val) {
                                  if (val.length == 6) {
                                    if (otpController.text == otp.toString()) {
                                      setState(() {
                                        validOtp = true;
                                      });
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('OTP is incorrect'),
                                        ),
                                      );
                                    }
                                  }
                                },
                                maxLength: 6,
                                keyboardType: TextInputType.number,
                                controller: otpController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  counter: Offstage(),
                                  hintText: 'Enter your Username',
                                  hintStyle: TextStyle(color: Colors.white70),
                                  prefixIcon: Icon(
                                    Icons.confirmation_num,
                                    color: Colors.white,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        : const SizedBox(),
                    validOtp
                        ? Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2B7CA8),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white),
                          ),
                          child: TextField(
                            keyboardType: TextInputType.number,
                            controller: otpController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Enter your Password',
                              hintStyle: TextStyle(color: Colors.white70),
                              prefixIcon: Icon(
                                Icons.confirmation_num,
                                color: Colors.white,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 20,
                              ),
                            ),
                          ),
                        )
                        : SizedBox(),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Back to Login",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
