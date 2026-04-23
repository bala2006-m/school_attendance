import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
import '../dashboard/admin_dashboard.dart';

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

  void _removeImage() {
    setState(() {
      _newImageFile = null;
      _checkForChanges();
    });
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Profile updated successfully')),
          );
        }
      } else {
        if (mounted) {
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
  }

  Future<bool> onWillPop() async {
    Navigator.push(
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
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
        isMobile
            ? AdminAppbarMobile(
          username: widget.username,
          schoolId: widget.schoolId,
          title: 'Edit Profile',
          enableDrawer: false,
          enableBack: true,
          onBack: () {
            Navigator.push(
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
            : AdminAppbarDesktop(
          username: widget.username,
          schoolId: widget.schoolId,
          title: 'Edit Profile',

          onBack: () {
            Navigator.push(
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
        ),
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
                          radius: 70,
                          backgroundImage: imageProvider,
                          child:
                          imageProvider == null
                              ? const Icon(Icons.person, size: 70)
                              : null,
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: _newImageFile != null
                              ? InkWell(
                            onTap: _removeImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent,
                              ),
                              child: const Icon(Icons.clear, size: 20, color: Colors.white),
                            ),
                          )
                              : InkWell(
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
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      "Upload image up to 80 KB",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildTextField(_nameController, 'Full Name', Icons.person),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _mobileController,
                    'Mobile Number',
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _designationController,
                    'Designation',
                    Icons.work,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    _emailController,
                    'Email',
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    isEmail: true,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    "Gender",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _buildGenderChip("Male", "M"),
                      _buildGenderChip("Female", "F"),
                      _buildGenderChip("Other", "O"),
                    ],
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton.icon(
                    onPressed: _hasChanges && !_isSaving ? _saveProfile : null,
                    icon:
                    _isSaving
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: Center(
                        child: SpinKitFadingCircle(
                          color: Colors.white,
                          size: 20.0,
                        ),
                      ),
                    )
                        : const Icon(Icons.save, size: 20),
                    label: Text(
                      _isSaving ? 'Saving...' : 'Save Changes',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: _hasChanges ? Colors.teal : Colors.grey[300]!,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _hasChanges && !_isSaving ? 2 : 0,
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenderChip(String label, String value) {
    return FilterChip(
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
      avatar: const CircleAvatar(
        backgroundColor: Colors.transparent,
        radius: 0,
      ),
      showCheckmark: false,
      labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      side: BorderSide(
        color: adminGender == value ? Colors.teal.shade600 : Colors.grey[300]!,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
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
        prefixIcon: Icon(icon, color: Colors.teal[700]),
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.teal,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.redAccent,
            width: 2.0,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        suffixIcon: controller.text.isNotEmpty && !readOnly
            ? IconButton(
          icon: const Icon(Icons.clear, size: 20),
          color: Colors.grey[400],
          onPressed: () {
            controller.clear();
            _checkForChanges();
          },
        )
            : null,
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
      style: const TextStyle(fontSize: 16),
      cursorColor: Colors.teal,
    );
  }
}