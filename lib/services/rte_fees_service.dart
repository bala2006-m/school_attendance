import 'dart:convert';

import 'package:dio/dio.dart';

import '../utils/utils.dart' as app_config;

class RteFeesService {
  late final Dio _dio;
  final String baseUrl;

  RteFeesService({String? base}) : baseUrl = base ?? app_config.baseUrl {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.next(options);
        },
        onResponse: (resp, handler) {
          return handler.next(resp);
        },
        onError: (err, handler) {
          return handler.next(err);
        },
      ),
    );
  }

  Future<Map<String, dynamic>?> getBySchoolIdClassAndDate({
    required int schoolId,
    required int classId,
    required String date,
  }) async {
    try {
      final resp = await _dio.get(
        '/rte-fees/school_class_date/$schoolId/$classId/$date',
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.toString());
        return data;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> countRtePaidStudents(int schoolId) async {
    try {
      final resp = await _dio.get('/rte-fees/pending_paid_school/$schoolId');
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.toString());
        return data;
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<List<dynamic>?> getRtePaidStudents(
    int schoolId, {
    int? classId,
  }) async {
    try {
      final Map<String, dynamic> query = {'school_id': schoolId};
      if (classId != null) query['class_id'] = classId;
      final resp = await _dio.get(
        '/rte-fees/rte_paid_students',
        queryParameters: query,
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is List) return data;

        if (data is Map && data.containsKey('data')) {
          return (data['data'] as List<dynamic>);
        }
        return data as List<dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> getRteStudentsBySchool(
    int schoolId, {
    int? classId,
  }) async {
    try {
      final Map<String, dynamic> query = {'school_id': schoolId};
      if (classId != null) query['class_id'] = classId;
      final resp = await _dio.get(
        '/rte-fees/rte_students',
        queryParameters: query,
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is List) return data;

        if (data is Map && data.containsKey('data')) {
          return (data['data'] as List<dynamic>);
        }
        return data as List<dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  // ============================
  // Structures (RteStructure)
  // ============================

  Future<List<dynamic>?> getStructuresBySchool(
    int schoolId, {
    int? classId,
  }) async {
    try {
      final Map<String, dynamic> query = {'school_id': schoolId};
      if (classId != null) query['class_id'] = classId;
      final resp = await _dio.get(
        '/rte-fees/structure',
        queryParameters: query,
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is List) return data;

        if (data is Map && data.containsKey('data')) {
          return (data['data'] as List<dynamic>);
        }
        return data as List<dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> getAllStructuresBySchool(int schoolId) async {
    try {
      final Map<String, dynamic> query = {'school_id': schoolId};
      final resp = await _dio.get(
        '/rte-fees/all_structure',
        queryParameters: query,
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is List) return data;

        if (data is Map && data.containsKey('data')) {
          return (data['data'] as List<dynamic>);
        }
        return data as List<dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>?> getActiveStructuresBySchool(
    int schoolId, {
    int? classId,
  }) async {
    try {
      final Map<String, dynamic> query = {'school_id': schoolId};
      if (classId != null) query['class_id'] = classId;
      final resp = await _dio.get(
        '/rte-fees/structure_active',
        queryParameters: query,
      );
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is List) return data;

        if (data is Map && data.containsKey('data')) {
          return (data['data'] as List<dynamic>);
        }
        return data as List<dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> createStructure(
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.post('/rte-fees/structure', data: payload);
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return resp.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// PATCH /rte-fees/structure/:id
  /// returns updated object or null
  Future<Map<String, dynamic>?> updateStructure(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.patch('/rte-fees/structure/$id', data: payload);
      if (resp.statusCode == 200) {
        return resp.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// DELETE /rte-fees/structure/:id
  /// returns true on success, false otherwise
  Future<bool> deleteStructure(int id) async {
    try {
      final resp = await _dio.delete('/rte-fees/structure/$id');
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  /// Toggle status by calling update with status and updated_by
  /// convenience method used by your Flutter UI
  Future<Map<String, dynamic>?> toggleStatusById(
    int id,
    String status,
    String updatedBy,
  ) async {
    try {
      final payload = {
        'status': status, // "active" or "inactive"
        'updated_by': updatedBy,
      };
      return await updateStructure(id, payload);
    } catch (e) {
      return null;
    }
  }

  // ============================
  // Payments (RteFeePayment)
  // ============================

  /// POST /rte-fees/payment
  /// payload: {
  ///   school_id, class_id, student_id, rte_fee_structure_id,
  ///   amount_paid, payment_mode, reference_number?, status, created_by
  /// }
  Future<Map<String, dynamic>?> createPayment(
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _dio.post('/rte-fees/payment', data: payload);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return resp.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// GET /rte-fees/payment?school_id=...&student_id=...
  Future<List<dynamic>?> listPayments(int schoolId, {String? studentId}) async {
    try {
      final query = {'school_id': schoolId};
      if (studentId != null) query['student_id'] = int.parse(studentId);
      final resp = await _dio.get('/rte-fees/payment', queryParameters: query);
      if (resp.statusCode == 200) {
        final data = resp.data;
        if (data is List) return data;
        if (data is Map && data.containsKey('data')) {
          return (data['data'] as List<dynamic>);
        }
        return data as List<dynamic>?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ============================
  // Helpers
  // ============================

  /// Parses server error message when available
  // String _extractErrorMessage(Object error) {
  //   if (error is DioException) {
  //     try {
  //       final resp = error.response;
  //       if (resp?.data != null) {
  //         if (resp!.data is Map && resp.data.containsKey('message')) {
  //           return resp.data['message'].toString();
  //         }
  //         return resp.data.toString();
  //       }
  //       return error.message ?? 'Network error';
  //     } catch (_) {
  //       return error.toString();
  //     }
  //   }
  //   return error.toString();
  // }
}
