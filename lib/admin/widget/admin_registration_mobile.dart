import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../services/admin_api_service.dart';

class AdminRegistrationMobile extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController designationController;
  final TextEditingController mobileController;
  final TextEditingController countryCodeController;
  final FocusNode passwordFocus;
  final FocusNode mobileFocus;
  final FocusNode countryCodeFocus;
  final bool isMobile;
  final String schoolId;
  final VoidCallback onRegistered;

  const AdminRegistrationMobile({
    super.key,
    required this.passwordController,
    required this.designationController,
    required this.mobileController,
    required this.countryCodeController,
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
  bool fillPass = false;
  bool fillMobile = false;
  bool fillCountry = true;
  bool obscureText = true;

  /// Error messages per field
  Map<String, String?> fieldErrors = {
    'Mobile Number': null,
    'Password': null,
    'Country Code': null,
  };

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
                (user) => AdminApiService.fetchAdminData(
                  username: user['username'],
                  schoolId: widget.schoolId,
                ),
              )
              .toList();

      List<Map<String, dynamic>?> results = await Future.wait(futures);

      for (var adminData in results) {
        final mobile = adminData?['mobile'];
        if (mobile != null) {
          adminMobiles.add(mobile);
        }
      }
    } catch (e) {
      debugPrint('Failed to load admin data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isFiled =
        fillPass && fillMobile && widget.countryCodeController.text.isNotEmpty;

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
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: buildAnimatedField(
                              label: widget.isMobile ? 'Code' : 'Country Code',
                              controller: widget.countryCodeController,
                              focusNode: widget.countryCodeFocus,
                              keyboardType: TextInputType.phone,
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
                            ),
                          ),
                        ],
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
                final username = widget.mobileController.text.trim();
                final password = widget.passwordController.text.trim();
                final designation = widget.designationController.text.trim();

                if (password.length < 6) {
                  setState(() {
                    fieldErrors['Password'] =
                        'Password must be at least 6 characters';
                  });
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
                  setState(() {
                    fieldErrors['Mobile Number'] =
                        'Invalid mobile number format. Include a valid country code (e.g., +91).';
                  });
                  return;
                }

                final result = await ApiService.registerUser(
                  username: username,
                  password: password,
                  role: 'admin',
                  school_id: widget.schoolId,
                );

                final res = await ApiService.registerUserDesignation(
                  username: username,
                  designation: designation,
                  school_id: widget.schoolId,
                  mobile: fullMobileNumber,
                  table: 'admin',
                );

                if (result['success'] && res['success']) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(result['message'])));
                  widget.passwordController.clear();
                  widget.mobileController.clear();
                  FocusScope.of(context).requestFocus(widget.mobileFocus);
                  init();
                  setState(() {
                    fillPass = false;
                    fillMobile = false;
                    fillCountry = true;
                    fieldErrors.updateAll((key, value) => null);
                  });
                  widget.onRegistered();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${result['error']}'),
                      backgroundColor: Colors.red,
                    ),
                  );
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
  }) {
    final hasError = fieldErrors[label] != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  hasError
                      ? Colors.red
                      : (focusNode.hasFocus
                          ? Colors.blue
                          : Colors.grey.shade400),
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
                  onChanged: (val) {
                    final trimmedVal = val.trim();

                    if (label == 'Mobile Number') {
                      bool exists =
                          admins.any(
                            (user) => user['username'] == trimmedVal,
                          ) ||
                          staffs.any(
                            (user) => user['username'] == trimmedVal,
                          ) ||
                          students.any(
                            (user) => user['username'] == trimmedVal,
                          ) ||
                          administrators.any(
                            (user) => user['username'] == trimmedVal,
                          );

                      if (exists) {
                        fieldErrors[label] = 'Mobile number already exists';
                        fillMobile = false;
                      } else if (trimmedVal.length != 10) {
                        fieldErrors[label] = 'Enter a valid 10-digit number';
                        fillMobile = false;
                      } else {
                        String country =
                            widget.countryCodeController.text.trim();
                        if (!country.startsWith('+')) country = '+$country';
                        String full = '$country$trimmedVal';
                        if (adminMobiles.contains(full)) {
                          fieldErrors[label] = 'Mobile number already exists';
                          fillMobile = false;
                        } else {
                          fieldErrors[label] = null;
                          fillMobile = true;
                        }
                      }
                    }

                    if (label == 'Password') {
                      if (trimmedVal.length < 6) {
                        fieldErrors[label] =
                            'Password must be at least 6 characters';
                        fillPass = false;
                      } else {
                        fieldErrors[label] = null;
                        fillPass = true;
                      }
                    }

                    if (label == 'Country Code' || label == 'Code') {
                      if (trimmedVal.isEmpty) {
                        fieldErrors['Country Code'] =
                            'Country code cannot be empty';
                        fillCountry = false;
                      } else {
                        fieldErrors['Country Code'] = null;
                        fillCountry = true;
                      }
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
                    hintText: hintText.isNotEmpty ? hintText : null,
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
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              fieldErrors[label] ?? '',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
      ],
    );
  }
}
