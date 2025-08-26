import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../services/api_service.dart';
import '../services/admin_api_service.dart';

class StudentRegistrationMobile extends StatefulWidget {
  final String schoolId;
  final String username;
  final VoidCallback onRegistered;

  const StudentRegistrationMobile({
    super.key,
    required this.schoolId,
    required this.username,
    required this.onRegistered,
  });

  @override
  State<StudentRegistrationMobile> createState() =>
      _StudentRegistrationMobileState();
}

class _StudentRegistrationMobileState extends State<StudentRegistrationMobile> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+91');

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _countryCodeFocus = FocusNode();

  String? _selectedGender;
  String? _selectedClass;
  String? _selectedSection;
  bool _obscureText = true;
  bool _isRegisterButtonEnabled = false;
  bool _isLoading = false;
  Timer? _debounce;

  List<dynamic> admins = [];
  List<dynamic> staffs = [];
  List<dynamic> students = [];
  List<dynamic> administrators = [];
  List<String> existingUsernames = [];
  List<String> existingMobiles = [];
  List<String> existingEmails = [];

  // for class/section
  List<Map<String, dynamic>> availableClasses = [];
  List<String> classList = [];
  List<String> sectionList = [];
  Map<String, String?> _fieldErrors = {}; // add in state

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool isPassword = false,
    bool isMobileNumber = false,
    bool isCode = false,
    String hintText = '',
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLength:
            isMobileNumber
                ? 10
                : isCode
                ? 3
                : 50,
        inputFormatters:
            isMobileNumber
                ? [FilteringTextInputFormatter.digitsOnly]
                : isCode
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\+\d{0,2}'))]
                : [],
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          counterText: '',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          errorText: _fieldErrors[label], // <-- shows error below text box
          suffixIcon:
              isPassword
                  ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed:
                        () => setState(() => _obscureText = !_obscureText),
                  )
                  : null,
        ),
        onChanged: (val) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            String? error;

            if (label == 'Roll Number' &&
                (existingUsernames.contains(val.trim()) ||
                    admins.any((u) => u['username'] == val.trim()) ||
                    staffs.any((u) => u['username'] == val.trim()) ||
                    students.any((u) => u['username'] == val.trim()) ||
                    administrators.any((u) => u['username'] == val.trim()))) {
              error = 'Roll Number already exists';
            }

            if (label == 'Mobile') {
              String full = _countryCodeController.text.trim() + val.trim();
              if (existingMobiles.contains(full)) {
                error = 'Mobile number already exists';
              } else if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) {
                error = 'Enter valid 10-digit mobile number';
              }
            }

            if (label == 'Email') {
              if (existingEmails.contains(val.trim())) {
                error = 'Email already exists';
              } else if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(val.trim())) {
                error = 'Enter a valid email address';
              }
            }

            if (label == 'Password') {
              if (val.length < 6) {
                error = 'Password must be at least 6 characters';
              } else if (!RegExp(r'^(?=.*[a-z])(?=.*\d).+$').hasMatch(val)) {
                error = 'Password must include lower and number';
              }
            }

            setState(() {
              _fieldErrors[label] = error;
            });

            _validateForm();
          });
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _usernameFocus.requestFocus();
    });
    _fetchExistingStudents();
    _fetchClasses();
    _addListeners();
  }

  void _addListeners() {
    [
      _nameController,
      _emailController,
      _mobileController,
      _usernameController,
      _passwordController,
    ].forEach((controller) => controller.addListener(_validateForm));
  }

  void _validateForm() {
    final fullMobile =
        _countryCodeController.text + _mobileController.text.trim();

    setState(() {
      _isRegisterButtonEnabled =
          _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _mobileController.text.isNotEmpty &&
          _usernameController.text.isNotEmpty &&
          _passwordController.text.length >= 6 &&
          _selectedClass != null &&
          _selectedSection != null &&
          _selectedGender != null &&
          !existingEmails.contains(_emailController.text.trim()) &&
          !existingMobiles.contains(fullMobile) &&
          !existingUsernames.contains(_usernameController.text.trim());
    });
  }

  Future<void> _fetchExistingStudents() async {
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

      final users = await AdminApiService.fetchAllStudentData(widget.schoolId);
      for (var user in users) {
        if (user['username'] != null) existingUsernames.add(user['username']);
        if (user['mobile'] != null) existingMobiles.add(user['mobile']);
        if (user['email'] != null) existingEmails.add(user['email']);
      }
    } catch (e) {
      debugPrint('Error fetching students: $e');
      _showError('Error fetching existing students');
    }
  }

  Future<void> _fetchClasses() async {
    try {
      final res = await AdminApiService.fetchAllClasses(widget.schoolId);
      availableClasses = List<Map<String, dynamic>>.from(res);
      classList =
          availableClasses.map((e) => e['class'].toString()).toSet().toList()
            ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
      setState(() {});
    } catch (e) {
      debugPrint('Error fetching classes: $e');
      _showError('Error fetching classes');
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedGender == null) {
      _showError('Please select gender');
      return;
    }

    if (_selectedClass == null || _selectedSection == null) {
      _showError('Please select class & section');
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final className = _selectedClass!;
    final section = _selectedSection!;
    final mobile =
        _countryCodeController.text.trim() + _mobileController.text.trim();

    if (!mobile.startsWith('+')) {
      _showError('Country code must start with "+"');
      return;
    }

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(_mobileController.text.trim())) {
      _showError('Invalid Indian mobile number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userRes = await ApiService.registerUser(
        username: username,
        password: password,
        role: 'student',
        school_id: widget.schoolId,
      );

      if (!(userRes['success'] ?? false)) {
        _showError(userRes['message'] ?? 'User registration failed');
        return;
      }

      final classIdRes = await ApiService.fetchClassId(
        schoolId: widget.schoolId,
        className: className,
        section: section,
      );

      if (classIdRes['status'] != 'success') {
        _showError(classIdRes['message'] ?? 'Error fetching class ID');
        return;
      }

      final regRes = await ApiService.registerStudent(
        email: email,
        name: name[0].toUpperCase() + name.substring(1),
        gender: _selectedGender!,
        mobile: mobile,
        username: username,
        classId: '${classIdRes['class_id']}',
        schoolId: widget.schoolId,
      );

      if (regRes['success'] == true) {
        showSnackBar(regRes['message'] ?? 'Student registered successfully');
        _clearForm();
        widget.onRegistered();
        FocusScope.of(context).requestFocus(_usernameFocus);
      } else {
        _showError(regRes['message'] ?? 'Student registration failed');
      }
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _mobileController.clear();
    _usernameController.clear();
    _passwordController.clear();
    _countryCodeController.text = '+91';
    setState(() {
      _selectedGender = null;
      _selectedClass = null;
      _selectedSection = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    showSnackBar(message, isError: true);
  }

  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : CupertinoColors.systemGreen,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _countryCodeController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _mobileFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _countryCodeFocus.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          buildTextField(
            label: 'Roll Number',
            controller: _usernameController,
            focusNode: _usernameFocus,
          ),
          buildTextField(
            label: 'Email',
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
          ),
          buildTextField(
            label: 'Full Name',
            controller: _nameController,
            focusNode: _nameFocus,
          ),
          buildTextField(
            label: 'Password',
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscureText,
            isPassword: true,
            hintText: 'At least 6 characters',
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: buildTextField(
                  label: 'Code',
                  controller: _countryCodeController,
                  focusNode: _countryCodeFocus,
                  keyboardType: TextInputType.phone,
                  isCode: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 5,
                child: buildTextField(
                  label: 'Mobile',
                  controller: _mobileController,
                  focusNode: _mobileFocus,
                  keyboardType: TextInputType.phone,
                  isMobileNumber: true,
                  hintText: '10 digits',
                ),
              ),
            ],
          ),

          /// CLASS DROPDOWN
          DropdownButtonFormField<String>(
            value: _selectedClass,
            decoration: InputDecoration(
              labelText: 'Class',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items:
                classList
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
            onChanged: (val) {
              setState(() {
                _selectedClass = val;
                _selectedSection = null;
                sectionList =
                    availableClasses
                        .where((e) => e['class'].toString() == val)
                        .map((e) => e['section'].toString())
                        .toSet()
                        .toList();
              });
              _validateForm();
            },
          ),
          const SizedBox(height: 12),

          /// SECTION DROPDOWN
          DropdownButtonFormField<String>(
            value: _selectedSection,
            decoration: InputDecoration(
              labelText: 'Section',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items:
                sectionList
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
            onChanged: (val) {
              setState(() => _selectedSection = val);
              _validateForm();
            },
          ),
          const SizedBox(height: 12),

          /// GENDER DROPDOWN
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'M', child: Text('Male')),
              DropdownMenuItem(value: 'F', child: Text('Female')),
              DropdownMenuItem(value: 'O', child: Text('Other')),
            ],
            onChanged: (value) {
              setState(() => _selectedGender = value);
              _validateForm();
            },
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isRegisterButtonEnabled ? Colors.blueAccent : Colors.grey,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed:
                _isRegisterButtonEnabled && !_isLoading ? _handleSubmit : null,
            child:
                _isLoading
                    ? const SpinKitFadingCircle(color: Colors.white, size: 30.0)
                    : const Text('Register'),
          ),
        ],
      ),
    );
  }
}
