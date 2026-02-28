import 'package:flutter/material.dart';
import 'package:school_attendance/services/offline_first_service.dart';

class OfflineFirstWidget extends StatefulWidget {
  @override
  _OfflineFirstWidgetState createState() => _OfflineFirstWidgetState();
}

class _OfflineFirstWidgetState extends State<OfflineFirstWidget> {
  Map<String, dynamic>? _offlineStatus;
  bool _isLoading = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadOfflineStatus();
    _initializeOfflineService();
  }

  Future<void> _initializeOfflineService() async {
    await OfflineFirstService.instance.initialize();
  }

  Future<void> _loadOfflineStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status = await OfflineFirstService.instance.getOfflineStatus();
      setState(() {
        _offlineStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _forceSyncAll() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final result = await OfflineFirstService.instance.forceSyncAll();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sync completed: ${result['success']} successful, ${result['failed']} failed',
          ),
          backgroundColor: result['failed'] > 0 ? Colors.orange : Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      _loadOfflineStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _checkConnectivity() async {
    await OfflineFirstService.instance.checkConnectivity();
    _loadOfflineStatus();
  }

  Future<void> _clearSyncedOperations() async {
    await OfflineFirstService.instance.clearSyncedOperations();
    _loadOfflineStatus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleared synced operations'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading offline status...'),
            ],
          ),
        ),
      );
    }

    if (_offlineStatus == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Unable to load offline status'),
        ),
      );
    }

    final isDesktopMode = _offlineStatus!['isDesktopMode'] ?? false;
    final isOnline = _offlineStatus!['isOnline'] ?? true;
    final pendingOperations = _offlineStatus!['pendingOperations'] ?? 0;
    final mode = _offlineStatus!['mode'] ?? 'Unknown';
    final connectivity = _offlineStatus!['connectivity'] ?? 'Unknown';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isDesktopMode ? Icons.desktop_windows : Icons.phone_android,
                  color: isDesktopMode ? Colors.green : Colors.blue,
                ),
                SizedBox(width: 8),
                Text(
                  'Offline-First Database Sync',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isOnline
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isOnline
                              ? Colors.green.withValues(alpha: 0.3)
                              : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    connectivity,
                    style: TextStyle(
                      color: isOnline ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),

            _buildStatusInfo(isDesktopMode, isOnline, mode, pendingOperations),
            SizedBox(height: 16),

            if (isDesktopMode) ...[
              _buildPendingOperationsList(),
              SizedBox(height: 16),
              _buildActionButtons(),
            ] else ...[
              _buildMobileInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusInfo(
    bool isDesktopMode,
    bool isOnline,
    String mode,
    int pendingOperations,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatusCard(
                'Mode',
                mode,
                isDesktopMode ? Colors.green : Colors.blue,
                isDesktopMode ? Icons.desktop_windows : Icons.phone_android,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _buildStatusCard(
                'Connectivity',
                isOnline ? 'Online' : 'Offline',
                isOnline ? Colors.green : Colors.orange,
                isOnline ? Icons.cloud_done : Icons.cloud_off,
              ),
            ),
          ],
        ),

        if (isDesktopMode) ...[
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Operations',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: pendingOperations > 0 ? Colors.orange : Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pendingOperations.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildPendingOperationsList() {
    final pendingOps = OfflineFirstService.instance.pendingOperations;

    if (pendingOps.isEmpty) {
      return Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            'No pending operations',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(
              'Pending Operations',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: pendingOps.length,
              itemBuilder: (context, index) {
                final operation = pendingOps[index];
                return ListTile(
                  dense: true,
                  leading: Icon(
                    _getOperationIcon(operation['operation']),
                    color: _getOperationColor(operation['operation']),
                    size: 20,
                  ),
                  title: Text(
                    '${operation['operation']} ${operation['endpoint']}',
                    style: TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    _formatTimestamp(operation['timestamp']),
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  trailing:
                      operation['retryCount'] > 0
                          ? Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Retry ${operation['retryCount']}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                          : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSyncing ? null : _forceSyncAll,
            icon: _isSyncing ? Icon(Icons.front_loader) : Icon(Icons.sync),
            label: Text(_isSyncing ? 'Syncing...' : 'Force Sync'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _checkConnectivity,
            icon: Icon(Icons.refresh),
            label: Text('Check Connection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _clearSyncedOperations,
            icon: Icon(Icons.clear),
            label: Text('Clear'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.phone_android, color: Colors.blue, size: 32),
          SizedBox(height: 8),
          Text(
            'Mobile Mode',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'All changes are stored directly in the cloud database',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
