import 'dart:io';
import 'package:school_attendance/utils/utils.dart';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> exportAttendanceToExcel(
  BuildContext context,
  List<Map<String, dynamic>> attendanceData,
  String staffUsername,
) async {
  try {
    if (isAndroidPlatform) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      if (!status.isGranted) {
        var manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Storage permission denied')),
            );
          }
          return;
        }
      }
    }

    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    sheet.appendRow(['Date', 'FN Status', 'AN Status']);
    for (var entry in attendanceData) {
      final date = entry['date']?.toString().substring(0, 10) ?? '';
      final fn = entry['fn_status'] ?? '';
      final an = entry['an_status'] ?? '';
      sheet.appendRow([date, fn, an]);
    }
    String path;
    if (isAndroidPlatform) {
      path = '/storage/emulated/0/Download';
    } else {
      final directory = await getApplicationDocumentsDirectory();
      path = directory.path;
    }
    final file = File('$path/${staffUsername}_Attendance.xlsx');
    await file.writeAsBytes(excel.encode()!);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('✅ Excel saved to: ${file.path}')));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to export Excel')));
    }
  }
}
