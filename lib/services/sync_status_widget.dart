import 'package:flutter/material.dart';
import 'package:school_attendance/services/hybrid_api_service.dart';

class SyncStatusWidget extends StatefulWidget {
  const SyncStatusWidget({super.key});

  @override
  _SyncStatusWidgetState createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  Map<String, dynamic>? _syncStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSyncStatus();
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
    final success = await HybridApiService.triggerFullSync();
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Full sync triggered successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadSyncStatus(); // Refresh status
    } else {
      if (mounted) {
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
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading sync status...'),
            ],
          ),
        ),
      );
    }

    if (_syncStatus == null) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Unable to load sync status'),
        ),
      );
    }

    final isHybridMode = _syncStatus!['isHybridMode'] ?? false;
    final isLocalAvailable = _syncStatus!['isLocalAvailable'] ?? false;
    final syncQueue = _syncStatus!['syncQueue'] ?? {};

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHybridMode ? Icons.sync : Icons.cloud,
                  color: isHybridMode ? Colors.green : Colors.blue,
                ),
                SizedBox(width: 8),
                Text(
                  'Database Sync Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),

            if (isHybridMode) ...[
              _buildStatusRow('Mode', 'Hybrid (Cloud + Local)', Colors.green),
              _buildStatusRow(
                'Local Server',
                isLocalAvailable ? 'Connected' : 'Disconnected',
                isLocalAvailable ? Colors.green : Colors.red,
              ),
            ] else ...[
              _buildStatusRow('Mode', 'Cloud Only', Colors.blue),
              _buildStatusRow('Local Server', 'Not Available', Colors.grey),
            ],

            SizedBox(height: 16),

            if (isHybridMode) ...[
              Text(
                'Sync Queue',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              _buildQueueStatus(syncQueue),
              SizedBox(height: 16),

              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _triggerFullSync,
                    icon: Icon(Icons.sync),
                    label: Text('Trigger Full Sync'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _loadSyncStatus,
                    icon: Icon(Icons.refresh),
                    label: Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
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

    return Row(
      children: [
        Expanded(child: _buildQueueItem('Pending', pending, Colors.orange)),
        SizedBox(width: 8),
        Expanded(child: _buildQueueItem('Completed', completed, Colors.green)),
        SizedBox(width: 8),
        Expanded(child: _buildQueueItem('Failed', failed, Colors.red)),
      ],
    );
  }

  Widget _buildQueueItem(String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }
}
