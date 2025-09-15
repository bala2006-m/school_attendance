import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../../../services/api_service.dart';
import '../../../student/services/student_api_services.dart';
import '../../appbar/admin_appbar_desktop.dart';
import '../../appbar/admin_appbar_mobile.dart';
import '../../services/admin_api_service.dart';
import '../dashboard/admin_dashboard.dart';
import 'build_daily_report.dart';

class DailyReport extends StatefulWidget {
  const DailyReport({
    super.key,
    required this.username,
    required this.schoolId,
  });
  final String username;
  final String schoolId;
  @override
  State<DailyReport> createState() => _DailyReportState();
}

class _DailyReportState extends State<DailyReport> {
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  bool isLoading = false;
  DateTime? date;
  bool isDownloading = false;
  List<Map<String, dynamic>> students = [];

  Future<void> fetchStudents() async {
    try {
      students = []; // Clear old data
      await fetchSchoolInfo();
      students = await AdminApiService.fetchAllStudentData(widget.schoolId);

      students.sort((a, b) => a["class_id"].compareTo(b["class_id"]));

      await Future.wait(
        students.map((student) async {
          try {
            final classData = await StudentApiServices.fetchClassDatas(
              widget.schoolId,
              student["class_id"].toString(),
            );
            student['class'] = classData?['class'] ?? '';
            student['section'] = classData?['section'] ?? '';

            final data =
                await AdminApiService.fetchStudentAttendanceBetweenDays(
                  username: student['username'],
                  fromDate: date!,
                  toDate: date!,
                  schoolId: int.parse(widget.schoolId),
                );

            student['fnPresentDates'] = data?['fnPresentDates'] ?? [];
            student['anPresentDates'] = data?['anPresentDates'] ?? [];
            student['TotalMarking'] = data?['TotalMarking'] ?? [];
            student['fnAbsentDates'] = data?['fnAbsentDates'] ?? [];
            student['anAbsentDates'] = data?['anAbsentDates'] ?? [];
            student['totalPercentage'] = data?['totalPercentage'] ?? [];
          } catch (e) {
            debugPrint("Error fetching student data: $e");
          }
        }),
      );
    } catch (e) {
      debugPrint("Error initializing data: $e");
    }
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'];
        schoolAddress = schoolData[0]['address'];

        if (schoolData[0]['photo'] != null) {
          try {
            schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
          } catch (e) {
            debugPrint('Image decode error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching school info: $e');
    }
  }

  Future<void> handleDownload() async {
    setState(() => isDownloading = true);
    try {
      await fetchSchoolInfo();
      await fetchStudents();
      await buildPdf(
        students: students,
        schoolName: schoolName,
        schoolAddress: schoolAddress,
        schoolPhotoBytes: schoolPhotoBytes,
        date: date,
      );
    } catch (e) {
      debugPrint("Download error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to generate PDF')));
    } finally {
      if (mounted) setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return WillPopScope(
      onWillPop: onWillPop,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(isMobile ? 190 : 150),
          child:
              isMobile
                  ? AdminAppbarMobile(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Daily Report',
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
                    title: 'Daily Report',

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
                : Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          Text(
                            'Do you want to download the Student Attendance Report as a PDF For whole School?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 30),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: pickDate,
                                child: Text(
                                  date == null
                                      ? 'Select Date'
                                      : 'From: ${date!.toLocal().toIso8601String().split('T')[0]}',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed:
                                (date != null)
                                    ? () async {
                                      if (true) {
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
                              isDownloading ? 'Downloading...' : 'Download PDF',
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
                          // const SizedBox(height: 60),
                          // Text(
                          //   'Do you want to download the Student Attendance Report as a PDF For Class Wise?',
                          //   textAlign: TextAlign.center,
                          //   style: TextStyle(
                          //     fontSize: 18,
                          //     color: Colors.grey[700],
                          //   ),
                          // ),
                          // const SizedBox(height: 30),
                          // ElevatedButton.icon(
                          //   onPressed: () {
                          //     // Navigator.push(
                          //     //   context,
                          //     //   MaterialPageRoute(
                          //     //     builder:
                          //     //         (context) => PrintStudentCertificates(
                          //     //           username: widget.username,
                          //     //           schoolId: widget.schoolId,
                          //     //         ),
                          //     //   ),
                          //     // );
                          //   },
                          //   icon: const Icon(Icons.arrow_right_alt_sharp),
                          //   label: const Text('Classes'),
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.blueAccent,
                          //     foregroundColor: Colors.white,
                          //     padding: const EdgeInsets.symmetric(
                          //       horizontal: 30,
                          //       vertical: 15,
                          //     ),
                          //     textStyle: const TextStyle(
                          //       fontSize: 16,
                          //       fontWeight: FontWeight.bold,
                          //     ),
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
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

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: "Select  Date",
    );

    if (picked != null) {
      setState(() {
        date = picked;
      });
    }
  }
}
