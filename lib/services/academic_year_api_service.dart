import 'dart:convert';

import 'package:school_attendance/services/hybrid_api_service.dart';

class AcademicYearApiService {
  /// Fetch all academic years for a school
  static Future<List<Map<String, dynamic>>> fetchAllAcademicYears(
    String schoolId,
  ) async {
    try {
      final response = await HybridApiService.get(
        '/acadamic_year/fetch_all/$schoolId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
    } catch (e) {
      // Return empty list on error
    }
    return [];
  }
}
