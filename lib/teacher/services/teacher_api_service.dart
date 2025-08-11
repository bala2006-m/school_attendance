import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/staff_models.dart';

class TeacherApiServices {
  static const String baseUrl = "http://51.20.189.225";
  //static const String tempUrl = "https://ghj5w9n1-3000.inc1.devtunnels.ms";

  static Future<void> updateProfile(
    String username,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/staff/update/$username'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  static Future<Staff> fetchProfile(String username) async {
    final url = Uri.parse('$baseUrl/staff/fetch-staffs?username=$username');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success' && data['staff'] != null) {
        return Staff.fromJson(data['staff']);
      } else {
        throw Exception('Invalid response structure');
      }
    } else {
      throw Exception('Failed to fetch profile');
    }
  }

  static Future<Map<String, dynamic>> changeStudentPassword({
    required String username,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final url = Uri.parse('$baseUrl/students/change-password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || data['status'] == 'success') {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Password update failed');
    }
  }

  static Future<bool> saveTimetable(
    List<Map<String, dynamic>> timetables,
  ) async {
    const String url = '$baseUrl/timetable';

    // Convert the list to the required plain-text format
    String timetableString = timetables
        .map((entry) {
          return '${entry["schoolId"]} ${entry["classId"]} ${entry["dayOfWeek"]} ${entry["periodNumber"]} ${entry["subject"]}';
        })
        .join('\n');

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"data": timetableString}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        print('Failed to save: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error saving timetable: $e');
      return false;
    }
  }

  /// Fetch staff data by username
  static Future<Map<String, dynamic>?> fetchStaffDataUsername(
    String username,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/staff/fetch-by-username',
      ).replace(queryParameters: {'username': username});

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final staff = data['staff'];
          if (staff != null || staff is Map<String, dynamic>) {
            return staff;
          }
        } else {
          print("API responded with error: ${data['message']}");
        }
      } else {
        print("Server error: HTTP ${response.statusCode}");
      }
    } catch (e) {
      print("Exception caught while fetching staff data: $e");
    }

    return null;
  }

  //FETCH STUDENT DATA
  static Future<List<Map<String, dynamic>>> fetchStudentData({
    String? schoolId,
    String? classId,
  }) async {
    final uri = Uri.parse('$baseUrl/students/fetch-student-data').replace(
      queryParameters: {
        if (schoolId != null && schoolId.isNotEmpty) 'school_id': schoolId,
        if (classId != null && classId.isNotEmpty) 'class_id': classId,
      },
    );

    try {
      final response = await http.get(uri);
      final res = jsonDecode(response.body);

      // print(res);
      // List students = res['students'];
      // print(students);
      if (response.statusCode == 200 || res['status'] == 'success') {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          // print(data['students']);
          final List<dynamic> students = data['students'];
          //print(students);

          return students.cast<Map<String, dynamic>>();
        } else {
          throw Exception("❌ Server error: ${data['message']}");
        }
      } else {
        throw Exception("❌ HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("❌ Failed to load students: $e");
    }
  }

  //Fetch Class Data
  static Future<List<Map<String, dynamic>>> fetchClassData(
    String schoolId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/class/fetch_class_data?school_id=$schoolId'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data.containsKey('classes')) {
          return List<Map<String, dynamic>>.from(data['classes']);
        }
      }
    } catch (e) {
      print("Error fetching class data: $e");
    }
    return [];
  }

  //Post Attendance
  static Future<bool> postStudentAttendance({
    required String username,
    required String date,
    required String session,
    required String status,
    required String schoolId,
    required String classId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/post_student_attendance'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'date': date,
          'session': session,
          'status': status,
          'school_id': schoolId,
          'class_id': classId,
        }),
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200 || res['status'] == 'success') {
        return true;
      } else {
        print('Attendance post failed: ${res['message'] ?? 'Unknown error'}');
        return false;
      }
    } catch (e) {
      print('Error posting attendance: $e');
      return false;
    }
  }
}
