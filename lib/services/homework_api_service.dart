import 'dart:convert';
import 'dart:io';


import 'package:http/http.dart' as http;
import 'package:school_attendance/services/hybrid_api_service.dart';
import 'package:http_parser/http_parser.dart';

class HomeworkApiService {

  // ────────────────────────────────────────────────
  // FETCH HOMEWORK BY CLASS
  // ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchByClass(
    int schoolId,
    int classId,
  ) async {
    final response = await HybridApiService.get("/homework/class/$schoolId/$classId");

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load homework');
    }
  }

  // ────────────────────────────────────────────────
  // FETCH HOMEWORK BY STAFF
  // ────────────────────────────────────────────────
  static Future<List<dynamic>> fetchByStaff({
    required int schoolId,
    required int classId,
    required String staff,
  }) async {
    final response = await HybridApiService.get(
      "/homework/staff/$schoolId/$classId/$staff",
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load homework');
    }
  }

  // ────────────────────────────────────────────────
  // CREATE HOMEWORK WITHOUT FILE
  // ────────────────────────────────────────────────
  Future<void> createHomework(Map<String, dynamic> data) async {
    await HybridApiService.post("/homework/create", body: jsonEncode(data));
  }

  // ────────────────────────────────────────────────
  // CREATE HOMEWORK WITH FILE (MULTIPART)
  // ────────────────────────────────────────────────
  static Future<void> createHomeworkWithFile(
    Map<String, dynamic> data,
    File file,
    String schoolId,
    String classId,
  ) async {
    final request = await HybridApiService.createMultipartRequest(
      'POST',
      "/homework/create_with_file/$schoolId/$classId",
    );

    // Add other fields from data
    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType('application', 'octet-stream'), // Generic stream
      ),
    );

    await request.send();
  }

  // ────────────────────────────────────────────────
  // DELETE HOMEWORK
  // ────────────────────────────────────────────────
  static Future<void> deleteHomework(int id) async {
    await HybridApiService.delete("/homework/delete/$id");
  }

  // ────────────────────────────────────────────────
  // DELETE IMAGE
  // ────────────────────────────────────────────────
  Future<void> deleteImage(
    String schoolId,
    String classId,
    String filename,
  ) async {
    await HybridApiService.delete("/homework/delete-image/$schoolId/$classId/$filename");
  }
}
