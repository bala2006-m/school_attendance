import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AdminApiService {
  static const String baseUrl = "http://51.20.189.225";
  // static const String tempUrl = "https://ghj5w9n1-3000.inc1.devtunnels.ms";
  //static const String parthiUrl = "https://rdt3tvjb-3000.inc1.devtunnels.ms";
  static Future<Map<String, dynamic>?> uploadStudentExcelFile(
    File file,
    String schoolId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/excel-upload/students');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType(
              'application',
              'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ),
        );

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respStr = await response.stream.bytesToString();
        return jsonDecode(respStr);
      } else {
        print('Upload failed with code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadStaffExcelFile(
    File file,
    String schoolId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/excel-upload/staff');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType(
              'application',
              'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ),
        );

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respStr = await response.stream.bytesToString();
        return jsonDecode(respStr);
      } else {
        print('Upload failed with code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadAdminExcelFile(
    File file,
    String schoolId,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/excel-upload/admin');
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            contentType: MediaType(
              'application',
              'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            ),
          ),
        );

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final respStr = await response.stream.bytesToString();
        return jsonDecode(respStr);
      } else {
        print('Upload failed with code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchStudentAttendanceBetweenDays({
    required String username,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final url = Uri.parse(
      '$baseUrl/attendance/student/betweensummary'
      '?username=$username'
      '&fromDate=${fromDate.toIso8601String().split("T").first}'
      '&toDate=${toDate.toIso8601String().split("T").first}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          return data;
        }
      }
    } catch (e) {
      print("API error: $e");
    }
    return null;
  }

  static Future<Map<String, dynamic>> fetchStudentMonthlyAttendance(
    String username,
    String month,
    String year,
  ) async {
    int mon = int.parse(month);
    int yr = int.parse(year);

    final url = Uri.parse(
      '$baseUrl/attendance/student/monthly?username=$username&month=$mon&year=$yr',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] != 'success') {
          throw Exception("❌ Attendance data not found");
        }

        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          "❌ ${error['message'] ?? 'Failed to fetch attendance'}",
        );
      }
    } catch (e) {
      throw Exception("❌ Error: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchLeaveRequest(
    String schoolId,
  ) async {
    int id = int.parse(schoolId);
    final url = Uri.parse('$baseUrl/leave-request/list?school_id=$id');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isEmpty) {
          return [];
        }

        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
          "❌ ${error['message'] ?? 'Failed to fetch leave request'}",
        );
      }
    } catch (e) {
      throw Exception("❌ Error: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchFeedback(
    String schoolId,
  ) async {
    int id = int.parse(schoolId);
    final url = Uri.parse('$baseUrl/feedback/list?school_id=$id');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);

        if (data.isEmpty) {
          return [];
        }

        // Return list of maps (each feedback entry)
        return data.map((e) => e as Map<String, dynamic>).toList();
      } else {
        final error = jsonDecode(response.body);
        throw Exception("❌ ${error['message'] ?? 'Failed to fetch feedback'}");
      }
    } catch (e) {
      throw Exception("❌ Error: $e");
    }
  }

  static Future<String> fetchStaffUsername(String mobile) async {
    final url = Uri.parse('$baseUrl/staff/fetch-by-mobile?mobile=$mobile');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['staff'] != null && data['staff'] is Map) {
          final username = data['staff']['username'];
          if (username != null && username is String) {
            return username;
          } else {
            return "❌ Username not found in response";
          }
        } else if (data['staff'] is String) {
          return data['staff'];
        } else {
          return "❌ Unexpected data format";
        }
      } else {
        final error = jsonDecode(response.body);
        return "❌ ${error['message'] ?? 'Failed to fetch username'}";
      }
    } catch (e) {
      return "❌ Error: $e";
    }
  }

  static Future<String> postMessage(String message, int schoolId) async {
    final url = Uri.parse('$baseUrl/messages/post-message');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messages': message, 'schoolId': schoolId}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "✅ ${data['message']}";
      } else {
        return "❌ ${data['message'] ?? 'Failed to post message'}";
      }
    } catch (e) {
      return "❌ Error: $e";
    }
  }

  static Future<String> fetchLatestMessage(String schoolId) async {
    try {
      final int id = int.parse(schoolId);
      final url = Uri.parse('$baseUrl/messages/last/$id');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return data['messages']?.toString() ?? '';
      } else {
        print('Failed to load message. Status code: ${response.statusCode}');
        return '';
      }
    } catch (e) {
      print('Error fetching message: $e');
      return '';
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllClasses(
    String schoolId,
  ) async {
    final url = Uri.parse('$baseUrl/class/all/${int.parse(schoolId)}');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(
        'Failed to fetch classes: ${error['message'] ?? 'Unknown error'}',
      );
    }

    final List data = jsonDecode(response.body);
    return data
        .map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Future<Map<String, dynamic>> fetchClassInfo({
    required int classId,
    required int schoolId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/class/get-name?class_id=$classId&school_id=$schoolId',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      } else {
        throw Exception('API returned error: ${data['message']}');
      }
    } else {
      throw Exception('Failed to load class info');
    }
  }

  static Future<Map<String, dynamic>> saveAttendance({
    required String username,
    required String date,
    required String session,
    required String status,
    required String schoolId,
    required String classId,
  }) async {
    final url = Uri.parse('$baseUrl/attendance/post_student_attendance');

    try {
      final response = await http.post(
        url,
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
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to save attendance: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saving attendance: $e');
    }
  }

  static Future<bool> updateProfile({
    required String username,
    required String name,
    required String designation,
    required String mobile,
    File? imageFile,
  }) async {
    try {
      String? photoBase64;
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        photoBase64 = base64Encode(bytes);
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/admin/$username'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'designation': designation,
          'mobile': mobile,
          if (photoBase64 != null) 'photoBase64': photoBase64,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Failed to update profile: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllStudentData(
    String schoolId,
  ) async {
    int id = int.parse(schoolId);

    final uri = Uri.parse(
      '$baseUrl/students/fetch_all_student_data',
    ).replace(queryParameters: {'school_id': id.toString()});

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          final List<dynamic> students = data['students'];
          return students.cast<Map<String, dynamic>>();
        } else {
          throw Exception(
            "❌ Server error: ${data['message'] ?? 'Unknown error'}",
          );
        }
      } else {
        throw Exception("❌ HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("❌ Failed to load students. Reason: $e");
    }
  }

  //FetchStaffData
  static Future<List<Map<String, dynamic>>> fetchStaffData(
    String schoolId,
  ) async {
    int id = int.parse(schoolId);
    try {
      final uri = Uri.parse(
        '$baseUrl/staff/all-by-school',
      ).replace(queryParameters: {'school_id': id.toString()});

      final response = await http.get(uri);
      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data.containsKey('staff')) {
          return List<Map<String, dynamic>>.from(data['staff']);
        }
      } else {
        print("Server responded with status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching staff data: $e");
    }

    return [];
  }

  //FETCH ADMIN DATA
  static Future<Map<String, dynamic>?> fetchAdminData(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/fetch_admin?username=$username'),
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded['data'].isNotEmpty) {
          return decoded['data'][0]; // Assuming you fetch a single admin
        }
      }
    } catch (e) {
      print("Error fetching admin data: $e");
    }
    return null;
  }

  //Count usernames
  static Future<int> countStudentUsernames(String schoolId) async {
    final url = Uri.parse(
      '$baseUrl/students/count_student?school_id=$schoolId',
    );

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['count'] != null) {
          return data['count'] as int;
        } else {
          throw Exception('Unexpected response format: ${response.body}');
        }
      } else {
        throw Exception(
          'Server error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Failed to count usernames: $e');
    }
  }
}
