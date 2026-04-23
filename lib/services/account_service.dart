import 'dart:convert';

import 'package:school_attendance/services/hybrid_api_service.dart';

import '../utils/utils.dart';

class AccountService {
  static Future<Map<String, dynamic>> fetchAll({required int schoolId}) async {
    try {
      final response = await HybridApiService.get(
        "/accounts/fetch_all/$schoolId",
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'] ?? {};
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

  static Future<Map<String, dynamic>> fetchAllPeriodical({
    required int schoolId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final response = await HybridApiService.get(
        "/accounts/fetch_all_periodical/$schoolId/$from/$to",
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          return data['data'] ?? {};
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
