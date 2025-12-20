import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

int classSortKey(String className) {
  final romanMap = {
    'i': 15,
    'ii': 16,
    'iii': 17,
    'iv': 18,
    'v': 19,
    'vi': 20,
    'vii': 21,
    'viii': 22,
    'ix': 23,
    'x': 24,
    'xi': 25,
    'xii': 26,
  };
  final lower = className.toLowerCase();

  if (lower == 'prekg') return 0;
  if (lower == 'lkg') return 1;
  if (lower == 'ukg') return 2;

  final arabicNum = int.tryParse(lower);
  if (arabicNum != null) return arabicNum + 2;

  if (romanMap.containsKey(lower)) return romanMap[lower]!;

  return 100; // unknown classes last
}

Future<pw.Document> buildPdf({
  required String title,
  required List<dynamic> examMarks,
  required String? schoolName,
  required String? schoolAddress,
  required Uint8List? schoolPhotoBytes,
}) async {
  final pdf = pw.Document();

  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();

  // Group exam marks by class_name
  final Map<String, List<dynamic>> classGroups = groupBy(
    examMarks,
    (e) => e['class_name'].toString(),
  );

  // Sort classes by custom key
  final sortedClasses =
      classGroups.keys.toList()
        ..sort((a, b) => classSortKey(a).compareTo(classSortKey(b)));

  for (final className in sortedClasses) {
    final records = classGroups[className]!;

    // Group by section within class
    final Map<String, List<dynamic>> sectionGroups = groupBy(
      records,
      (e) => e['section'].toString(),
    );
    final sortedSections = sectionGroups.keys.toList()..sort();

    // Capitalize first 3 characters of each subject
    final subjects =
        (records.isNotEmpty && records[0]['subjects'] != null)
            ? List<String>.from(records[0]['subjects']).map((subj) {
              if (subj.length <= 3) {
                return subj.toUpperCase();
              } else {
                return subj.substring(0, 3).toUpperCase();
              }
            }).toList()
            : <String>[];

    for (final section in sortedSections) {
      final sectionRecords = sectionGroups[section]!;

      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
          pageFormat: PdfPageFormat.a4,
          footer: (context) {
            return pw.Container(
              alignment: pw.Alignment.center,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 12,
                  color: PdfColors.grey,
                ),
              ),
            );
          },

          header: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
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
                            if (schoolName?.isNotEmpty == true)
                              pw.Text(
                                schoolName!,
                                textAlign: pw.TextAlign.center,
                                softWrap: true,
                                style: pw.TextStyle(
                                  font: ttfBold,
                                  color: PdfColors.blue900,
                                  fontSize: 16,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            if (schoolName?.isNotEmpty == true)
                              pw.SizedBox(height: 5),
                            if (schoolAddress != null &&
                                schoolAddress.isNotEmpty)
                              pw.Text(
                                schoolAddress,
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  font: ttf,
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
              ],
            );
          },
          build: (context) {
            List<pw.Widget> content = [];

            content.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'Class: $className',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          font: ttfBold,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text(
                        'Section: $section',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          font: ttfBold,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Exam: ${sectionRecords.isNotEmpty ? (sectionRecords[0]['title'] ?? '') : ''}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      font: ttfBold,
                    ),
                  ),
                ],
              ),
            );

            content.add(pw.SizedBox(height: 10));

            final List<List<String>> tableData =
                sectionRecords.map((student) {
                  List<int> marksList = [];
                  if (student['marks'] != null) {
                    marksList =
                        (student['marks'] as List<dynamic>).map<int>((m) {
                          final mark = int.tryParse(m.toString()) ?? -1;
                          return mark;
                        }).toList();
                  }

                  final total = marksList.fold(0, (a, b) => b < 0 ? a : a + b);

                  String rankStr = student['rank'].toString();
                  if (rankStr.toUpperCase() == 'AA') {
                    rankStr = 'AA';
                  } else {
                    final rankNum = int.tryParse(rankStr);
                    if (rankNum == null || rankNum < 0) rankStr = '-';
                  }

                  final displayMarks =
                      marksList.map((m) {
                        if (m < 0) return '-';
                        return m.toString();
                      }).toList();

                  if (student['marks'] != null) {
                    for (
                      var i = 0;
                      i < (student['marks'] as List).length;
                      i++
                    ) {
                      var origMark = (student['marks'] as List)[i].toString();
                      if (origMark.toUpperCase() == 'AA') {
                        displayMarks[i] = 'AA';
                      }
                    }
                  }

                  return [
                    student['username'].toString(),
                    student['name'].toString(),
                    ...displayMarks,
                    total.toString(),
                    rankStr,
                  ];
                }).toList();

            content.add(
              pw.TableHelper.fromTextArray(
                headers: ['Admn No', 'Name', ...subjects, 'Total', 'Rank'],
                data: tableData,
                headerStyle: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 9),
                cellAlignment: pw.Alignment.center,
                headerDecoration: pw.BoxDecoration(color: PdfColors.blue),
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(60),
                  1: const pw.FlexColumnWidth(),
                },
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                },
              ),
            );

            content.add(pw.SizedBox(height: 20));

            content.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("__________________"),
                      pw.Text(
                        "Class teacher",
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Spacer(),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("__________________"),
                      pw.Text("Principal", style: pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
            );

            return content;
          },
        ),
      );
    }
  }

  return pdf;
}
