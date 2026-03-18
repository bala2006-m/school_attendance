// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:school_attendance/utils/utils.dart';
// class HybridApiService {
//   static String? localBaseUrl;
//   static bool? _isDesktop;
//   static bool? _isLocalServerAvailable;
//   static bool _isInitialized = false;
//   static Future<void>? _initFuture;

//   static Future<void> initialize() async {
//     if (_isInitialized) return;
//     if (_initFuture != null) return _initFuture;

//     _initFuture = _doInitialize();
//     return _initFuture;
//   }

//   static Future<void> _doInitialize() async {
//     // Determine platform category
//     bool isDesktopUser = isDesktopPlatform;
//     bool isMobileUser = isMobilePlatform;

//     print("HYBRID: Init started. Desktop: $isDesktopUser, Mobile: $isMobileUser");

//     // RULE: Only mobile users use cloud server ONLY.
//     // Desktop users use cloud server for production.

//     if (isMobileUser) {
//       print("HYBRID: Mobile user detected. Forcing CLOUD mode.");
//       _isLocalServerAvailable = false;
//     } else if (isDesktopUser) {
//       print("HYBRID: Desktop user detected. Using CLOUD mode.");
//       _isLocalServerAvailable = false;
//     } else {
//       print("HYBRID: Unknown platform. Defaulting to CLOUD mode.");
//       _isLocalServerAvailable = false;
//     }

//     _isInitialized = true;
//   }

//   static Future<void> _detectLocalServer() async {
//     // Try to detect local server on common ports in parallel
//     final possiblePorts = [3000, 3001, 3002, 3003, 8000, 8080];
//     final possibleHosts = ['localhost', '127.0.0.1'];

//     List<Future<void>> scanTasks = [];

//     for (String host in possibleHosts) {
//       for (int port in possiblePorts) {
//         scanTasks.add(_testConnection(host, port));
//       }
//     }

//     // Wait for all scans to complete (parallel)
//     await Future.wait(scanTasks);

//     if (localBaseUrl == null) {
//       print("HYBRID: No local server found on common ports. Falling back to CLOUD.");
//       _isLocalServerAvailable = false;
//     } else {
//       print("HYBRID: LOCAL SERVER FOUND at $localBaseUrl. Prioritizing LOCAL.");
//     }
//   }

//   static Future<void> _testConnection(String host, int port) async {
//     if (_isLocalServerAvailable == true) return; // Already found

//     try {
//       final url = 'http://$host:$port/sync/test-connection';
//       final response = await http
//           .get(
//             Uri.parse(url),
//             headers: {"Content-Type": "application/json"},
//           )
//           .timeout(const Duration(seconds: 3));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         if (data['local']?['status'] == 'connected') {
//           localBaseUrl = 'http://$host:$port';
//           _isLocalServerAvailable = true;
//         }
//       }
//     } catch (e) {
//       // Failed connection, ignore
//     }
//   }

//   static String get effectiveBaseUrl {
//     if (_isLocalServerAvailable == true && localBaseUrl != null) {
//       return localBaseUrl!;
//     }
//     return baseUrl;
//   }

//   static bool get isHybridMode => _isLocalServerAvailable == true;

//   static bool get isLocalAvailable => _isLocalServerAvailable ?? false;

//   static Future<http.Response> post(
//     String endpoint, {
//     Map<String, String>? headers,
//     Object? body,
//     Encoding? encoding,
//     bool forceCloud = false,
//   }) async {
//     await initialize();

//     final url =
//         forceCloud || !isHybridMode
//             ? '$baseUrl$endpoint'
//             : '$localBaseUrl$endpoint';

//     final requestHeaders = {"Content-Type": "application/json", ...getApiHeaders(), ...?headers};

//     // Add sync source header for local requests
//     if (isHybridMode && !forceCloud) {
//       requestHeaders['x-sync-source'] = 'local';
//     }

//     return await http.post(
//       Uri.parse(url),
//       headers: requestHeaders,
//       body: body,
//       encoding: encoding,
//     );
//   }

//   static Future<http.Response> get(
//     String endpoint, {
//     Map<String, String>? headers,
//     bool forceCloud = false,
//   }) async {
//     await initialize();

//     final url =
//         forceCloud || !isHybridMode
//             ? '$baseUrl$endpoint'
//             : '$localBaseUrl$endpoint';

