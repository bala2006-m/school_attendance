import 'dart:convert';
import 'dart:io';

import 'package:school_attendance/services/hybrid_api_service.dart';

class StudentApiServices {
  static Future<List<dynamic>> fetchHomeworkByClassId({
    required int schoolId,
    required int classId,
  }) async {
    final response = await HybridApiService.get(
      '/homework/fetch_homework_by_class_id/$schoolId/$classId',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      if (data != []) {
        return data;
      } else {
        throw Exception('Invalid response structure');
      }
    } else {
      throw Exception('Failed to fetch homework');
    }
  }

  Future<Map<String, dynamic>> updateStudent({
    required String username,
    required int schoolId,
    String? name,
    String? email,
    String? mobile,
    String? gender,
    File? photoFile,
    String? fatherName,
    String? dob,
    String? community,
    String? route,
  }) async {
    try {
      // Convert file to Base64 string if provided
      String? photoBase64;
      if (photoFile != null) {
        final bytes = await photoFile.readAsBytes();
        photoBase64 = base64Encode(bytes);
      }

      final body = {
        if (name != null) "name": name,
        if (email != null) "email": email,
        if (mobile != null) "mobile": mobile,
        if (gender != null) "gender": gender,
        if (photoBase64 != null) "photo": photoBase64,
        if (fatherName != null) "father_name": fatherName,
        if (dob != null) "DOB": dob,
        if (community != null) "community": community,
        if (route != null) "route": route,
      };

      final res = await HybridApiService.put(
        "/students/update?username=$username&school_id=$schoolId",
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        return {
          "status": "error",
          "message": "Server error: ${res.statusCode}",
        };
      }
    } catch (e) {
      return {"status": "error", "message": e.toString()};
    }
  }

  static Future<void> storeFeedback({
    required String username,
    required String name,
    required String email,
    required String feedback,
    required String schoolId,
    required String classId,
  }) async {
    final response = await HybridApiService.post(
      '/feedback',
      body: jsonEncode({
        'name': name,
        'username': username,
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

  static Future<Map<String, dynamic>?> fetchStudentDataUsername({
    required String username,
    required int schoolId,
  }) async {
    try {
      final response = await HybridApiService.get(
        '/students/by-username?username=$username&school_id=$schoolId',
      );

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
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  //FetchSchoolData
  static Future<List<Map<String, dynamic>>> fetchSchoolData(String id) async {
    final response = await HybridApiService.get(
      '/school/fetch_school_data?id=$id',
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['status'] == 'success') {
        final List<Map<String, dynamic>> schoolList = [];

        for (var school in jsonData['schools']) {
          schoolList.add({
            'id': school['id'],
            'name': school['name'],
            'student_access': school['student_access'],
            'address': school['address'],
            'photo': school['photo'],
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
      final response = await HybridApiService.get(
        '/class/get_class_data?school_id=$schoolId&class_id=$classId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['class'] is Map) {
          return Map<String, dynamic>.from(data['class']);
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  // Fetch Student Attendance
  static Future<List<Map<String, dynamic>>> fetchStudentAttendanceByClassid({
    required String schoolId,
    required String classId,
    required String username,
  }) async {
    try {
      final response = await HybridApiService.get(
        '/attendance/student/fetch_stu_attendance_by_class_id?school_id=$schoolId&class_id=$classId&username=$username',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['student'] is List) {
          return List<Map<String, dynamic>>.from(data['student']);
        }
      }
    } catch (e) {
      return [];
    }

    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchHolidaysClasses({
    required String schoolId,
    required String classId,
  }) async {
    try {
      final response = await HybridApiService.get(
        '/holidays/class?school_id=$schoolId&class_id=$classId',
      );

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
      // Gracefully handle holiday load failures (e.g. production server 500)
      // Return empty list so the app continues working without holidays
      return [];
    }
  }

  static Future<Map<String, List<String>>> fetchTimetable({
    required String schoolId,
    required String classId,
  }) async {
    final response = await HybridApiService.get(
      '/timetable?schoolId=$schoolId&classId=$classId',
    );

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

  static Future<Map<String, dynamic>> fetchTimetableAdmin({
    required String schoolId,
    required String classId,
  }) async {
    final response = await HybridApiService.get(
      '/timetable?schoolId=$schoolId&classId=$classId',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      if (data['status'] == 'success') {
        return data;
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load timetable');
    }
  }
}
