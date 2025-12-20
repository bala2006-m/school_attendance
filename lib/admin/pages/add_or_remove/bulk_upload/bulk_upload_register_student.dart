import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../services/api_service.dart';
import '../../../../student/services/student_api_services.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/uploads/uploads.dart';
import '../../../services/admin_api_service.dart';
import '../../dashboard/admin_dashboard.dart';

class BulkUploadRegisterStudent extends StatefulWidget {
  final String schoolId;
  final String username;

  const BulkUploadRegisterStudent({
    super.key,
    required this.schoolId,
    required this.username,
  });

  @override
  State<BulkUploadRegisterStudent> createState() =>
      _BulkUploadRegisterStudentState();
}

class _BulkUploadRegisterStudentState extends State<BulkUploadRegisterStudent> {
  List<dynamic> student = [];
  Map<String, dynamic> studentData = {};

  bool isLoading = true;

  File? _selectedStudentExcelFile;

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
    Navigator.push(
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
  }

  Future<void> init() async {
    setState(() => isLoading = true);
    student = await ApiService.getUsersByRole(
      role: 'student',
      schoolId: int.parse(widget.schoolId),
    );
    studentData.clear();
    List<Future<void>> futures = [];

    for (var user in student) {
      final username = user['username'];
      futures.add(
        StudentApiServices.fetchStudentDataUsername(
          username: username,
          schoolId: int.parse(widget.schoolId),
        ).then((data) {
          studentData[username] = data;
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
          _showPermissionDenied('Storage permission denied');
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

        _showPermissionDenied('Template saved to: ${file.path}');
      } else {
        _showPermissionDenied('Storage permission denied');
      }
    } catch (e) {
      _showPermissionDenied('Download failed:');
    }
  }

  void _showPermissionDenied(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        _showPermissionDenied('Please upload only $expectedFileName');
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

  Future<void> uploadFileStudent() {
    if (_selectedStudentExcelFile == null) return Future.value();
    return uploadFile(
      AdminApiService.uploadStudentExcelFile,
      init,
      _selectedStudentExcelFile!,
    );
  }

  List<dynamic> sortedGroupedStudents(
    List<dynamic> admins,
    Map<String, dynamic> adminData,
  ) {
    int usernameComparator(a, b) {
      // Sort numbers as numbers, strings lexicographically
      final aStr = a['username'].toString();
      final bStr = b['username'].toString();
      final aNum = num.tryParse(aStr);
      final bNum = num.tryParse(bStr);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      } else {
        return aStr.compareTo(bStr);
      }
    }

    // Group by gender
    List<dynamic> males =
        admins.where((admin) {
          final data = adminData[admin['username']] ?? {};
          return (data['gender'] ?? '').toUpperCase() == 'M';
        }).toList();

    List<dynamic> females =
        admins.where((admin) {
          final data = adminData[admin['username']] ?? {};
          return (data['gender'] ?? '').toUpperCase() == 'F';
        }).toList();

    // Sort each group by username
    males.sort(usernameComparator);
    females.sort(usernameComparator);

    // Concatenate, males first
    return [...males, ...females];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          onWillPop();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Bulk Upload Student',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Bulk Upload Student',

                    onBack: () {
                      onWillPop();
                    },
                  ),
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
    final adminsToShow = sortedGroupedStudents(student, studentData);

    return Uploads.buildStudentUpload(
      context: context,
      downloadTemplateStudent: downloadTemplateStudent,
      pickExcelFileStudent: pickExcelFileStudent,
      uploadFileStudent: uploadFileStudent,
      student: adminsToShow,
      studentData: studentData,
      selectedExcelFile: _selectedStudentExcelFile,
    );
  }
}
