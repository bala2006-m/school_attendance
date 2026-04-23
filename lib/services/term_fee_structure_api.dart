import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:school_attendance/utils/utils.dart';
import 'package:school_attendance/services/hybrid_api_service.dart';

class TermFeeStructureApi {
  static Future<Map<String, dynamic>> countAllPendingTermFees(
    int schoolId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/student-fees/pending_paid_school/$schoolId',
    );

    final response = await HybridApiService.get(
      url.path + '?' + url.query,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load pending fees');
    }
  }

  static Future<Map<String, dynamic>> getAllPendingFees(int schoolId) async {
    final url = Uri.parse('$baseUrl/student-fees/pending?school_id=$schoolId');

    final response = await HybridApiService.get(
      url.path + '?' + url.query,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load pending fees');
    }
  }

  static Future<Map<String, dynamic>> getAllPendingFeesClass({
    required int schoolId,
    required int classId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/student-fees/pending_class?school_id=$schoolId&class_id=$classId',
    );

    final response = await HybridApiService.get(
      url.path + '?' + url.query,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load pending fees');
    }
  }

  static Future<List<dynamic>> getPeriodicalPaidFees({
    required int schoolId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/student-fees/periodical_paid/'
        '${startDate.toIso8601String().split('T').first}/'
        '${endDate.toIso8601String().split('T').first}'
        '?schoolId=$schoolId',
      );

      final response = await HybridApiService.get(url.path + '?' + url.query);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map && decoded['data'] != null) {
          return decoded['data'];
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to fetch fees: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getPeriodicalPaidFeesClass({
    required int schoolId,
    required int classId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final url = Uri.parse(
        '$baseUrl/student-fees/periodical_paid_class/'
        '${startDate.toIso8601String().split('T').first}/'
        '${endDate.toIso8601String().split('T').first}'
        '?schoolId=$schoolId&classId=$classId',
      );

      final response = await HybridApiService.get(url.path + '?' + url.query);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded;
        } else if (decoded is Map && decoded['data'] != null) {
          return decoded['data'];
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to fetch fees: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getDailyStudentPaidFee({
    required int schoolId,
    required DateTime date,
  }) async {
    final url = Uri.parse(
      '$baseUrl/student-fees/daily_paid/$date?schoolId=$schoolId',
    );
    final response = await HybridApiService.get(url.path + '?' + url.query);

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map) {
          return [data];
        } else {
          throw Exception("Unexpected response format");
        }
      } catch (e) {
        throw Exception("Invalid JSON: $e");
      }
    } else {
      throw Exception(
        "Failed to load student fee: ${response.statusCode} - ${response.body}",
      );
    }
  }

  static Future<List<dynamic>> getDailyStudentPaidFeeClass({
    required int schoolId,
    required int classId,
    required DateTime date,
  }) async {
    final url = Uri.parse(
      '$baseUrl/student-fees/daily_paid_class/$date?schoolId=$schoolId&classId=$classId',
    );
    final response = await HybridApiService.get(url.path + '?' + url.query);

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map) {
          return [data];
        } else {
          throw Exception("Unexpected response format");
        }
      } catch (e) {
        throw Exception("Invalid JSON: $e");
      }
    } else {
      throw Exception(
        "Failed to load student fee: ${response.statusCode} - ${response.body}",
      );
    }
  }

  static Future<List<dynamic>> getStudentPAidFeeByClass({
    required int schoolId,
    required int classId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/student-fees/paid_class/$classId?schoolId=$schoolId',
    );
    // print(url);
    final response = await HybridApiService.get(url.path + '?' + url.query);
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map) {
          return [data];
        } else {
          throw Exception("Unexpected response format");
        }
      } catch (e) {
        throw Exception("Invalid JSON: $e");
      }
    } else {
      throw Exception(
        "Failed to load student fee: ${response.statusCode} - ${response.body}",
      );
    }
  }

  static Future<List<dynamic>> getStudentFeeByUsername({
    required String username,
    required int schoolId,
    required int classId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/student-fees/student?username=$username&schoolId=$schoolId&classId=$classId',
    );

    final response = await HybridApiService.get(url.path + '?' + url.query);
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        } else if (data is Map) {
          return [data];
        } else {
          throw Exception("Unexpected response format");
        }
      } catch (e) {
        throw Exception("Invalid JSON: $e");
      }
    } else {
      throw Exception(
        "Failed to load student fee: ${response.statusCode} - ${response.body}",
      );
    }
  }

  static Future<List<Map<String, dynamic>>> fetchFeePayments() async {
    final response = await HybridApiService.get('/fee-payments');
    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(jsonList);
    } else {
      throw Exception('Failed to load fee payments');
    }
  }

  static Future<Map<String, dynamic>> createFeePayment(
    Map<String, dynamic> data,
  ) async {
    final response = await HybridApiService.post(
      '/fee-payments',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create fee payment');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchStudentFees() async {
    final response = await HybridApiService.get('/student-fees');
    if (response.statusCode == 200) {
      List jsonList = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(jsonList);
    } else {
      throw Exception('Failed to load student fees');
    }
  }

  // Fetch one student fee by id
  static Future<Map<String, dynamic>> fetchStudentFee(int id) async {
    final response = await HybridApiService.get('/student-fees/$id');
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch student fee');
    }
  }

  // Create student fee
  static Future<Map<String, dynamic>> createStudentFee(
    Map<String, dynamic> data,
  ) async {
    final response = await HybridApiService.post(
      '/student-fees-payments',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create student fee');
    }
  }

  // Update student fee
  static Future<Map<String, dynamic>> updateStudentFee(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await HybridApiService.put(
      '/student-fees/$id',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update student fee');
    }
  }
}
