import 'dart:convert';

import 'package:http/http.dart' as http;

class AdministratorApiService {
  static const String baseUrl = "https://ghj5w9n1-3000.inc1.devtunnels.ms";

  /// Fetch all schools
  static Future<List<Map<String, dynamic>>> fetchAllSchools() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/school/fetch_all_schools"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          return List<Map<String, dynamic>>.from(data['schools']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch schools');
        }
      } else {
        throw Exception("Server error: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching schools: $e");
    }
  }
}
