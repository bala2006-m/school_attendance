import 'dart:convert';

import 'package:school_attendance/services/hybrid_api_service.dart';
import '../utils/utils.dart';

class RteApiServices {
  static Future<Map<String, dynamic>> fetchRteStudentsSchool({
    required int schoolId,
  }) async {
    try {
      final url = Uri.parse(
        "$baseUrl/students/fetch_rte_student_school?school_id=$schoolId",
      );
      final response = await HybridApiService.get(
        "/students/fetch_rte_student_school?school_id=$schoolId",
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data ?? {};
        } else {
          return {};
        }
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }

  static Future<Map<String, dynamic>> fetchBusStudentsSchool({
    required int schoolId,
  }) async {
    try {
      final url = Uri.parse(
        "$baseUrl/students/fetch_bus_student_school?school_id=$schoolId",
      );
      final response = await HybridApiService.get(
        "/students/fetch_bus_student_school?school_id=$schoolId",
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data ?? {};
        } else {
          return {};
        }
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }
}
