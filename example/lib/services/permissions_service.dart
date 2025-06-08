import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionsService {
  static Future<bool> checkAndRequestPermissions() async {
    // For Android 12+ (API 31+)
    if (await Permission.bluetoothScan.isDenied) {
      final status = await Permission.bluetoothScan.request();
      if (!status.isGranted) {
        return false;
      }
    }
    
    if (await Permission.bluetoothConnect.isDenied) {
      final status = await Permission.bluetoothConnect.request();
      if (!status.isGranted) {
        return false;
      }
    }
    
    // Location permission is required for Bluetooth scanning on Android
    if (await Permission.locationWhenInUse.isDenied) {
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        return false;
      }
    }
    
    // Check if Bluetooth is enabled
    final bluetoothStatus = await Permission.bluetooth.status;
    if (!bluetoothStatus.isGranted) {
      return false;
    }
    
    return true;
  }

  static Future<bool> checkPermissionsStatus() async {
    final bluetoothScanDenied = await Permission.bluetoothScan.isDenied;
    final bluetoothConnectDenied = await Permission.bluetoothConnect.isDenied;
    final locationDenied = await Permission.locationWhenInUse.isDenied;
    
    return !bluetoothScanDenied && !bluetoothConnectDenied && !locationDenied;
  }

  static void showPermissionsDialog(BuildContext context, VoidCallback onRequestPermissions) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Text(
          'This app needs Bluetooth and Location permissions to discover and connect to Zebra printers.\n\n'
          'Location permission is required by Android for Bluetooth scanning, but we don\'t track your location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRequestPermissions();
            },
            child: const Text('Grant Permissions'),
          ),
        ],
      ),
    );
  }

  static void showLocationPermissionExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Android requires location permission to scan for Bluetooth devices. '
          'This app only uses location for Bluetooth discovery and does not track your location.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
