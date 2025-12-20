import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required List<dynamic> students,
  required String? schoolName,
  required String? schoolAddress,
  required Uint8List? schoolPhotoBytes,
  required DateTime? date,
}) async {
  final pdf = pw.Document();
  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();

  // Convert roman numerals to integer for sorting
  int romanToInt(String roman) {
    final map = {
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
    return map[roman.toUpperCase()] ?? 1000;
  }

  // Key for sorting class with order: PreKG (0), LKG (1), UKG (2), numeric+2, roman+14
  int classSortKey(String? className) {
    if (className == null) return 10000;
    final c = className.toUpperCase();
    if (c == 'PREKG') return 0;
    if (c == 'LKG') return 1;
    if (c == 'UKG') return 2;
    final numeric = int.tryParse(c);
    if (numeric != null) return numeric + 2;
    final roman = romanToInt(c);
    if (roman != 1000) return roman + 14;
    return 10000;
  }

  // Sort students list by class, section, then username (numeric if possible)
  students.sort((a, b) {
    final c1 = classSortKey(a['class']?.toString());
    final c2 = classSortKey(b['class']?.toString());
    if (c1 != c2) return c1.compareTo(c2);

    final s1 = a['section']?.toString() ?? '';
    final s2 = b['section']?.toString() ?? '';
    if (s1 != s2) return s1.compareTo(s2);

    final u1 = a['username']?.toString() ?? '';
    final u2 = b['username']?.toString() ?? '';
    final n1 = int.tryParse(u1);
    final n2 = int.tryParse(u2);
    if (n1 != null && n2 != null) return n1.compareTo(n2);

    return u1.compareTo(u2);
  });

  // TableCell widget with center alignment and borders
  pw.Widget tableCell(dynamic value, {bool bold = false}) {
    final displayValue = (value == null || value == 0) ? '-' : value.toString();
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Text(
        displayValue,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: 9,
        ),
      ),
    );
  }

  pw.Widget rightWhite({required String text, required PdfColor color}) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color),
      ),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide.none,
          bottom: pw.BorderSide.none,
          left: pw.BorderSide(color: PdfColors.black, width: 1),
          right: pw.BorderSide.none,
        ),
      ),
    );
  }

  pw.Widget leftWhite({required String text, required PdfColor color}) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color),
      ),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide.none,
          bottom: pw.BorderSide.none,
          right: pw.BorderSide.none,
          left: pw.BorderSide.none,
        ),
      ),
    );
  }

  pw.Widget header({required String text}) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
          fontSize: 10,
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
          "Daily Student Attendance Report",
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  if (students.isEmpty) {
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build:
            (context) => pw.Center(
              child: pw.Text(
                "No students found",
                style: const pw.TextStyle(fontSize: 18),
              ),
            ),
      ),
    );
  } else {
    // Group students after sorting
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var s in students) {
      final key = "${s['class']}-${s['section']}";
      grouped.putIfAbsent(key, () => []).add(s as Map<String, dynamic>);
    }

    final fnRows = <pw.TableRow>[];
    final anRows = <pw.TableRow>[];

    int totalMFnPresent = 0,
        totalFFnPresent = 0,
        totalMFnAbsent = 0,
        totalFFnAbsent = 0;
    int totalMAnPresent = 0,
        totalFAnPresent = 0,
        totalMAnAbsent = 0,
        totalFAnAbsent = 0;

    grouped.forEach((classKey, classStudents) {
      int mFnPresent = 0, fFnPresent = 0, mFnAbsent = 0, fFnAbsent = 0;
      int mAnPresent = 0, fAnPresent = 0, mAnAbsent = 0, fAnAbsent = 0;

      for (var s in classStudents) {
        if (s['gender']?.toString().toLowerCase() == 'm') {
          mFnPresent += (s['fnPresentDates'] as List?)?.length ?? 0;
          mFnAbsent += (s['fnAbsentDates'] as List?)?.length ?? 0;
          mAnPresent += (s['anPresentDates'] as List?)?.length ?? 0;
          mAnAbsent += (s['anAbsentDates'] as List?)?.length ?? 0;
        } else if (s['gender']?.toString().toLowerCase() == 'f') {
          fFnPresent += (s['fnPresentDates'] as List?)?.length ?? 0;
          fFnAbsent += (s['fnAbsentDates'] as List?)?.length ?? 0;
          fAnPresent += (s['anPresentDates'] as List?)?.length ?? 0;
          fAnAbsent += (s['anAbsentDates'] as List?)?.length ?? 0;
        }
      }

      totalMFnPresent += mFnPresent;
      totalFFnPresent += fFnPresent;
      totalMFnAbsent += mFnAbsent;
      totalFFnAbsent += fFnAbsent;

      totalMAnPresent += mAnPresent;
      totalFAnPresent += fAnPresent;
      totalMAnAbsent += mAnAbsent;
      totalFAnAbsent += fAnAbsent;

      fnRows.add(
        pw.TableRow(
          children: [
            tableCell(classKey, bold: true),
            tableCell(mFnPresent),
            tableCell(fFnPresent),
            tableCell(mFnPresent + fFnPresent),
            tableCell(mFnAbsent),
            tableCell(fFnAbsent),
            tableCell(mFnAbsent + fFnAbsent),
          ],
        ),
      );

      anRows.add(
        pw.TableRow(
          children: [
            tableCell(classKey, bold: true),
            tableCell(mAnPresent),
            tableCell(fAnPresent),
            tableCell(mAnPresent + fAnPresent),
            tableCell(mAnAbsent),
            tableCell(fAnAbsent),
            tableCell(mAnAbsent + fAnAbsent),
          ],
        ),
      );
    });

    final fnTotalRow = pw.TableRow(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      children: [
        tableCell('Total', bold: true),
        tableCell(totalMFnPresent, bold: true),
        tableCell(totalFFnPresent, bold: true),
        tableCell(totalMFnPresent + totalFFnPresent, bold: true),
        tableCell(totalMFnAbsent, bold: true),
        tableCell(totalFFnAbsent, bold: true),
        tableCell(totalMFnAbsent + totalFFnAbsent, bold: true),
      ],
    );

    final anTotalRow = pw.TableRow(
      children: [
        tableCell('Total', bold: true),
        tableCell(totalMAnPresent, bold: true),
        tableCell(totalFAnPresent, bold: true),
        tableCell(totalMAnPresent + totalFAnPresent, bold: true),
        tableCell(totalMAnAbsent, bold: true),
        tableCell(totalFAnAbsent, bold: true),
        tableCell(totalMAnAbsent + totalFAnAbsent, bold: true),
      ],
    );

    final tableBorder = pw.TableBorder.symmetric(
      outside: pw.BorderSide(color: PdfColors.black, width: 1),
    );

    final columnWidths = <int, pw.TableColumnWidth>{
      0: pw.FixedColumnWidth(60),
      1: pw.FlexColumnWidth(),
      2: pw.FlexColumnWidth(),
      3: pw.FlexColumnWidth(),
      4: pw.FlexColumnWidth(),
      5: pw.FlexColumnWidth(),
      6: pw.FlexColumnWidth(),
    };

    // Forenoon (FN) page
    pdf.addPage(
      pw.MultiPage(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        pageFormat: PdfPageFormat.a4,
        header: (context) => buildHeader(),
        build:
            (context) => [
              pw.Row(
                children: [
                  pw.Text(
                    "Date : ${DateFormat.yMMMMd().format(date ?? DateTime.now())}",
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    "Forenoon (FN)",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: tableBorder,
                columnWidths: columnWidths,
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue),
                    children: [
                      rightWhite(text: 'Class', color: PdfColors.white),
                      rightWhite(text: '-', color: PdfColors.blue),
                      leftWhite(text: 'Present', color: PdfColors.white),
                      leftWhite(text: '-', color: PdfColors.blue),
                      rightWhite(text: '-', color: PdfColors.blue),
                      leftWhite(text: 'Absent', color: PdfColors.white),
                      leftWhite(text: '-', color: PdfColors.blue),
                    ],
                  ),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue,
                      border: pw.Border.all(color: PdfColors.black, width: 1),
                    ),
                    children: [
                      pw.Container(),
                      header(text: 'Male'),
                      header(text: 'Female'),
                      header(text: 'Total'),
                      header(text: 'Male'),
                      header(text: 'Female'),
                      header(text: 'Total'),
                    ],
                  ),
                  ...fnRows,
                  fnTotalRow,
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.end,
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

    // Afternoon (AN) page
    pdf.addPage(
      pw.MultiPage(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        pageFormat: PdfPageFormat.a4,
        header: (context) => buildHeader(),
        build:
            (context) => [
              pw.Row(
                children: [
                  pw.Text(
                    "Date : ${DateFormat.yMMMMd().format(date ?? DateTime.now())}",
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Text(
                    "Afternoon (AN)",
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                border: tableBorder,
                columnWidths: columnWidths,
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue),
                    children: [
                      rightWhite(text: 'Class', color: PdfColors.white),
                      rightWhite(text: '-', color: PdfColors.blue),
                      leftWhite(text: 'Present', color: PdfColors.white),
                      leftWhite(text: '-', color: PdfColors.blue),
                      rightWhite(text: '-', color: PdfColors.blue),
                      leftWhite(text: 'Absent', color: PdfColors.white),
                      leftWhite(text: '-', color: PdfColors.blue),
                    ],
                  ),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue,
                      border: pw.Border.all(color: PdfColors.black, width: 1),
                    ),
                    children: [
                      pw.Container(),
                      header(text: 'Male'),
                      header(text: 'Female'),
                      header(text: 'Total'),
                      header(text: 'Male'),
                      header(text: 'Female'),
                      header(text: 'Total'),
                    ],
                  ),
                  ...anRows,
                  anTotalRow,
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.end,
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

  return pdf;
}
