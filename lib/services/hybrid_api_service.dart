import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:school_attendance/utils/utils.dart';

class HybridApiService {
  static String? _localBaseUrl;
  static bool? _isDesktop;
  static bool? _isLocalServerAvailable;

  static Future<void> initialize() async {
    _isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    
    if (_isDesktop!) {
      await _detectLocalServer();
    }
  }

  static Future<void> _detectLocalServer() async {
    // Try to detect local server on common ports
    final possiblePorts = [3000, 3001, 3002, 8000, 8080];
    final possibleHosts = ['localhost', '127.0.0.1'];
    
    for (String host in possibleHosts) {
      for (int port in possiblePorts) {
        try {
          final url = 'http://$host:$port/sync/test-connection';
          final response = await http.get(
            Uri.parse(url),
            headers: {"Content-Type": "application/json"},
          ).timeout(Duration(seconds: 3));
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['local']?['status'] == 'connected') {
              _localBaseUrl = 'http://$host:$port';
              _isLocalServerAvailable = true;
              print('Local server detected at: $_localBaseUrl');
              return;
            }
          }
        } catch (e) {
          // Continue trying next combination
        }
      }
    }
    
    _isLocalServerAvailable = false;
    print('No local server detected, using cloud only');
  }

  static String get _effectiveBaseUrl {
    if (_isDesktop! && _isLocalServerAvailable! && _localBaseUrl != null) {
      return _localBaseUrl!;
    }
    return baseUrl;
  }

  static bool get isHybridMode => _isDesktop! && _isLocalServerAvailable!;
  
  static bool get isLocalAvailable => _isLocalServerAvailable ?? false;

  static Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool forceCloud = false,
  }) async {
    await initialize();
    
    final url = forceCloud || !isHybridMode 
        ? '$baseUrl$endpoint'
        : '$_localBaseUrl$endpoint';
    
    final requestHeaders = {
      "Content-Type": "application/json",
      ...?headers,
    };
    
    // Add sync source header for local requests
    if (isHybridMode && !forceCloud) {
      requestHeaders['x-sync-source'] = 'local';
    }
    
    return await http.post(
      Uri.parse(url),
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );
  }

  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    bool forceCloud = false,
  }) async {
    await initialize();
    
    final url = forceCloud || !isHybridMode 
        ? '$baseUrl$endpoint'
        : '$_localBaseUrl$endpoint';
    
    final requestHeaders = {
      "Content-Type": "application/json",
      ...?headers,
    };
    
    // Add sync source header for local requests
    if (isHybridMode && !forceCloud) {
      requestHeaders['x-sync-source'] = 'local';
    }
    
    return await http.get(
      Uri.parse(url),
      headers: requestHeaders,
    );
  }

  static Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool forceCloud = false,
  }) async {
    await initialize();
    
    final url = forceCloud || !isHybridMode 
        ? '$baseUrl$endpoint'
        : '$_localBaseUrl$endpoint';
    
    final requestHeaders = {
      "Content-Type": "application/json",
      ...?headers,
    };
    
    // Add sync source header for local requests
    if (isHybridMode && !forceCloud) {
      requestHeaders['x-sync-source'] = 'local';
    }
    
    return await http.put(
      Uri.parse(url),
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );
  }

  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool forceCloud = false,
  }) async {
    await initialize();
    
    final url = forceCloud || !isHybridMode 
        ? '$baseUrl$endpoint'
        : '$_localBaseUrl$endpoint';
    
    final requestHeaders = {
      "Content-Type": "application/json",
      ...?headers,
    };
    
    // Add sync source header for local requests
    if (isHybridMode && !forceCloud) {
      requestHeaders['x-sync-source'] = 'local';
    }
    
    return await http.delete(
      Uri.parse(url),
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );
  }

  static Future<Map<String, dynamic>> getSyncStatus() async {
    if (!isHybridMode) {
      return {
        'isHybridMode': false,
        'isLocalAvailable': false,
        'syncQueue': {'pending': 0, 'completed': 0, 'failed': 0}
      };
    }
    
    try {
      final response = await get('/sync/status');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Failed to get sync status: $e');
    }
    
    return {
      'isHybridMode': false,
      'isLocalAvailable': false,
      'syncQueue': {'pending': 0, 'completed': 0, 'failed': 0}
    };
  }

  static Future<bool> triggerFullSync() async {
    if (!isHybridMode) return false;
    
    try {
      final response = await post('/sync/full-sync');
      return response.statusCode == 200;
    } catch (e) {
      print('Failed to trigger full sync: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> testConnections() async {
    final result = {
      'cloud': {'status': 'unknown', 'message': ''},
      'local': {'status': 'unknown', 'message': ''}
    };
    
    // Test cloud connection
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sync/test-connection'),
        headers: {"Content-Type": "application/json"},
      ).timeout(Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        result['cloud'] = data['cloud'];
      }
    } catch (e) {
      result['cloud'] = {
        'status': 'error',
        'message': 'Cloud connection failed: $e'
      };
    }
    
    // Test local connection if available
    if (isHybridMode) {
      try {
        final response = await http.get(
          Uri.parse('$_localBaseUrl/sync/test-connection'),
          headers: {"Content-Type": "application/json"},
        ).timeout(Duration(seconds: 5));
        
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          result['local'] = data['local'];
        }
      } catch (e) {
        result['local'] = {
          'status': 'error',
          'message': 'Local connection failed: $e'
        };
      }
    } else {
      result['local'] = {
        'status': 'unavailable',
        'message': 'Local server not available'
      };
    }
    
    return result;
  }
}
