import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:school_attendance/utils/utils.dart';

class AdminApiService {
  static Future<bool> updateFeeStructure({
    required int feeId,
    List<double>? amounts,
    double? totalAmount,
    required String updatedBy,
    String? startDate,
    String? endDate,
    List<String>? descriptions, // optional for detailed descriptions list
    String? title, // optional main title
  }) async {
    final url = Uri.parse('$baseUrl/fees/structure/$feeId');

    final Map<String, dynamic> bodyMap = {
      if (descriptions != null) 'description': descriptions,
      if (amounts != null) 'amounts': amounts,
      if (totalAmount != null) 'total_amount': totalAmount,
      'updated_by': updatedBy,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (title != null) 'title': title,
    };

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bodyMap),
    );

    return response.statusCode == 200;
  }

  // Add a new fee structure
  static Future<bool> addFeeStructure({
    required int schoolId,
    required int classId,
    required List<double> amounts,
    required double totalAmount,
    required String createdBy,
    required String title,
    String? startDate,
    String? endDate,
    required List<String> descriptions,
  }) async {
    final url = Uri.parse('$baseUrl/fees/structure');

    final Map<String, dynamic> bodyMap = {
      'school_id': schoolId,
      'class_id': classId,
      'title': title,
      'descriptions': descriptions,
      'amounts': amounts,
      'total_amount': totalAmount,
      'created_by': createdBy,
      'updated_by': createdBy,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bodyMap),
    );

    return response.statusCode == 201 || response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getFeeStructuresByClass({
    required int schoolId,
    required int classId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/fees/structure/all_class/$classId?schoolId=$schoolId',
    );

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to fetch fee structures');
    }
  }

  static Future<List<dynamic>> getFirstFeeStructuresByClassName({
    required int schoolId,
    required String className,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/fees/structure/class_name/$className?schoolId=$schoolId',
      );
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch fee structures');
      }
    } catch (e) {
      return [];
    }
  }

  // Get all fee structures for a school
  static Future<List<Map<String, dynamic>>> getFeeStructures(
    int schoolId,
  ) async {
    final url = Uri.parse('$baseUrl/fees/structure?schoolId=$schoolId');

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch fee structures');
    }
  }

  // Update fee structure

  // Update fee status (active/inactive)
  static Future<bool> updateFeeStatus({
    required int feeId,
    required String status,
  }) async {
    final validStatuses = ['active', 'inactive'];
    if (!validStatuses.contains(status)) {
      throw Exception('Status must be active or inactive');
    }

    final url = Uri.parse('$baseUrl/fees/structure/$feeId/status');
    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );

    return response.statusCode == 200;
  }

  // Delete a fee structure
  static Future<bool> deleteFeeStructure(int feeId) async {
    final url = Uri.parse('$baseUrl/fees/structure/$feeId');

    final response = await http.delete(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getStudentFees({
    required String username,
    required int schoolId,
    required int classId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/student-fees/student?username=$username&schoolId=$schoolId&classId=$classId',
    );

    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load student fees');
    }
  }

  // Get class-wise fees (for admin/staff)
  static Future<List<Map<String, dynamic>>> getFeesByClass(
    int classId,
    int schoolId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/student-fees/class/$classId?schoolId=$schoolId',
    );
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load class fees');
    }
  }

  // Assign student fee (Admin)
  static Future<bool> assignStudentFee({
    required int schoolId,
    required int classId,
    required String username,
    required String createdBy,
  }) async {
    final url = Uri.parse('$baseUrl/student-fees/assign');
    final body = json.encode({
      'schoolId': schoolId,
      'classId': classId,
      'username': username,
      'createdBy': createdBy,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // Record payment
  static Future<bool> recordPayment({
    required int studentFeeId,
    required double amount,
    required String method,
    String? transactionId,
  }) async {
    final url = Uri.parse('$baseUrl/student-fees/pay');
    final body = json.encode({
      'studentFeeId': studentFeeId,
      'amount': amount,
      'method': method,
      'transactionId': transactionId,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  static Future<List<dynamic>> getConsecutiveAbsents({
    required int schoolId,
    required int classId,
    required int limit,
  }) async {
    final url = Uri.parse(
      '$baseUrl/students/attendance/consecutive-absents?school_id=$schoolId&class_id=$classId&limit=$limit',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception(
        'Failed to load consecutive absents: ${response.statusCode}',
      );
    }
  }

  static Future<bool> updateExamMarkStatusById({
    required int id,
    required String status,
  }) async {
    final url = Uri.parse(
      '$baseUrl/exam-marks/update_status_by_id/$id/$status',
    );

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Success
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> updateExamMarkStatus({
    required String schoolId,
    required String classId,
    required String status,
  }) async {
    final url = Uri.parse(
      '$baseUrl/exam-marks/update_status_by_school_id_class_id/$schoolId/$classId/$status',
    );

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Success
      return true;
    } else {
      return false;
    }
  }

  static Future<bool> updateExamMarksByUsername({
    required int schoolId,
    required int classId,
    required String username,
    required String title,
    required Map<String, dynamic> updateData,
  }) async {
    final url = Uri.parse(
      '$baseUrl/exam-marks/$schoolId/$classId/$username/$title',
    );

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );

    if (response.statusCode == 200) {
      // Successfully updated
      return true;
    } else {
      // Handle error - you can parse response.body for error details
      return false;
    }
  }

  static Future<bool> updateExamMark(
    int id,
    Map<String, dynamic> updatedData,
  ) async {
    final url = Uri.parse('$baseUrl/exam-marks/update_by_id/$id');

    final response = await http.patch(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updatedData),
    );

    if (response.statusCode == 200) {
      // Success
      return true;
    } else {
      return false;
    }
  }

  // Delete exam mark by ID (DELETE)
  static Future<bool> deleteExamMark(int id) async {
    final url = Uri.parse('$baseUrl/exam-marks/delete_by_id/$id');

    final response = await http.delete(url);

    if (response.statusCode == 204) {
      // Successfully deleted - 204 No Content
      return true;
    } else {
      return false;
    }
  }

  static Future<List<dynamic>> fetchExamMarkStudent({
    required String schoolId,
    required String classId,
    required String username,
  }) async {
    final uri =
        '$baseUrl/exam-marks/fetch?school_id=$schoolId&class_id=$classId&username=$username';
    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load exam marks');
    }
  }

  static Future<List<dynamic>> fetchExamMarkClass({
    required String schoolId,
    required String classId,
  }) async {
    final uri =
        '$baseUrl/exam-marks/fetch?school_id=$schoolId&class_id=$classId';

    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  static Future<List<dynamic>> fetchExamMarkSchool({
    required String schoolId,
  }) async {
    final uri = '$baseUrl/exam-marks/fetch?school_id=$schoolId';

    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load exam marks');
    }
  }

  static Future<List<dynamic>> fetchExamMarkClassTitle({
    required String schoolId,
    required String classId,
    required String title,
  }) async {
    final uri =
        '$baseUrl/exam-marks/fetch?school_id=$schoolId&class_id=$classId&title=$title';
    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load exam marks');
    }
  }

  static Future<List<dynamic>> fetchExamMarkSchoolTitle({
    required String schoolId,
    required String title,
  }) async {
    final uri = '$baseUrl/exam-marks/fetch?school_id=$schoolId&title=$title';

    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load exam marks');
    }
  }

  static Future<List<dynamic>> fetchExamMarkClassTitles({
    required String schoolId,
    required String classId,
  }) async {
    final uri =
        '$baseUrl/exam-marks/fetch_titles?school_id=$schoolId&class_id=$classId';

    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  static Future<List<dynamic>> fetchExamMarkSchoolTitles({
    required String schoolId,
  }) async {
    final uri = '$baseUrl/exam-marks/fetch_titles?school_id=$schoolId';

    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load exam marks');
    }
  }

  static Future<String> createExamMark({
    required String schoolId,
    required String classId,
    required String username,
    required String title,
    required List<int> minMaxMarks,
    required List<String> marks,
    required List<String> subjects,
    required List<int> subjectRank,
    required String rank,
    required String createdBy,
    required String updatedBy,
    required List<String> date,
    required List<String> session,
  }) async {
    final url = Uri.parse('$baseUrl/exam-marks/create');
    final headers = {'Content-Type': 'application/json'};

    final data = {
      'school_id': int.parse(schoolId),
      'class_id': int.parse(classId),
      'username': username,
      'title': title.toUpperCase(),
      'min_max_marks': minMaxMarks,
      'marks': marks,
      'subjects': subjects,
      'subject_rank': subjectRank,
      'rank': rank.toUpperCase(),
      'created_by': createdBy,
      'updated_by': updatedBy,
      'date': date,
      'session': session,
    };

    final body = json.encode(data);

    final response = await http.post(url, headers: headers, body: body);

    if (response.body ==
        '{"clientVersion":"6.12.0","name":"PrismaClientUnknownRequestError"}') {
      return 'Failure';
    }
    if (response.body ==
        '{"name":"PrismaClientValidationError","clientVersion":"6.12.0"}') {
      return 'Failure';
    }
    if (response.statusCode == 201 || response.statusCode == 200) {
      // Successfully created
      if (response.body.isNotEmpty) {
        if (response.body ==
            'An exam mark with this title already exists for this student in this school and class.') {
          return response.body;
        } else {
          return 'Success';
        }
      }
      return 'Failure';
    } else {
      return 'Failure';
    }
  }

  static Future<List<dynamic>> fetchPeriodicalReportAll({
    required String schoolId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');

    final String fromDateFormatted = formatter.format(fromDate);
    final String toDateFormatted = formatter.format(toDate);

    final uri =
        '$baseUrl/students/periodical-report-all?schoolId=$schoolId&fromDate=$fromDateFormatted&toDate=$toDateFormatted';
    final response = await http.get(Uri.parse(uri));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        return data['students'];
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load student reports');
    }
  }

  static Future<bool> deleteTimetableEntry(String id) async {
    final url = Uri.parse('$baseUrl/timetable/delete/$id');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> uploadStudentExcelFile(
    File file,
    String schoolId,
  ) async {
    try {
      final uri = Uri.parse(
        "$baseUrl/auth/excel-upload/students/$schoolId/non",
      );
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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadStaffExcelFile(
    File file,
    String schoolId,
    String faculty,
  ) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/auth/excel-upload/staff/$schoolId/$faculty',
      );
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
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> uploadAdminExcelFile(
    File file,
    String schoolId,
  ) async {
    try {
      final uri = Uri.parse("$baseUrl/auth/excel-upload/admin/$schoolId/non");
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

      // ✅ Read stream only once
      final responseBody = await response.stream.bytesToString();
      final decoded = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return decoded;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> fetchStudentAttendanceBetweenDays({
    required String username,
    required DateTime fromDate,
    required DateTime toDate,
    required int schoolId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/attendance/student/betweensummary'
      '?username=$username'
      '&fromDate=${fromDate.toIso8601String().split("T").first}'
      '&toDate=${toDate.toIso8601String().split("T").first}'
      '&school_id=$schoolId',
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
      return null;
    }
    return null;
  }

  static Future<Map<String, dynamic>> fetchStudentMonthlyAttendance({
    required String username,
    required String month,
    required String year,
    required int schoolId,
  }) async {
    int mon = int.parse(month);
    int yr = int.parse(year);

    final url = Uri.parse(
      '$baseUrl/attendance/student/monthly?username=$username&month=$mon&year=$yr&school_id=$schoolId',
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

  static Future<String> fetchStaffUsername({
    required String mobile,
    required int schoolId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/staff/fetch-by-mobile?mobile=$mobile&school_id=$schoolId',
    );

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
        return '';
      }
    } catch (e) {
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
    required String email,
    required String gender,
    required int schoolId,
    File? imageFile,
  }) async {
    try {
      String? photoBase64;
      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        photoBase64 = base64Encode(bytes);
      }
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/$username/$schoolId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'designation': designation,
          'mobile': mobile,
          if (photoBase64 != null) 'photoBase64': photoBase64,
          'email': email,
          'gender': gender,
        }),
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllStudentDataWithClass(
    String schoolId,
  ) async {
    int id = int.parse(schoolId);

    final uri = Uri.parse(
      '$baseUrl/students/fetch_all_student_data_with_class?school_id=$id',
    );

    final client = http.Client();

    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          // Return list of students with class data included
          return List<Map<String, dynamic>>.from(data['students']);
        } else {
          throw Exception('Server Error: ${data['message']}');
        }
      } else {
        throw Exception('Failed to load students. HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception("❌ Failed to load students. Reason: $e");
    } finally {
      client.close();
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
      final uri = Uri.parse('$baseUrl/staff/all-by-school_id?school_id=$id');

      final response = await http.get(uri);
      if (response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data.containsKey('staff')) {
          return List<Map<String, dynamic>>.from(data['staff']);
        }
      }
    } catch (e) {
      return [];
    }

    return [];
  }

  //FETCH ADMIN DATA
  static Future<Map<String, dynamic>?> fetchAdminData({
    required String username,
    required String schoolId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/admin/fetch_admin?username=$username&school_id=$schoolId',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);

        if (decoded['status'] == 'success' && decoded['data'].isNotEmpty) {
          return decoded['data']; // Assuming you fetch a single admin
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchAllAdmin({
    required String schoolId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/fetch_all_admin?school_id=$schoolId'),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(response.body);

        if (decoded['data'] != null && decoded['data'].isNotEmpty) {
          return List<Map<String, dynamic>>.from(decoded['data']);
        }
      }
    } catch (e) {
      return [];
    }
    return [];
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
