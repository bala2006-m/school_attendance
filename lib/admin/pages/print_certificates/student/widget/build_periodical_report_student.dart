import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required String title,
  required Map<String, dynamic> attendanceData,
  required Map<String, dynamic>? studentData,
  required Uint8List? schoolPhotoBytes,
  required String? schoolName,
  required String? schoolAddress,
  required String studentUsername,
}) async {
  final pdf = pw.Document();
  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();

  pdf.addPage(
    pw.Page(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
      build:
          (context) => pw.Container(
            padding: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (schoolPhotoBytes != null)
                      pw.Image(
                        pw.MemoryImage(schoolPhotoBytes),
                        width: 80,
                        height: 80,
                      ),
                    if (schoolPhotoBytes != null) pw.SizedBox(width: 10),
                    // pw.Padding(
                    //   padding: pw.EdgeInsets.only(top: 10),
                    pw.Expanded(
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
                    // ),
                  ],
                ),
                pw.Divider(),
                pw.Text(
                  "Periodical Student Attendance Report",
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Student Details Section
                if (studentData != null) ...[
                  pw.Text(
                    "This is to certify that",
                    style: pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    studentData['name'] ?? '',
                    style: pw.TextStyle(
                      fontSize: 12,
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
                    style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                  pw.SizedBox(height: 20),
                ],

                // Attendance Details Section
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                if (attendanceData.isNotEmpty) ...[
                  pw.TableHelper.fromTextArray(
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
                        studentUsername,
                        studentData?['name'] ?? '',
                        attendanceData['TotalMarking']?.toString() ?? '0',
                        (((attendanceData['fnPresentDates']?.length ?? 0) +
                                    (attendanceData['anPresentDates']?.length ??
                                        0)) /
                                2)
                            .toString(),
                        (((attendanceData['fnAbsentDates']?.length ?? 0) +
                                    (attendanceData['anAbsentDates']?.length ??
                                        0)) /
                                2)
                            .toString(),
                        (attendanceData['totalPercentage']?.toString() ?? '0'),
                      ],
                    ],
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.blue,
                    ),
                    cellAlignment: pw.Alignment.centerLeft,
                    cellStyle: pw.TextStyle(fontSize: 9, font: ttf),
                    columnWidths: {
                      0: pw.FlexColumnWidth(1),
                      1: pw.FlexColumnWidth(1.8),
                      2: pw.FlexColumnWidth(3.5),
                      3: pw.FlexColumnWidth(1.8),
                      4: pw.FlexColumnWidth(2),
                      5: pw.FlexColumnWidth(2),
                      6: pw.FlexColumnWidth(1.5),
                    },
                  ),
                ] else
                  pw.Text("No attendance data available."),
                pw.SizedBox(height: 40),

                // Signature Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
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
                    pw.Column(
                      children: [
                        pw.Text("__________________"),
                        pw.Text("Principal", style: pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
    ),
  );

  // Return the PDF document to the caller instead of printing inside
  return pdf;
}
