import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:school_attendance/administrator/services/administrator_api_service.dart';

import '../../services/api_service.dart';

class SchoolRegistration extends StatefulWidget {
  const SchoolRegistration({super.key, required this.onRegister});
  final VoidCallback onRegister;
  @override
  State<SchoolRegistration> createState() => _SchoolRegistrationState();
}

class _SchoolRegistrationState extends State<SchoolRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  File? _selectedImage;
  List<Map<String, dynamic>> schools = [];

  bool _isButtonEnabled = false; // ✅ button control
  String? _nameError; // ✅ inline error message

  @override
  void initState() {
    super.initState();
    init();

    // Listen to input changes
    _nameController.addListener(_checkFormValidity);
    _addressController.addListener(_checkFormValidity);
  }

  Future<void> init() async {
    final school = await ApiService.fetchSchools();
    setState(() {
      schools = school;
    });
  }

  void _checkFormValidity() {
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();

    // Check if school already exists
    final alreadyExists = schools.any(
      (school) => school['name'].toString().toLowerCase() == name.toLowerCase(),
    );

    setState(() {
      _nameError = alreadyExists ? "School is already registered" : null;
      _isButtonEnabled =
          name.isNotEmpty && address.isNotEmpty && !alreadyExists;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_isButtonEnabled) return; // prevent accidental submit

    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final address = _addressController.text.trim();

      final success = await AdministratorApiService.createSchool(
        name,
        address,
        _selectedImage,
      );
      final res = jsonDecode(success!);

      if (res['name'] == name) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("School registered successfully ✅")),
        );
        _nameController.clear();
        _addressController.clear();
        setState(() {
          _selectedImage = null;
          _isButtonEnabled = false; // reset
          _nameError = null;
        });
        widget.onRegister();
      } else if (res['message'] == 'School is already registered') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("School is already registered")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to register school")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueAccent,
                  backgroundImage:
                      _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                  child:
                      _selectedImage == null
                          ? const Icon(
                            Icons.add_a_photo,
                            size: 40,
                            color: Colors.white,
                          )
                          : null,
                ),
              ),
              const SizedBox(height: 24),

              // School Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "School Name",
                  border: const OutlineInputBorder(),
                  errorText: _nameError, // ✅ show inline error
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? "Please enter school name"
                            : null,
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: "School Address",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? "Please enter school address"
                            : null,
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor:
                        _isButtonEnabled ? Colors.teal : Colors.grey, // ✅
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isButtonEnabled ? _submitForm : null, // ✅
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    "Register School",
                    style: TextStyle(fontSize: 16, color: Colors.white),
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
