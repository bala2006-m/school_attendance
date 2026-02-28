import 'dart:convert';
import 'package:school_attendance/services/hybrid_api_service.dart';


import '../utils/utils.dart';

/// Handles all API requests for Bus Fee Structures.
class BusFeeStructureApi {
  static String base = "$baseUrl/bus-fee-structure";

  Future<List<dynamic>> getStructuresByClass({
    required int schoolId,
    required int classId,
  }) async {
    try {
      final response = await HybridApiService.get(
        "/bus-fee-structure/school_class/$schoolId/$classId",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      } else if (response.statusCode == 404) {
        return [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getStructuresBySchoolAndRoute(
    int schoolId,
    String route,
  ) async {
    try {
      final encodedRoute = Uri.encodeComponent(route);
      final response = await HybridApiService.get(
        "/bus-fee-structure/route/$schoolId/$encodedRoute",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getOnlyStructuresBySchoolAndRoute(
    int schoolId,
    String route,
  ) async {
    try {
      final encodedRoute = Uri.encodeComponent(route);
      final response = await HybridApiService.get(
        "/bus-fee-structure/only_route/$schoolId/$encodedRoute",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getStructuresBySchoolAndRouteUsername({
    required int schoolId,
    required String route,
    required String username,
  }) async {
    try {
      final encodedRoute = Uri.encodeComponent(route);
      final response = await HybridApiService.get(
        "/bus-fee-structure/route_username/$schoolId/$encodedRoute/$username",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data is List ? data : [data];
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> toggleStatusById(
    int id,
    String status,
    String updatedBy,
  ) async {
    final response = await HybridApiService.put(
      '/bus-fee-structure/$id/toggle-status',
      body: jsonEncode({"status": status, "updated_by": updatedBy}),
      forceCloud: true,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  }

  /// ✅ Create a new bus fee structure
  Future<Map<String, dynamic>?> createStructure(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await HybridApiService.post(
        "/bus-fee-structure",
        body: jsonEncode(data),
        forceCloud: true,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// ✅ Get all bus fee structures
  Future<List<dynamic>> getAllStructures() async {
    try {
      final response = await HybridApiService.get("/bus-fee-structure");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// ✅ Get all active bus fee structures
  Future<List<dynamic>> getActiveStructures() async {
    try {
      final response = await HybridApiService.get("/bus-fee-structure/active");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// ✅ Get all bus fee structures for a specific school
  static Future<List<dynamic>> getStructuresBySchool(int schoolId) async {
    try {
      final response = await HybridApiService.get("/bus-fee-structure/school/$schoolId");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      } else if (response.statusCode == 404) {
        return [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getStructuresBySchoolActive(int schoolId) async {
    try {
      final response = await HybridApiService.get(
        "/bus-fee-structure/active_school/$schoolId",
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data;
      } else if (response.statusCode == 404) {
        return [];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// ✅ Get one bus fee structure by ID
  Future<Map<String, dynamic>?> getStructureById(int id) async {
    try {
      final response = await HybridApiService.get("/bus-fee-structure/$id");

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// ✅ Update a bus fee structure by ID
  Future<Map<String, dynamic>?> updateStructure(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await HybridApiService.put(
        "/bus-fee-structure/$id",
        body: jsonEncode(data),
        forceCloud: true,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// ✅ Delete a bus fee structure by ID
  Future<bool> deleteStructure(int id) async {
    try {
      final response = await HybridApiService.delete("/bus-fee-structure/$id", forceCloud: true);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}
