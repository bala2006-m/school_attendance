import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required List<dynamic> absentees,
  required String? schoolName,
  required String? schoolAddress,
  required Uint8List? schoolPhotoBytes,
}) async {
  final pdf = pw.Document();
  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();

  final List<String> classOrder = [
    'prekg',
    'lkg',
    'ukg',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    '11',
    '12',
    'i',
    'ii',
    'iii',
    'iv',
    'v',
    'vi',
    'vii',
    'viii',
    'ix',
    'x',
    'xi',
    'xii',
  ];

  int getClassOrderIndex(String cls) {
    final clsLower = cls.toLowerCase();
    final index = classOrder.indexOf(clsLower);
    return index == -1 ? 999 : index;
  }

  // Sort students by class → section → username
  List<dynamic> sortStudents(List<dynamic> students) {
    students.sort((a, b) {
      final classA = (a['class'] ?? '').toString().toLowerCase();
      final classB = (b['class'] ?? '').toString().toLowerCase();
      final classCompare = getClassOrderIndex(
        classA,
      ).compareTo(getClassOrderIndex(classB));
      if (classCompare != 0) return classCompare;

      final sectionA = (a['section'] ?? '').toString().toLowerCase();
      final sectionB = (b['section'] ?? '').toString().toLowerCase();
      final sectionCompare = sectionA.compareTo(sectionB);
      if (sectionCompare != 0) return sectionCompare;

      final userA = (a['username'] ?? '').toString().toLowerCase();
      final userB = (b['username'] ?? '').toString().toLowerCase();
      return userA.compareTo(userB);
    });
    return students;
  }

  pw.Widget tableCell(String text, {bool bold = false}) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text.isEmpty ? '-' : text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 9,
        ),
      ),
    );
  }

  pw.Widget tableCellHeader(String text) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
          color: PdfColors.white,
        ),
      ),
    );
  }

  final sortedAbsentees = sortStudents(absentees);
  // Header section
  pw.Widget buildHeader() {
    final formattedDate = DateFormat('dd MMM yyyy').format(DateTime.now());
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (schoolPhotoBytes != null)
              pw.Image(pw.MemoryImage(schoolPhotoBytes), width: 80, height: 80),
            if (schoolPhotoBytes != null) pw.SizedBox(width: 10),
            pw.Padding(
              padding: pw.EdgeInsets.only(top: 10),
              child: pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (schoolName?.isNotEmpty == true)
                      pw.Text(
                        schoolName!,
                        textAlign: pw.TextAlign.center,
                        softWrap: true,
                        style: pw.TextStyle(
                          color: PdfColors.blue900,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    if (schoolAddress?.isNotEmpty == true)
                      pw.Text(
                        schoolAddress!,
                        textAlign: pw.TextAlign.center,
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

        // pw.SizedBox(height: 10),
        pw.Text(
          "Long Absentees Report",
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          "Date: $formattedDate",
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'Class : ${sortedAbsentees[0]['class']}'
                ' Section : ${sortedAbsentees[0]['section']}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Table rows
  List<pw.TableRow> buildRows(List<dynamic> students) {
    int index = 1;
    return students.map<pw.TableRow>((student) {
      final dates = (student['dates'] as List?)?.join(', ') ?? '-';
      return pw.TableRow(
        children: [
          tableCell((index++).toString()),
          tableCell(student['username']?.toString() ?? '-'),
          tableCell(student['name']?.toString() ?? '-'),
          tableCell(
            student['gender']?.toString() == "M"
                ? "Male"
                : student['gender']?.toString() == "F"
                ? "Female"
                : '-',
          ),
          tableCell(student['mobile']?.toString() ?? '-'),
          tableCell(dates),
        ],
      );
    }).toList();
  }

  // Add a single absentees page
  void addAbsenteesPage(List<dynamic> students) {
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        pageFormat: PdfPageFormat.a4,
        header: (context) => buildHeader(),
        footer:
            (context) => pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
        build:
            (context) => [
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: pw.FixedColumnWidth(21),
                  1: pw.FlexColumnWidth(1.5),
                  2: pw.FlexColumnWidth(3),
                  3: pw.FixedColumnWidth(46),
                  4: pw.FixedColumnWidth(76),
                  5: pw.FlexColumnWidth(2.8),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue),
                    children: [
                      tableCellHeader('S.No'),
                      tableCellHeader('Admn. No'),
                      tableCellHeader('Name'),
                      tableCellHeader('Gender'),
                      tableCellHeader('Mobile'),
                      tableCellHeader('Absent Dates'),
                    ],
                  ),
                  ...buildRows(students),
                ],
              ),
              pw.SizedBox(height: 25),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Column(
                    children: [
                      pw.Text("__________________"),
                      pw.Text(
                        "Class Teacher",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Column(
                    children: [
                      pw.Text("__________________"),
                      pw.Text(
                        "Principal",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ],
      ),
    );
  }

  // Sort absentees

  // Handle empty data
  if (sortedAbsentees.isEmpty) {
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build:
            (context) => pw.Center(
              child: pw.Text(
                "No absentees found",
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
      ),
    );
  } else {
    addAbsenteesPage(sortedAbsentees);
  }

  return pdf;
}
