import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://51.20.189.225";
  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/auth/send_otp');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 ||
        data['message'] == "OTP sent successfully") {
      return data;
    } else {
      return data;
    }
  }

  static Future<Map<String, dynamic>> updatePassword({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/update_password');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'newPassword': password}),
    );
    final data = jsonDecode(response.body);
    print(data);
    if (response.statusCode == 200 ||
        data['message'] == "Password updated successfully") {
      return data;
    } else {
      return data;
    }
  }

  static Future<bool> deleteUser({
    required String username,
    required String role,
    required int schoolId,
  }) async {
    final url = Uri.parse('$baseUrl/attendance-users/delete');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'role': role,
        'school_id': schoolId,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 ||
        data['message'] == "User deleted successfully") {
      return true;
    } else {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getSchoolAndClassByUsername(
    String username,
  ) async {
    final url = Uri.parse('$baseUrl/students/school-class?username=$username');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to load school and class data: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  static Future<List<dynamic>> getUsersByRole(String role) async {
    final url = Uri.parse('$baseUrl/attendance-users?role=$role');

    try {
      final response = await http.get(url);
      // print(response.body);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSchools() async {
    final url = Uri.parse('$baseUrl/fetch_school');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);

        if (jsonBody['status'] == 'success') {
          // Expecting jsonBody['schools'] to be a List
          List schools = jsonBody['schools'];
          return List<Map<String, dynamic>>.from(schools);
        } else {
          throw Exception(jsonBody['message'] ?? 'Unknown error from server');
        }
      } else {
        throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching schools: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchClassId({
    required String schoolId,
    required String className,
    required String section,
  }) async {
    final url = Uri.parse(
      '$baseUrl/class/fetch_class_id?school_id=$schoolId&class=$className&section=$section',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'Server error',
          'code': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Failed to connect to server',
        'details': e.toString(),
      };
    }
  }

  static Future<Map<String, String>> fetchStudentDetails(
    String schoolId,
    String classId,
    String username,
  ) async {
    final url = Uri.parse(
      '$baseUrl/students/fetch_student_name?school_id=$schoolId&class_id=$classId&username=$username',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        final student = data['student'];
        return {
          'name': student['name'],
          'gender': student['gender'],
          'email': student['email'],
          'mobile': student['mobile'],
        };
      }
    }

    return {}; // return empty map if error or not found
  }

  static Future<Map<String, List<String>>> fetchTodayStudentAbsentees(
    String date,
    String schoolId,
    String classId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/attendance/fetch_stu_absent_all?date=$date&school_id=$schoolId&class_id=$classId',
      ),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['status'] == 'success') {
        final List<String> fnList = List<String>.from(jsonData['fn_absentees']);
        final List<String> anList = List<String>.from(jsonData['an_absentees']);

        return {'fn': fnList, 'an': anList};
      }
    }

    return {'fn': [], 'an': []};
  }

  static Future<Map<String, Map<String, dynamic>>>
  fetchTodayStudentAttendanceClass(
    String date,
    String session,
    String schoolId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/attendance/student/fetch_stu_attendance?date=$date&school_id=$schoolId',
      ),
    );
    //print(response.body);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);

      if (jsonData['status'] == 'success') {
        final Map<String, Map<String, dynamic>> attendanceMap = {};

        for (var entry in jsonData['staff']) {
          attendanceMap[entry['username']] = {
            'status': entry["${session}_status"] ?? 'A',
            'class_id': entry['class_id'],
          };
        }

        return attendanceMap;
      }
    }
    return {};
  }

  // Fetch student attendance
  static Future<Map<String, String>> fetchTodayStudentAttendance(
    String date,
    String session,
    String schoolId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/attendance/student/fetch_stu_attendance?date=$date&school_id=$schoolId',
      ),
    );
    //print(response.body);
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        final Map<String, String> attendanceMap = {};
        for (var entry in jsonData['staff']) {
          attendanceMap[entry['username']] = entry["${session}_status"] ?? 'A';
        }
        return attendanceMap;
      }
    }
    return {}; // If error, fallback to empty map
  }

  static Future<bool?> checkAttendanceStatus(
    String schoolId,
    String classId,
    String date,
  ) async {
    try {
      final Uri url = Uri.parse(
        '$baseUrl/attendance/check_attendance_status?school_id=$schoolId&class_id=$classId&date=$date',
      );

      final response = await http.get(url);
      //print(response.body);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data['attendance_exists'] as bool? ?? false;
        } else {
          print('Server responded with error: ${data['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exception while checking attendance: $e');
    }

    return null;
  }

  //CHECK ATTENDANCE STATUS
  static Future<bool?> checkAttendanceStatusSession(
    String schoolId,
    String classId,
    String date,
    String session,
  ) async {
    try {
      final Uri url = Uri.parse(
        '$baseUrl/attendance/check_attendance_status_session?school_id=$schoolId&class_id=$classId&date=$date&session=$session',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data['attendance_exists'] as bool? ?? false;
        } else {
          print('Server responded with error: ${data['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Exception while checking attendance: $e');
    }

    return null;
  }

  // Fetch Student Attendance
  static Future<List<Map<String, dynamic>>> fetchStudentAttendance({
    required String date,
    required String schoolId,
    required String classId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/attendance/student/class?date=$date&school_id=$schoolId&class_id=$classId',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['attendance'] is List) {
          return List<Map<String, dynamic>>.from(data['attendance']);
        } else {
          print("Unexpected data format or status: ${data['status']}");
        }
      } else {
        print("Error response: ${response.statusCode}");
      }
    } catch (e) {
      print("Fetch attendance error: $e");
    }

    return [];
  }

  //Fetch School id

  static Future<String?> fetchSchoolId(String username) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/fetch_school_id?username=$username'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final data = jsonData['data'];
          if (data != null && data.isNotEmpty) {
            return data[0]['school_id']?.toString();
          }
        }
      } else {
        print('Failed: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching school_id: $e');
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

  // Fetch staff attendance
  static Future<Map<String, String>> fetchTodayAttendance(
    String date,
    String session,
    String schoolId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/attendance/staff/fetch_staff_attendance?date=$date&school_id=$schoolId',
      ),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        final Map<String, String> attendanceMap = {};
        for (var entry in jsonData['staff']) {
          attendanceMap[entry['username']] = entry["${session}_status"] ?? 'A';
        }
        return attendanceMap;
      }
    }
    return {};
  }

  static Future<List<Map<String, dynamic>>> fetchStaffAttendanceByUsername(
    String username,
    String schoolId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/attendance/staff/fetch_staff_attendance_by_username?username=$username&school_id=$schoolId',
        ),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success' && jsonData['staff'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['staff']);
        }
      }
    } catch (e) {
      print('Error fetching attendance: $e');
    }

    return [];
  }

  //Post Attendance
  static Future<bool> postAttendance({
    required String username,
    required String date,
    required String session,
    required String status,
    required String school_id,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/attendance/staff'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'date': date,
          'session': session,
          'status': status,
          'school_id': school_id,
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

  //Add Class
  static Future<String> addClass(
    String className,
    String section,
    String schoolId,
  ) async {
    final url = Uri.parse('$baseUrl/class/add');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'class': className,
              'section': section,
              'school_id': schoolId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return "✅ ${data['message']}";
      } else if (response.statusCode == 409 ||
          data['message'] == 'Add failed: Class already marked') {
        return "❌ Class already exists: ${data['error']}";
      } else if (response.statusCode == 400) {
        return "❌ Missing fields: ${data['error']}";
      } else {
        return "❌ Failed: ${data['error'] ?? 'Unknown error'}";
      }
    } catch (e) {
      return "❌ Network or Server Error: $e";
    }
  }

  static Future<String> deleteClass(
    String className,
    String section,
    String schoolId,
  ) async {
    final url = Uri.parse('$baseUrl/class/delete');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'class': className,
              'section': section,
              'school_id': schoolId,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);
      print(data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return "✅ ${data['message']}";
      } else if (response.statusCode == 409 ||
          data['message'] == 'Delete failed: Class not found') {
        return "❌ Class not found: ${data['error']}";
      } else if (response.statusCode == 400) {
        return "❌ Missing fields: ${data['error']}";
      } else {
        return "❌ Failed: ${data['error'] ?? 'Unknown error'}";
      }
    } catch (e) {
      return "❌ Network or Server Error: $e";
    }
  }

  //Delete Holiday
  static Future<void> deleteHoliday(String date, String schoolId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/holidays/delete_holiday'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'date': date, 'school_id': int.parse(schoolId)}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete holiday');
    }
  }

  // Add Holidays
  static Future<String> addHoliday({
    required String date,
    required String reason,
    required String schoolId,
    required List<int> classIds,
    required String fn,
    required String an,
  }) async {
    final url = Uri.parse('$baseUrl/holidays/add_holiday');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'date': date,
        'reason': reason,
        'school_id': int.parse(schoolId),
        'class_ids': classIds,
        'fn': fn,
        'an': an,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final error = jsonDecode(response.body);
      final err = error['error'];
      throw ('Failed to add holiday: $err');
    }
    return 'Added Successfully';
  }

  //Fetch holidays
  static Future<List<Map<String, dynamic>>> fetchHolidays(
    String schoolId,
  ) async {
    final url = Uri.parse('$baseUrl/holidays/fetch?school_id=$schoolId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(data['holidays']);
      } else {
        throw Exception('Server error: ${data['message']}');
      }
    } else {
      throw Exception('HTTP error ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> registerStudent({
    required String username,
    required String name,
    required String gender,
    required String email,
    required String mobile,
    required String classId,
    required String schoolId,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register_student');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'name': name.trim(),
          'gender': gender.trim(),
          'email': email.trim(),
          'mobile': mobile.trim(),
          'class_id': classId.trim(),
          'school_id': schoolId.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      print(data);
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'],
          'username': data['username'], // in case backend sends it back
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Unknown error occurred.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network or server error: $e',
        'statusCode': 0,
      };
    }
  }

  //Register
  static Future<Map<String, dynamic>> registerUser({
    required String username,
    required String password,
    required String role,
    required String school_id,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    int sId = int.parse(school_id);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role,
        'school_id': sId,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        data['status'] == 'success') {
      return {'success': true, 'message': data['message']};
    } else {
      return {
        'success': false,
        'error': data['error'] ?? 'Unknown error',
        'statusCode': response.statusCode,
      };
    }
  }

  static Future<Map<String, dynamic>> registerUserDesignation({
    required String username,
    required String designation,
    required String school_id,
    required String mobile,
    required String table,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register-designation');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'designation': designation.trim(),
          'school_id': school_id.trim(),
          'table': table.trim(),
          'mobile': mobile.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          data['status'] == 'success') {
        return {
          'success': true,
          'message': data['message'],
          'username': username,
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Unknown error occurred.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network or server error: $e',
        'statusCode': 0,
      };
    }
  }

  //Fetch Presence
  static Future<int> fetchPresence(String role) async {
    final url = Uri.parse('$baseUrl/count');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': role}),
    );
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 ||
        response.statusCode == 201 ||
        data['status'] == 'success') {
      final data = jsonDecode(response.body);
      return data['count'];
    } else {
      throw Exception('Failed to count usernames');
    }
  }

  //Count usernames
  static Future<int> countStaffUsernames(String schoolId) async {
    final url = Uri.parse('$baseUrl/staff/count?school_id=$schoolId');
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

  //Fetch username
  static Future<List<Map<String, dynamic>>> fetchUsernamesByRole(
    String role,
    String schoolId,
  ) async {
    final url = Uri.parse('$baseUrl/fetch_usernames');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'role': role, 'school_id': schoolId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return List<Map<String, dynamic>>.from(data['users']);
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to fetch usernames');
    }
  }

  // Teacher login
  static Future<bool> loginTeacher(
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse('$baseUrl/email_login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } else {
      return false;
    }
  }

  //Student login
  static Future<bool> loginStudent(
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse('$baseUrl/email_login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } else {
      return false;
    }
  }

  //Admin login
  static Future<bool> loginAdmin(
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse('$baseUrl/email_login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } else {
      return false;
    }
  }

  static Future<bool> sendOTP(String email, String otp) async {
    final url = Uri.parse('$baseUrl/send_otp');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } else {
      return false;
    }
  }
}
