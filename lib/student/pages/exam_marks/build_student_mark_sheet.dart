import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:school_attendance/student/pages/exam_marks/student_exam_marks.dart';

import '../../../admin/widget/pdf_preview_custom_page.dart';
import '../../../services/api_service.dart';
import '../../Appbar/student_appbar_desktop.dart';
import '../../Appbar/student_appbar_mobile.dart';
import '../../services/student_api_services.dart';

class BuildStudentMarkSheet extends StatefulWidget {
  const BuildStudentMarkSheet({
    super.key,
    required this.studentMarks,
    required this.classId,
    required this.schoolId,
    required this.username,
    required this.name,
    required this.email,
    required this.gender,
    required this.dob,
    required this.phone,
  });

  final String classId;
  final String schoolId;
  final String username;
  final String name;
  final String email;
  final String gender;
  final String dob;
  final String phone;
  final List<dynamic> studentMarks;

  @override
  State<BuildStudentMarkSheet> createState() => _BuildStudentMarkSheetState();
}

class _BuildStudentMarkSheetState extends State<BuildStudentMarkSheet> {
  String? schoolName;
  String? schoolAddress;
  Uint8List? schoolPhotoBytes;
  Map<String, dynamic> classData = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    await Future.wait([fetchSchoolInfo(), fetchClassData()]);
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> fetchSchoolInfo() async {
    try {
      final schoolData = await ApiService.fetchSchoolData(widget.schoolId);
      if (schoolData.isNotEmpty) {
        schoolName = schoolData[0]['name'] ?? '';
        schoolAddress = schoolData[0]['address'] ?? '';
        if (schoolData[0]['photo'] != null) {
          schoolPhotoBytes = base64Decode(schoolData[0]['photo']);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load school info")),
        );
      }
    }
  }

  Future<void> fetchClassData() async {
    try {
      classData =
          (await StudentApiServices.fetchClassDatas(
            widget.schoolId,
            widget.studentMarks[0]['class_id'].toString(),
          )) ??
          {};
    } catch (e) {
      return;
    }
  }

  List<Map<String, dynamic>> parseMarks() {
    final List<Map<String, dynamic>> result = [];

    for (final record in widget.studentMarks) {
      final List subjects = record['subjects'] ?? [];
      final List marks = record['marks'] ?? [];
      final List minMax = record['min_max_marks'] ?? [];
      final List subjectRanks = record['subject_rank'] ?? [];
      final List dateList = record['date'] ?? [];
      final List sessionList = record['session'] ?? [];

      final int minMark = minMax.isNotEmpty ? minMax[0] : 35;
      final int maxMark = minMax.isNotEmpty ? minMax.last : 100;

      for (int i = 0; i < subjects.length; i++) {
        final obtainedRaw = i < marks.length ? marks[i] : 0;
        final String obtained = obtainedRaw.toString();

        final String passStatus =
            obtained == 'AA'
                ? 'Absent'
                : (int.tryParse(obtained) ?? 0) >= minMark
                ? "Pass"
                : "Fail";

        // Parse and format date per subject
        String formattedDate = '';
        if (i < dateList.length && dateList[i] != null) {
          try {
            final DateTime parsedDate = DateTime.parse(dateList[i].toString());
            final String dateStr = DateFormat('yyyy-MM-dd').format(parsedDate);
            final String sessionStr =
                i < sessionList.length ? sessionList[i].toString() : '';
            formattedDate =
                sessionStr.isNotEmpty ? '$dateStr - $sessionStr' : dateStr;
          } catch (e) {
            formattedDate = '';
          }
        }

        result.add({
          'subject': subjects[i].toString().toUpperCase(),
          'marksObtained': obtained,
          'maxMarks': maxMark,
          'subjectRank': i < subjectRanks.length ? subjectRanks[i] : '-',
          'status': passStatus,
          'date': formattedDate,
        });
      }
    }

    return result;
  }

