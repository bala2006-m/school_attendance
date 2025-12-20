import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:school_attendance/admin/pages/print_certificates/student/print_student_certificates.dart';

import '../../../../services/api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../../widget/pdf_preview_custom_page.dart';
import '../../dashboard/admin_dashboard.dart';
import './widget/build_periodical_report_school.dart';

class PeriodicallyAttendanceReport extends StatefulWidget {
  const PeriodicallyAttendanceReport({
    super.key,
    required this.username,
    required this.schoolId,
  });

  final String username;
  final String schoolId;

  @override
  State<PeriodicallyAttendanceReport> createState() =>
      _PeriodicallyAttendanceReportState();
}

class _PeriodicallyAttendanceReportState
    extends State<PeriodicallyAttendanceReport> {
  List<dynamic> students = [];
  bool isLoading = false;
  bool isDownloading = false;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  DateTime? fromDate;
  DateTime? toDate;
  @override
  void initState() {
    super.initState();
  }

  Future<void> init({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      students = [];

      // Fetch school info asynchronously (no await to parallelize)
      fetchSchoolInfo();

      // Fetch student attendance report from backend API
      final fetchedStudents = await AdminApiService.fetchPeriodicalReportAll(
        schoolId: widget.schoolId,
        fromDate: fromDate,
        toDate: toDate,
      );
      students = fetchedStudents;

      // Sort students by class_id
      students.sort((a, b) => a["class_id"].compareTo(b["class_id"]));
    } catch (e) {
      setState(() {});
    }
  }

  Future<void> handleDownload() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf:
                  () => buildPdf(
                    students: students,
                    schoolName: schoolName,
                    schoolAddress: schoolAddress,
                    schoolPhotoBytes: schoolPhotoBytes,
                    fromDate: fromDate,
                    toDate: toDate,
                  ),
              title: 'Periodical Report',
              fileName: 'periodical_report',
            ),
      ),
    );
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
                    title: 'Periodical Report',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
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
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Class List',

                    onBack: () {
                      AdminDashboardState.selectedIndex = 2;
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
        body:
            isLoading
                ? const Center(
                  child: SpinKitFadingCircle(color: Colors.blue, size: 50),
                )
                : SingleChildScrollView(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: pickFromDate,
                                child: Text(
                                  fromDate == null
                                      ? 'Select From Date'
                                      : 'From: ${fromDate!.toLocal().toIso8601String().split('T')[0]}',
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton(
                                onPressed: pickToDate,
                                child: Text(
                                  toDate == null
                                      ? 'Select To Date'
                                      : 'To: ${toDate!.toLocal().toIso8601String().split('T')[0]}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                          Text(
                            'Do you want to Generate the Periodical Student Attendance Report as a PDF For whole School?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed:
                                (fromDate != null &&
                                        toDate != null &&
                                        isDateRangeValid() &&
                                        !isDownloading)
                                    ? () async {
                                      setState(() {
                                        isLoading = true;
                                      });

                                      await init(
                                        fromDate: fromDate!,
                                        toDate: toDate!,
                                      );

                                      setState(() {
                                        isLoading = false;
                                      });

                                      if (students.isNotEmpty) {
                                        await handleDownload();
                                      }
                                    }
                                    : null,
                            icon:
                                isDownloading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: Center(
                                        child: SpinKitFadingCircle(
                                          color: Colors.blueAccent,
                                          size: 60.0,
                                        ),
                                      ),
                                    )
                                    : const Icon(Icons.download_rounded),
                            label: Text(
                              isDownloading ? 'Generating...' : 'Generate PDF',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),

                          const SizedBox(height: 60),
                          Text(
                            'Do you want to Generate the Periodical Student Attendance Report as a PDF For Class Wise?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => PrintStudentCertificates(
                                        username: widget.username,
                                        schoolId: widget.schoolId,
                                      ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_right_alt_sharp),
                            label: const Text('Class Wise'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 15,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];

        if (schoolData[0]['photo'] != null) {
          schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
        }
      }
    } catch (e) {
      setState(() {});
    }
  }

  Future<bool> onWillPop() async {
    AdminDashboardState.selectedIndex = 2;
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

  bool isDateRangeValid() {
    if (fromDate == null || toDate == null) return false;
    return !toDate!.isBefore(fromDate!);
  }
}
