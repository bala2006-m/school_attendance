import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class StaffRegistrationDesktop extends StatefulWidget {
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController designationController;
  final TextEditingController mobileController;
  final TextEditingController countryCodeController;
  final FocusNode usernameFocus;
  final FocusNode passwordFocus;
  final FocusNode mobileFocus;
  final FocusNode countryCodeFocus;
  final String schoolId;
  final VoidCallback onRegistered;

  const StaffRegistrationDesktop({
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
    required this.schoolId,
    required this.onRegistered,
  });

  @override
  State<StaffRegistrationDesktop> createState() =>
      _StaffRegistrationDesktopState();
}

class _StaffRegistrationDesktopState extends State<StaffRegistrationDesktop> {
  bool obscureText = true;
  List<dynamic> admins = [];
  List<dynamic> staffs = [];
  List<dynamic> students = [];
  List<dynamic> administrators = [];

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  Future<void> _loadAllUsers() async {
    admins = await ApiService.getUsersByRole(
      role: 'admin',
      schoolId: int.parse(widget.schoolId),
    );
    staffs = await ApiService.getUsersByRole(
      role: 'staff',
      schoolId: int.parse(widget.schoolId),
    );
    students = await ApiService.getUsersByRole(
      role: 'student',
      schoolId: int.parse(widget.schoolId),
    );
    administrators = await ApiService.getUsersByRole(
      role: 'administrator',
      schoolId: int.parse(widget.schoolId),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Center(
        child: Container(
          height: MediaQuery.of(context).size.height,
          alignment: Alignment.center,
          child: Container(
            width: screenWidth * 0.5,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(blurRadius: 12, color: Colors.black12),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 50),
                Row(
                  children: [
                    Expanded(
                      child: buildInputField(
                        label: 'Username',
                        controller: widget.usernameController,
                        focusNode: widget.usernameFocus,
                        onChanged: (val) {
                          final trimmed = val.trim();
                          final exists = _usernameExists(trimmed);
                          if (exists) {
                            _showSnackBar(
                              'Username already exists',
                              isError: true,
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildInputField(
                        label: 'Password',
                        hintText: "At least 6 Characters",
                        controller: widget.passwordController,
                        focusNode: widget.passwordFocus,
                        isPassword: true,
                        obscureText: obscureText,
                        toggleObscure: () {
                          setState(() => obscureText = !obscureText);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: buildInputField(
                        label: 'Country Code',
                        controller: widget.countryCodeController,
                        focusNode: widget.countryCodeFocus,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: buildInputField(
                        label: 'Mobile Number',
                        isMobileNumber: true,
                        controller: widget.mobileController,
                        focusNode: widget.mobileFocus,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Register',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    void Function(String)? onChanged,
    bool isPassword = false,
    bool obscureText = false,
    void Function()? toggleObscure,
    TextInputType? keyboardType,
    bool isMobileNumber = false,
    String hintText = '',
  }) {
    return TextField(
      maxLength: isMobileNumber ? 10 : 50,
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword && obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hint: Text(
          hintText,
          style: const TextStyle(fontSize: 18, color: Colors.grey),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: toggleObscure,
                )
                : null,
      ),
    );
  }

  bool _usernameExists(String username) {
    return admins.any((u) => u['username'] == username) ||
        staffs.any((u) => u['username'] == username) ||
        students.any((u) => u['username'] == username) ||
        administrators.any((u) => u['username'] == username);
  }

  Future<void> _handleSubmit() async {
    final username = widget.usernameController.text.trim();
    final password = widget.passwordController.text.trim();
    final designation = widget.designationController.text.trim();
    final mobile = widget.mobileController.text.trim();
    String countryCode = widget.countryCodeController.text.trim();

    if (username.isEmpty ||
        password.isEmpty ||
        mobile.isEmpty ||
        countryCode.isEmpty) {
      _showSnackBar('All fields are required', isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnackBar('Password must be at least 6 characters', isError: true);
      return;
    }

    if (!countryCode.startsWith('+')) {
      countryCode = '+$countryCode';
    }

    final fullMobile = '$countryCode$mobile';

    if (!RegExp(r'^\+\d{1,3}\d{4,14}$').hasMatch(fullMobile)) {
      _showSnackBar('Invalid mobile number format', isError: true);
      return;
    }

    if (_usernameExists(username)) {
      _showSnackBar('Username already exists', isError: true);
      return;
    }

    try {
      final result1 = await ApiService.registerUser(
        username: username,
        password: password,
        role: 'staff',
        school_id: widget.schoolId,
      );

      final result2 = await ApiService.registerUserDesignation(
        username: username,
        designation: designation,
        school_id: widget.schoolId,
        mobile: fullMobile,
        table: 'staff',
      );

      if (result1['success'] && result2['success']) {
        widget.usernameController.clear();
        widget.passwordController.clear();
        widget.mobileController.clear();
        widget.countryCodeController.clear();
        widget.designationController.clear();

        _showSnackBar(result1['message']);
        widget.onRegistered(); // ✅ Trigger parent callback
      } else {
        _showSnackBar(result1['error'] ?? 'Registration failed', isError: true);
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e', isError: true);
    }
  }
}
