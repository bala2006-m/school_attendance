import 'dart:convert';

import 'package:school_attendance/services/hybrid_api_service.dart';

import '../utils/utils.dart' as util;

class FinanceService {
  static final String financeBase = '${util.baseUrl}/finance';

  Future<List<dynamic>> getAllIncome({required String schoolId}) async {
    final response = await HybridApiService.get('/finance/income/$schoolId');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load finances');
    }
  }

  Future<List<dynamic>> getAllExpense({required String schoolId}) async {
    final response = await HybridApiService.get('/finance/expense/$schoolId');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load finances');
    }
  }

  Future<List<dynamic>> getAllDrawingIN({required String schoolId}) async {
    final response = await HybridApiService.get('/finance/drawing_in/$schoolId');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load finances');
    }
  }

  Future<List<dynamic>> getAllDrawingOUT({required String schoolId}) async {
    final response = await HybridApiService.get(
      '/finance/drawing_out/$schoolId',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body);
      return data;
    } else {
      throw Exception('Failed to load finances');
    }
  }

  Future<bool> createFinance(Map<String, dynamic> data) async {
    final response = await HybridApiService.post(
      '/finance',
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 201 || response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> updateFinance(int id, Map<String, dynamic> data) async {
    final response = await HybridApiService.put(
      '/finance/$id',
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (response.statusCode == 200 || response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> deleteFinance(int id) async {
    final response = await HybridApiService.delete('/finance/$id');
    if (response.statusCode != 200) {
      throw Exception('Failed to delete finance');
    }
  }
}
