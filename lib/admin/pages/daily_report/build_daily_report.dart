import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> buildPdf({
  required students,
  required schoolName,
  required schoolAddress,
  required schoolPhotoBytes,
  required date,
}) async {
  final pdf = pw.Document();

  // Helper function for table cells
  pw.Widget tableCell(dynamic value, {bool bold = false}) {
    final displayValue = (value == null || value == 0) ? '-' : value.toString();
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        displayValue,
        style: pw.TextStyle(
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget rightWhite({required String text, required PdfColor color}) {
    return pw.Container(
      alignment: pw.Alignment.center,
      padding: pw.EdgeInsets.all(4),
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
      padding: pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color),
      ),
      decoration: pw.BoxDecoration(
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
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
      ),
      alignment: pw.Alignment.center,
      padding: pw.EdgeInsets.all(4),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
    );
  }

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
    // Group students by class-section
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var s in students) {
      final key = "${s['class']}-${s['section']}";
      grouped.putIfAbsent(key, () => []).add(s);
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

      // FN row
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

      // AN row
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

    // Add Total row for FN
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

    // Add Total row for AN
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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build:
            (context) => [
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
                    "Daily Student Attendance Report",
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    "Date : ${DateFormat.yMMMMd().format(date ?? DateTime.now())}",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),

                  // Forenoon Table
                  pw.Text(
                    "Forenoon (FN)",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Table(
                    border: pw.TableBorder.symmetric(
                      outside: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                    columnWidths: {
                      0: pw.FixedColumnWidth(60),
                      for (int i = 1; i <= students.length * 2 + 2; i++)
                        i: pw.FlexColumnWidth(),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          rightWhite(text: 'Class', color: PdfColors.black),
                          rightWhite(text: '-', color: PdfColors.white),
                          leftWhite(text: 'Present', color: PdfColors.black),
                          leftWhite(text: '-', color: PdfColors.white),
                          rightWhite(text: '-', color: PdfColors.white),
                          leftWhite(text: 'Absent', color: PdfColors.black),
                          leftWhite(text: '-', color: PdfColors.white),
                        ],
                      ),
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 1,
                          ),
                        ),
                        children: [
                          pw.Container(), // empty under Class

                          header(text: 'Male'),
                          header(text: 'Female'),
                          header(text: 'Total'),
                          header(text: 'Male'),
                          header(text: 'Female'),
                          header(text: 'Total'),
                        ],
                      ),
                      ...fnRows,
                      fnTotalRow, // Total row added
                    ],
                  ),

                  pw.SizedBox(height: 20),

                  // Afternoon Table
                  pw.Text(
                    "Afternoon (AN)",
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Table(
                    border: pw.TableBorder.symmetric(
                      outside: pw.BorderSide(color: PdfColors.black, width: 1),
                    ),
                    columnWidths: {
                      0: pw.FixedColumnWidth(60),
                      for (int i = 1; i <= students.length * 2 + 2; i++)
                        i: pw.FlexColumnWidth(),
                    },
                    children: [
                      pw.TableRow(
                        children: [
                          rightWhite(text: 'Class', color: PdfColors.black),
                          rightWhite(text: '-', color: PdfColors.white),
                          leftWhite(text: 'Present', color: PdfColors.black),
                          leftWhite(text: '-', color: PdfColors.white),
                          rightWhite(text: '-', color: PdfColors.white),
                          leftWhite(text: 'Absent', color: PdfColors.black),
                          leftWhite(text: '-', color: PdfColors.white),
                        ],
                      ),
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 1,
                          ),
                        ),
                        children: [
                          pw.Container(), // empty under Class

                          header(text: 'Male'),
                          header(text: 'Female'),
                          header(text: 'Total'),
                          header(text: 'Male'),
                          header(text: 'Female'),
                          header(text: 'Total'),
                        ],
                      ),
                      ...anRows,
                      anTotalRow, // Total row added
                    ],
                  ),

                  pw.SizedBox(height: 40),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      // pw.Column(
                      //   children: [
                      //     pw.Text("__________________"),
                      //     pw.Text("Class Teacher"),
                      //   ],
                      // ),
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
  }

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}
