import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/api_service.dart';
import '../../student/services/student_api_services.dart';
import '../../teacher/services/teacher_api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../components/uploads/uploads.dart';
import '../services/admin_api_service.dart';
import 'admin_dashboard.dart';

class BulkUploadRegisterAdmin extends StatefulWidget {
  final String schoolId;
  final String username;

  const BulkUploadRegisterAdmin({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<BulkUploadRegisterAdmin> createState() => _BulkUploadRegisterAdminState();
}

class _BulkUploadRegisterAdminState extends State<BulkUploadRegisterAdmin> {
  List<dynamic> student = [];
  Map<String, dynamic> studentData = {};
  List<dynamic> staff = [];
  Map<String, dynamic> staffData = {};
  List<dynamic> admin = [];
  Map<String, dynamic> adminData = {};

  bool isLoading = true;
  int _selectedIndex = 2;

  File? _selectedStudentExcelFile;
  File? _selectedAdminExcelFile;
  File? _selectedStaffExcelFile;

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdminDashboard(
          schoolId: widget.schoolId,
          username: widget.username,
        ),
      ),
    );
    return false;
  }

  @override
  void initState() {
    super.initState();
    init();
    initAdmin();
    initStaff();
  }

  Future<void> init() async {
    setState(() => isLoading = true);
    student = await ApiService.getUsersByRole('student');
    studentData.clear();
    List<Future<void>> futures = [];

    for (var user in student) {
      final username = user['username'];
      futures.add(
        StudentApiServices.fetchStudentDataUsername(username).then((data) {
          studentData[username] = data;
        }),
      );
    }

    await Future.wait(futures);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> initAdmin() async {
    setState(() => isLoading = true);
    admin = await ApiService.getUsersByRole('admin');
    adminData.clear();
    List<Future<void>> futures = [];

    for (var user in admin) {
      final username = user['username'];
      futures.add(
        AdminApiService.fetchAdminData(username).then((data) {
          adminData[username] = data;
        }),
      );
    }

    await Future.wait(futures);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> initStaff() async {
    setState(() => isLoading = true);
    staff = await ApiService.getUsersByRole('staff');
    staffData.clear();
    List<Future<void>> futures = [];

    for (var user in staff) {
      final username = user['username'];
      futures.add(
        TeacherApiServices.fetchStaffDataUsername(username).then((data) {
          staffData[username] = data;
        }),
      );
    }

    await Future.wait(futures);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> downloadTemplate(String fileName) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) status = await Permission.storage.request();
      if (!status.isGranted) {
        var manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          _showPermissionDenied();
          return;
        }
        status = manageStatus;
      }

      if (status.isGranted) {
        final byteData = await rootBundle.load('assets/$fileName');
        final directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) await directory.create(recursive: true);
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(byteData.buffer.asUint8List());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Template saved to: ${file.path}')),
        );
      } else {
        _showPermissionDenied();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  void _showPermissionDenied() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Storage permission denied')));
  }

  Future<void> downloadTemplateStudent() => downloadTemplate('Student.xlsx');
  Future<void> downloadTemplateAdmin() => downloadTemplate('Admin.xlsx');
  Future<void> downloadTemplateStaff() => downloadTemplate('Staff.xlsx');

  Future<File?> _pickExcelFile(String expectedFileName) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      final fileName = file.path.split('/').last;
      if (fileName != expectedFileName) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload only $expectedFileName')),
        );
        return null;
      }
      return file;
    }
    return null;
  }

  Future<void> pickExcelFileStudent() async {
    final file = await _pickExcelFile('Student.xlsx');
    if (file != null) setState(() => _selectedStudentExcelFile = file);
  }

  Future<void> pickExcelFileAdmin() async {
    final file = await _pickExcelFile('Admin.xlsx');
    if (file != null) setState(() => _selectedAdminExcelFile = file);
  }

  Future<void> pickExcelFileStaff() async {
    final file = await _pickExcelFile('Staff.xlsx');
    if (file != null) setState(() => _selectedStaffExcelFile = file);
  }

  Future<void> uploadFile(
      Future<Map<String, dynamic>?> Function(File, String) uploadFunction,
      Future<void> Function() refreshDataCallback,
      File excelFile,
      ) async {
    setState(() => isLoading = true);

    final result = await uploadFunction(excelFile, widget.schoolId);
    if (!mounted) return;
    setState(() => isLoading = false);

    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload failed')));
      return;
    }

    final created = result['created'] ?? <dynamic>[];
    final existing = result['alreadyExisting'] ?? <dynamic>[];
    final duplicates = result['duplicates'] ?? <dynamic>[];
    final empty = result['empty'] ?? <dynamic>[];
    final errors = result['errors'] ?? <dynamic>[];
    final message = result['message'] ?? 'No details provided.';

    if (created.isEmpty &&
        existing.isEmpty &&
        duplicates.isEmpty &&
        empty.isEmpty &&
        errors.isEmpty) {
      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
          title: const Text('Excel Upload Result'),
          content: const Text('Your Excel is empty.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
        title: const Text('Excel Upload Result'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(
                message,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              if (created.isNotEmpty) ...[
                const Text(
                  '✅ Created:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...created.map<Widget>(
                      (e) => Text(
                    'Row ${e['row']}: ${e['username']} - ${e['reason']}',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (existing.isNotEmpty) ...[
                const Text(
                  '⚠️ Already Exists:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...existing.map<Widget>(
                      (e) => Text(
                    'Row ${e['row']}: ${e['username']} - ${e['reason']}',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (duplicates.isNotEmpty) ...[
                const Text(
                  '⚠️ Duplicates:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...duplicates.map<Widget>(
                      (e) => Text(
                    'Row ${e['row']}: ${e['username']} - ${e['reason']}',
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (empty.isNotEmpty) ...[
                const Text(
                  '⚠️ Empty Rows:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...empty.map<Widget>(
                      (e) => Text('Row ${e['row']}: ${e['reason']}'),
                ),
                const SizedBox(height: 12),
              ],
              if (errors.isNotEmpty) ...[
                const Text(
                  '❌ Errors:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                ...errors.map<Widget>(
                      (e) => Text(
                    'Row ${e['row']}: ${e['username']} - ${e['reason']}',
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    await refreshDataCallback();
  }

  Future<void> uploadFileStudent() {
    if (_selectedStudentExcelFile == null) return Future.value();
    return uploadFile(
      AdminApiService.uploadStudentExcelFile,
      init,
      _selectedStudentExcelFile!,
    );
  }

  Future<void> uploadFileAdmin() {
    if (_selectedAdminExcelFile == null) return Future.value();
    return uploadFile(
      AdminApiService.uploadAdminExcelFile,
      initAdmin,
      _selectedAdminExcelFile!,
    );
  }

  Future<void> uploadFileStaff() {
    if (_selectedStaffExcelFile == null) return Future.value();
    return uploadFile(
      AdminApiService.uploadStaffExcelFile,
      initStaff,
      _selectedStaffExcelFile!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 60),
          child:
          isMobile
              ? AdminAppbarMobile(
            title: 'Bulk Uploads',
            enableDrawer: false,
            enableBack: true,
            onBack: () {
              AdminDashboardState.selectedIndex = 2;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => AdminDashboard(
                    schoolId: widget.schoolId,
                    username: widget.username,
                  ),
                ),
              );
            },
          )
              : const AdminAppbarDesktop(title: 'Bulk Uploads'),
        ),
        body:
        isLoading
            ? const Center(
          child: SpinKitFadingCircle(
            color: Colors.blueAccent,
            size: 60.0,
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _getBody(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() => _selectedIndex = index);
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings_outlined, size: 30),
              label: 'Admin Uploads',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add, size: 30),
              label: 'Staff Uploads',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_add_alt_1, size: 30),
              label: 'Student Uploads',
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return Uploads.buildAdminUpload(
          context: context,
          downloadTemplateAdmin: downloadTemplateAdmin,
          pickExcelFileAdmin: pickExcelFileAdmin,
          uploadFileAdmin: uploadFileAdmin,
          admin: admin,
          adminData: adminData,
          selectedExcelFile: _selectedAdminExcelFile,
        );
      case 1:
        return Uploads.buildStaffUpload(
          context: context,
          downloadTemplateStaff: downloadTemplateStaff,
          pickExcelFileStaff: pickExcelFileStaff,
          uploadFileStaff: uploadFileStaff,
          staff: staff,
          staffData: staffData,
          selectedExcelFile: _selectedStaffExcelFile,
        );
      case 2:
        return Uploads.buildStudentUpload(
          context: context,
          downloadTemplateStudent: downloadTemplateStudent,
          pickExcelFileStudent: pickExcelFileStudent,
          uploadFileStudent: uploadFileStudent,
          student: student,
          studentData: studentData,
          selectedExcelFile: _selectedStudentExcelFile,
        );
      default:
        return const SizedBox();
    }
  }
}
