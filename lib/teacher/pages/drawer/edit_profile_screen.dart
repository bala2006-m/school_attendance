import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/teacher/pages/staff_dashboard.dart';

import '../appbar/desktop_appbar.dart';
import '../appbar/mobile_appbar.dart';
import '../services/teacher_api_service.dart'; // Backend service

class EditProfileScreen extends StatefulWidget {
  final String username;
  final VoidCallback submit;
  final int schoolId;
  const EditProfileScreen({
    super.key,
    required this.username,
    required this.submit,
    required this.schoolId,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  String designation = '';
  String? _gender;
  Uint8List? profilePhoto;
  File? _newImageFile;

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _designationController;

  bool _isLoading = true;
  String? _error;

  bool _isChanged = false;
  Map<String, dynamic> _initialData = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileController = TextEditingController();
    _designationController = TextEditingController();

    // Add listeners to track changes
    _nameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _mobileController.addListener(_checkForChanges);
    _designationController.addListener(_checkForChanges);

    init();
  }

  Future<void> init() async {
    try {
      setState(() => _isLoading = true);

      final data = await TeacherApiServices.fetchStaffDataUsername(
        username: widget.username,
        schoolId: widget.schoolId,
      );

      Uint8List? photoBytes;
      final photoField = data?['photo'];
      if (photoField != null) {
        if (photoField is Map) {
          photoBytes = Uint8List.fromList(List<int>.from(photoField.values));
        } else if (photoField is String && photoField.isNotEmpty) {
          try {
            photoBytes = base64Decode(photoField);
          } catch (e) {
            debugPrint("Invalid Base64 photo: $e");
          }
        }
      }

      setState(() {
        _nameController.text = data?['name'] ?? '';
        _emailController.text = data?['email'] ?? '';
        _mobileController.text = data?['mobile'] ?? '';
        _designationController.text = data?['designation'] ?? '';
        _gender = data?['gender'] ?? '';
        profilePhoto = photoBytes;
        _isLoading = false;

        // Store initial data for comparison
        _initialData = {
          'name': _nameController.text,
          'email': _emailController.text,
          'mobile': _mobileController.text,
          'designation': _designationController.text,
          'gender': _gender,
          'photo': profilePhoto != null ? base64Encode(profilePhoto!) : null,
        };
      });
    } catch (e) {
      debugPrint("Error loading staff data: $e");
      setState(() {
        _error = "Failed to load profile.";
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _newImageFile = File(result.files.single.path!);
      });
      _checkForChanges();
    }
  }

  /// ✅ Enable save only if all fields filled AND something changed
  void _checkForChanges() {
    String? newPhotoBase64;
    if (_newImageFile != null) {
      newPhotoBase64 = _newImageFile!.path; // Track new photo
    } else if (profilePhoto != null) {
      newPhotoBase64 = base64Encode(profilePhoto!);
    }

    // Check if values have changed
    final bool changed =
        _nameController.text != _initialData['name'] ||
        _emailController.text != _initialData['email'] ||
        _mobileController.text != _initialData['mobile'] ||
        _designationController.text != _initialData['designation'] ||
        _gender != _initialData['gender'] ||
        (newPhotoBase64 != _initialData['photo'] && _newImageFile != null);

    // ✅ Check if all fields are filled
    final bool allFieldsFilled =
        _nameController.text.trim().isNotEmpty &&
        _emailController.text.trim().isNotEmpty &&
        _mobileController.text.trim().isNotEmpty &&
        _designationController.text.trim().isNotEmpty &&
        (_gender != null && _gender!.isNotEmpty);

    final bool enableSave = changed && allFieldsFilled;

    if (enableSave != _isChanged) {
      setState(() {
        _isChanged = enableSave;
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
    final isMobile = MediaQuery.of(context).size.width < 500;

    final ImageProvider? imageProvider =
        _newImageFile != null
            ? FileImage(_newImageFile!)
            : profilePhoto != null
            ? MemoryImage(profilePhoto!)
            : null;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? MobileAppbar(
                  title: 'Edit Profile',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StaffDashboard(
                              username: widget.username,
                              schoolId: widget.schoolId.toString(),
                            ),
                      ),
                    );
                  },
                )
                : const DesktopAppbar(title: 'Edit Profile'),
      ),
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
                              Center(
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundImage: imageProvider,
                                      child:
                                          imageProvider == null
                                              ? const Icon(
                                                Icons.person,
                                                size: 60,
                                              )
                                              : null,
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: InkWell(
                                        onTap: _pickImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white,
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Center(
                                child: Text("Upload image up to 80 KB"),
                              ),
                              const SizedBox(height: 16),
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
                                label: 'Designation',
                                controller: _designationController,
                              ),
                              const SizedBox(height: 12),
                              _buildInputField(
                                label: 'Mobile',
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
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
                                  _checkForChanges();
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
                onPressed:
                    _isChanged
                        ? () async {
                          if (_formKey.currentState!.validate()) {
                            try {
                              final String name = _nameController.text.trim();
                              String fullname =
                                  name.isNotEmpty
                                      ? name[0].toUpperCase() +
                                          name.substring(1)
                                      : '';

                              Uint8List? imageBytes;
                              if (_newImageFile != null) {
                                imageBytes = await _newImageFile!.readAsBytes();
                              }

                              await TeacherApiServices.updateProfile(
                                username: widget.username,
                                data: {
                                  'name': fullname,
                                  'email': _emailController.text.trim(),
                                  'mobile': _mobileController.text.trim(),
                                  'designation':
                                      _designationController.text.trim(),
                                  'gender': _gender,
                                  if (imageBytes != null)
                                    'photo': base64Encode(imageBytes),
                                },
                                schoolId: widget.schoolId,
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Profile updated!'),
                                ),
                              );
                              StaffDashboardState.selectedIndex = 1;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => StaffDashboard(
                                        username: widget.username,
                                        schoolId: widget.schoolId.toString(),
                                      ),
                                ),
                              );
                            } catch (e) {
                              print(e);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Update failed: $e')),
                              );
                            }
                          }
                        }
                        : null,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
                backgroundColor: _isChanged ? Colors.blueAccent : Colors.grey,
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
      onChanged: (_) => _checkForChanges(), // ✅ Ensure validation re-checks
    );
  }
}
