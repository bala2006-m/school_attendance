import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/api_service.dart';
import '../../teacher/services/teacher_api_service.dart';
import '../appbar/admin_appbar_desktop.dart';
import '../appbar/admin_appbar_mobile.dart';
import '../components/uploads/uploads.dart';
import '../services/admin_api_service.dart';
import 'admin_dashboard.dart';

class BulkUploadRegisterStaff extends StatefulWidget {
  final String schoolId;
  final String username;

  const BulkUploadRegisterStaff({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<BulkUploadRegisterStaff> createState() =>
      _BulkUploadRegisterStaffState();
}

class _BulkUploadRegisterStaffState extends State<BulkUploadRegisterStaff> {
  List<dynamic> staff = [];
  Map<String, dynamic> staffData = {};

  bool isLoading = true;

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
    initStaff();
  }

  Future<void> initStaff() async {
    setState(() => isLoading = true);
    staff = await ApiService.getUsersByRole(
      role: 'staff',
      schoolId: int.parse(widget.schoolId),
    );
    staffData.clear();
    List<Future<void>> futures = [];

    for (var user in staff) {
      final username = user['username'];
      futures.add(
        TeacherApiServices.fetchStaffDataUsername(
          username: username,
          schoolId: int.parse(widget.schoolId),
        ).then((data) {
          staffData[username] = data;
        }),
      );
    }

    await Future.wait(futures);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _showPermissionDenied() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Storage permission denied')));
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
    final mismatched = result['mismatched'] ?? <dynamic>[]; // ✅ NEW
    final errors = result['errors'] ?? <dynamic>[];
    final message = result['message'] ?? 'No details provided.';

    if (created.isEmpty &&
        existing.isEmpty &&
        duplicates.isEmpty &&
        empty.isEmpty &&
        mismatched.isEmpty &&
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
                  if (mismatched.isNotEmpty) ...[
                    // ✅ NEW HANDLING
                    const Text(
                      '⚠️ Mismatched School IDs:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    ...mismatched.map<Widget>(
                      (e) => Text(
                        'Row ${e['row']}: ${e['username']} - Expected: ${e['expected']}, Found: ${e['found']}',
                      ),
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
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Bulk Upload Staff',
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
                  : const AdminAppbarDesktop(title: 'Bulk Upload Staff'),
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
      ),
    );
  }

  Widget _getBody() {
    return Uploads.buildStaffUpload(
      context: context,
      downloadTemplateStaff: downloadTemplateStaff,
      pickExcelFileStaff: pickExcelFileStaff,
      uploadFileStaff: uploadFileStaff,
      staff: staff,
      staffData: staffData,
      selectedExcelFile: _selectedStaffExcelFile,
    );
  }
}
