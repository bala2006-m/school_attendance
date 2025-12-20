import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/utils.dart';

/// Handles all API requests for Bus Fee Structures.
class BusFeeStructureApi {
  static String base = "$baseUrl/bus-fee-structure";

  Future<List<dynamic>> getStructuresByClass({
    required int schoolId,
    required int classId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse("$base/school_class/$schoolId/$classId"),
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
      final encodedRoute = Uri.encodeComponent(
        route,
      ); // handle spaces or special chars
      //  print("$base/route/$schoolId/$encodedRoute");
      final response = await http.get(
        Uri.parse("$base/route/$schoolId/$encodedRoute"),
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
      final encodedRoute = Uri.encodeComponent(
        route,
      ); // handle spaces or special chars
      final response = await http.get(
        Uri.parse("$base/only_route/$schoolId/$encodedRoute"),
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
      final encodedRoute = Uri.encodeComponent(
        route,
      ); // handle spaces or special chars
      final response = await http.get(
        Uri.parse("$base/route_username/$schoolId/$encodedRoute/$username"),
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
    final response = await http.put(
      Uri.parse('$base/$id/toggle-status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"status": status, "updated_by": updatedBy}),
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
      final response = await http.post(
        Uri.parse(base),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
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
      final response = await http.get(Uri.parse(base));

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
      final response = await http.get(Uri.parse("$base/active"));

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
      final response = await http.get(Uri.parse("$base/school/$schoolId"));

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
      final response = await http.get(
        Uri.parse("$base/active_school/$schoolId"),
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
      final response = await http.get(Uri.parse("$base/$id"));

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
      final response = await http.put(
        Uri.parse("$base/$id"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
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
      final response = await http.delete(Uri.parse("$base/$id"));

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
