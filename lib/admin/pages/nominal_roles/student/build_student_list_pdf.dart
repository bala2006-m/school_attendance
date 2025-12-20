import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<pw.Document> buildPdf({
  required List<Map<String, dynamic>> students,
  required String schoolName,
  required String schoolAddress,
  required Uint8List? schoolPhotoBytes,
}) async {
  final pdf = pw.Document();

  final ttf = await PdfGoogleFonts.notoSansRegular();
  final ttfBold = await PdfGoogleFonts.notoSansBold();

  // Helper: Convert Roman numeral class to integer
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
    return map[roman.toUpperCase()] ?? 100; // Large for unknown
  }

  // Helper: Provide sort key for class
  int classSortKey(String className) {
    switch (className.toUpperCase()) {
      case 'PREKG':
        return 0;
      case 'LKG':
        return 1;
      case 'UKG':
        return 2;
      default:
        final n = int.tryParse(className);
        if (n != null) return n + 2; // offset numeric by 2
        final rn = romanToInt(className);
        if (rn != 100) return rn + 14; // offset for roman numerals
        return 1000; // unknown classes last
    }
  }

  // Sort students by class, section, username
  students.sort((a, b) {
    final classCompare = classSortKey(
      a['class'],
    ).compareTo(classSortKey(b['class']));
    if (classCompare != 0) return classCompare;

    final sectionCompare = a['section'].toString().compareTo(
      b['section'].toString(),
    );
    if (sectionCompare != 0) return sectionCompare;

    final aUsername = a['username'].toString();
    final bUsername = b['username'].toString();
    final aNum = int.tryParse(aUsername);
    final bNum = int.tryParse(bUsername);
    if (aNum != null && bNum != null) {
      return aNum.compareTo(bNum);
    } else {
      return aUsername.compareTo(bUsername);
    }
  });

  if (students.isEmpty) {
    pdf.addPage(
      pw.Page(
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build:
            (context) => pw.Center(
              child: pw.Text(
                "No students found",
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
      ),
    );
    return pdf;
  }

  // Group students by class-section after sorting
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (var s in students) {
    final key = "${s['class']}-${s['section']}";
    grouped.putIfAbsent(key, () => []).add(s);
  }

  // Helper function to paginate list into chunks
  List<List<T>> chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    return chunks;
  }

  for (var entry in grouped.entries) {
    final classStudents = entry.value;

    final male =
        classStudents.where((s) => s['gender'] == 'M').toList()..sort((a, b) {
          var aUsername = a['username'].toString();
          var bUsername = b['username'].toString();
          final numA = int.tryParse(aUsername);
          final numB = int.tryParse(bUsername);
          if (numA != null && numB != null) {
            return numA.compareTo(numB);
          } else {
            return aUsername.compareTo(bUsername);
          }
        });

    final female =
        classStudents.where((s) => s['gender'] == 'F').toList()..sort((a, b) {
          var aUsername = a['username'].toString();
          var bUsername = b['username'].toString();
          final numA = int.tryParse(aUsername);
          final numB = int.tryParse(bUsername);
          if (numA != null && numB != null) {
            return numA.compareTo(numB);
          } else {
            return aUsername.compareTo(bUsername);
          }
        });

    final other =
        classStudents
            .where((s) => s['gender'] != 'M' && s['gender'] != 'F')
            .toList()
          ..sort((a, b) {
            var aUsername = a['username'].toString();
            var bUsername = b['username'].toString();
            final numA = int.tryParse(aUsername);
            final numB = int.tryParse(bUsername);
            if (numA != null && numB != null) {
              return numA.compareTo(numB);
            } else {
              return aUsername.compareTo(bUsername);
            }
          });

    final stats = [
      [
        male.length.toString(),
        female.length.toString(),
        (male.length + female.length).toString(),
      ],
    ];

    final combined = [
      ...male,
      if (male.isNotEmpty && female.isNotEmpty)
        <String, dynamic>{'isEmptyRow': true},
      ...female,
      ...other,
    ];

    // Remove empty row filler while building data to avoid error
    List<Map<String, dynamic>> filteredCombined =
        combined
            .where((s) => s['isEmptyRow'] != true)
            .toList()
            .cast<Map<String, dynamic>>();

    const int studentsPerPage = 40;
    List<List<Map<String, dynamic>>> pagedStudents = chunkList(
      filteredCombined,
      studentsPerPage,
    );

    // bool hasEmptyRow = male.isNotEmpty && female.isNotEmpty;
    int overallSerial = 1;

    for (int pageIndex = 0; pageIndex < pagedStudents.length; pageIndex++) {
      final currentPageStudents = pagedStudents[pageIndex];

      final data = <List<String>>[];

      for (var s in currentPageStudents) {
        data.add([
          (overallSerial++).toString(),
          s['username'] ?? '',
          s['name'] ?? '',
          s['gender'] == 'M'
              ? 'Male'
              : s['gender'] == 'F'
              ? 'Female'
              : 'Others',
          s['mobile'] ?? '',
          // '',
          '',
        ]);
      }

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
                    "Class: ${classStudents.first['class']}   Section: ${classStudents.first['section']}",
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  if (pageIndex == 0)
                    pw.TableHelper.fromTextArray(
                      headers: ["Male", "Female", "Total"],
                      data: stats,
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        fontSize: 10,
                      ),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.blue,
                      ),
                      cellAlignment: pw.Alignment.center,
                      cellStyle: pw.TextStyle(fontSize: 9, font: ttf),
                    ),
                  if (pageIndex == 0) pw.SizedBox(height: 10),
                ],
              ),
          build:
              (context) => [
                pw.TableHelper.fromTextArray(
                  headers: [
                    "S.No",
                    "Admn.No",
                    "Name",
                    "Gender",
                    "Mobile",
                    "Remark",
                  ],
                  data: data,
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
                    0: pw.FixedColumnWidth(23),
                    // 1: pw.FlexColumnWidth(2),
                    // 2: pw.FlexColumnWidth(4.3),
                    3: pw.FixedColumnWidth(46),
                    4: pw.FixedColumnWidth(77),
                    5: pw.FixedColumnWidth(77),
                    //5: pw.FlexColumnWidth(2),
                  },
                ),
              ],
        ),
      );
    }
  }

  return pdf;
}
