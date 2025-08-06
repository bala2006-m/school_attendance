import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../appbar/desktop_appbar.dart';
import '../appbar/mobile_appbar.dart';
import '../services/teacher_api_service.dart'; // Backend service

class EditProfileScreen extends StatefulWidget {
  final String username;
  const EditProfileScreen({super.key, required this.username});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _designationController;
  String? _gender; // Gender value

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStaffData();
  }

  Future<void> _loadStaffData() async {
    try {
      final staff = await TeacherApiServices.fetchProfile(widget.username);

      _nameController = TextEditingController(text: staff.name);
      _emailController = TextEditingController(text: staff.email);
      _mobileController = TextEditingController(text: staff.mobile);
      _designationController = TextEditingController(text: staff.designation);
      _gender = staff.gender; // Load gender (expected 'M', 'F', or 'O')

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          MediaQuery.sizeOf(context).width > 600
              ? DesktopAppbar(title: 'Edit Profile')
              : MobileAppbar(title: 'Edit Profile'),
      body:
          _isLoading
              ? const Center(
                child: SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 60.0,
                ),
              )
              : _error != null
              ? Center(child: Text(_error!))
              : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _buildInputField(
                                label: 'Full Name',
                                controller: _nameController,
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                label: 'Email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                label: 'Mobile',
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                label: 'Designation',
                                controller: _designationController,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value:
                                    (_gender != 'M' &&
                                            _gender != 'F' &&
                                            _gender != 'O')
                                        ? null
                                        : _gender,
                                decoration: InputDecoration(
                                  labelText: 'Gender',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'M',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'F',
                                    child: Text('Female'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'O',
                                    child: Text('Other'),
                                  ),
                                ],
                                hint: const Text('Select Gender'),
                                onChanged: (value) {
                                  setState(() {
                                    _gender = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Please select your gender';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      floatingActionButton:
          _isLoading
              ? null
              : FloatingActionButton.extended(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final String name = _nameController.text.trim();
                      String fullname =
                          name[0].toUpperCase() + name.substring(1);
                      await TeacherApiServices.updateProfile(widget.username, {
                        'name': fullname,
                        'email': _emailController.text.trim(),
                        'mobile': _mobileController.text.trim(),
                        'designation': _designationController.text.trim(),
                        'gender': _gender,
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Update failed: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                backgroundColor: Colors.blueAccent,
              ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label is required';
        }
        return null;
      },
    );
  }
}
