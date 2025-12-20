import 'dart:io';

import 'package:dio/dio.dart';
import 'package:school_attendance/utils/utils.dart';

// import './model/homework_model.dart';

class HomeworkApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 12),
      receiveTimeout: Duration(seconds: 12),
    ),
  );

  // ────────────────────────────────────────────────
  // FETCH HOMEWORK BY CLASS
  // ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchByClass(
    int schoolId,
    int classId,
  ) async {
    final response = await _dio.get("/homework/class/$schoolId/$classId");

    return response.data;
  }

  // ────────────────────────────────────────────────
  // FETCH HOMEWORK BY STAFF
  // ────────────────────────────────────────────────
  static Future<List<dynamic>> fetchByStaff({
    required int schoolId,
    required int classId,
    required String staff,
  }) async {
    final response = await _dio.get(
      "/homework/staff/$schoolId/$classId/$staff",
    );

    return response.data;
  }

  // ────────────────────────────────────────────────
  // CREATE HOMEWORK WITHOUT FILE
  // ────────────────────────────────────────────────
  Future<void> createHomework(Map<String, dynamic> data) async {
    await _dio.post("/homework/create", data: data);
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
    String fileName = file.path.split("/").last;

    final formData = FormData.fromMap({
      ...data,
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
    });

    await _dio.post(
      "/homework/create_with_file/$schoolId/$classId",
      data: formData,
    );
  }

  // ────────────────────────────────────────────────
  // DELETE HOMEWORK
  // ────────────────────────────────────────────────
  static Future<void> deleteHomework(int id) async {
    await _dio.delete("/homework/delete/$id");
  }

  // ────────────────────────────────────────────────
  // DELETE IMAGE
  // ────────────────────────────────────────────────
  Future<void> deleteImage(
    String schoolId,
    String classId,
    String filename,
  ) async {
    await _dio.delete("/homework/delete-image/$schoolId/$classId/$filename");
  }
}
