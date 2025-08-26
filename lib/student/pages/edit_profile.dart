import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/student_api_services.dart';

class EditProfile extends StatefulWidget {
  final String username;
  const EditProfile({super.key, required this.username});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  String? _gender;
  File? _photoFile;

  bool _loading = false;

  final picker = ImagePicker();
  final studentService = StudentApiServices();

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _photoFile = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final res = await studentService.updateStudent(
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
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ ${res["message"]}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _photoFile != null
                          ? FileImage(_photoFile!)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.camera_alt, size: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        v != null && v.trim().isEmpty
                            ? "Name cannot be empty"
                            : null,
              ),
              const SizedBox(height: 12),

              // Email
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (v) =>
                        v != null && !v.contains("@")
                            ? "Enter a valid email"
                            : null,
              ),
              const SizedBox(height: 12),

              // Mobile
              TextFormField(
                controller: _mobileCtrl,
                decoration: const InputDecoration(
                  labelText: "Mobile",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _gender,
                items: const [
                  DropdownMenuItem(value: "M", child: Text("Male")),
                  DropdownMenuItem(value: "F", child: Text("Female")),
                  DropdownMenuItem(value: "O", child: Text("Other")),
                ],
                decoration: const InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => setState(() => _gender = val),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveProfile,
                  child:
                      _loading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
