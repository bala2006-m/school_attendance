import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
  final _idController = TextEditingController();

  File? _selectedImage;
  List<Map<String, dynamic>> schools = [];

  bool _isButtonEnabled = false;
  bool _isLoading = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    init();

    // Listen to input changes
    _nameController.addListener(_checkFormValidity);
    _addressController.addListener(_checkFormValidity);
    _idController.addListener(_checkFormValidity);
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
      (school) =>
          school['name'].toString().trim().toLowerCase() == name.toLowerCase(),
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

  void sendMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitForm() async {
    if (!_isButtonEnabled) return;

    if (_formKey.currentState!.validate()) {
      // // Optional: enforce school photo upload
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please upload a school photo")),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final name = _nameController.text.trim();
        final address = _addressController.text.trim();
        final schoolId = _idController.text.trim();

        final success = await AdministratorApiService.createSchool(
          name: name,
          address: address,
          photo: _selectedImage,
          schoolId: schoolId,
        );

        final res = jsonDecode(success!);

        if (res['name'] == name) {
          sendMessage("School registered successfully ✅");
          _nameController.clear();
          _addressController.clear();
          _idController.clear();
          setState(() {
            _selectedImage = null;
            _isButtonEnabled = false;
            _nameError = null;
          });
          await init(); // refresh list after successful registration
          widget.onRegister();
        } else if (res['message'] == 'School is already registered') {
          sendMessage("School is already registered");
        } else {
          sendMessage("Failed to register school");
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _idController.dispose();
    super.dispose();
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

              // School Photo Picker
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

              // School ID
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: "School Id",
                  border: OutlineInputBorder(),
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? "Please enter school id"
                            : null,
              ),
              const SizedBox(height: 16),

              // School Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "School Name",
                  border: const OutlineInputBorder(),
                  errorText: _nameError,
                ),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? "Please enter school name"
                            : null,
              ),
              const SizedBox(height: 16),

              // School Address
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
                        _isButtonEnabled ? Colors.teal : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed:
                      _isButtonEnabled && !_isLoading ? _submitForm : null,
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: Center(
                              child: SpinKitFadingCircle(
                                color: Colors.blueAccent,
                                size: 60.0,
                              ),
                            ),
                          )
                          : const Text(
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
