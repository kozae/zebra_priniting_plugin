import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _zebraPrintingPlugin = ZebraPrintingPlugin();
  String _platformVersion = 'Unknown';
  List<DiscoveredPrinterInfo> _discoveredPrinters = [];
  PrinterStatusInfo? _currentStatus;
  bool _isConnected = false;
  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isPrinting = false;
  StreamSubscription<PrinterStatusInfo?>? _statusSubscription;
  
  // Error tracking
  String? _lastError;
  final List<String> _errorLog = [];
  final List<String> _actionLog = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
    // Check permissions on startup
    _checkPermissionsOnStartup();
  }

  Future<void> _checkPermissionsOnStartup() async {
    // Small delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 500));
    
    _logAction('Checking initial permissions...');
    
    // Check if any permission is denied
    final bluetoothScanDenied = await Permission.bluetoothScan.isDenied;
    final bluetoothConnectDenied = await Permission.bluetoothConnect.isDenied;
    final locationDenied = await Permission.locationWhenInUse.isDenied;
    
    if (bluetoothScanDenied || bluetoothConnectDenied || locationDenied) {
      _logAction('Some permissions are missing. Showing permission dialog...');
      
      if (mounted) {
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
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _checkAndRequestPermissions();
                },
                child: const Text('Grant Permissions'),
              ),
            ],
          ),
        );
      }
    } else {
      _logAction('All permissions already granted');
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _zebraPrintingPlugin.disconnect();
    super.dispose();
  }

  void _logAction(String action) {
    setState(() {
      _actionLog.insert(0, '${DateTime.now().toString().substring(11, 19)}: $action');
      if (_actionLog.length > 10) _actionLog.removeLast();
    });
  }

  void _logError(String error) {
    setState(() {
      _lastError = error;
      _errorLog.insert(0, '${DateTime.now().toString().substring(11, 19)}: $error');
      if (_errorLog.length > 10) _errorLog.removeLast();
    });
    _logAction('ERROR: $error');
  }

  void _clearError() {
    setState(() {
      _lastError = null;
    });
  }

  Future<void> initPlatformState() async {
    _logAction('Initializing platform...');
    String platformVersion;
    try {
      platformVersion = await _zebraPrintingPlugin.getPlatformVersion() ?? 'Unknown platform version';
      _logAction('Platform version: $platformVersion');
    } catch (e) {
      platformVersion = 'Failed to get platform version';
      _logError('Platform init failed: $e');
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _discoverPrinters() async {
    _clearError();
    _logAction('Checking permissions...');
    
    // Check and request permissions first
    final permissionsGranted = await _checkAndRequestPermissions();
    if (!permissionsGranted) {
      _logError('Required permissions not granted. Please enable Bluetooth and Location permissions.');
      return;
    }
    
    _logAction('Starting printer discovery...');
    
    setState(() {
      _isDiscovering = true;
      _discoveredPrinters.clear();
    });

    try {
      final printers = await _zebraPrintingPlugin.discoverPrinters();
      _logAction('Discovery completed. Found ${printers.length} printers');
      
      for (var printer in printers) {
        _logAction('Found: ${printer.friendlyName} (${printer.macAddress})');
      }
      
      setState(() {
        _discoveredPrinters = printers;
      });
    } catch (e) {
      _logError('Discovery failed: $e');
    } finally {
      setState(() {
        _isDiscovering = false;
      });
    }
  }

  Future<bool> _checkAndRequestPermissions() async {
    // For Android 12+ (API 31+)
    if (await Permission.bluetoothScan.isDenied) {
      _logAction('Requesting Bluetooth Scan permission...');
      final status = await Permission.bluetoothScan.request();
      if (!status.isGranted) {
        _logError('Bluetooth Scan permission denied');
        return false;
      }
    }
    
    if (await Permission.bluetoothConnect.isDenied) {
      _logAction('Requesting Bluetooth Connect permission...');
      final status = await Permission.bluetoothConnect.request();
      if (!status.isGranted) {
        _logError('Bluetooth Connect permission denied');
        return false;
      }
    }
    
    // Location permission is required for Bluetooth scanning on Android
    if (await Permission.locationWhenInUse.isDenied) {
      _logAction('Requesting Location permission (required for Bluetooth)...');
      final status = await Permission.locationWhenInUse.request();
      if (!status.isGranted) {
        _logError('Location permission denied (required for Bluetooth scanning)');
        
        // Show dialog explaining why location is needed
        if (mounted) {
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
        return false;
      }
    }
    
    // Check if Bluetooth is enabled
    final bluetoothStatus = await Permission.bluetooth.status;
    if (!bluetoothStatus.isGranted) {
      _logError('Bluetooth is not enabled. Please enable Bluetooth in device settings.');
      return false;
    }
    
    _logAction('All permissions granted');
    return true;
  }

  Future<void> _connectToPrinter(String macAddress) async {
    _clearError();
    _logAction('Connecting to $macAddress...');
    
    setState(() {
      _isConnecting = true;
    });

    try {
      final status = await _zebraPrintingPlugin.connect(macAddress);
      _logAction('Connection response received');
      
      setState(() {
        _currentStatus = status;
        _isConnected = status.isConnected;
      });

      if (_isConnected) {
        _logAction('Connected successfully! Starting status updates...');
        
        // Start listening to status updates
        try {
          await _zebraPrintingPlugin.startStatusUpdates();
          _logAction('Status updates started');
          
          _statusSubscription = _zebraPrintingPlugin.statusUpdates.listen(
            (status) {
              _logAction('Status update received');
              if (mounted) {
                setState(() {
                  _currentStatus = status;
                  _isConnected = status?.isConnected ?? false;
                });
              }
            },
            onError: (error) {
              _logError('Status stream error: $error');
            },
          );
        } catch (e) {
          _logError('Failed to start status updates: $e');
        }
      } else {
        _logError('Connection failed - status shows not connected');
      }
    } catch (e) {
      _logError('Connection error: $e');
      setState(() {
        _isConnected = false;
        _currentStatus = null;
      });
    } finally {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Future<void> _disconnect() async {
    _clearError();
    _logAction('Disconnecting...');
    
    try {
      await _zebraPrintingPlugin.stopStatusUpdates();
      _logAction('Status updates stopped');
      
      _statusSubscription?.cancel();
      _statusSubscription = null;

      final success = await _zebraPrintingPlugin.disconnect();
      _logAction('Disconnect result: $success');
      
      setState(() {
        _isConnected = false;
        _currentStatus = null;
      });

      if (success) {
        _logAction('Disconnected successfully');
      } else {
        _logError('Disconnect returned false');
      }
    } catch (e) {
      _logError('Disconnect error: $e');
    }
  }

  Future<void> _printTestLabel() async {
    if (!_isConnected) {
      _logError('Cannot print - not connected to printer');
      return;
    }

    _clearError();
    _logAction('Printing test label...');
    
    setState(() {
      _isPrinting = true;
    });

    try {
      final zpl = ZplHelper.createTextLabel('Hello from Flutter!');
      _logAction('ZPL created: ${zpl.substring(0, 20)}...');
      
      final success = await _zebraPrintingPlugin.printZpl(zpl);
      _logAction('Print result: $success');
      
      if (success) {
        _logAction('Print job completed successfully!');
      } else {
        _logError('Print job failed - returned false');
      }
    } catch (e) {
      _logError('Print error: $e');
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  Future<void> _printQrCode() async {
    if (!_isConnected) {
      _logError('Cannot print QR code - not connected to printer');
      return;
    }

    _clearError();
    _logAction('Printing QR code...');
    
    setState(() {
      _isPrinting = true;
    });

    try {
      final zpl = ZplHelper.createQrCodeLabel('https://flutter.dev');
      _logAction('QR ZPL created: ${zpl.substring(0, 20)}...');
      
      final success = await _zebraPrintingPlugin.printZpl(zpl);
      _logAction('QR print result: $success');
      
      if (success) {
        _logAction('QR Code printed successfully!');
      } else {
        _logError('QR Code print failed - returned false');
      }
    } catch (e) {
      _logError('QR Code print error: $e');
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  Future<void> _printBarcode() async {
    if (!_isConnected) {
      _logError('Cannot print barcode - not connected to printer');
      return;
    }

    _clearError();
    _logAction('Printing barcode...');
    
    setState(() {
      _isPrinting = true;
    });

    try {
      final zpl = ZplHelper.createCode128Label('123456789');
      _logAction('Barcode ZPL created: ${zpl.substring(0, 20)}...');
      
      final success = await _zebraPrintingPlugin.printZpl(zpl);
      _logAction('Barcode print result: $success');
      
      if (success) {
        _logAction('Barcode printed successfully!');
      } else {
        _logError('Barcode print failed - returned false');
      }
    } catch (e) {
      _logError('Barcode print error: $e');
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  Future<void> _refreshStatus() async {
    if (!_isConnected) {
      _logError('Cannot refresh status - not connected');
      return;
    }

    _clearError();
    _logAction('Refreshing printer status...');

    try {
      final status = await _zebraPrintingPlugin.getPrinterStatus();
      _logAction('Status refreshed successfully');
      
      setState(() {
        _currentStatus = status;
        _isConnected = status.isConnected;
      });
    } catch (e) {
      _logError('Status refresh error: $e');
    }
  }

  void _clearLogs() {
    setState(() {
      _actionLog.clear();
      _errorLog.clear();
      _lastError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Zebra Printer Plugin Demo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearLogs,
              tooltip: 'Clear Logs',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current Error Display
              if (_lastError != null)
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
                              onPressed: _clearError,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(_lastError!, style: const TextStyle(color: Colors.red)),
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
                      Text('Platform: $_platformVersion'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('Connection: ${_isConnected ? "Connected" : "Disconnected"}'),
                          const SizedBox(width: 8),
                          Icon(
                            _isConnected ? Icons.check_circle : Icons.cancel,
                            color: _isConnected ? Colors.green : Colors.red,
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Permission Check Button
                      ElevatedButton.icon(
                        onPressed: () async {
                          final granted = await _checkAndRequestPermissions();
                          if (granted) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('All permissions granted!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.security),
                        label: const Text('Check Permissions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                      if (_currentStatus != null) ...[
                        const SizedBox(height: 8),
                        const Divider(),
                        const Text('Printer Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        _buildStatusRow('Ready to Print', _currentStatus!.isReadyToPrint),
                        _buildStatusRow('Paper Out', _currentStatus!.isPaperOut),
                        _buildStatusRow('Head Open', _currentStatus!.isHeadOpen),
                        _buildStatusRow('Paused', _currentStatus!.isPaused),
                        if (_currentStatus!.errorMessage != null)
                          Text('Error: ${_currentStatus!.errorMessage}', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _refreshStatus,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh Status'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Discovery Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Printer Discovery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isDiscovering ? null : _discoverPrinters,
                        icon: _isDiscovering 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.search),
                        label: Text(_isDiscovering ? 'Discovering...' : 'Discover Printers'),
                      ),
                      const SizedBox(height: 16),
                      if (_discoveredPrinters.isNotEmpty) ...[
                        const Text('Found Printers:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...(_discoveredPrinters.map((printer) => Card(
                          elevation: 2,
                          child: ListTile(
                            leading: const Icon(Icons.print),
                            title: Text(printer.friendlyName ?? 'Unknown Printer'),
                            subtitle: Text(printer.macAddress),
                            trailing: ElevatedButton(
                              onPressed: (_isConnected || _isConnecting) ? null : () => _connectToPrinter(printer.macAddress),
                              child: _isConnecting 
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Connect'),
                            ),
                          ),
                        ))),
                      ] else if (!_isDiscovering) ...[
                        const Text('No printers found. Try discovering again.', style: TextStyle(color: Colors.grey)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Connection Controls
              if (_isConnected) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Connection Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _disconnect,
                          icon: const Icon(Icons.close),
                          label: const Text('Disconnect'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Print Controls
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Print Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (_isPrinting)
                          const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isPrinting ? null : _printTestLabel,
                              icon: const Icon(Icons.print),
                              label: const Text('Print Text'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isPrinting ? null : _printQrCode,
                              icon: const Icon(Icons.qr_code),
                              label: const Text('Print QR Code'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isPrinting ? null : _printBarcode,
                              icon: const Icon(Icons.barcode_reader),
                              label: const Text('Print Barcode'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action Log
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Action Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListView.builder(
                          itemCount: _actionLog.length,
                          itemBuilder: (context, index) {
                            final log = _actionLog[index];
                            final isError = log.contains('ERROR:');
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              child: Text(
                                log,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: isError ? Colors.red : Colors.black87,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
