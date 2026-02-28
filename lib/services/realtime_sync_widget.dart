import 'dart:async';

import 'package:flutter/material.dart';
import 'package:school_attendance/services/hybrid_api_service.dart';
import 'package:school_attendance/services/websocket_service.dart';

class RealtimeSyncWidget extends StatefulWidget {
  const RealtimeSyncWidget({super.key});

  @override
  _RealtimeSyncWidgetState createState() => _RealtimeSyncWidgetState();
}

class _RealtimeSyncWidgetState extends State<RealtimeSyncWidget> {
  Map<String, dynamic>? _syncStatus;
  List<Map<String, dynamic>> _recentChanges = [];
  bool _isLoading = false;
  bool _isWebSocketConnected = false;

  late StreamSubscription<Map<String, dynamic>> _syncStatusSubscription;
  late StreamSubscription<Map<String, dynamic>> _syncUpdateSubscription;
  late StreamSubscription<Map<String, dynamic>> _databaseChangeSubscription;

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
    _loadSyncStatus();
  }

  void _initializeWebSocket() async {
    // Initialize WebSocket service
    WebSocketService.instance.initializeStreams();

    // Connect to WebSocket
    await WebSocketService.instance.connect();

    // Set up stream subscriptions
    _syncStatusSubscription = WebSocketService.instance.syncStatusStream.listen(
      (status) {
        if (mounted) {
          setState(() {
            _syncStatus = status;
          });
        }
      },
    );

    _syncUpdateSubscription = WebSocketService.instance.syncUpdateStream.listen(
      (update) {
        if (mounted) {
          _handleSyncUpdate(update);
        }
      },
    );

    _databaseChangeSubscription = WebSocketService.instance.databaseChangeStream
        .listen((change) {
          if (mounted) {
            _handleDatabaseChange(change);
          }
        });

    // Subscribe to sync updates
    WebSocketService.instance.subscribeToSyncUpdates();

    // Update connection status
    setState(() {
      _isWebSocketConnected = WebSocketService.instance.isConnected;
    });
  }

  void _handleSyncUpdate(Map<String, dynamic> update) {
    if (update.containsKey('status')) {
      // This is a sync trigger response
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(update['message'] ?? 'Sync update received'),
          backgroundColor:
              update['status'] == 'success' ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _handleDatabaseChange(Map<String, dynamic> change) {
    if (change['type'] == 'database-change') {
      setState(() {
        _recentChanges.insert(0, {
          'tableName': change['tableName'],
          'operation': change['operation'],
          'timestamp': change['timestamp'],
          'data': change['data'],
        });

        // Keep only last 10 changes
        if (_recentChanges.length > 10) {
          _recentChanges.removeLast();
        }
      });
    }
  }

  Future<void> _loadSyncStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await HybridApiService.getSyncStatus();
      setState(() {
        _syncStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _triggerFullSync() async {
    // Try WebSocket first for real-time feedback
    if (_isWebSocketConnected) {
      WebSocketService.instance.triggerFullSync();
    } else {
      // Fallback to HTTP
      final success = await HybridApiService.triggerFullSync();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Full sync triggered successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadSyncStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to trigger full sync'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _syncStatusSubscription.cancel();
    _syncUpdateSubscription.cancel();
    _databaseChangeSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isWebSocketConnected ? Icons.wifi : Icons.wifi_off,
                  color: _isWebSocketConnected ? Colors.green : Colors.grey,
                ),
                SizedBox(width: 8),
                Text(
                  'Real-time Database Sync',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                if (_isWebSocketConnected)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),

            if (_isLoading) ...[
              Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Loading sync status...'),
                ],
              ),
            ] else if (_syncStatus != null) ...[
              _buildSyncStatusInfo(),
              SizedBox(height: 16),
              _buildActionButtons(),
            ] else ...[
              Text('Unable to load sync status'),
            ],

            if (_recentChanges.isNotEmpty) ...[
              SizedBox(height: 16),
              _buildRecentChanges(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSyncStatusInfo() {
    final isHybridMode = _syncStatus!['isHybridMode'] ?? false;
    final isLocalAvailable = _syncStatus!['isLocalAvailable'] ?? false;
    final syncQueue = _syncStatus!['syncQueue'] ?? {};

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Mode',
                isHybridMode ? 'Hybrid' : 'Cloud Only',
                isHybridMode ? Colors.green : Colors.blue,
                Icons.sync,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildStatusCard(
                'Local Server',
                isLocalAvailable ? 'Connected' : 'Disconnected',
                isLocalAvailable ? Colors.green : Colors.red,
                Icons.storage,
              ),
            ),
          ],
        ),

        if (isHybridMode) ...[
          SizedBox(height: 12),
          _buildQueueStatus(syncQueue),
        ],
      ],
    );
  }

  Widget _buildStatusCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueStatus(Map<String, dynamic> queue) {
    final pending = queue['pending'] ?? 0;
    final completed = queue['completed'] ?? 0;
    final failed = queue['failed'] ?? 0;

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sync Queue',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildQueueItem('Pending', pending, Colors.orange),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildQueueItem('Completed', completed, Colors.green),
              ),
              SizedBox(width: 8),
              Expanded(child: _buildQueueItem('Failed', failed, Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _triggerFullSync,
            icon: Icon(Icons.sync),
            label: Text('Full Sync'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _loadSyncStatus,
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChanges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Changes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: _recentChanges.length,
            itemBuilder: (context, index) {
              final change = _recentChanges[index];
              return ListTile(
                dense: true,
                leading: Icon(
                  _getOperationIcon(change['operation']),
                  color: _getOperationColor(change['operation']),
                  size: 20,
                ),
                title: Text(
                  '${change['operation']} ${change['tableName']}',
                  style: TextStyle(fontSize: 12),
                ),
                subtitle: Text(
                  _formatTimestamp(change['timestamp']),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getOperationIcon(String? operation) {
    switch (operation) {
      case 'create':
        return Icons.add;
      case 'update':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      default:
        return Icons.info;
    }
  }

  Color _getOperationColor(String? operation) {
    switch (operation) {
      case 'create':
        return Colors.green;
      case 'update':
        return Colors.blue;
      case 'delete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}:'
          '${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
