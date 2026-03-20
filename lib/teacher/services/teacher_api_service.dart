import 'dart:convert';
import 'package:school_attendance/services/hybrid_api_service.dart';
import 'package:school_attendance/utils/utils.dart';

import '../models/staff_models.dart';

class TeacherApiServices {
  // static Future<bool> createHomework(Map<String, dynamic> data) async {
  //   final url = Uri.parse("$baseUrl/homework/create");
  //
  //   final response = await http.post(
  //     url,
  //     headers: {"Content-Type": "application/json"},
  //     body: jsonEncode(data),
  //   );
  //
  //   if (response.statusCode == 201 || response.statusCode == 200) {
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }
  //
  // static Future<void> deleteHomeworkById(int id) async {
  //   final url = Uri.parse("$baseUrl/homework/delete_homework_by_id/$id");
  //   final response = await http.delete(url);
  //
  //   if (response.statusCode != 200) {
  //     throw Exception("Failed to delete homework");
  //   }
  // }
  //
  // static Future<List<dynamic>> fetchHomeworkByStaff({
  //   required String staff,
  //   required int schoolId,
  //   required int classId,
  // }) async {
  //   final String st = staff.toLowerCase();
  //   final url = Uri.parse(
  //     '$baseUrl/homework/fetch_homework_by_staff/$schoolId/$classId/$st',
  //   );
  //
  //   final response = await http.get(url);
  //   if (response.statusCode == 200 || response.statusCode == 201) {
  //     final data = jsonDecode(response.body);
  //     if (data != []) {
  //       return data;
  //     } else {
  //       throw Exception('Invalid response structure');
  //     }
  //   } else {
  //     throw Exception('Failed to fetch homework');
  //   }
  // }

  static Future<Map<String, dynamic>> createLeaveRequest({
    required String username,
    required String email,
    String? role,
    required int schoolId,
    required int classId,
    required DateTime fromDate,
    required DateTime toDate,
    String? reason,
  }) async {
    final response = await HybridApiService.post(
      "/leave-request/create",
      body: jsonEncode({
        "username": username,
        "role": role,
        "school_id": schoolId,
        "class_id": classId,
        "from_date": fromDate.toIso8601String(),
        "to_date": toDate.toIso8601String(),
        "reason": reason,
        'email': email,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        "Failed to create leave request: ${response.statusCode} ${response.body}",
      );
    }
  }

  static Future<String> updateLeaveStatus(int id, String status) async {
    final response = await HybridApiService.patch(
      '/leave-request/$id/status',
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception(
        'Failed to update status. Code: ${response.statusCode}, Body: ${response.body}',
      );
    }
  }

  static Future<void> updateProfile({
    required String username,
    required Map<String, dynamic> data,
    required int schoolId,
  }) async {
    final response = await HybridApiService.put(
      '/staff/update/$username/$schoolId',
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  static Future<Staff> fetchProfile({
    required String username,
    required int schoolId,
  }) async {
    final response = await HybridApiService.get(
      '/staff/fetch-staffs?username=$username&school_id=$schoolId',
    );
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
    required int schoolId,
  }) async {
    final response = await HybridApiService.post(
      '/students/change-password',
      body: jsonEncode({
        'username': username,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
        'school_id': schoolId,
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
    // Convert the list to the required plain-text format
    String timetableString = timetables
        .map((entry) {
          return '${entry["schoolId"]} ${entry["classId"]} ${entry["dayOfWeek"]} ${entry["periodNumber"]} ${entry["subject"]}';
        })
        .join('\n');

    try {
      final response = await HybridApiService.post(
        '/timetable/create',
        body: jsonEncode({"data": timetableString}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteTimetableEntry(String id) async {
    try {
      final response = await HybridApiService.delete('/timetable/delete/$id');

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Fetch staff data by username
  static Future<Map<String, dynamic>?> fetchStaffDataUsername({
    required String username,
    required int schoolId,
  }) async {
    try {
      final response = await HybridApiService.get(
        '/staff/fetch-by-username?username=$username&school_id=$schoolId',
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final staff = data['staff'];
          if (staff != null || staff is Map<String, dynamic>) {
            return staff;
          }
        }
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  //FETCH STUDENT DATA
  static Future<List<Map<String, dynamic>>> fetchStudentData({
    String? schoolId,
    String? classId,
  }) async {
    try {
      final response = await HybridApiService.get(
        '/students/fetch-student-data?school_id=$schoolId&class_id=$classId',
      );
      final res = jsonDecode(response.body);

      if (response.statusCode == 200 || res['status'] == 'success') {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final List<dynamic> students = data['students'];

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

  static Future<List<Map<String, dynamic>>> fetchNonRteStudentData({
    String? schoolId,
    String? classId,
  }) async {
    try {
      final response = await HybridApiService.get(
        '/students/fetch-non_rte_student-data?school_id=$schoolId&class_id=$classId',
      );
      final res = jsonDecode(response.body);

      if (response.statusCode == 200 || res['status'] == 'success') {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final List<dynamic> students = data['students'];

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
      final response = await HybridApiService.get(
        '/class/fetch_class_data?school_id=$schoolId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data.containsKey('classes')) {
          return List<Map<String, dynamic>>.from(data['classes']);
        }
      }
    } catch (e) {
      return [];
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
      final response = await HybridApiService.post(
        '/attendance/post_student_attendance',
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
      print(res);

      if (response.statusCode == 200 || res['status'] == 'success') {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
