import 'package:flutter/material.dart';
import 'package:school_attendance/administrator/pages/first_page.dart';

import '../../admin/services/admin_api_service.dart';
import '../../services/api_service.dart';
import '../appbar/administrator_appbar_desktop.dart';
import '../appbar/administrator_appbar_mobile.dart';

class AdminRegistration extends StatefulWidget {
  const AdminRegistration({
    super.key,
    required this.schoolId,
    required this.username,
    required this.schoolName,
    required this.schoolAddress,
  });
  final int schoolId;
  final String username;
  final String schoolName;
  final String schoolAddress;

  @override
  State<AdminRegistration> createState() => _AdminRegistrationState();
}

class _AdminRegistrationState extends State<AdminRegistration> {
  // ✅ Controllers
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController mobileController = TextEditingController();
  final TextEditingController countryCodeController = TextEditingController(
    text: '+91',
  );

  // ✅ Focus nodes
  late FocusNode passwordFocus;
  late FocusNode mobileFocus;
  late FocusNode countryCodeFocus;

  // ✅ Other state variables
  List<String> adminMobiles = [];
  List<dynamic> admins = [];
  List<dynamic> staffs = [];
  List<dynamic> students = [];
  List<dynamic> administrators = [];

  bool fillPass = false;
  bool fillMobile = false;
  bool fillCountry = true;
  bool obscureText = true;
  bool isLoading = false;

  /// Error messages per field
  Map<String, String?> fieldErrors = {
    'Mobile Number': null,
    'Password': null,
    'Country Code': null,
  };

