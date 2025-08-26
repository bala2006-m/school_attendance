import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class AdministratorApiService {
  static const String baseUrl = "http://51.20.189.225";
  //static const String tempUrl = "https://ghj5w9n1-3000.inc1.devtunnels.ms";

  static Future<List<Map<String, dynamic>>> fetchTicket(String schoolId) async {
    int id = int.parse(schoolId);
    final url = Uri.parse('$baseUrl/Tickets/list?school_id=$id');

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

  static Future<Map<String, dynamic>> isSchoolBlocked(int schoolId) async {
    final url = Uri.parse("$baseUrl/blocked-schools/is-blocked/$schoolId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Failed with status: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error checking school blocked: $e");
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAllBlockedSchools() async {
    try {
      final response = await http.get(Uri.parse("$baseUrl/blocked-schools"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          // Ensure each element is Map<String, dynamic>
          return data
              .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
              .toList();
        } else {
          throw Exception("Unexpected response format: not a List");
        }
      } else {
        throw Exception(
          "Failed to fetch blocked schools. Status code: ${response.statusCode}",
        );
      }
    } catch (e) {
      throw Exception("Error fetching blocked schools: $e");
    }
  }

  static Future<Map<String, dynamic>> editPassword({
    required String username,
    required String role,
    required int schoolId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse("$baseUrl/user/edit-password");

    final response = await http.patch(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "role": role,
        "school_id": schoolId,
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed: ${response.statusCode} -> ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> createBlockedSchool(
    int schoolId,
    String reason,
  ) async {
    final url = Uri.parse("$baseUrl/blocked-schools");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"school_id": schoolId, "reason": reason}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to block school: ${response.body}");
    }
  }

  // ✅ Delete Blocked School
  static Future<void> deleteBlockedSchool(int id) async {
    final url = Uri.parse("$baseUrl/blocked-schools/$id");

    final response = await http.delete(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to delete blocked school: ${response.body}");
    }
  }

  // ✅ Get All Blocked Schools
  static Future<List<dynamic>> getBlockedSchools() async {
    final url = Uri.parse("$baseUrl/blocked-schools");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List;
    } else {
      throw Exception("Failed to fetch blocked schools: ${response.body}");
    }
  }

  static Future<String?> createSchool(
    String name,
    String address,
    File? photo,
  ) async {
    var responseBody = '';
    try {
      var uri = Uri.parse("$baseUrl/school/create");
      var request = http.MultipartRequest("POST", uri);

      request.fields['name'] = name;
      request.fields['address'] = address;

      if (photo != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', photo.path),
        );
      }

      var response = await request.send();
      responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201 || response.statusCode == 200) {
        return responseBody; // ✅ return full response body
      } else {
        throw Exception("❌ Failed with ${response.statusCode}: $responseBody");
      }
    } catch (e) {
      print("❌ Error: $e");
      return responseBody;
    }
  }

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
