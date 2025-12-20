import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../services/api_service.dart';
import '../../../../teacher/services/teacher_api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../components/uploads/uploads.dart';
import '../../../services/admin_api_service.dart';
import '../../dashboard/admin_dashboard.dart';

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
  int selectedIndex = 0; // 0 = Teaching, 1 = Non-Teaching

  bool isLoading = true;
  File? _selectedStaffExcelFile;

  @override
  void initState() {
    super.initState();
    _initStaff();
  }

  Future<void> _initStaff() async {
    setState(() => isLoading = true);
    staff = await ApiService.getUsersByRole(
      role: 'staff',
      schoolId: int.parse(widget.schoolId),
    );
    staffData.clear();

    // Fetch detailed data for each staff
    List<Future<void>> futures = [];
    for (var user in staff) {
      final username = user['username'];
      futures.add(
        TeacherApiServices.fetchStaffDataUsername(
          username: username,
          schoolId: int.parse(widget.schoolId),
        ).then((data) => staffData[username] = data),
      );
    }
    await Future.wait(futures);

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  // Filter staff based on selected index
  List<dynamic> get filteredStaff {
    if (selectedIndex == 0) {
      // Teaching
      return staff
          .where(
            (s) =>
                staffData[s['username']]?['faculty']?.toLowerCase() ==
                'teaching',
          )
          .toList();
    } else if (selectedIndex == 1) {
      // Non-Teaching
      return staff
          .where(
            (s) =>
                staffData[s['username']]?['faculty']?.toLowerCase() ==
                'nonteaching',
          )
          .toList();
    } else {
      return staff;
    }
  }

  Future<bool> _onWillPop() async {
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

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _downloadTemplate(String fileName) async {
    try {
      var status = await Permission.storage.status;
      if (!status.isGranted) status = await Permission.storage.request();
      if (!status.isGranted) {
        _showSnack('Storage permission denied');
        return;
      }

      final byteData = await rootBundle.load('assets/$fileName');
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) await directory.create(recursive: true);
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      _showSnack('Template saved to: ${file.path}');
    } catch (e) {
      _showSnack('Download failed: $e');
    }
  }

  Future<File?> _pickExcelFile(String expectedFileName) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null) {
      final file = File(result.files.single.path!);
      final fileName = file.path.split('/').last;
      if (fileName != expectedFileName) {
        _showSnack('Please upload only $expectedFileName');
        return null;
      }
      return file;
    }
    return null;
  }

  Future<void> _pickStaffFile() async {
    final file = await _pickExcelFile('Staff.xlsx');
    if (file != null) setState(() => _selectedStaffExcelFile = file);
  }

  Future<void> _uploadFileStaff() async {
    if (_selectedStaffExcelFile == null) return;

    setState(() => isLoading = true);
    final faculty =
        selectedIndex == 0
            ? 'teaching'
            : selectedIndex == 1
            ? 'nonteaching'
            : 'null';

    final result = await AdminApiService.uploadStaffExcelFile(
      _selectedStaffExcelFile!,
      widget.schoolId,
      faculty,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result == null) {
      _showSnack('Upload failed');
      return;
    }

    final created = result['created'] ?? <dynamic>[];
    final existing = result['alreadyExisting'] ?? <dynamic>[];
    final duplicates = result['duplicates'] ?? <dynamic>[];
    final empty = result['empty'] ?? <dynamic>[];
    final mismatched = result['mismatched'] ?? <dynamic>[];
    final errors = result['errors'] ?? <dynamic>[];
    final message = result['message'] ?? 'No details provided.';

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

    await _initStaff();
  }

  List<dynamic> groupAndSortAdmins(
    List<dynamic> admins,
    Map<String, dynamic> adminData,
  ) {
    // Filter groups
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

    // Sort by name inside each group (case-insensitive)
    int nameComparator(a, b) {
      final aName =
          (adminData[a['username']]?['name'] ?? '').toString().toLowerCase();
      final bName =
          (adminData[b['username']]?['name'] ?? '').toString().toLowerCase();
      return aName.compareTo(bName);
    }

    males.sort(nameComparator);
    females.sort(nameComparator);

    // Combine with males on top
    return [...males, ...females];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final adminsToShow = groupAndSortAdmins(filteredStaff, staffData);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, res) {
        if (!didPop) {
          _onWillPop();
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
                    title: 'Bulk Upload Staff',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: _onWillPop,
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Bulk Upload Staff',

                    onBack: _onWillPop,
                  ),
        ),
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(
                    color: Colors.blueAccent,
                    size: 60,
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Uploads.buildStaffUpload(
                    context: context,
                    downloadTemplateStaff:
                        () => _downloadTemplate('Staff.xlsx'),
                    pickExcelFileStaff: _pickStaffFile,
                    uploadFileStaff: _uploadFileStaff,
                    staff: adminsToShow, // Filtered staff list
                    staffData: staffData,
                    selectedExcelFile: _selectedStaffExcelFile,
                  ),
                ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          selectedItemColor: Colors.pink,
          unselectedItemColor: Colors.grey,
          onTap: (index) => setState(() => selectedIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people, size: 30),
              label: 'Teaching',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline, size: 30),
              label: 'Non Teaching',
            ),
          ],
        ),
      ),
    );
  }
}