//     final requestHeaders = {"Content-Type": "application/json", ...getApiHeaders(), ...?headers};

//     // Add sync source header for local requests
//     if (isHybridMode && !forceCloud) {
//       requestHeaders['x-sync-source'] = 'local';
//     }

//     return await http.get(Uri.parse(url), headers: requestHeaders);
//   }

//   static Future<http.Response> put(
//     String endpoint, {
//     Map<String, String>? headers,
//     Object? body,
//     Encoding? encoding,
//     bool forceCloud = false,
//   }) async {
//     await initialize();

//     final url =
//         forceCloud || !isHybridMode
//             ? '$baseUrl$endpoint'
//             : '$localBaseUrl$endpoint';

//     final requestHeaders = {"Content-Type": "application/json", ...getApiHeaders(), ...?headers};

//     // Add sync source header for local requests
//     if (isHybridMode && !forceCloud) {
//       requestHeaders['x-sync-source'] = 'local';
//     }

//     return await http.put(
//       Uri.parse(url),
//       headers: requestHeaders,
//       body: body,
//       encoding: encoding,
//     );
//   }

//   static Future<http.Response> patch(
//     String endpoint, {
//     Map<String, String>? headers,
//     Object? body,
//     Encoding? encoding,
//     bool forceCloud = false,
//   }) async {
//     await initialize();

//     final url =
//         forceCloud || !isHybridMode
//             ? '$baseUrl$endpoint'
//             : '$localBaseUrl$endpoint';

//     final requestHeaders = {"Content-Type": "application/json", ...getApiHeaders(), ...?headers};

//     // Add sync source header for local requests
//     if (isHybridMode && !forceCloud) {
//       requestHeaders['x-sync-source'] = 'local';
//     }

//     return await http.patch(
//       Uri.parse(url),
//       headers: requestHeaders,
//       body: body,
//       encoding: encoding,
//     );
//   }

//   static Future<http.Response> delete(
//     String endpoint, {
//     Map<String, String>? headers,
//     Object? body,
//     Encoding? encoding,
//     bool forceCloud = false,
//   }) async {
//     await initialize();

//     final url =
//         forceCloud || !isHybridMode
//             ? '$baseUrl$endpoint'
//             : '$localBaseUrl$endpoint';

//     final requestHeaders = {"Content-Type": "application/json", ...getApiHeaders(), ...?headers};

//     // Add sync source header for local requests
//     if (isHybridMode && !forceCloud) {
//       requestHeaders['x-sync-source'] = 'local';
//     }

//     return await http.delete(
//       Uri.parse(url),
//       headers: requestHeaders,
//       body: body,
//       encoding: encoding,
//     );
//   }

//   static Future<Map<String, dynamic>> getSyncStatus() async {
//     if (!isHybridMode) {
//       return {
//         'isHybridMode': false,
//         'isLocalAvailable': false,
//         'syncQueue': {'pending': 0, 'completed': 0, 'failed': 0},
//       };
//     }

//     try {
//       final response = await get('/sync/status');
//       if (response.statusCode == 200) {
//         return jsonDecode(response.body);
//       }
//     } catch (e) {
//       // print('Failed to get sync status: $e');
//     }

//     return {
//       'isHybridMode': false,
//       'isLocalAvailable': false,
//       'syncQueue': {'pending': 0, 'completed': 0, 'failed': 0},
//     };
//   }

//   static Future<bool> triggerFullSync() async {
//     if (!isHybridMode) return false;

//     try {
//       final response = await post('/sync/full-sync');
//       return response.statusCode == 200;
//     } catch (e) {
//       return false;
//     }
//   }

//   static Future<Map<String, dynamic>> testConnections() async {
//     final result = {
//       'cloud': {'status': 'unknown', 'message': ''},
//       'local': {'status': 'unknown', 'message': ''},
//     };

//     // Test cloud connection
//     try {
//       final response = await http
//           .get(
//             Uri.parse('$baseUrl/sync/test-connection'),
//             headers: {"Content-Type": "application/json"},
//           )
//           .timeout(Duration(seconds: 5));

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         result['cloud'] = data['cloud'];
//       }
//     } catch (e) {
//       result['cloud'] = {
//         'status': 'error',
//         'message': 'Cloud connection failed: $e',
//       };
//     }

//     // Test local connection if available
//     if (isHybridMode) {
//       try {
//         final response = await http
//             .get(
//               Uri.parse('$localBaseUrl/sync/test-connection'),
//               headers: {"Content-Type": "application/json"},
//             )
//             .timeout(Duration(seconds: 5));

