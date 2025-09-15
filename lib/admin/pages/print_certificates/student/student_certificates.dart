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
import '../../../../teacher/services/teacher_api_service.dart';
import '../../../appbar/admin_appbar_desktop.dart';
import '../../../appbar/admin_appbar_mobile.dart';
import '../../../services/admin_api_service.dart';
import 'download.dart';

class StudentCertificates extends StatefulWidget {
  const StudentCertificates({
    super.key,
    required this.username,
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

  @override
  State<StudentCertificates> createState() => _StudentCertificatesState();
}

class _StudentCertificatesState extends State<StudentCertificates> {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> classStudents = [];
  bool isLoading = true;
  DateTime? fromDate;
  DateTime? toDate;
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    students = await TeacherApiServices.fetchStudentData(
      schoolId: widget.schoolId,
      classId: widget.classId,
    );

    setState(() {
      isLoading = false;
    });
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

  Future<bool> onWillPop() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => PrintStudentCertificates(
              schoolId: widget.schoolId,
              username: widget.username,
            ),
      ),
    );
    return false;
  }

  Future<void> fetchAllStudents({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    try {
      classStudents = await TeacherApiServices.fetchStudentData(
        classId: widget.classId,
        schoolId: widget.schoolId,
      );

      await Future.wait(
        classStudents.map((student) async {
          try {
            final classData = await StudentApiServices.fetchClassDatas(
              widget.schoolId,
              widget.classId,
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
            await fetchSchoolInfo();
          } catch (e) {
            debugPrint("Error fetching student data: $e");
          }
        }),
      );
    } catch (e) {
      debugPrint("Error initializing data: $e");
    }
  }

  Future<void> buildPdf() async {
    final pdf = pw.Document();

    if (classStudents.isEmpty) {
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
      for (var s in classStudents) {
        final key = "${s['class']}-${s['section']}";
        grouped.putIfAbsent(key, () => []).add(s);
      }

      grouped.forEach((classKey, classStudents) {
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
                    mainAxisAlignment: pw.MainAxisAlignment.center,
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
                          int serialNo = 1;
                          final rows = <List<String>>[];

                          for (var s in combinedStudents) {
                            if (s.isEmpty) {
                              rows.add(["", "", "", "", "", "", "", ""]);
                            } else {
                              rows.add([
                                (serialNo++).toString(),
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

  Future<void> showDateRangePickerAndGeneratePdf() async {
    final result = await showDialog<Map<String, DateTime>>(
      context: context,
      builder: (context) {
        DateTime? tempFromDate;
        DateTime? tempToDate;

        return StatefulBuilder(
          builder: (context, setState) {
            bool isValid =
                tempFromDate != null &&
                tempToDate != null &&
                !tempToDate!.isBefore(tempFromDate!);

            return AlertDialog(
              title: const Text('Select Date Range'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      tempFromDate == null
                          ? 'Select From Date'
                          : 'From: ${tempFromDate?.toLocal().toString().split(' ')[0]}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final selected = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (selected != null) {
                        setState(() {
                          tempFromDate = selected;
                          if (tempToDate != null &&
                              tempToDate!.isBefore(tempFromDate!)) {
                            tempToDate = null;
                          }
                        });
                      }
                    },
                  ),
                  ListTile(
                    title: Text(
                      tempToDate == null
                          ? 'Select To Date'
                          : 'To: ${tempToDate?.toLocal().toString().split(' ')[0]}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap:
                        tempFromDate != null
                            ? () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: tempFromDate!,
                                firstDate: tempFromDate!,
                                lastDate: DateTime(2100),
                              );
                              if (selected != null) {
                                setState(() {
                                  tempToDate = selected;
                                });
                              }
                            }
                            : null,
                  ),
                  if (tempFromDate != null &&
                      tempToDate != null &&
                      tempToDate!.isBefore(tempFromDate!))
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0),
                      child: Text(
                        "To Date must be after From Date",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      isValid
                          ? () {
                            Navigator.pop(context, {
                              'fromDate': tempFromDate!,
                              'toDate': tempToDate!,
                            });
                          }
                          : null,
                  child: const Text('Generate PDF'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        fromDate = result['fromDate'];
        toDate = result['toDate'];
        isLoading = true;
      });

      await fetchAllStudents(fromDate: fromDate!, toDate: toDate!);

      await buildPdf();

      setState(() {
        isLoading = false;
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
                    onBack: () => onWillPop(),
                  )
                  : AdminAppbarDesktop(
                    schoolId: widget.schoolId,
                    username: widget.username,
                    title: 'Download Report',

                    onBack: () => onWillPop(),
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
                : students.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "No Students Found",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
                : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Do you want to download the Periodical Student Attendance Report as a PDF For Whole Class?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: showDateRangePickerAndGeneratePdf,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download PDF'),
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
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => Download(
                                          classId: widget.classId,
                                          className: widget.className,
                                          section: widget.section,
                                          schoolId: widget.schoolId,
                                          username: widget.username,
                                          studentUsername: student['username'],
                                        ),
                                  ),
                                );
                              },
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    student['name'][0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  student['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(student['username']),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 18,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
