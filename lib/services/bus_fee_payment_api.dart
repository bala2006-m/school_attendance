import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class BusFeePaymentApi {
  static String base = "$baseUrl/bus-fee-payment";

  static Future<Map<String, dynamic>?> getPaidPendingBySchoolId(
    int schoolId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$base/pending_paid_school/$schoolId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// 🔹 Create a new payment
  Future<Map<String, dynamic>?> createPayment(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(base),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {}
    } catch (e) {
      return null;
    }
    return null;
  }

  /// 🔹 Get all bus fee payments
  // Future<List<dynamic>> getAllPayments() async {
  //   try {
  //     final response = await http.get(Uri.parse(base));
  //
  //     if (response.statusCode == 200) {
  //       return jsonDecode(response.body);
  //     }
  //   } catch (e) {
  //     return [];
  //   }
  //   return [];
  // }

  /// 🔹 Get a single payment by ID
  Future<Map<String, dynamic>?> getPaymentById(int id) async {
    try {
      final response = await http.get(Uri.parse("$base/$id"));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// 🔹 Update a payment record
  Future<Map<String, dynamic>?> updatePayment(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http.put(
        Uri.parse("$base/$id"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// 🔹 Delete a payment
  Future<bool> deletePayment(int id) async {
    try {
      final response = await http.delete(Uri.parse("$base/$id"));
      if (response.statusCode == 200) return true;
    } catch (e) {
      return false;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // 🔹 NEW METHODS: Filter by school, class, and student
  // ---------------------------------------------------------------------------

  /// 🏫 Get payments by school ID
  static Future<Map<String, dynamic>?> getBySchoolId(int schoolId) async {
    try {
      final response = await http.get(Uri.parse("$base/school/$schoolId"));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getBySchoolIdAndDate({
    required int schoolId,
    required String date,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$base/school_date/$schoolId/$date"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getBySchoolIdClassAndDate({
    required int schoolId,
    required int classId,
    required String date,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$base/school_class_date/$schoolId/$classId/$date"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// 🏫🎓 Get payments by school ID and class ID
  static Future<Map<String, dynamic>?> getBySchoolIdAndClassId(
    int schoolId,
    int classId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$base/school/$schoolId/class/$classId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// 🧒 Get payments by school ID, class ID, and student ID
  Future<Map<String, dynamic>?> getBySchoolClassAndStudent(
    int schoolId,
    int classId,
    String studentId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse("$base/school/$schoolId/class/$classId/student/$studentId"),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  /// 🧾 Get payments by student (Query params)
  Future<Map<String, dynamic>?> getByStudent(
    String studentId,
    int schoolId,
  ) async {
    try {
      final uri = Uri.parse("$base/student").replace(
        queryParameters: {
          'student_id': studentId,
          'school_id': schoolId.toString(),
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}
