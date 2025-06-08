import 'dart:async';
import 'package:flutter/material.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin_platform_interface.dart';

import 'services/permissions_service.dart';
import 'services/printer_service.dart';
import 'widgets/status_widget.dart';
import 'widgets/printer_discovery_widget.dart';
import 'widgets/printer_controls_widget.dart';
import 'widgets/action_log_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PrinterService _printerService = PrinterService();
  
  // State variables
  String _platformVersion = 'Unknown';
  List<DiscoveredPrinterInfo> _discoveredPrinters = [];
  PrinterStatusInfo? _currentStatus;
  bool _isConnected = false;
  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isPrinting = false;
  
  // Error and logging
  String? _lastError;
  final List<String> _errorLog = [];
  final List<String> _actionLog = [];

  @override
  void initState() {
    super.initState();
    _initializePlatform();
    _checkPermissionsOnStartup();
  }

  @override
  void dispose() {
    _printerService.dispose();
    super.dispose();
  }

  // Initialization
  Future<void> _initializePlatform() async {
    _logAction('Initializing platform...');
    try {
      final platformVersion = await _printerService.getPlatformVersion();
      _logAction('Platform version: $platformVersion');
      setState(() {
        _platformVersion = platformVersion;
      });
    } catch (e) {
      _logError('Platform init failed: $e');
      setState(() {
        _platformVersion = 'Failed to get platform version';
      });
    }
  }

  Future<void> _checkPermissionsOnStartup() async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    _logAction('Checking initial permissions...');
    
    final hasPermissions = await PermissionsService.checkPermissionsStatus();
    if (!hasPermissions) {
      _logAction('Some permissions are missing. Showing permission dialog...');
      
      if (mounted) {
        PermissionsService.showPermissionsDialog(context, _checkAndRequestPermissions);
      }
    } else {
      _logAction('All permissions already granted');
    }
  }

  // Permission handling
  Future<void> _checkAndRequestPermissions() async {
    final granted = await PermissionsService.checkAndRequestPermissions();
    if (granted) {
      _logAction('All permissions granted');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All permissions granted!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      _logError('Required permissions not granted. Please enable Bluetooth and Location permissions.');
      if (mounted) {
        PermissionsService.showLocationPermissionExplanationDialog(context);
      }
    }
  }

  // Printer discovery
  Future<void> _discoverPrinters() async {
    _clearError();
    _logAction('Checking permissions...');
    
    final permissionsGranted = await PermissionsService.checkAndRequestPermissions();
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
      final printers = await _printerService.discoverPrinters();
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

  // Connection management
  Future<void> _connectToPrinter(String macAddress) async {
    _clearError();
    _logAction('Connecting to $macAddress...');
    
    setState(() {
      _isConnecting = true;
    });

    try {
      final status = await _printerService.connect(macAddress);
      _logAction('Connection response received');
      
      setState(() {
        _currentStatus = status;
        _isConnected = status.isConnected;
      });

      if (_isConnected) {
        _logAction('Connected successfully! Starting status updates...');
        
        try {
          await _printerService.startStatusUpdates();
          _logAction('Status updates started');
          
          _printerService.listenToStatusUpdates(
            (status) {
              _logAction('Status update received');
              if (mounted) {
                setState(() {
                  _currentStatus = status;
                  _isConnected = status?.isConnected ?? false;
                });
              }
            },
            (error) {
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
      final success = await _printerService.disconnect();
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

  // Printing operations
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
      final success = await _printerService.printTestLabel();
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
      final success = await _printerService.printQrCode('https://flutter.dev');
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
      final success = await _printerService.printBarcode('123456789');
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

  // Status operations
  Future<void> _refreshStatus() async {
    if (!_isConnected) {
      _logError('Cannot refresh status - not connected');
      return;
    }

    _clearError();
    _logAction('Refreshing printer status...');

    try {
      final status = await _printerService.getPrinterStatus();
      _logAction('Status refreshed successfully');
      
      setState(() {
        _currentStatus = status;
        _isConnected = status.isConnected;
      });
    } catch (e) {
      _logError('Status refresh error: $e');
    }
  }

  // Logging helpers
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
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Widget
              StatusWidget(
                platformVersion: _platformVersion,
                isConnected: _isConnected,
                currentStatus: _currentStatus,
                lastError: _lastError,
                onClearError: _clearError,
                onCheckPermissions: _checkAndRequestPermissions,
                onRefreshStatus: _refreshStatus,
              ),
              const SizedBox(height: 16),
              
              // Discovery Widget
              PrinterDiscoveryWidget(
                isDiscovering: _isDiscovering,
                isConnected: _isConnected,
                isConnecting: _isConnecting,
                discoveredPrinters: _discoveredPrinters,
                onDiscoverPrinters: _discoverPrinters,
                onConnectToPrinter: _connectToPrinter,
              ),
              const SizedBox(height: 16),

              // Print Controls Widget
              PrinterControlsWidget(
                isConnected: _isConnected,
                isPrinting: _isPrinting,
                onDisconnect: _disconnect,
                onPrintTestLabel: _printTestLabel,
                onPrintQrCode: _printQrCode,
                onPrintBarcode: _printBarcode,
              ),
              const SizedBox(height: 16),

              // Action Log Widget
              ActionLogWidget(
                actionLog: _actionLog,
                onClearLogs: _clearLogs,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
