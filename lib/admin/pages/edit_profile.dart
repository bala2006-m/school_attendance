import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../services/admin_api_service.dart';
import 'admin_dashboard.dart';

class EditProfile extends StatefulWidget {
  final String username;
  final String schoolName;
  final String schoolAddress;
  final String schoolId;
  const EditProfile({
    super.key,
    required this.username,
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolId,
  });

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  String adminName = '';
  String adminDesignation = '';
  String adminMobileNumber = '';
  Image? adminPhoto;
  Map<String, dynamic>? adminData;
  bool _isLoading = true;

  File? _newImageFile;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    initializeInitialData();
  }

  void _checkForChanges() {
    final nameChanged = _nameController.text.trim() != adminName.trim();
    final mobileChanged =
        _mobileController.text.trim() != adminMobileNumber.trim();
    final imageChanged = _newImageFile != null;

    final anyFieldEmpty =
        _nameController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty;

    setState(() {
      _hasChanges =
          !anyFieldEmpty && (nameChanged || mobileChanged || imageChanged);
    });
  }

  Future<void> initializeInitialData() async {
    try {
      setState(() => _isLoading = true);
      adminData = await AdminApiService.fetchAdminData(widget.username);
      adminName = adminData?['name'] ?? '';
      adminMobileNumber = adminData?['mobile'] ?? '';
      adminDesignation = adminData?['designation'] ?? '';

      if (adminData?['photo'] != null) {
        adminPhoto = Image.memory(base64Decode(adminData!['photo']));
      }

      // ✅ Initialize controllers with actual data
      _nameController = TextEditingController(text: adminName);
      _mobileController = TextEditingController(text: adminMobileNumber);
      _nameController.addListener(_checkForChanges);
      _mobileController.addListener(_checkForChanges);

      setState(() => _isLoading = false);
    } catch (e) {
      print('Initial load failed: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      setState(() {
        _newImageFile = File(result.files.single.path!);
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      bool success = await AdminApiService.updateProfile(
        username: widget.username,
        name: _nameController.text,
        mobile: _mobileController.text,
        imageFile: _newImageFile,
        designation: adminDesignation,
      );

      if (success) {
        setState(() {
          initializeInitialData();
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Failed to update profile')),
        );
      }
    }
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 0;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => AdminDashboard(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final ImageProvider? imageProvider =
        _newImageFile != null ? FileImage(_newImageFile!) : adminPhoto?.image;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitFadingCircle(color: Colors.blueAccent, size: 60.0),
        ),
      );
    }
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 60),
        child:
            isMobile
                ? AdminAppbarMobile(
                  title: 'Edit Profile',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AdminDashboard(
                              schoolId: widget.schoolId,
                              username: widget.username,
                            ),
                      ),
                    );
                  },
                )
                : const AdminAppbarDesktop(title: 'Edit Profile'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 600,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  ? const Icon(Icons.person, size: 60)
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
                              child: const Icon(Icons.edit, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(_nameController, 'Full Name', Icons.person),
                  const SizedBox(height: 12),

                  _buildTextField(
                    _mobileController,
                    'Mobile Number',
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _hasChanges ? _saveProfile : null,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        if (!readOnly && (value == null || value.trim().isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
