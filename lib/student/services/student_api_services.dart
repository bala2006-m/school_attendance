import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class StudentApiServices {
  static const String baseUrl = "http://51.20.189.225";
  static Future<void> storeFeedback({
    required String name,
    required String email,
    required String feedback,
    required String schoolId,
    required String classId,
  }) async {
    const apiUrl = '$baseUrl/feedback';

    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'feedback': feedback,
        'schoolId': schoolId,
        'classId': classId,
      }),
    );
    final data = json.decode(response.body);
    if (data['status'] == 'failure') {
      throw Exception('Failed to submit feedback');
    }
  }

  static Future<Map<String, dynamic>?> fetchStudentDataUsername(
    String username,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/students/by-username',
      ).replace(queryParameters: {'username': username});

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final staff = data['student'];

        if (data['status'] == 'success') {
          if (staff is Map<String, dynamic>) {
            return staff;
          } else if (staff is List && staff.isEmpty) {
            return null;
          }
        }
      } else {
        print("Server responded with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching student data: $e");
    }

    return null;
  }

  //FetchSchoolData
  static Future<List<Map<String, dynamic>>> fetchSchoolData(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/fetch_school_data?id=$id'),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['status'] == 'success') {
        final List<Map<String, dynamic>> schoolList = [];

        for (var school in jsonData['schools']) {
          schoolList.add({
            'id': school['id'],
            'name': school['name'],
            'address': school['address'],
            'photo': school['photo'], // base64 string (or null)
          });
        }

        return schoolList;
      }
    }

    return []; // fallback if request fails or no data
  }

  static Future<Map<String, dynamic>?> fetchClassDatas(
    String schoolId,
    String classId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/class/get_class_data?school_id=$schoolId&class_id=$classId',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['class'] is Map) {
          return Map<String, dynamic>.from(data['class']);
        }
      }
    } catch (e) {
      print("Error fetching class data: $e");
    }
    return null;
  }

  // Fetch Student Attendance
  static Future<List<Map<String, dynamic>>> fetchStudentAttendanceByClassid({
    required String schoolId,
    required String classId,
    required String username,
  }) async {
    final url = Uri.parse(
      '$baseUrl/attendance/student/fetch_stu_attendance_by_class_id',
    ).replace(
      queryParameters: {
        'school_id': schoolId,
        'class_id': classId,
        'username': username,
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['student'] is List) {
          return List<Map<String, dynamic>>.from(data['student']);
        } else {
          debugPrint("Unexpected data format or status: ${data['status']}");
        }
      } else {
        debugPrint("Error response: ${response.statusCode}");
      }
    } catch (e, stack) {
      debugPrint("Fetch attendance error: $e\n$stack");
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchHolidaysClasses({
    required String schoolId,
    required String classId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/holidays/class?school_id=$schoolId&class_id=$classId',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final holidays = data['holidays'];

          if (holidays is List) {
            return List<Map<String, dynamic>>.from(holidays);
          } else {
            throw Exception('Invalid "holidays" format: Expected List');
          }
        } else {
          throw Exception(
            'Server error: ${data['message'] ?? "Unknown error"}',
          );
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred: $e');
      throw Exception('Failed to load holidays: $e');
    }
  }

  static Future<Map<String, List<String>>> fetchTimetable({
    required String schoolId,
    required String classId,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/timetable?schoolId=$schoolId&classId=$classId',
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'success') {
        final timetable = <String, List<String>>{};
        (data['timetable'] as Map<String, dynamic>).forEach((day, entries) {
          timetable[day] =
              (entries as List)
                  .map((entry) => entry['subject'].toString())
                  .toList();
        });
        return timetable;
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load timetable');
    }
  }
}
