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
  final String classId;
  const StudentRegistrationMobile({
    super.key,
    required this.schoolId,
    required this.username,
    required this.onRegistered,
    required this.classId,
  });

  @override
  State<StudentRegistrationMobile> createState() =>
      _StudentRegistrationMobileState();
}

class _StudentRegistrationMobileState extends State<StudentRegistrationMobile> {
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _routeController = TextEditingController();
  final _communityController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+91');

  final _nameFocus = FocusNode();
  final _fatherNameFocus = FocusNode();
  final _communityFocus = FocusNode();
  final _routeFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _mobileFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _countryCodeFocus = FocusNode();

  DateTime? dob;
  String? _selectedGender;
  bool _obscureText = true;
  bool _isRegisterButtonEnabled = false;
  bool _isLoading = false;
  Timer? _debounce;

  List<dynamic> admins = [];
  List<dynamic> staffs = [];
  List<dynamic> students = [];
  List<dynamic> administrators = [];
  List<String> existingUsernames = [];
  // List<String> existingMobiles = [];
  // List<String> existingEmails = [];

  List<Map<String, dynamic>> availableClasses = [];
  List<String> classList = [];
  List<String> sectionList = [];
  Map<String, String?> fieldErrors = {};

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
          errorText: fieldErrors[label],
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

            if (label == 'Admn. No' &&
                (existingUsernames.contains(val.trim()) ||
                    admins.any((u) => u['username'] == val.trim()) ||
                    staffs.any((u) => u['username'] == val.trim()) ||
                    students.any((u) => u['username'] == val.trim()) ||
                    administrators.any((u) => u['username'] == val.trim()))) {
              error = 'Admission Number already exists';
            }

            if (label == 'Mobile') {
              // String full = _countryCodeController.text.trim() + val.trim();
              // if (existingMobiles.contains(full)) {
              //   error = 'Mobile number already exists';
              // } else
              if (!RegExp(r'^[6-9]\d{9}$').hasMatch(val.trim())) {
                error = 'Enter valid 10-digit mobile number';
              }
            }

            if (label == 'Email') {
              // if (existingEmails.contains(val.trim())) {
              //   error = 'Email already exists';
              // } else
              if (!RegExp(
                r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
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
              fieldErrors[label] = error;
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
    for (var controller in [
      _nameController,
      _emailController,
      _mobileController,
      _usernameController,
      _passwordController,
    ]) {
      controller.addListener(_validateForm);
    }
  }

  void _validateForm() {
    // final fullMobile =
    _countryCodeController.text + _mobileController.text.trim();

    setState(() {
      _isRegisterButtonEnabled =
          _fatherNameController.text.isNotEmpty &&
          _communityController.text.isNotEmpty &&
          _routeController.text.isNotEmpty &&
          _nameController.text.isNotEmpty &&
          _emailController.text.isNotEmpty &&
          _mobileController.text.isNotEmpty &&
          _usernameController.text.isNotEmpty &&
          _passwordController.text.length >= 6 &&
          _selectedGender != null &&
          dob != null &&
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
      }
    } catch (e) {
      _showError('Error fetching existing students');
    }
  }

  Future<void> _fetchClasses() async {
    try {
      final res = await AdminApiService.fetchAllClasses(widget.schoolId);
      availableClasses = List<Map<String, dynamic>>.from(res);

      classList =
          availableClasses.map((e) => e['class'].toString()).toSet().toList();

      classList.sort((a, b) {
        final aNum = int.tryParse(a);
        final bNum = int.tryParse(b);
        if (aNum != null && bNum != null) {
          return aNum.compareTo(bNum);
        } else if (aNum != null) {
          return -1;
        } else if (bNum != null) {
          return 1;
        } else {
          return a.compareTo(b);
        }
      });

      setState(() {});
    } catch (e) {
      _showError('Error fetching classes');
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedGender == null) {
      _showError('Please select gender');
      return;
    }
    if (dob == null) {
      _showError('Please select Date of Birth');
      return;
    }

    final fatherName = _fatherNameController.text.trim();
    final community = _communityController.text.trim();
    final route = _routeController.text.trim();
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
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
        schoolId: widget.schoolId,
      );

      if (!(userRes['success'] ?? false)) {
        _showError(userRes['message'] ?? 'User registration failed');
        return;
      }

      final regRes = await ApiService.registerStudent(
        email: email,
        name: name.toUpperCase(),
        gender: _selectedGender!,
        mobile: mobile,
        username: username,
        classId: widget.classId,
        schoolId: widget.schoolId,
        fatherName: fatherName.toUpperCase(),
        community: community.toUpperCase(),
        route: route.toUpperCase(),
        dob: dob!.toIso8601String(),
      );

      if (regRes['success'] == true) {
        showSnackBar(regRes['message'] ?? 'Student registered successfully');
        _clearForm();
        widget.onRegistered();
        if (mounted) {
          FocusScope.of(context).requestFocus(_usernameFocus);
        }
      } else {
        _showError(regRes['message'] ?? 'Student registration failed');
      }
    } catch (e) {
      _showError('Unexpected error');
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
    dob = null;
    setState(() {
      _selectedGender = null;
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

  Future<void> _pickDateOfBirth() async {
    DateTime initialDate = DateTime.now().subtract(
      const Duration(days: 365 * 10),
    );
    DateTime firstDate = DateTime(1990);
    DateTime lastDate = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: dob ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null) {
      setState(() {
        dob = pickedDate;
      });
      _validateForm();
    }
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
    _fatherNameFocus.dispose();
    _communityFocus.dispose();
    _routeFocus.dispose();
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
            label: 'Admn. No',
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
            label: 'Father Name',
            controller: _fatherNameController,
            focusNode: _fatherNameFocus,
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

          const SizedBox(height: 12),

          /// ✅ DOB Picker
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              onTap: _pickDateOfBirth,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: dob == null ? 'Please select DOB' : null,
                ),
                child: Text(
                  dob != null
                      ? "${dob!.day}/${dob!.month}/${dob!.year}"
                      : 'Select Date',
                  style: TextStyle(
                    fontSize: 16,
                    color: dob != null ? Colors.black : Colors.grey[600],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
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
          ),
          const SizedBox(height: 12),
          buildTextField(
            label: 'Community',
            controller: _communityController,
            focusNode: _communityFocus,
          ),
          buildTextField(
            label: 'Bus Route',
            controller: _routeController,
            focusNode: _routeFocus,
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
