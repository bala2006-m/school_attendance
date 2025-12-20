// excel_generator.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

/// ------------------------------------------------------------
/// STEP 1: CREATE EXCEL CLASS-WISE SHEETS
/// ------------------------------------------------------------
Future<Uint8List> buildExcel({
  required List<Map<String, dynamic>> students,
}) async {
  final excel = Excel.createExcel();
  excel.delete('Sheet1'); // Remove default empty sheet

  // Convert Roman Numeral Class to Integer
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
    return map[roman.toUpperCase()] ?? 100;
  }

  // Determine sorting weight for class names
  int classSortKey(String className) {
    switch (className.toUpperCase()) {
      case 'PREKG':
        return 0;
      case 'LKG':
        return 1;
      case 'UKG':
        return 2;
      default:
        final numVal = int.tryParse(className);
        if (numVal != null) return numVal + 2; // 1,2,3... classes
        final rn = romanToInt(className);
        if (rn != 100) return rn + 14;
        return 1000;
    }
  }

  // Sort all students (same way as your PDF)
  students.sort((a, b) {
    final classCompare = classSortKey(
      a['class'],
    ).compareTo(classSortKey(b['class']));
    if (classCompare != 0) return classCompare;

    final sectionCompare = a['section'].toString().compareTo(
      b['section'].toString(),
    );
    if (sectionCompare != 0) return sectionCompare;

    // Sort by username/admission no
    final aNum = int.tryParse(a['username'].toString());
    final bNum = int.tryParse(b['username'].toString());
    if (aNum != null && bNum != null) return aNum.compareTo(bNum);

    return a['username'].toString().compareTo(b['username'].toString());
  });

  // Group students by Class-Section
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (var s in students) {
    final key = "${s['class']}-${s['section']}";
    grouped.putIfAbsent(key, () => []).add(s);
  }

  // Create one sheet per class-section
  for (var entry in grouped.entries) {
    String sheetName = entry.key;
    if (sheetName.length > 31) {
      sheetName = sheetName.substring(0, 31); // Excel limit
    }

    final sheet = excel[sheetName];

    // Header
    final headers = ["S.No", "Admn.No", "Name", "Gender", "Mobile", "Remark"];
    sheet.appendRow(headers);

    // Body
    int serial = 1;
    for (var s in entry.value) {
      sheet.appendRow([
        serial++,
        s['username'] ?? "",
        s['name'] ?? "",
        s['gender'] == 'M'
            ? "Male"
            : s['gender'] == 'F'
            ? "Female"
            : "Others",
        "",
        "",
      ]);
    }
  }

  return Uint8List.fromList(excel.encode()!);
}

/// ------------------------------------------------------------
/// STEP 2: SAVE + PREVIEW + SHARE
/// ------------------------------------------------------------

Future<void> generatePreviewShareExcel(
  List<Map<String, dynamic>> students,
) async {
  Uint8List excelBytes = await buildExcel(students: students);

  // final dir = await getApplicationDocumentsDirectory();
  final filePath = "/storage/emulated/0/Download/StudentList.xlsx";
  final file = File(filePath);

  await file.writeAsBytes(excelBytes);

  // Preview
  await OpenFilex.open(filePath);

  // SHARE USING flutter_share

  await Share.shareXFiles([
    XFile(
      filePath,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    ),
  ], text: 'Student List');
}
