import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_attendance/student/pages/student_dashboard.dart';

import '../Appbar/student_appbar_desktop.dart';
import '../Appbar/student_appbar_mobile.dart';
import '../services/student_api_services.dart';

class EditProfile extends StatefulWidget {
  final String username;
  final int schoolId;
  const EditProfile({
    super.key,
    required this.username,
    required this.onSave,
    required this.schoolId,
  });
  final VoidCallback onSave;
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  Map<String, dynamic>? studentData;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  String? _gender;
  File? _photoFile;
  Uint8List? _photoBytes;
  bool _loading = false;
  bool _fetching = true;
  bool _hasChanges = false;

  final picker = ImagePicker();
  final studentService = StudentApiServices();

  @override
  void initState() {
    super.initState();
    _init();
    _nameCtrl.addListener(_checkChanges);
    _emailCtrl.addListener(_checkChanges);
    _mobileCtrl.addListener(_checkChanges);
  }

  void _checkChanges() {
    if (studentData == null) return;

    final changed =
        _nameCtrl.text.trim() != (studentData?['name'] ?? '') ||
        _emailCtrl.text.trim() != (studentData?['email'] ?? '') ||
        _mobileCtrl.text.trim() != (studentData?['mobile'] ?? '') ||
        _gender != (studentData?['gender'] ?? '') ||
        _photoFile != null;

    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  Future<void> _init() async {
    try {
      final data = await StudentApiServices.fetchStudentDataUsername(
        username: widget.username,
        schoolId: widget.schoolId,
      );

      Uint8List? bytes;
      File? file;

      if (data?['photo'] != null) {
        if (data?['photo'] is Map) {
          bytes = Uint8List.fromList(
            (data?['photo'] as Map).values.cast<int>().toList(),
          );
        } else if (Uri.tryParse(data?['photo'])?.isAbsolute ?? false) {
          file = null;
        } else if (data!['photo'].toString().isNotEmpty) {
          file = File(data['photo']);
        }
      }

      setState(() {
        studentData = data;
        _nameCtrl.text = data?['name'] ?? '';
        _emailCtrl.text = data?['email'] ?? '';
        _mobileCtrl.text = data?['mobile'] ?? '';
        _gender = data?['gender'] ?? '';
        _photoFile = file;
        _photoBytes = bytes;
        _fetching = false;
        _hasChanges = false;
      });
    } catch (e) {
      setState(() => _fetching = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Failed to load profile: $e")));
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _photoFile = File(picked.path);
        _photoBytes = null;
      });
      _checkChanges();
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final res = await studentService.updateStudent(
      schoolId: widget.schoolId,
      username: widget.username,
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      mobile: _mobileCtrl.text.trim().isEmpty ? null : _mobileCtrl.text.trim(),
      gender: _gender,
      photoFile: _photoFile,
    );

    setState(() => _loading = false);

    if (res["status"] == "success") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Profile updated successfully!")),
      );
      widget.onSave;
      StudentDashboardState.selectedIndex = 1;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => StudentDashboard(
                username: widget.username,
                schoolId: widget.schoolId,
              ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ ${res["message"]}")));
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 500;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? StudentAppbarMobile(
                  title: 'Edit Profile',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentDashboard(
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
                  },
                )
                : const StudentAppbarDesktop(title: 'Edit Profile'),
      ),
      body:
          _fetching
              ? const Center(
                child: SpinKitFadingCircle(
                  color: Colors.blueAccent,
                  size: 60.0,
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Avatar
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 55,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage:
                                  _photoFile != null
                                      ? FileImage(_photoFile!)
                                      : (_photoBytes != null
                                              ? MemoryImage(_photoBytes!)
                                              : (studentData?['photo'] !=
                                                          null &&
                                                      Uri.tryParse(
                                                            studentData!['photo'],
                                                          )?.isAbsolute ==
                                                          true
                                                  ? NetworkImage(
                                                    studentData!['photo'],
                                                  )
                                                  : const AssetImage(
                                                    'assets/default_avatar.png',
                                                  )))
                                          as ImageProvider,
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Center(child: Text("Upload image up to 80 KB")),
                      const SizedBox(height: 20),

                      // Name
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: _inputDecoration("Name", Icons.person),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Name cannot be empty";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: _inputDecoration("Email", Icons.email),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Email cannot be empty";
                          }
                          if (!v.contains("@")) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Mobile
                      TextFormField(
                        controller: _mobileCtrl,
                        decoration: _inputDecoration("Mobile", Icons.phone),
                      ),
                      const SizedBox(height: 12),

                      // Gender Toggle Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ToggleButtons(
                              isSelected: [
                                _gender == 'M',
                                _gender == 'F',
                                _gender == 'O',
                              ],
                              onPressed: (index) {
                                setState(() {
                                  _gender = ['M', 'F', 'O'][index];
                                });
                                _checkChanges();
                              },
                              borderRadius: BorderRadius.circular(12),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text("Male"),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text("Female"),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: Text("Other"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                _hasChanges
                                    ? Colors.blue
                                    : Colors.grey.shade400,
                          ),
                          onPressed:
                              _loading || !_hasChanges ? null : _saveProfile,
                          child:
                              _loading
                                  ? const SpinKitFadingCircle(
                                    color: Colors.blueAccent,
                                    size: 60.0,
                                  )
                                  : const Text(
                                    "Save Changes",
                                    style: TextStyle(fontSize: 16),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
