import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> exportAttendanceToExcel(
  BuildContext context,
  List<Map<String, dynamic>> attendanceData,
  String staffUsername,
) async {
  try {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }

      if (!status.isGranted) {
        var manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Storage permission denied')),
          );
          return;
        }
      }
    }
    final excel = Excel.createExcel();
    final sheet = excel['${staffUsername}_Attendance'];
    sheet.appendRow(['Date', 'FN Status', 'AN Status']);

    for (var entry in attendanceData) {
      final date = entry['date']?.toString().substring(0, 10) ?? '';
      final fn = entry['fn_status'] ?? '';
      final an = entry['an_status'] ?? '';
      sheet.appendRow([date, fn, an]);
    }

    final path = '/storage/emulated/0/Download';
    final file = File('$path/${staffUsername}_attendance.xlsx');

    final excelBytes = excel.encode();
    await file.writeAsBytes(excelBytes!);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Excel saved to: ${file.path}')));
  } catch (e) {
    print('Failed to export Excel: $e');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Failed to export Excel')));
  }
}
