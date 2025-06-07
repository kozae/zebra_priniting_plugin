import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'zebra_printing_plugin_platform_interface.dart';

/// An implementation of [ZebraPrintingPluginPlatform] that uses method channels.
class MethodChannelZebraPrintingPlugin extends ZebraPrintingPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('com.example.zebra_printing_plugin/methods');
  
  /// The event channel used for status updates
  @visibleForTesting
  final eventChannel = const EventChannel('com.example.zebra_printing_plugin/status');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<List<DiscoveredPrinterInfo>> discoverPrinters() async {
    try {
      final List<dynamic> result = await methodChannel.invokeMethod('discoverPrinters');
      return result.map((item) => DiscoveredPrinterInfo.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      throw ZebraPrinterException('Failed to discover printers: $e');
    }
  }

  @override
  Future<PrinterStatusInfo> connect(String macAddress) async {
    try {
      final Map<dynamic, dynamic> result = await methodChannel.invokeMethod('connect', {
        'macAddress': macAddress,
      });
      return PrinterStatusInfo.fromMap(Map<String, dynamic>.from(result));
    } catch (e) {
      throw ZebraPrinterException('Failed to connect: $e');
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      final bool result = await methodChannel.invokeMethod('disconnect');
      return result;
    } catch (e) {
      throw ZebraPrinterException('Failed to disconnect: $e');
    }
  }

  @override
  Future<PrinterStatusInfo> getPrinterStatus() async {
    try {
      final Map<dynamic, dynamic> result = await methodChannel.invokeMethod('getPrinterStatus');
      return PrinterStatusInfo.fromMap(Map<String, dynamic>.from(result));
    } catch (e) {
      throw ZebraPrinterException('Failed to get printer status: $e');
    }
  }

  @override
  Future<bool> printZpl(String zplData) async {
    try {
      final bool result = await methodChannel.invokeMethod('printZpl', {
        'zplData': zplData,
      });
      return result;
    } catch (e) {
      throw ZebraPrinterException('Failed to print: $e');
    }
  }

  @override
  Future<bool> setLanguageToZpl() async {
    try {
      final bool result = await methodChannel.invokeMethod('setLanguageToZpl');
      return result;
    } catch (e) {
      throw ZebraPrinterException('Failed to set language: $e');
    }
  }

  @override
  Future<void> startStatusUpdates() async {
    try {
      await methodChannel.invokeMethod('startStatusUpdates');
    } catch (e) {
      throw ZebraPrinterException('Failed to start status updates: $e');
    }
  }

  @override
  Future<void> stopStatusUpdates() async {
    try {
      await methodChannel.invokeMethod('stopStatusUpdates');
    } catch (e) {
      throw ZebraPrinterException('Failed to stop status updates: $e');
    }
  }

  @override
  Stream<PrinterStatusInfo?> get statusUpdates {
    return eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event == null) return null;
      return PrinterStatusInfo.fromMap(Map<String, dynamic>.from(event));
    });
  }
}
