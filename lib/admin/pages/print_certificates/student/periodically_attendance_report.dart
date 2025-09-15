import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_attendance/admin/pages/print_certificates/student/print_student_certificates.dart';

import '../../../../services/api_service.dart';
import '../../../../student/services/student_api_services.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import '../../dashboard/admin_dashboard.dart';

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
  List<Map<String, dynamic>> students = [];
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
                  fromDate: fromDate,
                  toDate: toDate,
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

  Future<void> handleDownload() async {
    setState(() => isDownloading = true);
    try {
      await buildPdf();
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
                          // Card(
                          //   elevation: 4,
                          //   shape: RoundedRectangleBorder(
                          //     borderRadius: BorderRadius.circular(10),
                          //   ),
                          //   child: Padding(
                          //     padding: const EdgeInsets.all(20.0),
                          //     child: Row(
                          //       mainAxisAlignment: MainAxisAlignment.center,
                          //       mainAxisSize: MainAxisSize.min,
                          //       children: [
                          //         const Icon(
                          //           Icons.people,
                          //           color: Colors.teal,
                          //           size: 28,
                          //         ),
                          //         const SizedBox(width: 10),
                          //         const Text(
                          //           'Total Students:',
                          //           style: TextStyle(
                          //             color: Colors.teal,
                          //             fontWeight: FontWeight.bold,
                          //             fontSize: 20,
                          //           ),
                          //         ),
                          //         const SizedBox(width: 8),
                          //         Text(
                          //           '${students.length}',
                          //           style: const TextStyle(
                          //             color: Colors.black,
                          //             fontWeight: FontWeight.bold,
                          //             fontSize: 20,
                          //           ),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // ),
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
                            'Do you want to download the Periodical Student Attendance Report as a PDF For whole School?',
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

                          const SizedBox(height: 60),
                          Text(
                            'Do you want to download the Periodical Student Attendance Report as a PDF For Class Wise?',
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

  Future<void> buildPdf() async {
    final pdf = pw.Document();

    if (students.isEmpty) {
      pdf.addPage(
        pw.Page(
          build:
              (context) => pw.Center(
                child: pw.Text(
                  "No students found",
                  style: pw.TextStyle(fontSize: 18),
                ),
              ),
        ),
      );
    } else {
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (var s in students) {
        final key = "${s['class']}-${s['section']}";
        grouped.putIfAbsent(key, () => []).add(s);
      }

      grouped.forEach((classKey, classStudents) {
        // Separate and sort male and female students
        List<Map<String, dynamic>> maleStudents =
            classStudents
                .where((s) => s['gender']?.toString().toLowerCase() == 'm')
                .toList()
              ..sort(
                (a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''),
              );

        List<Map<String, dynamic>> femaleStudents =
            classStudents
                .where((s) => s['gender']?.toString().toLowerCase() == 'f')
                .toList()
              ..sort(
                (a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''),
              );

        // Combine male and female students with a blank row in between
        final combinedStudents = [
          ...maleStudents,
          if (maleStudents.isNotEmpty && femaleStudents.isNotEmpty)
            {}, // blank row
          ...femaleStudents,
        ];

        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            build:
                (pw.Context context) => [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (schoolPhotoBytes != null)
                        pw.Image(
                          pw.MemoryImage(schoolPhotoBytes!),
                          width: 80,
                          height: 80,
                        ),
                      if (schoolName != null)
                        pw.Text(
                          schoolName!,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      if (schoolAddress != null)
                        pw.Text(
                          schoolAddress!,
                          style: const pw.TextStyle(fontSize: 12),
                        ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        "Periodical Student Attendance Report",
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        "Class: ${classStudents.first['class']}   Section: ${classStudents.first['section']}",
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        "Date: ${fromDate!.toLocal().toIso8601String().split('T')[0]} - ${toDate!.toLocal().toIso8601String().split('T')[0]}",
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      // Combined table
                      pw.Table.fromTextArray(
                        headers: [
                          "S.No",
                          "Admn.No",
                          "Name",
                          "Gender",
                          "Days Marked",
                          "Present",
                          "Absent",
                          "%",
                        ],
                        data: () {
                          List<List<String>> rows = [];
                          int serial = 1;

                          for (var s in combinedStudents) {
                            if (s.isEmpty) {
                              // Add blank row without incrementing serial
                              rows.add(["", "", "", "", "", "", "", ""]);
                            } else {
                              rows.add([
                                serial.toString(),
                                s['username'] ?? '',
                                s['name'] ?? '',
                                (s['gender'] == 'M'
                                    ? 'Male'
                                    : s['gender'] == 'F'
                                    ? 'Female'
                                    : 'Others'),
                                s['TotalMarking']?.toString() ?? '0',
                                (((s['fnPresentDates']?.length ?? 0) +
                                            (s['anPresentDates']?.length ??
                                                0)) /
                                        2)
                                    .toStringAsFixed(1),
                                (((s['fnAbsentDates']?.length ?? 0) +
                                            (s['anAbsentDates']?.length ?? 0)) /
                                        2)
                                    .toStringAsFixed(1),
                                '${s['totalPercentage'] ?? '0'} %',
                              ]);
                              serial++; // increment only for actual student rows
                            }
                          }

                          return rows;
                        }(),
                        headerStyle: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                        headerDecoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                        ),
                        cellAlignment: pw.Alignment.centerLeft,
                        cellStyle: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 40),

                      // Signature Section
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            children: [
                              pw.Text("__________________"),
                              pw.Text("Class Teacher"),
                            ],
                          ),
                          pw.Column(
                            children: [
                              pw.Text("__________________"),
                              pw.Text("Principal"),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
          ),
        );
      });
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
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
