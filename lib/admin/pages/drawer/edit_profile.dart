import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../services/admin_api_service.dart';
import 'admin_dashboard.dart';

class EditProfile extends StatefulWidget {
  final String username;
  final String schoolName;
  final String schoolAddress;
  final String schoolId;
  final VoidCallback onBack;
  const EditProfile({
    super.key,
    required this.username,
    required this.schoolName,
    required this.schoolAddress,
    required this.schoolId,
    required this.onBack,
  });

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _designationController;
  late TextEditingController _emailController;

  String adminName = '';
  String adminDesignation = '';
  String adminMobileNumber = '';
  String adminEmail = '';
  String adminGender = '';
  late String _initialGender;
  ImageProvider? _adminPhoto;
  Map<String, dynamic>? adminData;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;

  File? _newImageFile;

  @override
  void initState() {
    super.initState();
    initializeInitialData();
  }

  /// ✅ Checks if there are any changes
  void _checkForChanges() {
    final nameChanged = _nameController.text.trim() != adminName.trim();
    final mobileChanged =
        _mobileController.text.trim() != adminMobileNumber.trim();
    final designationChanged =
        _designationController.text.trim() != adminDesignation.trim();
    final emailChanged = _emailController.text.trim() != adminEmail.trim();
    final genderChanged = adminGender != _initialGender;
    final imageChanged = _newImageFile != null;

    final anyFieldEmpty =
        _nameController.text.trim().isEmpty ||
        _mobileController.text.trim().isEmpty ||
        _designationController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        adminGender.isEmpty;

    setState(() {
      _hasChanges =
          !anyFieldEmpty &&
          (nameChanged ||
              mobileChanged ||
              designationChanged ||
              emailChanged ||
              genderChanged ||
              imageChanged);
    });
  }

  Future<void> initializeInitialData() async {
    try {
      setState(() => _isLoading = true);
      adminData = await AdminApiService.fetchAdminData(
        username: widget.username,
        schoolId: widget.schoolId,
      );
      print(adminData?['gender']);
      adminName = adminData?['name'] ?? '';
      adminMobileNumber = adminData?['mobile'] ?? '';
      adminDesignation = adminData?['designation'] ?? '';
      adminEmail = adminData?['email'] ?? '';
      _initialGender = adminData?['gender'] ?? '';
      adminGender = _initialGender;

      if (adminData?['photo'] != null) {
        _adminPhoto = MemoryImage(base64Decode(adminData!['photo']));
      }

      _nameController = TextEditingController(text: adminName);
      _mobileController = TextEditingController(text: adminMobileNumber);
      _designationController = TextEditingController(text: adminDesignation);
      _emailController = TextEditingController(text: adminEmail);

      _nameController.addListener(_checkForChanges);
      _mobileController.addListener(_checkForChanges);
      _designationController.addListener(_checkForChanges);
      _emailController.addListener(_checkForChanges);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Initial load failed: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _designationController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// ✅ Compress image to ≤80KB
  Future<File?> _compressImage(File file) async {
    final bytes = await file.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return null;

    int quality = 90;
    File? compressedFile;
    final tempDir = await getTemporaryDirectory();

    do {
      final compressedBytes = img.encodeJpg(image, quality: quality);
      final targetPath =
          "${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg";
      compressedFile = File(targetPath)..writeAsBytesSync(compressedBytes);
      quality -= 10;
    } while (compressedFile.lengthSync() > 80 * 1024 && quality > 10);

    return compressedFile;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null && result.files.single.path != null) {
      File originalFile = File(result.files.single.path!);
      File? compressed = await _compressImage(originalFile);

      if (compressed != null) {
        setState(() {
          _newImageFile = compressed;
        });
        _checkForChanges();
      }
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      bool success = await AdminApiService.updateProfile(
        username: widget.username,
        name: _nameController.text,
        mobile: _mobileController.text,
        imageFile: _newImageFile,
        designation: _designationController.text,
        email: _emailController.text,
        gender: adminGender,
        schoolId: int.parse(widget.schoolId),
      );

      setState(() => _isSaving = false);

      if (success) {
        setState(() {
          adminName = _nameController.text;
          adminMobileNumber = _mobileController.text;
          adminDesignation = _designationController.text;
          adminEmail = _emailController.text;
          _initialGender = adminGender;
          adminData?['gender'] = adminGender;
          _newImageFile = null;
          _hasChanges = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Failed to update profile (image may be too large)',
            ),
          ),
        );
      }
    }
  }

  Future<bool> onWillPop() async {
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
        _newImageFile != null ? FileImage(_newImageFile!) : _adminPhoto;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
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
                  username: widget.username,
                  schoolId: widget.schoolId,
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
                  const SizedBox(height: 8),
                  const Center(child: Text("Upload image up to 80 KB")),
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

                  _buildTextField(
                    _designationController,
                    'Designation',
                    Icons.work,
                  ),
                  const SizedBox(height: 12),

                  _buildTextField(
                    _emailController,
                    'Email',
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    isEmail: true,
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    "Gender",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 12,
                    children: [
                      _buildGenderChip("Male", "M"),
                      _buildGenderChip("Female", "F"),
                      _buildGenderChip("Other", "O"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: _hasChanges && !_isSaving ? _saveProfile : null,
                    icon:
                        _isSaving
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: _hasChanges ? Colors.teal : Colors.grey,
                      foregroundColor: Colors.white,
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

  Widget _buildGenderChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: adminGender == value,
      onSelected: (_) {
        setState(() => adminGender = value);
        _checkForChanges();
      },
      selectedColor: Colors.teal.shade600,
      labelStyle: TextStyle(
        color: adminGender == value ? Colors.white : Colors.black87,
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
    bool isEmail = false,
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
        if (isEmail && value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
          if (!emailRegex.hasMatch(value.trim())) {
            return 'Please enter a valid email';
          }
        }
        return null;
      },
    );
  }
}
