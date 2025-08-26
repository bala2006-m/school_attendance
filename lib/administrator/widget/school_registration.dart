import 'package:flutter/material.dart';

class SchoolRegistration extends StatefulWidget {
  const SchoolRegistration({super.key});

  @override
  State<SchoolRegistration> createState() => _SchoolRegistrationState();
}

class _SchoolRegistrationState extends State<SchoolRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final address = _addressController.text.trim();

      // 🔹 You can call your API service here to save school
      print("School registered: $name - $address");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("School '$name' registered successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register School"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.school, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 24),

                // School Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "School Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter school name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // School Address
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: "School Address",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Please enter school address";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitForm,
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
      ),
    );
  }
}
