import 'package:flutter/material.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin_platform_interface.dart';

class StatusWidget extends StatelessWidget {
  final String platformVersion;
  final bool isConnected;
  final PrinterStatusInfo? currentStatus;
  final String? lastError;
  final VoidCallback onClearError;
  final VoidCallback onCheckPermissions;
  final VoidCallback onRefreshStatus;

  const StatusWidget({
    super.key,
    required this.platformVersion,
    required this.isConnected,
    this.currentStatus,
    this.lastError,
    required this.onClearError,
    required this.onCheckPermissions,
    required this.onRefreshStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Current Error Display
        if (lastError != null)
          Card(
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text('Current Error:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: onClearError,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(lastError!, style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        
        // Status Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('System Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Platform: $platformVersion'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Connection: ${isConnected ? "Connected" : "Disconnected"}'),
                    const SizedBox(width: 8),
                    Icon(
                      isConnected ? Icons.check_circle : Icons.cancel,
                      color: isConnected ? Colors.green : Colors.red,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Permission Check Button
                ElevatedButton.icon(
                  onPressed: onCheckPermissions,
                  icon: const Icon(Icons.security),
                  label: const Text('Check Permissions'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                if (currentStatus != null) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const Text('Printer Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  _buildStatusRow('Ready to Print', currentStatus!.isReadyToPrint),
                  _buildStatusRow('Paper Out', currentStatus!.isPaperOut),
                  _buildStatusRow('Head Open', currentStatus!.isHeadOpen),
                  _buildStatusRow('Paused', currentStatus!.isPaused),
                  if (currentStatus!.errorMessage != null)
                    Text('Error: ${currentStatus!.errorMessage}', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: onRefreshStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Status'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: '),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(value ? 'Yes' : 'No'),
        ],
      ),
    );
  }
}
