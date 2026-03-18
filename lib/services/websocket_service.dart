import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:school_attendance/services/hybrid_api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();

  WebSocketService._();

  io.Socket? _socket;
  StreamController<Map<String, dynamic>>? _syncStatusController;
  StreamController<Map<String, dynamic>>? _syncUpdateController;
  StreamController<Map<String, dynamic>>? _databaseChangeController;

  bool _isConnected = false;
  bool _isSubscribedToSync = false;

  // Getters for streams
  Stream<Map<String, dynamic>> get syncStatusStream =>
      _syncStatusController?.stream ?? const Stream.empty();

  Stream<Map<String, dynamic>> get syncUpdateStream =>
      _syncUpdateController?.stream ?? const Stream.empty();

  Stream<Map<String, dynamic>> get databaseChangeStream =>
      _databaseChangeController?.stream ?? const Stream.empty();

  bool get isConnected => _isConnected;
  bool get isSubscribedToSync => _isSubscribedToSync;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) {
      debugPrint('WebSocket already connected');
      return;
    }

    try {
      // Get the appropriate base URL
      final baseUrl =
          HybridApiService.isHybridMode
              ? await _getLocalBaseUrl()
              : HybridApiService.effectiveBaseUrl;

      // Convert HTTP URL to WebSocket URL
      final wsUrl = baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');

      debugPrint('Connecting to WebSocket at: $wsUrl');

      _socket = io.io(wsUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionAttempts': 5,
        'maxReconnectionAttempts': 5,
      });

      _initializeEventListeners();
      _socket!.connect();
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
    }
  }

  Future<String> _getLocalBaseUrl() async {
    // Detect local server URL similar to HybridApiService
    if (HybridApiService.isLocalAvailable) {
      return HybridApiService.localBaseUrl!;
    }
    return HybridApiService.effectiveBaseUrl;
  }

  void _initializeEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('WebSocket connected');
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      debugPrint('WebSocket disconnected');
      _isConnected = false;
      _isSubscribedToSync = false;
    });

    _socket!.onConnectError((error) {
      debugPrint('WebSocket connection error: $error');
      _isConnected = false;
    });

    _socket!.on('sync-status', (data) {
      debugPrint('Received sync status: $data');
      _syncStatusController?.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('sync-update', (data) {
      debugPrint('Received sync update: $data');
      _syncUpdateController?.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('sync-triggered', (data) {
      debugPrint('Sync triggered: $data');
      _syncUpdateController?.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('database-change', (data) {
      debugPrint('Database change: $data');
      _databaseChangeController?.add(Map<String, dynamic>.from(data));
    });
  }

  void subscribeToSyncUpdates() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('subscribe-sync');
      _isSubscribedToSync = true;
      debugPrint('Subscribed to sync updates');
    } else {
      debugPrint('Cannot subscribe: WebSocket not connected');
    }
  }

  void requestSyncStatus() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('get-sync-status');
    }
  }

  void triggerFullSync() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('trigger-full-sync');
      debugPrint('Triggered full sync via WebSocket');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }

    _isConnected = false;
    _isSubscribedToSync = false;

    _syncStatusController?.close();
    _syncUpdateController?.close();
    _databaseChangeController?.close();

    _syncStatusController = null;
    _syncUpdateController = null;
    _databaseChangeController = null;
  }

  void initializeStreams() {
    _syncStatusController = StreamController<Map<String, dynamic>>.broadcast();
    _syncUpdateController = StreamController<Map<String, dynamic>>.broadcast();
    _databaseChangeController =
        StreamController<Map<String, dynamic>>.broadcast();
  }
}
