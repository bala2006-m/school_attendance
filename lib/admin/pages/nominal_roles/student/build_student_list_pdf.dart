import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> buildPdf({
  required List<Map<String, dynamic>> students,
  required String schoolName,
  required String schoolAddress,
  required Uint8List? schoolPhotoBytes,
}) async {
  final pdf = pw.Document();

  if (students.isEmpty) {
    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Center(
              child: pw.Text(
                "No students Found",
                style: pw.TextStyle(fontSize: 18),
              ),
            ),
      ),
    );
  } else {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var s in students) {
      final key = "${s['class']}-${s['section']}";
      grouped.putIfAbsent(key, () => []).add(s);
    }

    grouped.forEach((classKey, classStudents) {
      // Separate by gender and sort
      final maleStudents =
          classStudents.where((s) => s['gender'] == 'M').toList()..sort(
            (a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''),
          );
      final femaleStudents =
          classStudents.where((s) => s['gender'] == 'F').toList()..sort(
            (a, b) => (a['username'] ?? '').compareTo(b['username'] ?? ''),
          );
      final otherStudents =
          classStudents
              .where((s) => s['gender'] != 'M' && s['gender'] != 'F')
              .toList();

      final combinedList = [
        ...maleStudents,
        if (maleStudents.isNotEmpty && femaleStudents.isNotEmpty) {},
        ...femaleStudents,
        ...otherStudents,
      ];

      int serialNo = 1;
      final data =
          combinedList.map((s) {
            if (s.isEmpty) {
              return ["", "", "", "", "", "", ""];
            }
            return [
              (serialNo++).toString(),
              s['username'] ?? '',
              s['name'] ?? '',
              s['gender'] == 'M'
                  ? 'Male'
                  : s['gender'] == 'F'
                  ? 'Female'
                  : 'Others',
              s['mobile'] ?? '',
              s['email'] ?? '',
              "",
            ];
          }).toList();

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
                        pw.MemoryImage(schoolPhotoBytes),
                        width: 80,
                        height: 80,
                      ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      schoolName,
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      schoolAddress,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      "Student List",
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      "Class: ${classStudents.first['class']}   Section: ${classStudents.first['section']}",
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Table.fromTextArray(
                      headers: [
                        "S.No",
                        "Admn.No",
                        "Name",
                        "Gender",
                        "Mobile",
                        "Email",
                        "Remark",
                      ],
                      data: data,
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black,
                      ),
                      cellAlignment: pw.Alignment.centerLeft,
                      cellStyle: const pw.TextStyle(fontSize: 10),
                      columnWidths: {
                        0: pw.FlexColumnWidth(1), // S.No
                        1: pw.FlexColumnWidth(3), // Admn.No
                        2: pw.FlexColumnWidth(3), // Name
                        3: pw.FlexColumnWidth(2), // Gender
                        4: pw.FlexColumnWidth(3), // Mobile
                        5: pw.FlexColumnWidth(3), // Email
                        6: pw.FlexColumnWidth(2), // Remark
                      },
                    ),
                  ],
                ),
              ],
        ),
      );
    });
  }

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}
