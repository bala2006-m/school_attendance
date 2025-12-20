import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required List<dynamic> students,
  required String? schoolName,
  required Uint8List? schoolPhotoBytes,
  required String? schoolAddress,
  required DateTime? fromDate,
  required DateTime? toDate,
}) async {
  final pdf = pw.Document();
  final ttf = await PdfGoogleFonts.openSansRegular();
  final ttfBold = await PdfGoogleFonts.openSansBold();

  int romanToInt(String roman) {
    const map = {
      'I': 1,
      'II': 2,
      'III': 3,
      'IV': 4,
      'V': 5,
      'VI': 6,
      'VII': 7,
      'VIII': 8,
      'IX': 9,
      'X': 10,
      'XI': 11,
      'XII': 12,
    };
    return map[roman.toUpperCase()] ?? 100;
  }

  int classSortKey(String className) {
    switch (className.toUpperCase()) {
      case 'PREKG':
        return 0;
      case 'LKG':
        return 1;
      case 'UKG':
        return 2;
      default:
        final n = int.tryParse(className);
        if (n != null) return n + 2;
        final rn = romanToInt(className);
        if (rn != 100) return rn + 14;
        return 1000;
    }
  }

  students.sort((a, b) {
    final c = classSortKey(a['class']).compareTo(classSortKey(b['class']));
    if (c != 0) return c;
    final s = a['section'].compareTo(b['section']);
    if (s != 0) return s;
    final aNum = int.tryParse(a['username'] ?? '');
    final bNum = int.tryParse(b['username'] ?? '');
    return (aNum != null && bNum != null)
        ? aNum.compareTo(bNum)
        : (a['username'] ?? '').compareTo(b['username'] ?? '');
  });

  if (students.isEmpty) {
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
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

    for (var entry in grouped.entries) {
      final classStudents = entry.value;

      final males =
          classStudents
              .where((s) => (s['gender'] ?? '').toString().toLowerCase() == 'm')
              .toList();
      final females =
          classStudents
              .where((s) => (s['gender'] ?? '').toString().toLowerCase() == 'f')
              .toList();

      final combinedStudents = [...males, ...females];
      int serial = 1;

      final rows =
          combinedStudents.map((s) {
            final per = s['totalPercentage'].toString().split("%");
            String p = (int.parse(per[0].toString()) / 2).toString();
            return [
              (serial++).toString(),
              s['username'] ?? '',
              s['name'] ?? '',
              (s['gender'] ?? '').toString().toUpperCase() == 'M'
                  ? 'Male'
                  : (s['gender'] ?? '').toString().toUpperCase() == 'F'
                  ? 'Female'
                  : 'Others',
              (s['TotalMarking'] ?? 0).toString(),
              (((s['fnPresentDates']?.length ?? 0) +
                          (s['anPresentDates']?.length ?? 0)) /
                      2)
                  .toStringAsFixed(1),
              (((s['fnAbsentDates']?.length ?? 0) +
                          (s['anAbsentDates']?.length ?? 0)) /
                      2)
                  .toStringAsFixed(1),
              p,
            ];
          }).toList();

      final headers = [
        "S.No",
        "Admn.No",
        "Name",
        "Gender",
        "Days Marked",
        "Present",
        "Absent",
        "%",
      ];

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          header:
              (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      if (schoolPhotoBytes != null)
                        pw.ClipOval(
                          child: pw.Image(
                            pw.MemoryImage(schoolPhotoBytes),
                            width: 60,
                            height: 60,
                          ),
                        ),
                      if (schoolPhotoBytes != null) pw.SizedBox(width: 10),
                      pw.Padding(
                        padding: pw.EdgeInsets.only(top: 10),
                        child: pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              if (schoolName!.isNotEmpty)
                                pw.Text(
                                  softWrap: true,
                                  schoolName,
                                  textAlign: pw.TextAlign.center,
                                  style: pw.TextStyle(
                                    color: PdfColors.blue900,
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              pw.SizedBox(height: 5),
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
                  // pw.SizedBox(height: 8),
                  pw.Text(
                    "Periodical Student Attendance Report",
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "Class: ${classStudents.first['class']}   Section: ${classStudents.first['section']}",
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    "From: ${fromDate?.toLocal().toString().split(' ').first ?? '-'}   To: ${toDate?.toLocal().toString().split(' ').first ?? '-'}",
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
          footer:
              (context) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    "Generated: ${DateTime.now().toLocal().toString().split(' ').first}",
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    "Page ${context.pageNumber} of ${context.pagesCount}",
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
          build:
              (context) => [
                pw.TableHelper.fromTextArray(
                  headers: headers,
                  data: rows,
                  border: pw.TableBorder.symmetric(
                    inside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                    outside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  ),
                  headerDecoration: const pw.BoxDecoration(
                    color: PdfColors.blue,
                  ),
                  headerStyle: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  cellStyle: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.black,
                    font: ttf,
                  ),
                  headerAlignment: pw.Alignment.center,
                  cellAlignments: {
                    0: pw.Alignment.center,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerLeft,
                    3: pw.Alignment.centerLeft,
                    4: pw.Alignment.center,
                    5: pw.Alignment.center,
                    6: pw.Alignment.center,
                    7: pw.Alignment.center,
                  },
                  columnWidths: {
                    0: pw.FixedColumnWidth(23),
                    1: pw.FlexColumnWidth(2),
                    2: pw.FlexColumnWidth(4.3),
                    3: pw.FixedColumnWidth(46),
                    4: pw.FixedColumnWidth(50),
                    5: pw.FixedColumnWidth(50),
                    6: pw.FixedColumnWidth(50),
                    7: pw.FixedColumnWidth(40),
                  },
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),

                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        children: [
                          pw.Text("________________"),
                          pw.Text(
                            "Class Teacher",
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      pw.Column(
                        children: [
                          pw.Text("________________"),
                          pw.Text(
                            "Principal",
                            style: pw.TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
        ),
      );
    }
  }

  return pdf;
}
