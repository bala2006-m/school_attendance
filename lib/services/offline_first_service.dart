import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:school_attendance/services/hybrid_api_service.dart';
import 'package:school_attendance/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineFirstService {
  static OfflineFirstService? _instance;
  static OfflineFirstService get instance =>
      _instance ??= OfflineFirstService._();

  OfflineFirstService._();

  bool _isDesktop = false;
  bool _isOnline = true;
  List<Map<String, dynamic>> _pendingOperations = [];
  Timer? _syncTimer;
  Timer? _connectivityTimer;

  // Getters
  bool get isDesktop => _isDesktop;
  bool get isOnline => _isOnline;
  List<Map<String, dynamic>> get pendingOperations =>
      List.from(_pendingOperations);
  int get pendingOperationsCount => _pendingOperations.length;

  Future<void> initialize() async {
    _isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

    if (_isDesktop) {
      await _loadPendingOperations();
      _startPeriodicSync();
      _startConnectivityCheck();
    }

    debugPrint('Offline-first service initialized - Desktop: $_isDesktop');
  }

  // Store data locally first (for desktop users)
  Future<http.Response> storeLocally(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    bool forceCloud = false,
  }) async {
    await initialize();

    if (!_isDesktop || forceCloud) {
      // Mobile users or forced cloud - use regular API
      return await HybridApiService.post(
        endpoint,
        headers: headers,
        body: body,
      );
    }

    try {
      // Store in local server first
      final response = await HybridApiService.post(
        endpoint,
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Add to pending operations for cloud sync
        final operation = _extractOperationFromEndpoint(endpoint, body);
        if (operation != null) {
          final pendingOp = {
            'id': _generateOperationId(),
            'endpoint': endpoint,
            'operation': operation['type'],
            'data': operation['data'],
            'timestamp': DateTime.now().toIso8601String(),
            'synced': false,
            'retryCount': 0,
          };

          _pendingOperations.add(pendingOp);
          await _savePendingOperations();

          debugPrint(
            'Stored locally and queued for cloud sync: ${operation['type']} on ${endpoint}',
          );

          // Try to sync immediately if online
          if (_isOnline) {
            _syncToCloud(pendingOp);
          }
        }
      }

      return response;
    } catch (e) {
      debugPrint('Failed to store locally: $e');
      rethrow;
    }
  }

  Map<String, dynamic>? _extractOperationFromEndpoint(
    String endpoint,
    dynamic body,
  ) {
    try {
      // Extract operation type and data from endpoint and body
      if (endpoint.contains('/create') || endpoint.contains('/register')) {
        return {
          'type': 'create',
          'data': body is Map ? body : jsonDecode(body),
        };
      } else if (endpoint.contains('/update')) {
        return {
          'type': 'update',
          'data': body is Map ? body : jsonDecode(body),
        };
      } else if (endpoint.contains('/delete')) {
        return {
          'type': 'delete',
          'data': body is Map ? body : {'id': body},
        };
      }
      return null;
    } catch (e) {
      debugPrint('Failed to extract operation: $e');
      return null;
    }
  }

  // Sync pending operations to cloud
  Future<void> _syncToCloud(Map<String, dynamic> operation) async {
    if (!_isDesktop) return;

    try {
      final response = await HybridApiService.post(
        operation['endpoint'],
        headers: {'x-sync-source': 'desktop'},
        body: operation['data'],
        forceCloud: true, // Force cloud sync
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mark as synced
        operation['synced'] = true;
        operation['retryCount'] = 0;

        _pendingOperations.removeWhere((op) => op['id'] == operation['id']);
        await _savePendingOperations();

        debugPrint('Successfully synced to cloud: ${operation['operation']}');
      } else {
        // Increment retry count
        operation['retryCount'] = (operation['retryCount'] ?? 0) + 1;

        // Remove from pending if too many retries
        if (operation['retryCount'] >= 3) {
          operation['synced'] = true; // Mark as synced to stop retrying
          _pendingOperations.removeWhere((op) => op['id'] == operation['id']);
          await _savePendingOperations();

          debugPrint('Max retries reached for operation: ${operation['id']}');
        }

        await _savePendingOperations();
        debugPrint(
          'Failed to sync to cloud: ${operation['operation']}, retry ${operation['retryCount']}',
        );
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }
  }

  // Start periodic sync for desktop users
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      if (_isOnline && _pendingOperations.isNotEmpty) {
        await _syncPendingOperations();
      }
    });
  }

  // Start connectivity check
  void _startConnectivityCheck() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(Duration(seconds: 10), (timer) async {
      await checkConnectivity();
    });
  }

  // Check connectivity to cloud
  Future<void> checkConnectivity() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/sync/test-connection'),
            headers: {"Content-Type": "application/json"},
          )
          .timeout(Duration(seconds: 5));

      final wasOnline = _isOnline;
      _isOnline = response.statusCode == 200;

      if (wasOnline != _isOnline) {
        debugPrint(_isOnline ? 'Connected to cloud' : 'Working offline');

        // If we just came online, try to sync pending operations
        if (_isOnline && _pendingOperations.isNotEmpty) {
          await _syncPendingOperations();
        }
      }
    } catch (e) {
      final wasOnline = _isOnline;
      _isOnline = false;

      if (wasOnline != _isOnline) {
        debugPrint('Cloud connection lost, working in offline mode');
      }
    }
  }

  // Sync all pending operations
  Future<void> _syncPendingOperations() async {
    final operations = _pendingOperations.where((op) => !op['synced']).toList();

    for (final operation in operations) {
      await _syncToCloud(operation);
      await Future.delayed(
        Duration(milliseconds: 500),
      ); // Small delay between operations
    }
  }

  // Force sync all pending operations
  Future<Map<String, dynamic>> forceSyncAll() async {
    final initialCount = _pendingOperations.length;
    await _syncPendingOperations();

    final successCount = initialCount - _pendingOperations.length;
    final failedCount =
        _pendingOperations.where((op) => op['retryCount'] >= 3).length;

    return {
      'success': successCount,
      'failed': failedCount,
      'total': initialCount,
    };
  }

  // Get offline status
  Future<Map<String, dynamic>> getOfflineStatus() async {
    await initialize();

    return {
      'isDesktopMode': _isDesktop,
      'isOnline': _isOnline,
      'pendingOperations': _pendingOperations.length,
      'pendingOperationsList': List.from(_pendingOperations),
      'mode': _isDesktop ? 'Desktop Offline-First' : 'Mobile Cloud-Only',
      'connectivity': _isOnline ? 'Online' : 'Offline',
    };
  }

  // Clear synced operations
  Future<void> clearSyncedOperations() async {
    _pendingOperations.removeWhere((op) => op['synced']);
    await _savePendingOperations();
  }

  // Save pending operations to local storage
  Future<void> _savePendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'pending_operations',
        jsonEncode(_pendingOperations),
      );
    } catch (e) {
      debugPrint('Failed to save pending operations: $e');
    }
  }

  // Load pending operations from local storage
  Future<void> _loadPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operationsJson = prefs.getString('pending_operations');

      if (operationsJson != null) {
        final operations = List<Map<String, dynamic>>.from(
          jsonDecode(operationsJson),
        );
        _pendingOperations = operations.where((op) => !op['synced']).toList();
        debugPrint('Loaded ${_pendingOperations.length} pending operations');
      }
    } catch (e) {
      debugPrint('Failed to load pending operations: $e');
    }
  }

  String _generateOperationId() {
    return 'offline_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond.toString()}';
  }

  void dispose() {
    _syncTimer?.cancel();
    _connectivityTimer?.cancel();
  }
}
