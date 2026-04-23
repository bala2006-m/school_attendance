import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:school_attendance/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HybridApiService {
  static String? localBaseUrl;
  static bool? _isLocalServerAvailable;
  static bool _isInitialized = false;
  static Future<void>? _initFuture;
  static DateTime? _lastLocalScan;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initFuture != null) return _initFuture;

    _initFuture = _doInitialize();
    return _initFuture;
  }

  static Future<void> _doInitialize() async {
    final isDesktopUser = isDesktopPlatform;
    final isMobileUser = isMobilePlatform;

    print("HYBRID: Init started. Desktop: $isDesktopUser, Mobile: $isMobileUser, Web: $kIsWeb");

    if (kIsWeb) {
      print("HYBRID: Web detected. Trying LOCAL first, fallback CLOUD.");
      await _detectLocalServer();
      if (_isLocalServerAvailable == true && localBaseUrl != null) {
        print("HYBRID: Web app connected to LOCAL server at $localBaseUrl.");
      } else {
        print("HYBRID: No local server on web. Using CLOUD mode.");
        _isLocalServerAvailable = false;
        localBaseUrl = null;
      }
    } else if (isMobileUser) {
      print("HYBRID: Mobile user detected. Forcing CLOUD mode.");
      _isLocalServerAvailable = false;
    } else if (isDesktopUser) {
      print("HYBRID: Desktop user detected. Scanning for local server...");
      await _detectLocalServer();

      if (_isLocalServerAvailable == true && localBaseUrl != null) {
        print("HYBRID: LOCAL SERVER FOUND at $localBaseUrl. Prioritizing LOCAL.");
      } else {
        print("HYBRID: No local server found on common ports. Falling back to CLOUD.");
        _isLocalServerAvailable = false;
      }
    } else {
      print("HYBRID: Unknown platform. Defaulting to CLOUD mode.");
      _isLocalServerAvailable = false;
    }

    _isInitialized = true;
  }

  static Future<void> _detectLocalServer() async {
    // Only detect on port 3003 as per server config
    final possiblePorts = [3003];
    final possibleHosts = ['localhost', '127.0.0.1'];

    final List<Future<void>> scanTasks = [];

    for (final host in possibleHosts) {
      for (final port in possiblePorts) {
        scanTasks.add(_testConnection(host, port));
      }
    }

    await Future.wait(scanTasks);

    if (localBaseUrl == null) {
      print("HYBRID: Detection complete. No local server found.");
      _isLocalServerAvailable = false;
    }
  }

  static Future<void> _testConnection(String host, int port) async {
    if (_isLocalServerAvailable == true) return; // Already found

    try {
      final url = 'http://$host:$port/sync/test-connection';
      print("HYBRID: Testing connection to $url");

      final response = await http
          .get(Uri.parse(url), headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200 || response.statusCode == 201) {
        localBaseUrl = 'http://$host:$port';
        _isLocalServerAvailable = true;
        print("HYBRID: Local server confirmed at $localBaseUrl");
      } else {
        print("HYBRID: Connection to $host:$port returned status ${response.statusCode}");
      }
    } catch (e) {
      // Just log for debugging, don't spam errors
      print("HYBRID: Local test failed for $host:$port");
    }
  }

  static void _scheduleLocalRescanIfNeeded() {
    if (isMobilePlatform) return;
    if (_isLocalServerAvailable == true && localBaseUrl != null) return;

    final now = DateTime.now();
    if (_lastLocalScan != null &&
        now.difference(_lastLocalScan!) < const Duration(seconds: 30)) {
      return; 
    }

    _lastLocalScan = now;
    _detectLocalServer();
  }

  static String get effectiveBaseUrl {
    if (_isLocalServerAvailable == true && localBaseUrl != null) {
      return localBaseUrl!;
    }
    return baseUrl;
  }

  static Future<Map<String, String>> _getAcademicHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getString('x_academic_start');
    final end = prefs.getString('x_academic_end');
    final id = prefs.getString('x_academic_id');
    
    final headers = <String, String>{};
    if (start != null && start.isNotEmpty) headers['x-academic-start'] = start;
    if (end != null && end.isNotEmpty) headers['x-academic-end'] = end;
    if (id != null && id.isNotEmpty) headers['x-academic-id'] = id;
    
    return headers;
  }

  static bool get isHybridMode => _isLocalServerAvailable == true;

  static bool get isLocalAvailable => _isLocalServerAvailable ?? false;

  static Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool forceCloud = false,
  }) async {
    await initialize();
    _scheduleLocalRescanIfNeeded();
    
    final cloudUrl = '$baseUrl$endpoint';
    final localUrl = !forceCloud && isHybridMode && localBaseUrl != null
            ? '$localBaseUrl$endpoint'
            : null;

    final academicHeaders = await _getAcademicHeaders();

    final requestHeaders = {
      "Content-Type": "application/json",
      ...getApiHeaders(),
      ...academicHeaders,
      ...?headers,
    };

    if (isHybridMode && !forceCloud) {
      requestHeaders['x-sync-source'] = 'local';
    }

    Future<http.Response> callCloud() => http.post(
      Uri.parse(cloudUrl),
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );

    if (localUrl == null) return callCloud();

    try {
      return await http.post(
        Uri.parse(localUrl),
        headers: requestHeaders,
        body: body,
        encoding: encoding,
      );
    } catch (e) {
      print("HYBRID: Local POST failed, falling back to cloud. Error: $e");
      _isLocalServerAvailable = false;
      localBaseUrl = null;
      return callCloud();
    }
  }

  static Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    bool forceCloud = false,
  }) async {
    await initialize();
    _scheduleLocalRescanIfNeeded();
    
    final cloudUrl = '$baseUrl$endpoint';
    final localUrl = !forceCloud && isHybridMode && localBaseUrl != null
            ? '$localBaseUrl$endpoint'
            : null;

    final academicHeaders = await _getAcademicHeaders();

    final requestHeaders = {
      "Content-Type": "application/json",
      ...getApiHeaders(),
      ...academicHeaders,
      ...?headers,
    };

    if (isHybridMode && !forceCloud) {
      requestHeaders['x-sync-source'] = 'local';
    }

    Future<http.Response> callCloud() => http
        .get(Uri.parse(cloudUrl), headers: requestHeaders)
        .timeout(const Duration(seconds: 10));

    if (localUrl == null) return callCloud();

    try {
      return await http.get(Uri.parse(localUrl), headers: requestHeaders);
    } catch (e) {
      print("HYBRID: Local GET failed, falling back to cloud. Error: $e");
      _isLocalServerAvailable = false;
      localBaseUrl = null;
      return callCloud();
    }
  }

  static Future<http.Response> put(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool forceCloud = false,
  }) async {
    await initialize();
    _scheduleLocalRescanIfNeeded();
    
    final cloudUrl = '$baseUrl$endpoint';
    final localUrl = !forceCloud && isHybridMode && localBaseUrl != null
            ? '$localBaseUrl$endpoint'
            : null;

    final academicHeaders = await _getAcademicHeaders();

    final requestHeaders = {
      "Content-Type": "application/json",
      ...getApiHeaders(),
      ...academicHeaders,
      ...?headers,
    };

    if (isHybridMode && !forceCloud) {
      requestHeaders['x-sync-source'] = 'local';
    }

    Future<http.Response> callCloud() => http.put(
      Uri.parse(cloudUrl),
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );

    if (localUrl == null) return callCloud();

    try {
      return await http.put(
        Uri.parse(localUrl),
        headers: requestHeaders,
        body: body,
        encoding: encoding,
      );
    } catch (e) {
      print("HYBRID: Local PUT failed, falling back to cloud. Error: $e");
      _isLocalServerAvailable = false;
      localBaseUrl = null;
      return callCloud();
    }
  }

  static Future<http.Response> patch(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool forceCloud = false,
  }) async {
    await initialize();
    _scheduleLocalRescanIfNeeded();
    
    final cloudUrl = '$baseUrl$endpoint';
    final localUrl = !forceCloud && isHybridMode && localBaseUrl != null
            ? '$localBaseUrl$endpoint'
            : null;

    final academicHeaders = await _getAcademicHeaders();

    final requestHeaders = {
      "Content-Type": "application/json",
      ...getApiHeaders(),
      ...academicHeaders,
      ...?headers,
    };

    if (isHybridMode && !forceCloud) {
      requestHeaders['x-sync-source'] = 'local';
    }

    Future<http.Response> callCloud() => http.patch(
      Uri.parse(cloudUrl),
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );

    if (localUrl == null) return callCloud();

    try {
      return await http.patch(
        Uri.parse(localUrl),
        headers: requestHeaders,
        body: body,
        encoding: encoding,
      );
    } catch (e) {
      print("HYBRID: Local PATCH failed, falling back to cloud. Error: $e");
      _isLocalServerAvailable = false;
      localBaseUrl = null;
      return callCloud();
    }
  }

  static Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool forceCloud = false,
  }) async {
    await initialize();
    _scheduleLocalRescanIfNeeded();
    
    final cloudUrl = '$baseUrl$endpoint';
    final localUrl = !forceCloud && isHybridMode && localBaseUrl != null
            ? '$localBaseUrl$endpoint'
            : null;

    final academicHeaders = await _getAcademicHeaders();

    final requestHeaders = {
      "Content-Type": "application/json",
      ...getApiHeaders(),
      ...academicHeaders,
      ...?headers,
    };

    if (isHybridMode && !forceCloud) {
      requestHeaders['x-sync-source'] = 'local';
    }

    Future<http.Response> callCloud() => http.delete(
      Uri.parse(cloudUrl),
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );

    if (localUrl == null) return callCloud();

    try {
      return await http.delete(
        Uri.parse(localUrl),
        headers: requestHeaders,
        body: body,
        encoding: encoding,
      );
    } catch (e) {
      print("HYBRID: Local DELETE failed, falling back to cloud. Error: $e");
      _isLocalServerAvailable = false;
      localBaseUrl = null;
      return callCloud();
    }
  }

  static Future<Map<String, dynamic>> getSyncStatus() async {
    if (!isHybridMode) {
      return {
        'isHybridMode': false,
        'isLocalAvailable': false,
        'syncQueue': {'pending': 0, 'completed': 0, 'failed': 0},
      };
    }

    try {
      final response = await get('/sync/status');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}

    return {
      'isHybridMode': true,
      'isLocalAvailable': true,
      'syncQueue': {'pending': 0, 'completed': 0, 'failed': 0},
    };
  }

  static Future<bool> triggerFullSync() async {
    if (!isHybridMode) return false;

    try {
      final response = await post('/sync/full-sync');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> testConnections() async {
    final result = {
      'cloud': {'status': 'unknown', 'message': ''},
      'local': {'status': 'unknown', 'message': ''},
    };

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/sync/test-connection'), headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        result['cloud'] = data['cloud'];
      }
    } catch (e) {
      result['cloud'] = {'status': 'error', 'message': 'Cloud connection failed: $e'};
    }

    if (isHybridMode) {
      try {
        final response = await http
            .get(Uri.parse('$localBaseUrl/sync/test-connection'), headers: {"Content-Type": "application/json"})
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          result['local'] = data['local'];
        }
      } catch (e) {
        result['local'] = {'status': 'error', 'message': 'Local connection failed: $e'};
      }
    } else {
      result['local'] = {'status': 'unavailable', 'message': 'Local server not available'};
    }

    return result;
  }

  static Future<http.MultipartRequest> createMultipartRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    bool forceCloud = false,
  }) async {
    await initialize();
    _scheduleLocalRescanIfNeeded();

    final url = forceCloud || !isHybridMode ? '$baseUrl$endpoint' : '$localBaseUrl$endpoint';

    final request = http.MultipartRequest(method, Uri.parse(url));

    final academicHeaders = await _getAcademicHeaders();
    final requestHeaders = {...getApiHeaders(), ...academicHeaders, ...?headers};
    if (isHybridMode && !forceCloud) {
      requestHeaders['x-sync-source'] = 'local';
    }
    request.headers.addAll(requestHeaders);

    return request;
  }
}
