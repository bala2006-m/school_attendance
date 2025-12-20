import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required List<Map<String, dynamic>> students,
  required String cls,
  required String section,
  required String schoolName,
  required String schoolAddress,
  Uint8List? schoolPhotoBytes,
}) async {
  final pdf = pw.Document();

  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();

  // Separate students by gender and sort each list by username
  List<Map<String, dynamic>> sortByUsername(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      String aUser = a['username'] ?? '';
      String bUser = b['username'] ?? '';
      final aNum = int.tryParse(aUser);
      final bNum = int.tryParse(bUser);
      if (aNum != null && bNum != null) {
        return aNum.compareTo(bNum);
      } else {
        return aUser.compareTo(bUser);
      }
    });
    return list;
  }

  final maleStudents = sortByUsername(
    students.where((s) => s['gender'] == 'M').toList(),
  );
  final femaleStudents = sortByUsername(
    students.where((s) => s['gender'] == 'F').toList(),
  );
  final otherStudents = sortByUsername(
    students.where((s) => s['gender'] != 'M' && s['gender'] != 'F').toList(),
  );

  // Combine with an empty “blank row” placeholder between male and female if both present
  final combinedList = <Map<String, dynamic>>[
    ...maleStudents,
    if (maleStudents.isNotEmpty && femaleStudents.isNotEmpty)
      {'isEmptyRow': true},
    ...femaleStudents,
    ...otherStudents,
  ];

  // Stats row for male, female, total counts
  final stats = [
    [
      maleStudents.length.toString(),
      femaleStudents.length.toString(),
      (maleStudents.length + femaleStudents.length).toString(),
    ],
  ];

  pdf.addPage(
    pw.MultiPage(
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
      pageFormat: PdfPageFormat.a4,
      header:
          (context) => pw.Column(
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
                  pw.Padding(
                    padding: pw.EdgeInsets.only(top: 10),
                    child: pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (schoolName.isNotEmpty)
                            pw.Text(
                              schoolName,
                              softWrap: true,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                color: PdfColors.blue900,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          pw.SizedBox(height: 5),
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
              // pw.SizedBox(height: 10),
              pw.Text(
                "Student List",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                "Class: $cls   Section: $section",
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ["Male", "Female", "Total"],
                data: stats,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue),
                cellAlignment: pw.Alignment.center,
                cellStyle: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 10),
            ],
          ),
      build: (context) {
        if (students.isEmpty) {
          return [
            pw.Center(
              child: pw.Text(
                "No students found",
                style: pw.TextStyle(fontSize: 18),
              ),
            ),
          ];
        }

        int serial = 1;
        final data =
            combinedList.map((student) {
              if (student['isEmptyRow'] == true) {
                return ['', '', '', '', '', ''];
              }

              return [
                (serial++).toString(),
                student['username'] ?? '',
                student['name'] ?? '',
                student['gender'] == 'M'
                    ? 'Male'
                    : student['gender'] == 'F'
                    ? 'Female'
                    : 'Others',
                student['mobile'] ?? '',
                '',
              ];
            }).toList();

        return [
          pw.TableHelper.fromTextArray(
            headers: ["S.No", "Admn.No", "Name", "Gender", "Mobile", "Remark"],
            data: data,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 10,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
            cellStyle: pw.TextStyle(fontSize: 9, font: ttf),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: pw.FixedColumnWidth(23),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(4.3),
              3: pw.FixedColumnWidth(46),
              4: pw.FixedColumnWidth(77),
              5: pw.FlexColumnWidth(2),
            },
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
          ),
        ];
      },
    ),
  );

  return pdf;
}
