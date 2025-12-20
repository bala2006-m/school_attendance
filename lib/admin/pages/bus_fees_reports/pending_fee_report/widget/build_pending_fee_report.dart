import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required List<dynamic> students,
  required List<dynamic> fees,
  required String? schoolName,
  required String? schoolAddress,
  required Uint8List? schoolPhotoBytes,
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

  // Group students by term
  final Map<String, List<Map<String, dynamic>>> groupedByTerm = {};
  for (var s in students) {
    final term = s['term'] ?? 'N/A';
    groupedByTerm.putIfAbsent(term, () => []).add(s);
  }

  List<pw.Widget> buildContent() {
    List<pw.Widget> content = [];

    // HEADER
    content.add(
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
                  image: pw.DecorationImage(image: logo, fit: pw.BoxFit.cover),
                  border: pw.Border.all(color: PdfColors.blueAccent, width: 1),
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
    );

    content.add(pw.SizedBox(height: 20));

    // TITLE
    content.add(
      pw.Wrap(
        children: [
          pw.Center(
            child: pw.Text(
              "PENDING BUS FEE REPORT",
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueAccent,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
          pw.SizedBox(height: 10),

          // CLASS INFO
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
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

          pw.SizedBox(height: 15),
        ],
      ),
    );

    if (students.isEmpty) {
      content.add(
        pw.Center(
          child: pw.Text(
            "✅ All students have paid their bus fees!",
            style: pw.TextStyle(
              color: PdfColors.green800,
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );
    } else {
      // FOR EACH TERM, USE Wrap TO KEEP HEADER AND TABLE TOGETHER
      for (var entry in groupedByTerm.entries) {
        final term = entry.key;
        final termStudents = entry.value;

        content.add(
          pw.Wrap(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 10),
                  pw.Text(
                    "Term: $term",
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                      color: PdfColors.indigo700,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.TableHelper.fromTextArray(
                    border: pw.TableBorder.all(
                      width: 0.5,
                      color: PdfColors.grey400,
                    ),
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
                      7: pw.Alignment.centerRight,
                    },
                    headers: const [
                      'S.No',
                      'Name',
                      'Adm No',
                      'Route',
                      'Father',
                      'Mobile',
                      'Amount (₹)',
                    ],
                    data: List.generate(termStudents.length, (i) {
                      final s = termStudents[i];
                      return [
                        (i + 1).toString(),
                        s['name'] ?? '-',
                        s['username']?.toString() ?? '-',
                        s['route'] ?? '-',
                        s['father_name'] ?? '-',
                        s['mobile'] ?? '-',
                        (double.parse(
                          s['pending_amount'].toString(),
                        ).toStringAsFixed(2)),
                      ];
                    }),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }

    content.add(pw.SizedBox(height: 30));

    // FOOTER
    content.add(pw.Divider(color: PdfColors.grey300));
    content.add(pw.SizedBox(height: 12));
    content.add(
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Generated on $formattedDate",
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey600,
                ),
              ),
              pw.Text(
                "Report Prepared by: Admin",
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
              pw.Container(height: 1, width: 100, color: PdfColors.grey500),
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
    );

    return content;
  }

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        margin: const pw.EdgeInsets.all(24),
      ),
      build: (context) => buildContent(),
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
