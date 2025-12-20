import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds a visually enhanced PDF for Paid Fee Report.
Future<pw.Document> buildPdf({
  required List<dynamic> students,
  required List<dynamic> fees,
  String? schoolName,
  String? schoolAddress,
  Uint8List? schoolPhotoBytes,
  required String className,
  required String section,
}) async {
  final pdf = pw.Document();

  final fontRegular = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();

  final logo =
      schoolPhotoBytes != null ? pw.MemoryImage(schoolPhotoBytes) : null;
  final now = DateTime.now();
  final formattedDate =
      "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";

  // Map student ID -> name for quick lookup
  final studentMap = {
    for (var s in students)
      (s['username'] ?? s['id']).toString(): s['name'] ?? 'Unknown',
  };

  final totalAmount = fees.fold<num>(
    0,
    (sum, f) => sum + (f['amount_paid'] ?? 0),
  );

  // final baseColor = PdfColors.indigo800;

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),
      build: (context) {
        return [
          // ===== HEADER =====
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (logo != null)
                  pw.Container(
                    width: 60,
                    height: 60,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      image: pw.DecorationImage(
                        image: logo,
                        fit: pw.BoxFit.cover,
                      ),
                      border: pw.Border.all(
                        color: PdfColors.blueAccent,
                        width: 1,
                      ),
                    ),
                  ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        schoolName ?? 'School Name',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      if (schoolAddress != null)
                        pw.Text(
                          schoolAddress,
                          style: const pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ===== TITLE SECTION =====
          pw.Center(
            child: pw.Text(
              'PAID BUS FEE REPORT',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueAccent,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  "Class: $className - $section",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.Text(
                  "Date: $formattedDate",
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 14),

          // ===== TABLE =====
          if (fees.isNotEmpty)
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey400),
              headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 5,
                horizontal: 4,
              ),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
              cellAlignments: {
                0: pw.Alignment.center,
                6: pw.Alignment.centerRight,
              },
              headerAlignment: pw.Alignment.center,
              columnWidths: {
                0: pw.FixedColumnWidth(21),
                3: const pw.FlexColumnWidth(1.2),
                4: const pw.FixedColumnWidth(45),
                5: const pw.FixedColumnWidth(45),
                6: const pw.FixedColumnWidth(63),
                7: const pw.FixedColumnWidth(45),
              },
              headers: const [
                'S.No',
                'Name',
                'Admn. No',
                'Route',
                'Term',
                'Paid At',
                'Amount (₹)',
                'Mode',
                'Collected\nBy',
              ],
              data: List<List<String>>.generate(fees.length, (index) {
                final payment = fees[index];
                final studentId = payment['student_id'].toString();
                final studentName = studentMap[studentId] ?? '-';
                final structure = payment['busFeeStructure'] ?? {};
                final route = structure['route'] ?? '-';
                final term = structure['term'] ?? '-';
                final date =
                    (payment['payment_date'] ?? '').toString().split('T').first;
                final amount = (payment['amount_paid'] ?? 0).toString();
                final mode = (payment['payment_mode'] ?? '-').toString();
                final admin = payment['admin']?['name'] ?? '-';

                return [
                  '${index + 1}',
                  studentName,
                  studentId,
                  route,
                  term,
                  DateFormat(
                    'dd-MM-yy',
                  ).format(DateTime.parse(date.toString())),
                  double.parse(amount).toStringAsFixed(2),
                  mode,
                  admin,
                ];
              }),
            )
          else
            pw.Center(
              child: pw.Text(
                'No paid fee records found.',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.red600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),

          pw.SizedBox(height: 20),

          // ===== TOTAL SECTION =====
          if (fees.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green200, width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total Amount Collected : ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.green800,
                    ),
                  ),
                  pw.Text(
                    '₹${totalAmount.toDouble().toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.green900,
                    ),
                  ),
                ],
              ),
            ),

          pw.SizedBox(height: 25),

          // ===== FOOTER =====
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Generated on: ${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                  pw.Text(
                    'Report prepared by: Admin',
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.Column(
                children: [
                  pw.SizedBox(height: 25),
                  pw.Container(height: 1, width: 100, color: PdfColors.grey400),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "Authorized Signature",
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ];
      },
      footer:
          (context) => pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
    ),
  );

  return pdf;
}
