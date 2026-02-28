import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:school_attendance/utils/utils.dart';

import 'exam_time_table_model.dart';

class ExamTimeTableService {
  final String baseUrl1 = "$baseUrl/exam-time-table";

  // CREATE
  Future<void> createExam(ExamTimeTable exam) async {
    final response = await http.post(
      Uri.parse(baseUrl1),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(exam.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception("Failed to create exam");
    }
  }

  // GET ALL
  Future<List<ExamTimeTable>> getAllExams() async {
    final response = await http.get(Uri.parse(baseUrl1));

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => ExamTimeTable.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load exams");
    }
  }

  // GET ONE
  Future<ExamTimeTable> getExam(int id) async {
    final response = await http.get(Uri.parse("$baseUrl1/$id"));

    if (response.statusCode == 200) {
      return ExamTimeTable.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Exam not found");
    }
  }

  // UPDATE
  Future<void> updateExam(int id, Map<String, dynamic> data) async {
    final response = await http.patch(
      Uri.parse("$baseUrl1/$id"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update");
    }
  }

  // DELETE
  Future<void> deleteExam(int id) async {
    final response = await http.delete(Uri.parse("$baseUrl1/$id"));

    if (response.statusCode != 200) {
      throw Exception("Failed to delete");
    }
  }

  // FILTER
  Future<List<ExamTimeTable>> filterBySchoolClass(
    int schoolId,
    int classId,
  ) async {
    final response = await http.get(
      Uri.parse("$baseUrl1/filter?school_id=$schoolId&class_id=$classId"),
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => ExamTimeTable.fromJson(e)).toList();
    } else {
      throw Exception("Filter failed");
    }
  }
}
