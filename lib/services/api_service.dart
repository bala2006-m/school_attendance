import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:school_attendance/services/hybrid_api_service.dart';
import 'package:school_attendance/utils/utils.dart';

class ApiService {
  static Future<String> updateStudentAccess({
    required int schoolId,
    bool? viewHomework,
    bool? events,
    bool? message,
  }) async {
    final response = await HybridApiService.post(
      '/school/student-access',
      body: jsonEncode({
        "school_id": schoolId,
        "student_access": {
          "viewHomework": viewHomework,
          "events": events,
          "message": message,
        },
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response.body;
    } else {
      throw Exception("Failed to update student access");
    }
  }

  static Future<bool> markStudentLeft({
    required int schoolId,
    required int classId,
    required String username,
  }) async {
    try {
      final response = await HybridApiService.post(
        '/students/mark-left',
        body: jsonEncode({
          'school_id': schoolId,
          'class_id': classId,
          'username': username,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<dynamic>> fetchStudentsRoutesSchool({
    required int schoolId,
  }) async {
    try {
      final response = await HybridApiService.get(
        "/students/fetch_student_routs_school?school_id=$schoolId",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['routs'] ?? [];
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> fetchStudentsRoutes({
    required int schoolId,
    required int classId,
  }) async {
    try {
      final response = await HybridApiService.get(
        "/students/fetch_student_routs?school_id=$schoolId&class_id=$classId",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['routs'] ?? [];
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> fetchUniqueRoutes(int schoolId) async {
    final response = await HybridApiService.get(
      '/students/fetch_unique_routs?school_id=$schoolId',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load unique routes');
    }
  }

  static Future<Map<String, dynamic>> getSchool(String schoolId) async {
    try {
      final response = await HybridApiService.get('/school/$schoolId');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get school: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching school: $e');
    }
  }

  // Update school due date
  static Future<Map<String, dynamic>> updateSchoolDueDate({
    required String schoolId,
    required DateTime dueDate,
  }) async {
    try {
      final response = await HybridApiService.put(
        '/school/$schoolId/due-date',
        body: json.encode({'dueDate': dueDate.toIso8601String()}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update due date: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating due date: $e');
    }
  }

  // Check payment status (overdue or not)
  static Future<Map<String, dynamic>> checkPaymentStatus(
    String schoolId,
  ) async {
    try {
      final response = await HybridApiService.get(
        '/school/$schoolId/payment-status',
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to check payment status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error checking payment status: $e');
    }
  }

  // Get school with payment history
  static Future<Map<String, dynamic>> getSchoolWithPayments(
    String schoolId,
  ) async {
    try {
      final response = await HybridApiService.get(
        '/school/$schoolId/with-payments',
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Failed to get school with payments: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching school with payments: $e');
    }
  }

  static Future<Map<String, dynamic>> getDueAmount({
    required String schoolId,
  }) async {
    try {
      final response = await HybridApiService.get(
        '/app_payment/due-amount/$schoolId',
        forceCloud: true,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get due amount');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Calculate payment amount
  static Future<Map<String, dynamic>> calculatePayment({
    required int studentsCount,
    required String paymentPlan, // 'MONTHLY' or 'YEARLY'
  }) async {
    try {
      final response = await HybridApiService.post(
        '/app_payment/calculate',
        body: json.encode({
          'studentsCount': studentsCount,
          'paymentPlan': paymentPlan,
        }),
        forceCloud: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to calculate payment');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Create payment record
  static Future<Map<String, dynamic>> createPayment({
    required int schoolId,
    required int studentsCount,
    required String paymentPlan,
    String? transactionId,
  }) async {
    try {
      final response = await HybridApiService.post(
        '/app_payment/create',
        body: json.encode({
          'schoolId': schoolId,
          'studentsCount': studentsCount,
          'paymentPlan': paymentPlan,
          'transactionId': transactionId,
        }),
        forceCloud: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to create payment');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Update payment status after payment gateway response
  static Future<Map<String, dynamic>> updatePaymentStatus({
    required int paymentId,
    required String status,
    String? transactionId,
  }) async {
    try {
      final response = await HybridApiService.put(
        '/app_payment/update-status/$paymentId',
        body: json.encode({'status': status, 'transactionId': transactionId}),
        forceCloud: true,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update payment status');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get payment history
  static Future<List<dynamic>> getPaymentHistory(String schoolId) async {
    try {
      final response = await HybridApiService.get(
        '/app_payment/history/$schoolId',
        forceCloud: true,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get payment history');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Get payment report
  static Future<Map<String, dynamic>> getPaymentReport(String schoolId) async {
    try {
      final response = await HybridApiService.get(
        '/app_payment/report/$schoolId',
        forceCloud: true,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get payment report');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchCombinedData(String schoolId) async {
    try {
      final response = await HybridApiService.get('/school/combined/$schoolId');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load combined school data');
      }
    } catch (e) {
      throw Exception('Error fetching combined school data: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchAbsenteesSchool(
    String date,
    String schoolId,
  ) async {
    final response = await HybridApiService.get(
      '/attendance/student/fetch_stu_absentees_school?date=$date&school_id=$schoolId',
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return {
          'fn_absentees': data['fn_absentees'],
          'an_absentees': data['an_absentees'],
        };
      } else {
        throw Exception('Backend returned error status');
      }
    } else {
      throw Exception('Failed to load absentees');
    }
  }

  static Future<Map<String, dynamic>> fetchAdminAndSchoolData({
    required String username,
    required String schoolId,
  }) async {
    final response = await HybridApiService.get(
      '/admin/fetch_admin_and_school_data?username=$username&school_id=$schoolId',
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return jsonData;
    } else {
      throw Exception('Failed to fetch data: HTTP ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> storeTickets({
    required String username,
    required String name,
    required String email,
    required String tickets,
    required int schoolId,
  }) async {
    final body = {
      "username": username,
      "name": name,
      "email": email,
      "tickets": tickets,
      "schoolId": schoolId,
    };

    try {
      final response = await HybridApiService.post(
        "/Tickets/post",
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      throw Exception("Failed to connect to API: $e");
    }
  }

  static Future<Map<String, dynamic>> sendOtp({
    required String email,
    required String otp,
  }) async {
    final response = await HybridApiService.post(
      '/auth/send_otp',
      body: jsonEncode({'email': email, 'otp': otp}),
      forceCloud: true,
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
    required int schoolId,
  }) async {
    final response = await HybridApiService.post(
      '/auth/update_password',
      body: jsonEncode({
        'username': username,
        'newPassword': password,
        'school_id': schoolId,
      }),
      forceCloud: true,
    );
    final data = jsonDecode(response.body);

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
    final response = await HybridApiService.post(
      '/attendance-users/delete',
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

  static Future<Map<String, dynamic>> getSchoolAndClassByUsername({
    required String username,
    required int schoolId,
  }) async {
    try {
      final response = await HybridApiService.get(
        '/students/school-class?username=$username&school_id=$schoolId',
      );

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

  static Future<List<dynamic>> getUsersByRole({
    required String role,
    required int schoolId,
    bool forceCloud = false,
  }) async {
    try {
      final response = await HybridApiService.get(
        '/attendance-users?role=$role&school_id=$schoolId',
        headers: getApiHeaders(),
        forceCloud: forceCloud,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  static Future<List<dynamic>> getUsersByRoleAll({required String role}) async {
    try {
      final response = await HybridApiService.get(
        '/attendance-users/attendance-users-all?role=$role',
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSchools() async {
    try {
      final response = await HybridApiService.get('/school/fetch_all_schools');

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
    try {
      final response = await HybridApiService.get(
        '/class/fetch_class_id?school_id=$schoolId&class=$className&section=$section',
      );

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
    final response = await HybridApiService.get(
      '/students/fetch_student_name?school_id=$schoolId&class_id=$classId&username=$username',
    );

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
    final response = await HybridApiService.get(
      '/attendance/fetch_stu_absent_all?date=$date&school_id=$schoolId&class_id=$classId',
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
    final response = await HybridApiService.get(
      '/attendance/student/fetch_stu_attendance?date=$date&school_id=$schoolId',
    );

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
    final response = await HybridApiService.get(
      '/attendance/student/fetch_stu_attendance?date=$date&school_id=$schoolId',
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
    return {}; // If error, fallback to empty map
  }

  static Future<bool?> checkAttendanceStatus(
    String schoolId,
    String classId,
    String date,
  ) async {
    try {
      final response = await HybridApiService.get(
        '/attendance/check_attendance_status?school_id=$schoolId&class_id=$classId&date=$date',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data['attendance_exists'] as bool? ?? false;
        }
      }
    } catch (e) {
      return null;
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
      final response = await HybridApiService.get(
        '/attendance/check_attendance_status_session?school_id=$schoolId&class_id=$classId&date=$date&session=$session',
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'success') {
          return data['attendance_exists'] as bool? ?? false;
        } else {}
      } else {}
    } catch (e) {
      return null;
    }

    return null;
  }

  // Fetch Student Attendance
  static Future<List<Map<String, dynamic>>> fetchStudentAttendance({
    required String date,
    required String schoolId,
    required String classId,
  }) async {
    try {
      final response = await HybridApiService.get(
        '/attendance/student/class?date=$date&school_id=$schoolId&class_id=$classId',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['attendance'] is List) {
          return List<Map<String, dynamic>>.from(data['attendance']);
        }
      }
    } catch (e) {
      return [];
    }

    return [];
  }

  //Fetch School id

  static Future<String?> fetchSchoolId(String username) async {
    try {
      final response = await HybridApiService.get(
        '/fetch_school_id?username=$username',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['status'] == 'success') {
          final data = jsonData['data'];
          if (data != null && data.isNotEmpty) {
            return data[0]['school_id']?.toString();
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
    if (response.statusCode == 200 || response.statusCode == 201) {
      final jsonData = json.decode(response.body);

      if (jsonData['status'] == 'success') {
        final List<Map<String, dynamic>> schoolList = [];

        for (var school in jsonData['schools']) {
          schoolList.add({
            'id': school['id'],
            'name': school['name'],
            'address': school['address'],
            'photo': school['photo'],
            'createdAt': school['createdAt'],
            'dueDate': school['dueDate'],
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
    final response = await HybridApiService.get(
      '/attendance/staff/fetch_staff_attendance?date=$date&school_id=$schoolId',
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
      final response = await HybridApiService.get(
        '/attendance/staff/fetch_staff_attendance_by_username?username=$username&school_id=$schoolId',
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success' && jsonData['staff'] != null) {
          return List<Map<String, dynamic>>.from(jsonData['staff']);
        }
      }
    } catch (e) {
      return [];
    }

    return [];
  }

  //Post Attendance
  static Future<bool> postAttendance({
    required String username,
    required String date,
    required String session,
    required String status,
    required String schoolId,
  }) async {
    try {
      final response = await HybridApiService.post(
        '/attendance/staff',
        body: jsonEncode({
          'username': username,
          'date': date,
          'session': session,
          'status': status,
          'school_id': schoolId,
        }),
      );

      final res = jsonDecode(response.body);

      if (response.statusCode == 200 || res['status'] == 'success') {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  //Add Class
  static Future<String> addClass(
    String className,
    String section,
    String schoolId,
  ) async {
    try {
      final response = await HybridApiService.post(
        '/class/add',
        body: jsonEncode({
          'class': className,
          'section': section,
          'school_id': schoolId,
        }),
      ).timeout(const Duration(seconds: 10));

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
    try {
      final response = await HybridApiService.post(
        '/class/delete',
        body: jsonEncode({
          'class': className,
          'section': section,
          'school_id': schoolId,
        }),
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

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
    final response = await HybridApiService.post(
      '/holidays/delete_holiday',
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
    final response = await HybridApiService.post(
      '/holidays/add_holiday',
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
    final response = await HybridApiService.get(
      '/holidays/fetch?school_id=$schoolId',
    );

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
    required String fatherName,
    required String community,
    required String route,
    required String dob,
  }) async {
    try {
      final response = await HybridApiService.post(
        '/auth/register_student',
        body: jsonEncode({
          'username': username.trim(),
          'name': name.trim(),
          'gender': gender.trim(),
          'email': email.trim(),
          'mobile': mobile.trim(),
          'class_id': classId.trim(),
          'school_id': schoolId.trim(),
          'fatherName': fatherName.trim(),
          'community': community.trim(),
          'route': route.trim(),
          'dob': dob.trim(),
        }),
      );

      final data = jsonDecode(response.body);

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
    required String schoolId,
  }) async {
    int sId = int.parse(schoolId);
    final response = await HybridApiService.post(
      '/auth/register',
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
    required String schoolId,
    required String mobile,
    required String table,
    String? faculty,
  }) async {
    try {
      final response = await HybridApiService.post(
        '/auth/register-designation',
        body: jsonEncode({
          'username': username.trim(),
          'designation': designation.trim(),
          'school_id': schoolId.trim(),
          'table': table.trim(),
          'mobile': mobile.trim(),
          'faculty': faculty?.toLowerCase(),
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
    final response = await HybridApiService.post(
      '/count',
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
    try {
      final response = await HybridApiService.get(
        '/staff/count?school_id=$schoolId',
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
    final response = await HybridApiService.post(
      '/fetch_usernames',
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
    final response = await HybridApiService.post(
      '/email_login',
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
    final response = await HybridApiService.post(
      '/email_login',
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
    final response = await HybridApiService.post(
      '/email_login',
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
    final response = await HybridApiService.post(
      '/send_otp',
      body: jsonEncode({'email': email, 'otp': otp}),
      forceCloud: true,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] == 'success';
    } else {
      return false;
    }
  }

  // Sync trigger methods
  static Future<Map<String, dynamic>> triggerInitialSync({
    required int schoolId,
    required String userId,
  }) async {
    try {
      final response = await HybridApiService.post(
        '/offline/trigger-initial-sync',
        body: jsonEncode({'schoolId': schoolId, 'userId': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to trigger initial sync: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Sync trigger error: $e');
    }
  }

  static Future<Map<String, dynamic>> triggerUserLogout({
    required int schoolId,
    required String userId,
  }) async {
    try {
      final response = await HybridApiService.post(
        '/offline/user-logout',
        body: jsonEncode({'schoolId': schoolId, 'userId': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to trigger user logout: Status ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Logout sync error: $e');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required int schoolId,
  }) async {
    try {
      // 1. Try High-Speed Centralized Login First
      final response = await HybridApiService.post(
        '/auth/login',
        body: jsonEncode({
          'username': username,
          'password': password,
          'school_id': schoolId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      }

      // 2. Legacy Fallback: If server hasn't been updated yet or any error occurs
      print(
        "FALLBACK START: Status ${response.statusCode}. Trying legacy role-check via hybrid routing (LOCAL first, CLOUD fallback)...",
      );

      List<String> roles = ['student', 'staff', 'admin', 'administrator'];
      bool userFoundInLegacy = false;

      for (String role in roles) {
        try {
          print("  -> Checking role: $role...");
          final users = await getUsersByRole(
            role: role,
            schoolId: schoolId,
            forceCloud:
                false, // Use hybrid routing (local first, cloud fallback)
          );
          List<dynamic> effectiveUsers = users;
          if (effectiveUsers.isEmpty) {
            // Some legacy/local datasets may miss school_id mapping.
            // Fallback to all-users-by-role endpoint, then filter by username.
            try {
              final usersAll = await getUsersByRoleAll(role: role);
              effectiveUsers = usersAll;
            } catch (_) {}
          }
          print("  <- Role $role: ${effectiveUsers.length} users returned.");

          final user = effectiveUsers.cast<Map<String, dynamic>?>().firstWhere((u) {
            final uname = u?['username']?.toString();
            return uname == username;
          }, orElse: () => null);

          if (user != null) {
            userFoundInLegacy = true;
            final hashedPassword = user['password']?.toString();
            print(
              "     MATCH: Found $username in $role. Verifying password...",
            );

            if (hashedPassword != null &&
                BCrypt.checkpw(password, hashedPassword)) {
              print("     SUCCESS: Legacy password verified!");

              // CRITICAL: Add the role to the user object since legacy server doesn't return it
              final userWithRole = Map<String, dynamic>.from(user);
              userWithRole['role'] = role;

              return {
                'status': 'success',
                'message': 'Legacy login successful',
                'user': userWithRole,
              };
            } else {
              print("     FAILURE: Legacy password mismatch.");
            }
          }
        } catch (roleError) {
          print("     ERROR in $role check: $roleError");
        }
      }

      if (!userFoundInLegacy) {
        print("FALLBACK COMPLETE: No matching user found in any role.");
      }

      throw Exception('Invalid user Id or password');
    } catch (e) {
      if (e.toString().contains('Invalid user Id or password')) rethrow;
      print("FATAL LOGIN ERROR: $e");
      throw Exception('Login connection error: $e');
    }
  }
}
