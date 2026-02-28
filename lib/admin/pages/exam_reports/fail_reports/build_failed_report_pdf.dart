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

Future<pw.Document> buildFailedReportPdf({
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

    final minMarks =
        (records.isNotEmpty && records[0]['min_max_marks'] != null)
            ? List<int>.from(
              (records[0]['min_max_marks'] as List).take(subjects.length),
            )
            : <int>[];

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
                  fontSize: 10,
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
                        width: 60,
                        height: 60,
                      ),
                    if (schoolPhotoBytes != null) pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          if (schoolName?.isNotEmpty == true)
                            pw.Text(
                              schoolName!,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: ttfBold,
                                color: PdfColors.blue900,
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          if (schoolName?.isNotEmpty == true)
                            pw.SizedBox(height: 2),
                          if (schoolAddress != null && schoolAddress.isNotEmpty)
                            pw.Text(
                              schoolAddress,
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: ttf,
                                fontSize: 10,
                                color: PdfColors.blue900,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 5),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 5),
              ],
            );
          },
          build: (context) {
            List<pw.Widget> content = [];

            content.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Class: $className - $section',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      font: ttfBold,
                    ),
                  ),
                  pw.Text(
                    'Exam: $title (Failed List)',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      font: ttfBold,
                    ),
                  ),
                ],
              ),
            );

            content.add(pw.SizedBox(height: 10));

            final List<List<String>> tableData =
                sectionRecords
                    .map((student) {
                      List<dynamic> marksListRaw = student['marks'] ?? [];
                      List<dynamic> subjectRanksRaw =
                          student['subject_rank'] ?? [];
                      List<String> rowCells = [];
                      int total = 0;
                      bool hasFailed = false;

                      final int passThreshold =
                          minMarks.isNotEmpty ? minMarks[0] : 0;

                      for (int i = 0; i < subjects.length; i++) {
                        if (i < marksListRaw.length) {
                          final m = marksListRaw[i];
                          final mStr = m.toString().toUpperCase();
                          if (mStr == 'AA') {
                            rowCells.add('AA');
                            hasFailed = true;
                          } else {
                            final markVal = int.tryParse(mStr) ?? 0;
                            int sRank = 0;
                            if (i < subjectRanksRaw.length) {
                              sRank =
                                  int.tryParse(subjectRanksRaw[i].toString()) ??
                                  0;
                            }

                            if (sRank > 0) {
                              rowCells.add('$markVal ($sRank)');
                            } else {
                              rowCells.add(markVal.toString());
                            }

                            total += markVal;

                            if (markVal < passThreshold) {
                              hasFailed = true;
                            }
                          }
                        } else {
                          rowCells.add('-');
                          hasFailed = true;
                        }
                      }

                      if (!hasFailed) return null;

                      String rankStr = student['rank'].toString();
                      if (rankStr == '-1' || rankStr == '0') rankStr = '-';

                      return [
                        student['username'].toString(),
                        student['name'].toString(),
                        ...rowCells,
                        total.toString(),
                        // rankStr,
                      ];
                    })
                    .whereType<List<String>>()
                    .toList();

            if (tableData.isEmpty) {
              return [
                pw.Center(
                  child: pw.Text(
                    'No students failed in this section.',
                    style: pw.TextStyle(font: ttf, fontSize: 12),
                  ),
                ),
              ];
            }

            content.add(
              pw.TableHelper.fromTextArray(
                headers: ['Admn No', 'Name', ...subjects, 'Total'],
                data: tableData,
                headerStyle: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                cellStyle: pw.TextStyle(font: ttf, fontSize: 8),
                cellAlignment: pw.Alignment.center,
                headerDecoration: pw.BoxDecoration(color: PdfColors.red900),
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FixedColumnWidth(50),
                  1: const pw.FlexColumnWidth(3),
                  for (int i = 0; i < subjects.length; i++)
                    i + 2: const pw.FlexColumnWidth(1.5),
                  subjects.length + 2: const pw.FixedColumnWidth(40),
                  subjects.length + 3: const pw.FixedColumnWidth(40),
                },
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  for (int i = 0; i < subjects.length; i++)
                    i + 2: pw.Alignment.center,
                  subjects.length + 2: pw.Alignment.center,
                  subjects.length + 3: pw.Alignment.center,
                },
              ),
            );

            content.add(pw.SizedBox(height: 40));

            content.add(
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // pw.Column(
                  //   crossAxisAlignment: pw.CrossAxisAlignment.center,
                  //   children: [
                  //     pw.Text("____________________"),
                  //     pw.Text("Class Teacher", style: pw.TextStyle(fontSize: 9)),
                  //   ],
                  // ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text("____________________"),
                      pw.Text("Principal", style: pw.TextStyle(fontSize: 9)),
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
