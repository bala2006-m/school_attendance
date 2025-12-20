import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required Map<String, dynamic> absentees,
  required String? schoolName,
  required String? schoolAddress,
  required Uint8List? schoolPhotoBytes,
  required DateTime? date,
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

  // Sort students by class order, then section, then username
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

  pw.Widget tableCellHeader(String text, {bool bold = false}) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text.isEmpty ? '-' : text,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 10,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget buildHeader() {
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
                    if (schoolName?.isNotEmpty == true) pw.SizedBox(height: 5),
                    if (schoolAddress != null && schoolAddress.isNotEmpty)
                      pw.Text(
                        schoolAddress,
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

        pw.Text(
          "Daily Student Absentees Report",
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
      ],
    );
  }

  List<pw.TableRow> buildRows(List<dynamic> students) {
    int index = 1;
    return students.map<pw.TableRow>((student) {
      return pw.TableRow(
        children: [
          tableCell((index++).toString()),
          tableCell(student['username'] ?? ''),
          tableCell(student['name'] ?? ''),
          tableCell(
            student['gender'] == 'M'
                ? 'Male'
                : student['gender'] == 'F'
                ? 'Female'
                : '-',
          ),
          tableCell(student['mobile'] ?? ''),
          tableCell(student['class']?.toString() ?? ''),
          tableCell(student['section']?.toString() ?? ''),
        ],
      );
    }).toList();
  }

  void addAbsenteesPage(String title, List<dynamic> students) {
    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        pageFormat: PdfPageFormat.a4,
        header: (context) => buildHeader(),
        build:
            (context) => [
              pw.Text(
                "$title Absentees",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                "Date: ${DateFormat.yMMMMd().format(date ?? DateTime.now())}",
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.black),
                columnWidths: {
                  0: pw.FixedColumnWidth(21),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(3.5),
                  3: pw.FixedColumnWidth(46),
                  4: pw.FixedColumnWidth(77),
                  5: pw.FixedColumnWidth(40),
                  6: pw.FixedColumnWidth(40),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue),
                    children: [
                      tableCellHeader('S.No', bold: true),
                      tableCellHeader('Admn. No', bold: true),
                      tableCellHeader('Name', bold: true),
                      tableCellHeader('Gender', bold: true),
                      tableCellHeader('Mobile', bold: true),
                      tableCellHeader('Class', bold: true),
                      tableCellHeader('Sec', bold: true),
                    ],
                  ),
                  ...buildRows(students),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("__________________"),
                      pw.Text("Principal", style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ],
      ),
    );
  }

  final fnAbsentees = sortStudents(
    List<dynamic>.from(absentees['fn_absentees'] ?? []),
  );
  final anAbsentees = sortStudents(
    List<dynamic>.from(absentees['an_absentees'] ?? []),
  );

  if (fnAbsentees.isEmpty && anAbsentees.isEmpty) {
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build:
            (context) => pw.Center(
              child: pw.Text(
                "No absentees found",
                style: pw.TextStyle(fontSize: 18),
              ),
            ),
      ),
    );
  } else {
    if (fnAbsentees.isNotEmpty) {
      addAbsenteesPage("Forenoon (FN)", fnAbsentees);
    }
    if (anAbsentees.isNotEmpty) {
      addAbsenteesPage("Afternoon (AN)", anAbsentees);
    }
  }

  return pdf;
}
