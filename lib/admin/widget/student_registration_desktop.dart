import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../services/api_service.dart';

class StudentRegistrationDesktop extends StatefulWidget {
  final String schoolId;
  final String username;

  const StudentRegistrationDesktop({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<StudentRegistrationDesktop> createState() =>
      _StudentRegistrationDesktopState();
}

class _StudentRegistrationDesktopState
    extends State<StudentRegistrationDesktop> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _classController = TextEditingController();
  final _sectionController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+91');

  String? _selectedGender;
  bool _obscureText = true;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final double maxWidth = MediaQuery.of(context).size.width * 0.6;

    return SingleChildScrollView(
      child: Center(
        child: Container(
          width: maxWidth,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Full Name',
                        controller: _nameController,
                        capitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        hint: const Text('Select'),
                        onChanged:
                            (value) => setState(() => _selectedGender = value),
                        items: const [
                          DropdownMenuItem(value: 'M', child: Text('Male')),
                          DropdownMenuItem(value: 'F', child: Text('Female')),
                          DropdownMenuItem(value: 'O', child: Text('Other')),
                        ],
                        validator:
                            (value) =>
                                value == null ? 'Please select gender' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 80,
                      child: _buildField(
                        label: 'Code',
                        controller: _countryCodeController,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildField(
                        label: 'Mobile',
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                            return 'Invalid mobile';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Roll Number',
                        controller: _usernameController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        label: 'Password',
                        controller: _passwordController,
                        isPassword: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildField(
                        label: 'Class',
                        controller: _classController,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildField(
                        label: 'Section',
                        controller: _sectionController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child:
                        _isSubmitting
                            ? const SpinKitFadingCircle(
                              color: Colors.blueAccent,
                              size: 60.0,
                            )
                            : const Text(
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscureText,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      validator: validator ?? (value) => value!.isEmpty ? 'Required' : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon:
            isPassword
                ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                )
                : null,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final email = _emailController.text.trim();
    final name = _capitalizeWords(_nameController.text.trim());
    final className = _classController.text.trim().toUpperCase();
    final section = _sectionController.text.trim().toUpperCase();
    final mobile =
        _countryCodeController.text.trim() + _mobileController.text.trim();

    if (_selectedGender == null) {
      _showError('Please select gender');
      setState(() => _isSubmitting = false);
      return;
    }

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
        name: name,
        gender: _selectedGender!,
        mobile: mobile,
        username: username,
        classId: '${classIdRes['class_id']}',
        schoolId: widget.schoolId,
      );

      if (regRes['success'] == true) {
        _showSuccess(regRes['message'] ?? 'Student registered successfully');
        _formKey.currentState!.reset();
        setState(() => _selectedGender = null);
      } else {
        _showError(regRes['message'] ?? 'Student registration failed');
      }
    } catch (e) {
      _showError('Unexpected error: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  String _capitalizeWords(String name) {
    return name
        .split(' ')
        .map(
          (word) =>
              word.isNotEmpty
                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                  : '',
        )
        .join(' ');
  }
}