  String getAcademicSession() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    if (month >= 7 && month <= 12) {
      // July to December
      return '$year-${year + 1}';
    } else {
      // January to June
      return '${year - 1}-$year';
    }
  }

  Future<pw.Document> buildPdfDocument() async {
    final pdf = pw.Document();
    final ttf = await PdfGoogleFonts.notoSansRegular();
    final ttfBold = await PdfGoogleFonts.notoSansBold();
    final parsedMarks = parseMarks();

    final overallRank =
        widget.studentMarks.isNotEmpty
            ? (widget.studentMarks.first['rank']?.toString() ?? '-')
            : '-';

    // ✅ Safe total calculation with int.tryParse
    final totalMarksObtained = parsedMarks.fold<int>(0, (sum, m) {
      final marks = int.tryParse(m['marksObtained'].toString()) ?? 0;
      return sum + marks;
    });

    final totalMaxMarks = parsedMarks.fold<int>(0, (sum, m) {
      final maxMarks = int.tryParse(m['maxMarks'].toString()) ?? 0;
      return sum + maxMarks;
    });

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build:
            (pw.Context context) => [
              pw.Container(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Center(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.blue,
                            width: 1,
                          ),
                        ),
                        child: pw.Padding(
                          padding: pw.EdgeInsets.only(
                            left: 30,
                            right: 30,
                            top: 30,
                            bottom: 20,
                          ),
                          child: pw.Center(
                            child: pw.Column(
                              children: [
                                // 📌 School logo and name
                                pw.Row(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.center,
                                  children: [
                                    if (schoolPhotoBytes != null)
                                      pw.Image(
                                        pw.MemoryImage(schoolPhotoBytes!),
                                        width: 80,
                                        height: 80,
                                      ),
                                    pw.SizedBox(width: 10),
                                    pw.Padding(
                                      padding: pw.EdgeInsets.only(top: 10),
                                      child: pw.Expanded(
                                        child: pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              pw.MainAxisAlignment.center,
                                          children: [
                                            if (schoolName?.isNotEmpty == true)
                                              pw.Text(
                                                schoolName!,
                                                textAlign: pw.TextAlign.center,
                                                softWrap: true,
                                                style: pw.TextStyle(
                                                  color: PdfColors.blue900,
                                                  fontSize: 16,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                ),
                                              ),

                                            pw.SizedBox(height: 5),
                                            if (schoolAddress?.isNotEmpty ==
                                                true)
                                              pw.Text(
                                                schoolAddress!,
                                                style: const pw.TextStyle(
                                                  fontSize: 12,
                                                  color: PdfColors.blue900,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                pw.Divider(),
                                // pw.SizedBox(height: 20),
                                pw.Text(
                                  "Progress Report Card ${getAcademicSession()}",
                                  style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 10),

                                // 📌 Exam name
                                parsedMarks.isEmpty
                                    ? pw.SizedBox()
                                    : pw.Text(
                                      '${widget.studentMarks[0]['title']}',
                                      style: pw.TextStyle(
                                        fontSize: 12,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                pw.SizedBox(height: 20),
                                // 📌 Student details table with selective bold
                                pw.Container(
                                  child: pw.Row(
                                    children: [
                                      pw.Expanded(
                                        child: pw.Container(
                                          child: pw.TableHelper.fromTextArray(
                                            columnWidths: const {
                                              0: pw.FixedColumnWidth(110),
                                              1: pw.FlexColumnWidth(1),
                                            },
                                            border: pw.TableBorder.symmetric(
                                              inside: pw.BorderSide.none,
                                              outside: pw.BorderSide(
                                                color: PdfColors.blue,
                                                width: 1,
                                              ),
                                            ),
                                            headerAlignment:
                                                pw.Alignment.centerLeft,
                                            // headers: ['', ''],
                                            data: [
                                              [
                                                pw.Text(
                                                  ' Name : ',
                                                  style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Text(widget.name),
                                              ],
                                              [
                                                pw.Text(
                                                  ' Admn No : ',
                                                  style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Text(widget.username),
                                              ],

                                              [
                                                pw.Text(
                                                  ' Phone : ',
                                                  style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Text(widget.phone),
                                              ],
                                              [
                                                pw.Text(
                                                  '',
                                                  style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Text(''),
                                              ],
                                            ],
                                          ),
                                          color: PdfColors.blue50,
                                        ),
                                      ),
                                      pw.SizedBox(width: 20),
                                      pw.Expanded(
                                        child: pw.Container(
                                          child: pw.TableHelper.fromTextArray(
                                            columnWidths: const {
                                              0: pw.FixedColumnWidth(110),
                                              1: pw.FlexColumnWidth(1),
                                            },
                                            border: pw.TableBorder.symmetric(
                                              inside: pw.BorderSide.none,
                                              outside: pw.BorderSide(
                                                color: PdfColors.blue,
                                                width: 1,
                                              ),
                                            ),
                                            headerAlignment:
                                                pw.Alignment.centerLeft,
                                            data: [
                                              [
                                                pw.Text(
                                                  ' Gender : ',
                                                  style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Text(widget.gender),
                                              ],
                                              [
                                                pw.Text(
                                                  ' DOB : ',
                                                  style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Text(widget.dob),
                                              ],
                                              [
                                                pw.Text(
                                                  'Class : ',
                                                  style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Text(
                                                  '${classData['class'] ?? ''} - ${classData['section'] ?? ''}',
                                                ),
                                              ],
                                              [
                                                pw.Text(
                                                  '',
                                                  style: pw.TextStyle(
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.Text(''),
                                              ],
                                            ],
                                          ),
                                          color: PdfColors.blue50,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                pw.SizedBox(height: 20),

                                // 📌 Subject-wise marks title

                                // 📌 Marks table
                                parsedMarks.isEmpty
                                    ? pw.Text("No marks available")
                                    : pw.TableHelper.fromTextArray(
                                      columnWidths: const {
                                        0: pw.FixedColumnWidth(23),
                                        1: pw.FlexColumnWidth(5),
                                        2: pw.FixedColumnWidth(40),
                                        3: pw.FixedColumnWidth(40),
                                        6: pw.FixedColumnWidth(40),
                                      },
                                      headerDecoration: pw.BoxDecoration(
                                        color: PdfColors.blue,
                                      ),
                                      headerStyle: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                      headers: [
                                        'S.No',
                                        'Subject',
                                        'Marks',
                                        'Max Mark',
                                        'Exam Date',
                                        'Status',
                                        'Rank',
                                      ],
                                      data: [
                                        for (
                                          int i = 0;
                                          i < parsedMarks.length;
                                          i++
                                        )
                                          [
                                            (i + 1).toString(),
                                            parsedMarks[i]['subject']
                                                .toString(),
                                            parsedMarks[i]['marksObtained']
                                                .toString(),
                                            parsedMarks[i]['maxMarks']
                                                .toString(),
                                            parsedMarks[i]['date'].toString(),
                                            parsedMarks[i]['status'].toString(),
                                            parsedMarks[i]['subjectRank'] == -1
                                                ? '-'
                                                : parsedMarks[i]['subjectRank']
                                                    .toString(),
                                          ],
                                        // ✅ Total row with bold
                                        [
                                          '',
                                          pw.Text(
                                            'Total',
                                            style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.Text(
                                            totalMarksObtained.toString(),
                                            style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          pw.Text(
                                            totalMaxMarks.toString(),
                                            style: pw.TextStyle(
                                              fontWeight: pw.FontWeight.bold,
                                            ),
                                          ),
                                          '',
                                          '',
                                        ],
                                      ],
                                    ),
                                pw.SizedBox(height: 10),
                                pw.Center(
                                  child: pw.Row(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.end,
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.center,
                                    children: [
                                      pw.Text(
                                        'Overall Rank : ',
                                        style: pw.TextStyle(
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.Text(
                                        overallRank == '-1' ||
                                                overallRank == '0'
                                            ? '-'
                                            : overallRank,
                                      ),
                                    ],
                                  ),
                                ),
                                pw.SizedBox(height: 40),

                                // 📌 Principal signature
                                pw.Row(
                                  mainAxisAlignment: pw.MainAxisAlignment.end,
                                  children: [
                                    pw.Column(
                                      children: [
                                        pw.Text("__________________"),
                                        pw.Text(
                                          "Class Teacher",
                                          style: pw.TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    pw.Spacer(),
                                    pw.Column(
                                      children: [
                                        pw.Text("__________________"),
                                        pw.Text(
                                          "Principal",
                                          style: pw.TextStyle(fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
      ),
    );

    return pdf;
  }

  Future<void> handleDownload() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PdfPreviewCustomPage(
              buildPdf: () => buildPdfDocument(),
              title: 'Report Card',
              fileName: 'report_card',
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final marks = parseMarks();
    final isMobile = MediaQuery.of(context).size.width < 500;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isMobile ? 190 : 150),
        child:
            isMobile
                ? StudentAppbarMobile(
                  schoolId: int.parse(widget.schoolId),
                  username: widget.username,
                  title: 'Mark Sheet',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentExamMarks(
                              classId: widget.classId,
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
                  },
                )
                : StudentAppbarDesktop(
                  title: 'Mark Sheet',
                  enableDrawer: false,
                  enableBack: true,
                  onBack: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => StudentExamMarks(
                              classId: widget.classId,
                              username: widget.username,
                              schoolId: widget.schoolId,
                            ),
                      ),
                    );
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
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🪪 Student Info Card
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Student Information",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const Divider(),
                                _infoRow("Name", widget.name),
                                _infoRow("Admission No", widget.username),
                                _infoRow("Gender", widget.gender),
                                _infoRow("Date of Birth", widget.dob),
                                _infoRow("Phone", widget.phone),
                                _infoRow(
                                  "Class",
                                  "${classData['class'] ?? ''} - ${classData['section'] ?? ''}",
                                ),
                                _infoRow(
                                  "Overall Rank",
                                  widget.studentMarks.first['rank']
                                              ?.toString() ==
                                          '0'
                                      ? '-'
                                      : widget.studentMarks.first['rank']
                                              ?.toString() ==
                                          '-1'
                                      ? '-'
                                      : widget.studentMarks.first['rank'] ??
                                          "-",
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // 📊 Subject Marks
                        Text(
                          "Subject-wise Marks",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),

                        marks.isEmpty
                            ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20.0),
                                child: Text(
                                  "No marks available",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                            : Column(
                              children: [
                                Text(
                                  'Exam :${widget.studentMarks[0]['title']} ',
                                  style: TextStyle(fontSize: 18),
                                ),
                                Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 3,
                                  child: DataTable(
                                    columnSpacing: 15,

                                    border: TableBorder.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    headingRowColor: WidgetStateProperty.all(
                                      Colors.blueAccent.shade100,
                                    ),
                                    columns: const [
                                      DataColumn(label: Text('S.\nNo')),
                                      DataColumn(label: Text('Subject')),
                                      DataColumn(label: Text('Marks')),
                                      DataColumn(label: Text('Max\nMarks')),
                                      // DataColumn(label: Text('Date')),
                                      DataColumn(label: Text('Status')),
                                      DataColumn(label: Text('Rank')),
                                    ],
                                    rows: [
                                      for (int i = 0; i < marks.length; i++)
                                        DataRow(
                                          cells: [
                                            DataCell(Text("${i + 1}")),
                                            DataCell(
                                              Text(
                                                marks[i]['subject']
                                                    .toString()
                                                    .toUpperCase(),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                "${marks[i]['marksObtained']}",
                                              ),
                                            ),
                                            DataCell(
                                              Text("${marks[i]['maxMarks']}"),
                                            ),
                                            // DataCell(Text(marks[i]['date'])),
                                            DataCell(Text(marks[i]['status'])),
                                            DataCell(
                                              Text(
                                                marks[i]['subjectRank'] == -1
                                                    ? '-'
                                                    : marks[i]['subjectRank']
                                                            .toString() ==
                                                        '-1'
                                                    ? '-'
                                                    : marks[i]['subjectRank']
                                                        .toString(),
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                        const SizedBox(height: 40),

                        Center(
                          child: ElevatedButton.icon(
                            onPressed: handleDownload,
                            icon: const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Generate PDF",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 14,
                              ),
                              backgroundColor: Colors.blueAccent,
                              textStyle: const TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
