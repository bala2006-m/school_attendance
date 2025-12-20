import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required List<Map<String, dynamic>> classStudents,
  required String? schoolName,
  required Uint8List? schoolPhotoBytes,
  required String? schoolAddress,
  required DateTime? fromDate,
  required DateTime? toDate,
}) async {
  final pdf = pw.Document();
  final ttf = await PdfGoogleFonts.openSansRegular();
  final ttfBold = await PdfGoogleFonts.openSansBold();

  if (classStudents.isEmpty) {
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build:
            (_) => pw.Center(
              child: pw.Text(
                "No students found",
                style: pw.TextStyle(fontSize: 18, color: PdfColors.red),
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

    int compareStudents(Map a, Map b) {
      final aU = a['username'].toString(), bU = b['username'].toString();
      final aNum = int.tryParse(aU), bNum = int.tryParse(bU);
      if (aNum != null && bNum != null) return aNum.compareTo(bNum);
      return aU.compareTo(bU);
    }

    grouped.forEach((classKey, classList) {
      final maleStudents =
          classList
              .where((s) => s['gender']?.toString().toUpperCase() == 'M')
              .toList()
            ..sort(compareStudents);

      final femaleStudents =
          classList
              .where((s) => s['gender']?.toString().toUpperCase() == 'F')
              .toList()
            ..sort(compareStudents);

      final combinedStudents = [
        ...maleStudents,
        if (maleStudents.isNotEmpty && femaleStudents.isNotEmpty) {},
        ...femaleStudents,
      ];

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header:
              (_) => pw.Column(
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
                      if (schoolPhotoBytes != null) pw.SizedBox(width: 12),
                      pw.Padding(
                        padding: pw.EdgeInsets.only(top: 10),
                        child: pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              if (schoolName!.isNotEmpty)
                                pw.Text(
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
                  pw.Text(
                    "Periodical Student Attendance Report",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Text(
                    "Class: ${classList.first['class']}   Section: ${classList.first['section']}",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  pw.Text(
                    "From ${fromDate?.toString().split(' ').first ?? '--'}  To ${toDate?.toString().split(' ').first ?? '--'}",
                    style: const pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
          footer:
              (context) => pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "Generated on: ${DateTime.now().toLocal().toString().split(' ').first}",
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
              ),
          build: (context) {
            int serial = 1;
            final dataRows = <List<String>>[];

            for (final s in combinedStudents) {
              if (s.isEmpty) {
                dataRows.add(List.filled(8, ""));
              } else {
                dataRows.add([
                  (serial++).toString(),
                  s['username'] ?? '',
                  s['name'] ?? '',
                  s['gender'] == 'M'
                      ? 'Male'
                      : s['gender'] == 'F'
                      ? 'Female'
                      : 'Other',
                  (s['TotalMarking'] ?? 0).toString(),
                  (((s['fnPresentDates']?.length ?? 0) +
                              (s['anPresentDates']?.length ?? 0)) /
                          2)
                      .toStringAsFixed(1),
                  (((s['fnAbsentDates']?.length ?? 0) +
                              (s['anAbsentDates']?.length ?? 0)) /
                          2)
                      .toStringAsFixed(1),
                  "${s['totalPercentage'] ?? '0'}",
                ]);
              }
            }

            return [
              pw.TableHelper.fromTextArray(
                headers: const [
                  "S.No",
                  "Admn.No",
                  "Name",
                  "Gender",
                  "Days Marked",
                  "Present",
                  "Absent",
                  "%",
                ],
                data: dataRows,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                // cellDecoration:  pw.BoxDecoration(
                //   border: pw.Border(
                //     bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                //   ),
                // ),
                cellStyle: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.black,
                  font: ttf,
                ),
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
              pw.SizedBox(height: 25),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text("__________________"),
                      pw.Text(
                        "Class Teacher",
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text("__________________"),
                      pw.Text(
                        "Principal",
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ];
          },
        ),
      );
    });
  }

  return pdf;
}
