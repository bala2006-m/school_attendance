import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required List<dynamic> students,
  required String schoolName,
  required String schoolAddress,
  required Uint8List? schoolPhotoBytes,
}) async {
  final doc = pw.Document();

  final logo =
      schoolPhotoBytes != null ? pw.MemoryImage(schoolPhotoBytes) : null;

  // Load Google Fonts
  final fontRegular = await PdfGoogleFonts.notoSansRegular();
  final fontBold = await PdfGoogleFonts.notoSansBold();

  doc.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(24),

      // ---------------- HEADER ----------------
      header:
          (context) => pw.Column(
            children: [
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
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            schoolName,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue900,
                            ),
                          ),
                          pw.Text(
                            schoolAddress,
                            style: pw.TextStyle(
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
            ],
          ),

      // ---------------- BODY ----------------
      build: (context) {
        final List<pw.Widget> content = [];

        // Group students by class + section
        final Map<String, List<dynamic>> grouped = {};
        for (final s in students) {
          final className = s['class']?['class'] ?? '';
          final section = s['class']?['section'] ?? '';
          final key = '$className - $section';

          grouped.putIfAbsent(key, () => []);
          grouped[key]!.add(s);
        }

        // Title
        content.add(
          pw.Center(
            child: pw.Text(
              'BUS GOING STUDENTS LIST',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueAccent,
                decoration: pw.TextDecoration.underline,
              ),
            ),
          ),
        );
        content.add(pw.SizedBox(height: 10));

        // ---------------- TABLES FOR EACH CLASS ----------------
        grouped.forEach((key, group) {
          content.add(
            pw.Text(
              key,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          );

          content.add(pw.SizedBox(height: 8));

          content.add(
            pw.Table(
              border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey400),
              children: [
                // TABLE HEADER
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: PdfColors.blue),
                  children: [
                    _headerCell('S.No'),
                    _headerCell('Admn. No'),
                    _headerCell('Name'),
                    _headerCell('Gender'),
                    _headerCell('Mobile'),
                    _headerCell('Route'),
                    _headerCell('Remark'),
                  ],
                ),

                // TABLE ROWS
                ...List.generate(group.length, (i) {
                  final s = group[i];
                  final index = i + 1;

                  return pw.TableRow(
                    decoration:
                        index.isOdd
                            ? const pw.BoxDecoration(color: PdfColors.grey100)
                            : null,
                    children: [
                      _cell(index.toString()),
                      _cell(s['username'] ?? ''),
                      _cell(s['name'] ?? ''),
                      _cell(s['gender'] ?? ''),
                      _cell(s['mobile'] ?? ''),
                      _cell(s['route'] ?? ''),
                      _cell(''),
                    ],
                  );
                }),
              ],
            ),
          );

          content.add(pw.SizedBox(height: 16));
        });

        return content;
      },
    ),
  );

  return doc;
}

// ------------------ CELL HELPERS ------------------
pw.Widget _headerCell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
    ),
  );
}

pw.Widget _cell(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
  );
}