  @override
  void initState() {
    super.initState();

    passwordFocus = FocusNode();
    mobileFocus = FocusNode();
    countryCodeFocus = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      mobileFocus.requestFocus();
    });

    init();
  }

  @override
  void dispose() {
    passwordController.dispose();
    mobileController.dispose();
    countryCodeController.dispose();
    passwordFocus.dispose();
    mobileFocus.dispose();
    countryCodeFocus.dispose();
    super.dispose();
  }

  Future<void> init() async {
    try {
      admins = await ApiService.getUsersByRole(
        role: 'admin',
        schoolId: widget.schoolId,
      );
      staffs = await ApiService.getUsersByRole(
        role: 'staff',
        schoolId: widget.schoolId,
      );
      students = await ApiService.getUsersByRole(
        role: 'student',
        schoolId: widget.schoolId,
      );
      administrators = await ApiService.getUsersByRole(
        role: 'administrator',
        schoolId: widget.schoolId,
      );

      List<Future<Map<String, dynamic>?>> futures =
          admins
              .map(
                (user) => AdminApiService.fetchAdminData(
                  username: user['username'],
                  schoolId: widget.schoolId.toString(),
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
        fillPass && fillMobile && countryCodeController.text.isNotEmpty;
    final isMobile = MediaQuery.of(context).size.width < 500;

    return WillPopScope(
      onWillPop: () async {
        FirstPageState.selectedIndex = 1;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => FirstPage(
                  username: widget.username,
                  schoolName: widget.schoolName,
                  schoolAddress: widget.schoolAddress,
                  schoolId: widget.schoolId.toString(),
                ),
          ),
        );
        return false;
      },
      child: RefreshIndicator(
        onRefresh: init,
        child: Scaffold(
          backgroundColor: Colors.blue.shade50,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(isMobile ? 190 : 60),
            child:
                isMobile
                    ? AdministratorAppbarMobile(
                      title: 'Add Admin',
                      enableDrawer: false,
                      enableBack: true,
                      onBack: () {
                        FirstPageState.selectedIndex = 1;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => FirstPage(
                                  username: widget.username,
                                  schoolName: widget.schoolName,
                                  schoolAddress: widget.schoolAddress,
                                  schoolId: widget.schoolId.toString(),
                                ),
                          ),
                        );
                      },
                    )
                    : const AdministratorAppbarDesktop(title: 'Add Admin'),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: isMobile ? double.infinity : 450,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Register New Admin",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Country + Mobile row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: buildInputField(
                            label: "Code",
                            controller: countryCodeController,
                            focusNode: countryCodeFocus,
                            keyboardType: TextInputType.phone,
                            icon: Icons.flag,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 5,
                          child: buildInputField(
                            label: "Mobile Number",
                            controller: mobileController,
                            focusNode: mobileFocus,
                            keyboardType: TextInputType.phone,
                            isMobileNumber: true,
                            icon: Icons.phone,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    buildInputField(
                      label: "Password",
                      controller: passwordController,
                      focusNode: passwordFocus,
                      isPassword: true,
                      obscureText: obscureText,
                      toggleObscure:
                          () => setState(() => obscureText = !obscureText),
                      icon: Icons.lock,
                      hintText: "At least 6 characters",
                    ),

                    const SizedBox(height: 20),
                    submitButton(isFiled),
                  ],
                ),
              ),
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
    IconData? icon,
    bool isPassword = false,
    bool obscureText = false,
    void Function()? toggleObscure,
    TextInputType? keyboardType,
    bool isMobileNumber = false,
    String hintText = '',
  }) {
    final hasError = fieldErrors[label] != null;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword && obscureText,
      keyboardType: keyboardType,
      maxLength: isMobileNumber ? 10 : null,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        prefixIcon: icon != null ? Icon(icon, color: Colors.blueAccent) : null,
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
        labelText: label,
        hintText: hintText.isNotEmpty ? hintText : null,
        counterText: '',
        filled: true,
        fillColor: Colors.grey.shade100,
        errorText: hasError ? fieldErrors[label] : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      onChanged: (val) {
        // Keep your validation logic here (same as before)
        final trimmedVal = val.trim();

        if (label == 'Mobile Number') {
          bool exists =
              admins.any((user) => user['username'] == trimmedVal) ||
              staffs.any((user) => user['username'] == trimmedVal) ||
              students.any((user) => user['username'] == trimmedVal) ||
              administrators.any((user) => user['username'] == trimmedVal);

          if (exists) {
            fieldErrors[label] = 'Mobile number already exists';
            fillMobile = false;
          } else if (trimmedVal.length != 10) {
            fieldErrors[label] = 'Enter a valid 10-digit number';
            fillMobile = false;
          } else {
            String country = countryCodeController.text.trim();
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
            fieldErrors[label] = 'Password must be at least 6 characters';
            fillPass = false;
          } else {
            fieldErrors[label] = null;
            fillPass = true;
          }
        }

        if (label == 'Country Code' || label == 'Code') {
          if (trimmedVal.isEmpty) {
            fieldErrors['Country Code'] = 'Country code cannot be empty';
            fillCountry = false;
          } else {
            fieldErrors['Country Code'] = null;
            fillCountry = true;
          }
        }

        setState(() {});
      },
    );
  }

  Widget submitButton(bool isFiled) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: isFiled ? Colors.blueAccent : Colors.grey,
          elevation: 4,
        ),
        onPressed:
            isFiled && !isLoading
                ? () async {
                  setState(() => isLoading = true);
                  await handleSubmit();
                  setState(() => isLoading = false);
                }
                : null,
        child:
            isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                  "Register",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
      ),
    );
  }

  Future<void> handleSubmit() async {
    final username = mobileController.text.trim();
    final password = passwordController.text.trim();
    final designation = 'Admin';

    if (password.length < 6) {
      setState(() {
        fieldErrors['Password'] = 'Password must be at least 6 characters';
      });
      return;
    }

    String mobileNumber = mobileController.text.trim();
    String countryCode = countryCodeController.text.trim();
    if (!countryCode.startsWith('+')) {
      countryCode = '+$countryCode';
    }
    String fullMobileNumber = '$countryCode$mobileNumber';

    if (!RegExp(r'^\+\d{1,3}\d{4,14}\$').hasMatch(fullMobileNumber)) {
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
      school_id: widget.schoolId.toString(),
    );

    final res = await ApiService.registerUserDesignation(
      username: username,
      designation: designation,
      school_id: widget.schoolId.toString(),
      mobile: fullMobileNumber,
      table: 'admin',
    );

    if (result['success'] && res['success']) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
      passwordController.clear();
      mobileController.clear();
      FocusScope.of(context).requestFocus(mobileFocus);
      init();
      setState(() {
        fillPass = false;
        fillMobile = false;
        fillCountry = true;
        fieldErrors.updateAll((key, value) => null);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