//         if (response.statusCode == 200) {
//           final data = jsonDecode(response.body);
//           result['local'] = data['local'];
//         }
//       } catch (e) {
//         result['local'] = {
//           'status': 'error',
//           'message': 'Local connection failed: $e',
//         };
//       }
//     } else {
//       result['local'] = {
//         'status': 'unavailable',
//         'message': 'Local server not available',
//       };
//     }

//     return result;
//   }

//   static Future<http.MultipartRequest> createMultipartRequest(
//     String method,
//     String endpoint, {
//     Map<String, String>? headers,
//     bool forceCloud = false,
//   }) async {
//     await initialize();

//     final url =
//         forceCloud || !isHybridMode
//             ? '$baseUrl$endpoint'
//             : '$localBaseUrl$endpoint';

//     final request = http.MultipartRequest(method, Uri.parse(url));

//     final requestHeaders = {...getApiHeaders(), ...?headers};
//     if (isHybridMode && !forceCloud) {
//       requestHeaders['x-sync-source'] = 'local';
//     }
//     request.headers.addAll(requestHeaders);

//     return request;
//   }
// }

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
  static bool _localSyncTriggered = false;
  static Future<void> _triggerLocalInitialSyncIfPossible() async {
    if (_localSyncTriggered != false) return;
    if (_isLocalServerAvailable == false || localBaseUrl == null) return;

    final prefs = await SharedPreferences.getInstance();
    final schoolId = prefs.get('schoolId')?.toString();
    final username = prefs.get('username')?.toString();

    if (schoolId == null || username == null) return;

    try {
      _localSyncTriggered = true;
      await post(
        '/offline/trigger-initial-sync',
        body: jsonEncode({'schoolId': schoolId, 'userId': username}),
        forceCloud: false, // ensure it hits LOCAL
      );
    } catch (_) {
      // allow retry on next detection if it failed
      _localSyncTriggered = false;
    }
  }

  static Future<void> initialize() async {
    if (_isInitialized) return;
    if (_initFuture != null) return _initFuture;

    _initFuture = _doInitialize();
    return _initFuture;
  }

  static Future<void> _doInitialize() async {
    final isDesktopUser = isDesktopPlatform;
    final isMobileUser = isMobilePlatform;

    print(
      "HYBRID: Init started. Desktop: $isDesktopUser, Mobile: $isMobileUser, Web: $kIsWeb",
    );

    if (kIsWeb) {
      // Web → try local if we are on localhost, else cloud
      print("HYBRID: Web detected. Attempting local server detection...");
      await _detectLocalServer();
    } else if (isMobileUser) {
      // Mobile native → always cloud
      print("HYBRID: Mobile user detected. Forcing CLOUD mode.");
      _isLocalServerAvailable = false;
    } else if (isDesktopUser) {
      // Desktop native → try local first, else cloud
      print("HYBRID: Desktop user detected. Scanning for local server...");
      await _detectLocalServer(); // sets _isLocalServerAvailable / localBaseUrl

      if (_isLocalServerAvailable == true && localBaseUrl != null) {
        print(
          "HYBRID: LOCAL SERVER FOUND at $localBaseUrl. Prioritizing LOCAL.",
        );
      } else {
        print(
          "HYBRID: No local server found on common ports. Falling back to CLOUD.",
        );
        _isLocalServerAvailable = false;
      }
    } else {
      print("HYBRID: Unknown platform. Defaulting to CLOUD mode.");
      _isLocalServerAvailable = false;
    }

    _isInitialized = true;
  }

  static Future<void> _detectLocalServer() async {
    // Try to detect local server on common ports in parallel
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
      print(
        "HYBRID: No local server found on common ports. Falling back to CLOUD.",
      );
      _isLocalServerAvailable = false;
    } else {
      print("HYBRID: LOCAL SERVER FOUND at $localBaseUrl. Prioritizing LOCAL.");
    }
  }

  static Future<void> _testConnection(String host, int port) async {
    if (_isLocalServerAvailable == true) return; // Already found

    try {
      final url = 'http://$host:$port/sync/test-connection';

      final response = await http
          .get(Uri.parse(url), headers: {"Content-Type": "application/json"})
          .timeout(const Duration(seconds: 3));

      // Treat any HTTP 200 here as "local server is ready"
      if (response.statusCode == 200 || response.statusCode == 201) {
        localBaseUrl = 'http://$host:$port';
        _isLocalServerAvailable = true;
        print("HYBRID: Local server confirmed at $localBaseUrl");
        await _triggerLocalInitialSyncIfPossible();
      }
    } catch (e) {
      print("HYBRID: Local test failed For $host:$port: $e");
    }
  }

  static void _scheduleLocalRescanIfNeeded() {
    if (!isDesktopPlatform) return;
    if (_isLocalServerAvailable == true && localBaseUrl != null) return;

    final now = DateTime.now();
    if (_lastLocalScan != null &&
        now.difference(_lastLocalScan!) < const Duration(seconds: 15)) {
      return; // too soon to rescan
    }

    _lastLocalScan = now;
    // Fire-and-forget; current request still uses cloud,
    // future ones may switch to local if found.
    _detectLocalServer();
  }

  static String get effectiveBaseUrl {
    if (_isLocalServerAvailable == true && localBaseUrl != null) {
      return localBaseUrl!;
    }
    return baseUrl;
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
    final localUrl =
        !forceCloud && isHybridMode && localBaseUrl != null
            ? '$localBaseUrl$endpoint'
            : null;

    final requestHeaders = {
      "Content-Type": "application/json",
      ...getApiHeaders(),
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
      // Local failed → mark unavailable, reset sync flag, and fall back to cloud
      _isLocalServerAvailable = false;
      localBaseUrl = null;
      _localSyncTriggered = false; // Allow re-sync when server returns
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
    final localUrl =
        !forceCloud && isHybridMode && localBaseUrl != null
            ? '$localBaseUrl$endpoint'
            : null;

    final requestHeaders = {
      "Content-Type": "application/json",
      ...getApiHeaders(),
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
      _isLocalServerAvailable = false;
      localBaseUrl = null;
      _localSyncTriggered = false; // Allow re-sync when server returns
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
    final localUrl =
        !forceCloud && isHybridMode && localBaseUrl != null
            ? '$localBaseUrl$endpoint'
            : null;

    final requestHeaders = {
      "Content-Type": "application/json",
      ...getApiHeaders(),
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
      _isLocalServerAvailable = false;
      localBaseUrl = null;
      _localSyncTriggered = false; // Allow re-sync when server returns
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
    final localUrl =
        !forceCloud && isHybridMode && localBaseUrl != null
            ? '$localBaseUrl$endpoint'
            : null;

    final requestHeaders = {
      "Content-Type": "application/json",
      ...getApiHeaders(),
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
      _isLocalServerAvailable = false;
      localBaseUrl = null;
      _localSyncTriggered = false; // Allow re-sync when server returns
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
    final localUrl =
        !forceCloud && isHybridMode && localBaseUrl != null
            ? '$localBaseUrl$endpoint'
            : null;

    final requestHeaders = {
      "Content-Type": "application/json",
      ...getApiHeaders(),
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
      _isLocalServerAvailable = false;
      localBaseUrl = null;
      _localSyncTriggered = false; // Allow re-sync when server returns
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
      'isHybridMode': false,
      'isLocalAvailable': false,
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

    // Test cloud connection
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/sync/test-connection'),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        result['cloud'] = data['cloud'];
      }
    } catch (e) {
      result['cloud'] = {
        'status': 'error',
        'message': 'Cloud connection failed: $e',
      };
    }

    // Test local connection if available
    if (isHybridMode) {
      try {
        final response = await http
            .get(
              Uri.parse('$localBaseUrl/sync/test-connection'),
              headers: {"Content-Type": "application/json"},
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          result['local'] = data['local'];
        }
      } catch (e) {
        result['local'] = {
          'status': 'error',
          'message': 'Local connection failed: $e',
        };
      }
    } else {
      result['local'] = {
        'status': 'unavailable',
        'message': 'Local server not available',
      };
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

    final url =
        forceCloud || !isHybridMode
            ? '$baseUrl$endpoint'
            : '$localBaseUrl$endpoint';

    final request = http.MultipartRequest(method, Uri.parse(url));

    final requestHeaders = {...getApiHeaders(), ...?headers};
    if (isHybridMode && !forceCloud) {
      requestHeaders['x-sync-source'] = 'local';
    }
    request.headers.addAll(requestHeaders);

    return request;
  }
}
