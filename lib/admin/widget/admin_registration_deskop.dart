import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../services/admin_api_service.dart';

class AdminRegistrationDesktop extends StatefulWidget {
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
  const AdminRegistrationDesktop({
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
  State<AdminRegistrationDesktop> createState() =>
      _AdminRegistrationDesktopState();
}

class _AdminRegistrationDesktopState extends State<AdminRegistrationDesktop> {
  bool obscureText = true;
  List<dynamic> users = [];
  List<String> adminMobiles = [];

  // Validation state
  bool isUsernameValid = false;
  bool isPasswordValid = false;
  bool isMobileValid = false;
  bool isCountryCodeValid = false;

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
    _setupFieldListeners();
  }

  void _setupFieldListeners() {
    widget.usernameController.addListener(_validateUsername);
    widget.passwordController.addListener(_validatePassword);
    widget.mobileController.addListener(_validateMobile);
    widget.countryCodeController.addListener(_validateCountryCode);
  }

  Future<void> _fetchAllUsers() async {
    try {
      final adminUsers = await ApiService.getUsersByRole('admin');
      final staffUsers = await ApiService.getUsersByRole('staff');
      final studentUsers = await ApiService.getUsersByRole('student');
      final administratorUsers = await ApiService.getUsersByRole(
        'administrator',
      );

      users = [
        ...adminUsers,
        ...staffUsers,
        ...studentUsers,
        ...administratorUsers,
      ];

      List<Future<Map<String, dynamic>?>> futures =
          adminUsers
              .map((user) => AdminApiService.fetchAdminData(user['username']))
              .toList();

      final results = await Future.wait(futures);
      adminMobiles.clear();

      for (var adminData in results) {
        final mobile = adminData?['mobile'];
        if (mobile != null) {
          adminMobiles.add(mobile);
        }
      }
    } catch (e) {
      _showSnackBar('Failed to load user data', isError: true);
    }
  }

  void _validateUsername() {
    final username = widget.usernameController.text.trim();
    setState(() {
      isUsernameValid =
          username.isNotEmpty &&
          !users.any((user) => user['username'] == username);
    });
  }

  void _validatePassword() {
    final password = widget.passwordController.text.trim();
    setState(() {
      isPasswordValid = password.length >= 6;
    });
  }

  void _validateMobile() {
    final mobile = widget.mobileController.text.trim();
    final country = widget.countryCodeController.text.trim();
    String full =
        country.startsWith('+') ? '$country$mobile' : '+$country$mobile';

    final validFormat = RegExp(r'^\+\d{1,3}\d{4,14}$').hasMatch(full);
    final exists = adminMobiles.contains(full);

    setState(() {
      isMobileValid = mobile.length == 10 && validFormat && !exists;
    });
  }

  void _validateCountryCode() {
    final code = widget.countryCodeController.text.trim();
    setState(() {
      isCountryCodeValid = code.isNotEmpty;
    });
  }

  bool get isFormValid =>
      isUsernameValid && isPasswordValid && isMobileValid && isCountryCodeValid;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final formWidth = screenWidth * 0.5;

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: Container(
          width: formWidth,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(blurRadius: 12, color: Colors.black12)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: buildInputField(
                      label: 'Username',
                      controller: widget.usernameController,
                      focusNode: widget.usernameFocus,
                      errorText:
                          !isUsernameValid &&
                                  widget.usernameController.text
                                      .trim()
                                      .isNotEmpty
                              ? 'Username already exists or is empty'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildInputField(
                      label: 'Password',
                      hintText: 'At least 6 characters',
                      controller: widget.passwordController,
                      focusNode: widget.passwordFocus,
                      isPassword: true,
                      obscureText: obscureText,
                      toggleObscure:
                          () => setState(() => obscureText = !obscureText),
                      errorText:
                          !isPasswordValid &&
                                  widget.passwordController.text
                                      .trim()
                                      .isNotEmpty
                              ? 'Password too short'
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: buildInputField(
                      label: 'Designation',
                      controller: widget.designationController,
                      focusNode: FocusNode(),
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
                      errorText:
                          !isCountryCodeValid &&
                                  widget.countryCodeController.text
                                      .trim()
                                      .isNotEmpty
                              ? 'Required'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: buildInputField(
                      label: 'Mobile Number',
                      controller: widget.mobileController,
                      focusNode: widget.mobileFocus,
                      keyboardType: TextInputType.phone,
                      isMobileNumber: true,
                      errorText:
                          !isMobileValid &&
                                  widget.mobileController.text.trim().isNotEmpty
                              ? 'Invalid or duplicate number'
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isFormValid ? _handleSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFormValid ? Colors.blueAccent : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Register', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildInputField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    bool isPassword = false,
    bool obscureText = false,
    void Function()? toggleObscure,
    TextInputType? keyboardType,
    bool isMobileNumber = false,
    String hintText = '',
    String? errorText,
  }) {
    return TextField(
      maxLength: isMobileNumber ? 10 : 50,
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword && obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hint:
            hintText.isNotEmpty
                ? Text(hintText, style: const TextStyle(color: Colors.grey))
                : null,
        counterText: '',
        labelText: label,
        errorText: errorText,
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

  Future<void> _handleSubmit() async {
    final username = widget.usernameController.text.trim();
    final password = widget.passwordController.text.trim();
    final designation = widget.designationController.text.trim();
    final mobile = widget.mobileController.text.trim();
    String countryCode = widget.countryCodeController.text.trim();

    if (!countryCode.startsWith('+')) {
      countryCode = '+$countryCode';
    }
    final fullMobile = '$countryCode$mobile';

    try {
      final result1 = await ApiService.registerUser(
        username: username,
        password: password,
        role: 'admin',
        school_id: widget.schoolId,
      );

      final result2 = await ApiService.registerUserDesignation(
        username: username,
        designation: designation,
        school_id: widget.schoolId,
        mobile: fullMobile,
        table: 'admin',
      );

      if (result1['success'] && result2['success']) {
        widget.usernameController.clear();
        widget.passwordController.clear();
        widget.mobileController.clear();
        widget.designationController.clear();
        widget.countryCodeController.clear();

        _fetchAllUsers();
        _showSnackBar(result1['message']);
        widget.onRegistered();
      } else {
        _showSnackBar(result1['error'] ?? 'Registration failed', isError: true);
      }
    } catch (e) {
      _showSnackBar('An error occurred: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
