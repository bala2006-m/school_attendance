import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../services/admin_api_service.dart';

class AdminRegistrationMobile extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController designationController;
  final TextEditingController mobileController;
  final TextEditingController countryCodeController;
  final FocusNode usernameFocus;
  final FocusNode passwordFocus;
  final FocusNode mobileFocus;
  final FocusNode countryCodeFocus;
  final bool isMobile;
  final String schoolId;
  final VoidCallback onRegistered;

  const AdminRegistrationMobile({
    super.key,
    required this.usernameController,
    required this.passwordController,
    required this.designationController,
    required this.mobileController,
    required this.countryCodeController,
    required this.usernameFocus,
    required this.passwordFocus,
    required this.mobileFocus,
    required this.countryCodeFocus,
    required this.isMobile,
    required this.schoolId,
    required this.onRegistered,
  });

  @override
  State<AdminRegistrationMobile> createState() =>
      _AdminRegistrationMobileState();
}

class _AdminRegistrationMobileState extends State<AdminRegistrationMobile> {
  List<String> adminMobiles = [];
  List<dynamic> admins = [];
  List<dynamic> staffs = [];
  List<dynamic> students = [];
  List<dynamic> administrators = [];
  bool fillUsername = false;
  bool fillPass = false;
  bool fillMobile = false;
  bool fillCountry = true;
  bool obscureText = true;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.usernameFocus.requestFocus();
    });
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      admins = await ApiService.getUsersByRole('admin');
      staffs = await ApiService.getUsersByRole('staff');
      students = await ApiService.getUsersByRole('student');
      administrators = await ApiService.getUsersByRole('administrator');

      List<Future<Map<String, dynamic>?>> futures =
          admins
              .map((user) => AdminApiService.fetchAdminData(user['username']))
              .toList();

      List<Map<String, dynamic>?> results = await Future.wait(futures);

      for (var adminData in results) {
        final mobile = adminData?['mobile'];
        if (mobile != null) {
          adminMobiles.add(mobile);
        }
      }
    } catch (e) {
      showSnackBar('Failed to load admin data', isError: true);
    }
  }

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : CupertinoColors.systemGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFiled =
        fillUsername &&
        fillPass &&
        fillMobile &&
        widget.countryCodeController.text.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.white,
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildAnimatedField(
                        label: 'Username',
                        controller: widget.usernameController,
                        focusNode: widget.usernameFocus,
                        onFocus: () {},
                      ),
                      const SizedBox(height: 16),
                      buildAnimatedField(
                        label: 'Password',
                        hintText: 'At least 6 Characters',
                        controller: widget.passwordController,
                        focusNode: widget.passwordFocus,
                        isPassword: true,
                        obscureText: obscureText,
                        toggleObscure: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                        onFocus: () {},
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: buildAnimatedField(
                              label: widget.isMobile ? 'Code' : 'Country Code',
                              controller: widget.countryCodeController,
                              focusNode: widget.countryCodeFocus,
                              keyboardType: TextInputType.phone,
                              onFocus: () {},
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: buildAnimatedField(
                              label: 'Mobile Number',
                              controller: widget.mobileController,
                              focusNode: widget.mobileFocus,
                              keyboardType: TextInputType.phone,
                              isMobileNumber: true,
                              onFocus: () {},
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      submitButton(isFiled),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget submitButton(bool isFiled) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isFiled ? Colors.blueAccent : Colors.grey,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed:
          isFiled
              ? () async {
                final username = widget.usernameController.text.trim();
                final password = widget.passwordController.text.trim();
                final designation = widget.designationController.text.trim();

                if (password.length < 6) {
                  showSnackBar(
                    'Password must be at least 6 characters',
                    isError: true,
                  );
                  return;
                }

                String mobileNumber = widget.mobileController.text.trim();
                String countryCode = widget.countryCodeController.text.trim();
                if (!countryCode.startsWith('+')) {
                  countryCode = '+$countryCode';
                }
                String fullMobileNumber = '$countryCode$mobileNumber';

                if (!RegExp(
                  r'^\+\d{1,3}\d{4,14}$',
                ).hasMatch(fullMobileNumber)) {
                  showSnackBar(
                    'Invalid mobile number format. Include a valid country code (e.g., +91).',
                    isError: true,
                  );
                  return;
                }

                final result = await ApiService.registerUser(
                  username: username,
                  password: password,
                  role: 'admin',
                  school_id: widget.schoolId,
                );
                print(result);
                final res = await ApiService.registerUserDesignation(
                  username: username,
                  designation: designation,
                  school_id: widget.schoolId,
                  mobile: fullMobileNumber,
                  table: 'admin',
                );
                print(res);
                if (result['success'] && res['success']) {
                  showSnackBar(result['message']);
                  widget.usernameController.clear();
                  widget.passwordController.clear();
                  widget.mobileController.clear();
                  FocusScope.of(context).requestFocus(widget.usernameFocus);
                  init();
                  setState(() {
                    fillUsername = false;
                    fillPass = false;
                    fillMobile = false;
                    fillCountry = true;
                  });
                  widget.onRegistered();
                } else {
                  showSnackBar('Error: ${result['error']}', isError: true);
                }
              }
              : null,
      child: const Text('Register', style: TextStyle(fontSize: 18)),
    );
  }

  Widget buildAnimatedField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool isPassword = false,
    bool obscureText = false,
    void Function()? toggleObscure,
    TextInputType? keyboardType,
    bool isMobileNumber = false,
    String hintText = '',
    required void Function() onFocus,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focusNode.hasFocus ? Colors.blue : Colors.grey.shade400,
          width: focusNode.hasFocus ? 2 : 1,
        ),
        boxShadow:
            focusNode.hasFocus
                ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
                : [],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onTap: onFocus,
              onChanged: (val) {
                final trimmedVal = val.trim();
                if (label == 'Username') {
                  bool exists =
                      admins.any((user) => user['username'] == trimmedVal) ||
                      staffs.any((user) => user['username'] == trimmedVal) ||
                      students.any((user) => user['username'] == trimmedVal) ||
                      administrators.any(
                        (user) => user['username'] == trimmedVal,
                      );
                  if (exists) {
                    showSnackBar('Username already exists', isError: true);
                    fillUsername = false;
                  } else {
                    fillUsername = trimmedVal.isNotEmpty;
                  }
                }

                if (label == 'Password') {
                  fillPass = trimmedVal.length >= 6;
                }

                if (label == 'Mobile Number') {
                  fillMobile = trimmedVal.length == 10;
                  String country = widget.countryCodeController.text.trim();
                  if (!country.startsWith('+')) {
                    country = '+$country';
                  }
                  String full = '$country$trimmedVal';

                  if (adminMobiles.contains(full)) {
                    showSnackBar('Mobile number already exists', isError: true);
                    fillMobile = false;
                  }
                }

                if (label == 'Country Code' || label == 'Code') {
                  fillCountry = trimmedVal.isNotEmpty;
                }

                setState(() {});
              },

              maxLength: isMobileNumber ? 10 : 50,
              controller: controller,
              focusNode: focusNode,
              obscureText: isPassword && obscureText,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                labelText: label,
                hint: Text(
                  hintText,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
                counterText: '',
                border: InputBorder.none,
                labelStyle: const TextStyle(fontSize: 18),
              ),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          if (isPassword)
            IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
                size: 24,
              ),
              onPressed: toggleObscure,
            ),
        ],
      ),
    );
  }
}
