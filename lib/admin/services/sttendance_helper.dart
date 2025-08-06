import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/teacher/services/teacher_api_service.dart';

import '../../services/api_service.dart';

class AttendanceHelper {
  static Future<List<Map<String, dynamic>>> fetchClasses(
    String schoolId,
  ) async {
    final classes = await TeacherApiServices.fetchClassData(schoolId);
    classes.sort((a, b) {
      int classCompare = a['class'].compareTo(b['class']);
      return classCompare != 0
          ? classCompare
          : a['section'].compareTo(b['section']);
    });
    return classes;
  }

  static Future<Map<String, dynamic>> fetchSchoolInfo(String schoolId) async {
    final schoolData = await ApiService.fetchSchoolData(schoolId);
    final Map<String, dynamic> result = {
      'name': schoolData[0]['name'],
      'address': schoolData[0]['address'],
      'image': null,
    };

    if (schoolData[0]['photo'] != null) {
      try {
        Uint8List imageBytes = base64Decode(schoolData[0]['photo']);
        result['image'] = Image.memory(imageBytes, gaplessPlayback: true);
      } catch (_) {}
    }

    return result;
  }

  static Future<Map<String, bool>> fetchAttendanceStatusMap(
    String schoolId,
    DateTime date,
    List<Map<String, dynamic>> classes,
  ) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final Map<String, bool> statusMap = {};

    List<Future<void>> futures = [];

    for (var cls in classes) {
      final classId = cls['id'].toString();
      futures.add(
        ApiService.checkAttendanceStatus(schoolId, classId, formattedDate)
            .then((result) {
              statusMap[classId] = result == false;
            })
            .catchError((e) {
              statusMap[classId] = true;
            }),
      );
    }

    await Future.wait(futures);
    return statusMap;
  }
}
