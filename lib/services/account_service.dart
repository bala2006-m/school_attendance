import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/utils.dart';

class AccountService {
  static Future<Map<String, dynamic>> fetchAll({required int schoolId}) async {
    try {
      final url = Uri.parse("$baseUrl/accounts/fetch_all/$schoolId");
      final response = await http.get(
        url,
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
      final url = Uri.parse(
        "$baseUrl/accounts/fetch_all_periodical/$schoolId/$from/$to",
      );

      final response = await http.get(
        url,
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
