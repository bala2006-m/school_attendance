import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_attendance/admin/pages/print_certificates/student/student_certificates.dart';

import '../../../../services/api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';

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
          try {
            Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
            schoolPhotoBytes = imageBytes;
          } catch (e) {
            debugPrint('Image decode error: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching school info: $e');
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
      debugPrint("Student data: $data");
    } catch (e) {
      debugPrint('Error fetching student data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load student data")),
        );
      }
    }
  }

  // Future<void> fetchMonthlyAttendance({
  //   required String month,
  //   required String year,
  // }) async {
  //   try {
  //     final data = await AdminApiService.fetchStudentMonthlyAttendance(
  //       username: widget.studentUsername,
  //       month: month,
  //       year: year,
  //       schoolId: int.parse(widget.schoolId),
  //     );
  //     if (mounted) {
  //       setState(() {
  //         monthlyAttendanceData = data;
  //       });
  //     }
  //     debugPrint("Monthly attendance: $data");
  //
  //     await generateAttendancePdf(
  //       title: "Monthly Attendance Certificate ($month/$year)",
  //       attendanceData: data,
  //       studentData: studentData,
  //     );
  //   } catch (e) {
  //     debugPrint("Error fetching monthly attendance: $e");
  //   }
  // }

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
      debugPrint("Periodic attendance: $data");

      await generateAttendancePdf(
        title:
            "Date: ${fromDate.toLocal().toIso8601String().split('T')[0]} - ${toDate.toLocal().toIso8601String().split('T')[0]}",

        attendanceData: data!,
        studentData: studentData,
      );
    } catch (e) {
      debugPrint("Error fetching periodic attendance: $e");
    }
  }

  Future<void> generateAttendancePdf({
    required String title,
    required Map<String, dynamic> attendanceData,
    required Map<String, dynamic>? studentData,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Container(
              padding: const pw.EdgeInsets.all(32),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // --- School Header ---
                  if (schoolPhotoBytes != null)
                    pw.Image(
                      pw.MemoryImage(schoolPhotoBytes!),
                      width: 80,
                      height: 80,
                    ),
                  if (schoolName != null) pw.SizedBox(height: 3),
                  pw.Text(
                    schoolName!,
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (schoolAddress != null) pw.SizedBox(height: 3),
                  pw.Text(
                    schoolAddress!,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "Periodical Student Attendance Report",
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Divider(
                    height: 20,
                    thickness: 2,
                    color: PdfColors.grey400,
                  ),
                  pw.SizedBox(height: 20),

                  // --- Student Details ---
                  if (studentData != null) ...[
                    pw.Text(
                      "This is to certify that",
                      style: pw.TextStyle(fontSize: 14),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      studentData['name'] ?? '',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      "Email: ${studentData['email'] ?? ''} | Mobile: ${studentData['mobile'] ?? ''} | Gender: ${studentData['gender'] == 'F'
                          ? 'Female'
                          : studentData['gender'] == 'M'
                          ? 'Male'
                          : studentData['gender'] == 'O'
                          ? 'Others'
                          : ''}",
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                  ],

                  // --- Attendance Details ---
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  if (attendanceData.isNotEmpty) ...[
                    // pw.Text(
                    //   "Total Sessions Marked: ${attendanceData['TotalMarking'] ?? 0}",
                    // ),
                    // pw.Text(
                    //   "FN Present : ${attendanceData['fnPresentDates'].length ?? 0}",
                    // ),
                    // pw.Text(
                    //   "AN Present : ${attendanceData['anPresentDates'].length ?? 0}",
                    // ),
                    // pw.Text(
                    //   "FN Absent : ${attendanceData['fnAbsentDates'].length ?? 0}",
                    // ),
                    // pw.Text(
                    //   "AN Absent : ${attendanceData['anAbsentDates'].length ?? 0}",
                    // ),
                    // pw.SizedBox(height: 12),
                    // pw.Text(
                    //   "Attendance Percentage: ${attendanceData['totalPercentage'] ?? 0}%",
                    //   style: pw.TextStyle(
                    //     fontSize: 16,
                    //     fontWeight: pw.FontWeight.bold,
                    //     color: PdfColors.green,
                    //   ),
                    // ),
                    pw.Table.fromTextArray(
                      headers: [
                        "S.No",
                        "Admn.No",
                        "Name",
                        "Days Marked",
                        "Present",
                        "Absent",
                        "%",
                      ],
                      data: [
                        [
                          '1',
                          widget.studentUsername,
                          studentData?['name'] ?? '',
                          attendanceData['TotalMarking']?.toString() ?? '0',
                          (((attendanceData['fnPresentDates']?.length ?? 0) +
                                      (attendanceData['anPresentDates']
                                              ?.length ??
                                          0)) /
                                  2)
                              .toString(),
                          (((attendanceData['fnAbsentDates']?.length ?? 0) +
                                      (attendanceData['anAbsentDates']
                                              ?.length ??
                                          0)) /
                                  2)
                              .toString(),
                          ('${attendanceData['totalPercentage']?.toString() ?? '0'} %'),
                        ],
                      ],
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
                  ] else
                    pw.Text("No attendance data available."),

                  pw.SizedBox(height: 40),

                  // --- Signature Section ---
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
            ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
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
                    title: 'Download Report',
                    enableDrawer: false,
                    enableBack: true,
                    onBack: () {
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
                    },
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Download Report',

                    onBack: () {
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

                    // --- Monthly Certificate ---
                    // Card(
                    //   elevation: 3,
                    //   shape: RoundedRectangleBorder(
                    //     borderRadius: BorderRadius.circular(12),
                    //   ),
                    //   child: Padding(
                    //     padding: const EdgeInsets.all(20.0),
                    //     child: Column(
                    //       children: [
                    //         const Text(
                    //           'Monthly Attendance Certificate',
                    //           style: TextStyle(
                    //             fontSize: 18,
                    //             fontWeight: FontWeight.bold,
                    //           ),
                    //         ),
                    //         const SizedBox(height: 12),
                    //         Text(
                    //           selectedMonth != null && selectedYear != null
                    //               ? "Selected: $selectedMonth/$selectedYear"
                    //               : "Pick a month & year",
                    //           style: TextStyle(color: Colors.grey[600]),
                    //         ),
                    //         const SizedBox(height: 20),
                    //         ElevatedButton.icon(
                    //           onPressed: () async {
                    //             await pickMonthYear();
                    //             if (selectedMonth != null &&
                    //                 selectedYear != null) {
                    //               fetchMonthlyAttendance(
                    //                 month: selectedMonth!,
                    //                 year: selectedYear!,
                    //               );
                    //             }
                    //           },
                    //           icon: const Icon(
                    //             Icons.download_rounded,
                    //             color: Colors.white,
                    //           ),
                    //           label: const Text(
                    //             "Download PDF",
                    //             style: TextStyle(color: Colors.white),
                    //           ),
                    //           style: ElevatedButton.styleFrom(
                    //             backgroundColor: Colors.blue,
                    //             minimumSize: const Size(double.infinity, 50),
                    //             shape: RoundedRectangleBorder(
                    //               borderRadius: BorderRadius.circular(8),
                    //             ),
                    //           ),
                    //         ),
                    //       ],
                    //     ),
                    //   ),
                    // ),
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
                                "Download PDF",
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
