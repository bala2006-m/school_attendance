import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../teacher/services/teacher_api_service.dart';

class StaffRegistrationMobile extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController mobileController;
  final TextEditingController countryCodeController;
  final FocusNode passwordFocus;
  final FocusNode mobileFocus;
  final FocusNode countryCodeFocus;
  final String schoolId;
  final VoidCallback onRegistered;

  const StaffRegistrationMobile({
    super.key,
    required this.passwordController,
    required this.mobileController,
    required this.countryCodeController,
    required this.passwordFocus,
    required this.mobileFocus,
    required this.countryCodeFocus,
    required this.schoolId,
    required this.onRegistered,
  });

  @override
  State<StaffRegistrationMobile> createState() =>
      _StaffRegistrationMobileState();
}

class _StaffRegistrationMobileState extends State<StaffRegistrationMobile> {
  bool obscureText = true;
  List<String> staffMobiles = [];
  bool fillPass = false;
  bool fillMobile = false;
  bool fillCountry = true;

  List<dynamic> admins = [];
  List<dynamic> staffs = [];
  List<dynamic> students = [];
  List<dynamic> administrators = [];
  Map<String, String?> fieldErrors = {};

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
    bool isCountry = false,
  }) {
    bool isFocused = focusNode.hasFocus || controller.text.isNotEmpty;
    bool hasError = fieldErrors[label] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isFocused ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  hasError
                      ? Colors.red
                      : (isFocused ? Colors.blue : Colors.grey.shade400),
              width: hasError ? 2 : (isFocused ? 2 : 1),
            ),
            boxShadow:
                isFocused
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
                  autofocus: true,
                  onTap: onFocus,
                  onChanged: (val) {
                    final trimmedVal = val.trim();

                    if (label == 'Mobile Number') {
                      bool usernameExists = [
                        ...admins,
                        ...staffs,
                        ...students,
                        ...administrators,
                      ].any((user) => user['username'] == trimmedVal);

                      if (usernameExists) {
                        fieldErrors[label] = 'Mobile Number already exists';
                        fillMobile = false;
                      } else {
                        fieldErrors[label] = null;
                        fillMobile = trimmedVal.length == 10;
                      }

                      String country = widget.countryCodeController.text.trim();
                      if (!country.startsWith('+')) country = '+$country';
                      String full = '$country$trimmedVal';

                      if (staffMobiles.contains(full)) {
                        fieldErrors[label] = 'Mobile number already exists';
                        fillMobile = false;
                      }
                    }

                    if (label == 'Password') {
                      fillPass = trimmedVal.length >= 6;
                      fieldErrors[label] =
                          fillPass
                              ? null
                              : 'Password must be at least 6 characters';
                    }

                    if (label == 'Country Code' || label == 'Code') {
                      fillCountry = trimmedVal.isNotEmpty;
                      fieldErrors[label] =
                          fillCountry ? null : 'Country code required';
                    }

                    setState(() {});
                  },
                  maxLength:
                      isMobileNumber
                          ? 10
                          : isCountry
                          ? 3
                          : 50,
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: isPassword && obscureText,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    labelText: label,
                    hint: Text(hintText),
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
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(
              fieldErrors[label]!,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.mobileFocus.requestFocus();
    });
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
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

      List<Future<Map<String, dynamic>?>> futures =
          admins
              .map(
                (user) => TeacherApiServices.fetchStaffDataUsername(
                  username: user['username'],
                  schoolId: int.parse(widget.schoolId),
                ),
              )
              .toList();

      List<Map<String, dynamic>?> results = await Future.wait(futures);
      staffMobiles =
          results
              .map((adminData) => adminData?['mobile'])
              .where((mobile) => mobile != null)
              .cast<String>()
              .toList();
    } catch (e) {
      showSnackBar('Failed to load staff data', isError: true);
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

  // Widget buildAnimatedField({
  //   required String label,
  //   required TextEditingController controller,
  //   required FocusNode focusNode,
  //   bool isPassword = false,
  //   bool obscureText = false,
  //   void Function()? toggleObscure,
  //   TextInputType? keyboardType,
  //   bool isMobileNumber = false,
  //   String hintText = '',
  //   required void Function() onFocus,
  //   bool isCountry = false,
  // }) {
  //   bool isFocused = focusNode.hasFocus || controller.text.isNotEmpty;
  //
  //   return AnimatedContainer(
  //     duration: const Duration(milliseconds: 300),
  //     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  //     decoration: BoxDecoration(
  //       color: isFocused ? Colors.white : Colors.grey[100],
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(
  //         color: isFocused ? Colors.blue : Colors.grey.shade400,
  //         width: isFocused ? 2 : 1,
  //       ),
  //       boxShadow:
  //           isFocused
  //               ? [
  //                 BoxShadow(
  //                   color: Colors.blue.withOpacity(0.1),
  //                   blurRadius: 8,
  //                   offset: const Offset(0, 4),
  //                 ),
  //               ]
  //               : [],
  //     ),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: TextField(
  //             autofocus: true,
  //             onTap: onFocus,
  //             onChanged: (val) {
  //               final trimmedVal = val.trim();
  //
  //               if (label == 'Mobile Number') {
  //                 bool usernameExists = [
  //                   ...admins,
  //                   ...staffs,
  //                   ...students,
  //                   ...administrators,
  //                 ].any((user) => user['username'] == trimmedVal);
  //
  //                 if (usernameExists) {
  //                   showSnackBar('Mobile Number already exists', isError: true);
  //                   fillMobile = false;
  //                 } else {
  //                   fillMobile = trimmedVal.isNotEmpty;
  //                 }
  //               }
  //
  //               if (label == 'Password') {
  //                 fillPass = trimmedVal.length >= 6;
  //               }
  //
  //               if (label == 'Mobile Number') {
  //                 fillMobile = trimmedVal.length == 10;
  //                 String country = widget.countryCodeController.text.trim();
  //                 if (!country.startsWith('+')) country = '+$country';
  //                 String full = '$country$trimmedVal';
  //
  //                 if (staffMobiles.contains(full)) {
  //                   showSnackBar('Mobile number already exists', isError: true);
  //                   fillMobile = false;
  //                 }
  //               }
  //
  //               if (label == 'Country Code' || label == 'Code') {
  //                 fillCountry = trimmedVal.isNotEmpty;
  //               }
  //
  //               setState(() {});
  //             },
  //             maxLength:
  //                 isMobileNumber
  //                     ? 10
  //                     : isCountry
  //                     ? 3
  //                     : 50,
  //             controller: controller,
  //             focusNode: focusNode,
  //             obscureText: isPassword && obscureText,
  //             keyboardType: keyboardType,
  //             decoration: InputDecoration(
  //               labelText: label,
  //               hint: Text(hintText),
  //               counterText: '',
  //               border: InputBorder.none,
  //               labelStyle: const TextStyle(fontSize: 18),
  //             ),
  //             style: const TextStyle(fontSize: 18),
  //           ),
  //         ),
  //         if (isPassword)
  //           IconButton(
  //             icon: Icon(
  //               obscureText ? Icons.visibility_off : Icons.visibility,
  //               color: Colors.grey,
  //               size: 24,
  //             ),
  //             onPressed: toggleObscure,
  //           ),
  //       ],
  //     ),
  //   );
  // }

  Future<void> _handleRegister() async {
    final username = widget.mobileController.text.trim();
    final password = widget.passwordController.text.trim();
    final mobile = widget.mobileController.text.trim();
    String countryCode = widget.countryCodeController.text.trim();

    if (username.isEmpty ||
        password.isEmpty ||
        mobile.isEmpty ||
        countryCode.isEmpty) {
      _showError('All fields are required');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    if (!countryCode.startsWith('+')) {
      countryCode = '+$countryCode';
    }

    final fullMobile = '$countryCode$mobile';
    if (!RegExp(r'^\+\d{1,3}\d{4,14}$').hasMatch(fullMobile)) {
      _showError('Invalid mobile number format');
      return;
    }

    try {
      final result1 = await ApiService.registerUser(
        username: username,
        password: password,
        role: 'staff',
        school_id: widget.schoolId,
      );
      print(result1);
      final result2 = await ApiService.registerUserDesignation(
        username: username,
        designation: 'staff',
        school_id: widget.schoolId,
        mobile: fullMobile,
        table: 'staff',
      );
      print(result2);
      if (result1['success'] && result2['success']) {
        showSnackBar(result1['message']);
        widget.passwordController.clear();
        widget.mobileController.clear();

        FocusScope.of(context).requestFocus(widget.mobileFocus);

        setState(() {
          fillPass = false;
          fillMobile = false;
          fillCountry = false;
        });

        await init(); // Refresh data
        widget.onRegistered(); // Notify parent
      } else {
        _showError(result1['error'] ?? 'Registration failed');
      }
    } catch (e) {
      _showError('Error occurred: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
      onPressed: isFiled ? _handleRegister : null,
      child: const Text('Register', style: TextStyle(fontSize: 18)),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isFiled = fillPass && fillMobile && fillCountry;

    return Center(
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.white,
          child: Center(
            child: Container(
              height: MediaQuery.of(context).size.height / 1.7,
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
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: buildAnimatedField(
                          label: 'Code',
                          isCountry: true,
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
                          isMobileNumber: true,
                          controller: widget.mobileController,
                          focusNode: widget.mobileFocus,
                          keyboardType: TextInputType.phone,
                          onFocus: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  buildAnimatedField(
                    label: 'Password',
                    hintText: "At least 6 Characters",
                    controller: widget.passwordController,
                    focusNode: widget.passwordFocus,
                    isPassword: true,
                    obscureText: obscureText,
                    toggleObscure: () {
                      setState(() => obscureText = !obscureText);
                    },
                    onFocus: () {},
                  ),

                  const SizedBox(height: 16),
                  submitButton(isFiled),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
