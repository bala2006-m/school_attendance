import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:school_attendance/admin/pages/print_certificates/student/student_certificates.dart';

import '../../../../services/api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import './widget/build_periodical_report_student.dart';

class Download extends StatefulWidget {
  const Download({
    super.key,
    required this.username,
    required this.studentUsername,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.section,
  });
  final String username;
  final String className;
  final String section;
  final String schoolId;
  final String classId;
  final String studentUsername;

  @override
  State<Download> createState() => _DownloadState();
}

class _DownloadState extends State<Download> {
  // --- State for pickers ---
  Map<String, dynamic>? studentData;
  String? selectedMonth;
  String? selectedYear;
  DateTime? fromDate;
  DateTime? toDate;
  Map<String, dynamic> monthlyAttendanceData = {};
  Map<String, dynamic> periodicAttendanceData = {};
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  @override
  void initState() {
    super.initState();
    fetchStudentData();
    fetchSchoolInfo();
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];
        if (schoolData[0]['photo'] != null) {
          Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
          schoolPhotoBytes = imageBytes;
        }
      }
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> fetchStudentData() async {
    try {
      final data = await ApiService.fetchStudentDetails(
        widget.schoolId,
        widget.classId,
        widget.studentUsername,
      );
      if (mounted) {
        setState(() {
          studentData = data;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load student data")),
        );
      }
    }
  }

  Future<void> fetchPeriodicAttendance({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      final data = await AdminApiService.fetchStudentAttendanceBetweenDays(
        username: widget.studentUsername,
        fromDate: fromDate,
        toDate: toDate,
        schoolId: int.parse(widget.schoolId),
      );
      if (mounted) {
        setState(() {
          periodicAttendanceData = data!;
        });
      }

      await generateAttendancePdf(
        title:
            "Date: ${fromDate.toLocal().toIso8601String().split('T')[0]} - ${toDate.toLocal().toIso8601String().split('T')[0]}",

        attendanceData: data!,
        studentData: studentData,
        schoolName: schoolName,
        schoolAddress: schoolAddress,
        schoolPhotoBytes: schoolPhotoBytes,
        studentUsername: widget.studentUsername,
      );
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> generateAttendancePdf({
    required String title,
    required Map<String, dynamic> attendanceData,
    required Map<String, dynamic>? studentData,
    required Uint8List? schoolPhotoBytes,
    required String? schoolName,
    required String? schoolAddress,
    required String studentUsername,
  }) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              title: 'Periodical Report Student',
              fileName: 'periodical_report_$studentUsername',
              buildPdf:
                  () => buildPdf(
                    schoolPhotoBytes: schoolPhotoBytes,
                    title: title,
                    attendanceData: attendanceData,
                    studentData: studentData,
                    schoolName: schoolName,
                    schoolAddress: schoolAddress,
                    studentUsername: studentUsername,
                  ),
            ),
      ),
    );
  }

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => StudentCertificates(
              username: widget.username,
              classId: widget.classId,
              className: widget.className,
              section: widget.section,
              schoolId: widget.schoolId,
            ),
      ),
    );
    return false;
  }

  Future<void> pickMonthYear() async {
    final picked = await showMonthYearPicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.2)),
          child: Theme(
            data: Theme.of(context).copyWith(
              dialogTheme: DialogThemeData(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              textTheme: TextTheme(
                headlineMedium: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                titleLarge: TextStyle(fontSize: 13),
                bodyLarge: TextStyle(fontSize: 11),
              ),
            ),
            child: child!,
          ),
        );
      },
    );

    if (picked == null) return;

    setState(() {
      selectedMonth = picked.month.toString().padLeft(2, "0");
      selectedYear = picked.year.toString();
    });
  }

  // --- Date Pickers for periodic attendance ---
  Future<void> pickFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: "Select Start Date",
    );

    if (picked != null) {
      setState(() {
        fromDate = picked;
      });
    }
  }

  Future<void> pickToDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: "Select End Date",
    );

    if (picked != null) {
      setState(() {
        toDate = picked;
      });
    }
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
                    title: 'Generate Report',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      onWillPop();
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Generate Report',

                    onBack: () {
                      onWillPop();
                    },
                  ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 600,
              ), // keeps it centered
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // --- Student Profile Card ---
                    if (studentData != null)
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.blue.shade100,
                                child: const Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                studentData!['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "ID: ${widget.studentUsername}",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const Divider(height: 30),
                              Column(
                                // mainAxisAlignment:
                                //     MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildInfoTile(
                                    Icons.email,
                                    studentData!['email'] ?? '',
                                  ),
                                  _buildInfoTile(
                                    Icons.phone,
                                    studentData!['mobile'] ?? '',
                                  ),
                                  _buildInfoTile(
                                    studentData!['gender'] == 'F'
                                        ? Icons.female
                                        : Icons.male,
                                    studentData!['gender'] ?? '',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: SpinKitFadingCircle(
                          color: Colors.blueAccent,
                          size: 60.0,
                        ),
                      ),

                    const SizedBox(height: 30),

                    const SizedBox(height: 30),

                    // --- Periodic Certificate ---
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            const Text(
                              'Periodic Attendance Report',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              (fromDate != null && toDate != null)
                                  ? "From: ${fromDate!.toLocal().toString().split(' ')[0]} → To: ${toDate!.toLocal().toString().split(' ')[0]}"
                                  : "Select a date range",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: pickFromDate,
                                    child: Text(
                                      fromDate != null
                                          ? "From: ${fromDate!.toLocal().toString().split(' ')[0]}"
                                          : "From Date",
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: pickToDate,
                                    child: Text(
                                      toDate != null
                                          ? "To: ${toDate!.toLocal().toString().split(' ')[0]}"
                                          : "To Date",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed:
                                  (fromDate != null && toDate != null)
                                      ? () {
                                        fetchPeriodicAttendance(
                                          fromDate: fromDate!,
                                          toDate: toDate!,
                                        );
                                      }
                                      : null,
                              icon: const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Generate PDF",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- helper widget for student info ---
  Widget _buildInfoTile(IconData icon, String text) {
    return Row(
      children: [
        const SizedBox(width: 12),
        Icon(icon, color: Colors.blueAccent),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
