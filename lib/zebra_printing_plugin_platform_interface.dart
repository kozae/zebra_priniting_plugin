import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'zebra_printing_plugin_method_channel.dart';

/// Data model for discovered printer information
class DiscoveredPrinterInfo {
  final String macAddress;
  final String? friendlyName;

  const DiscoveredPrinterInfo({
    required this.macAddress,
    this.friendlyName,
  });

  Map<String, dynamic> toMap() {
    return {
      'macAddress': macAddress,
      'friendlyName': friendlyName,
    };
  }

  factory DiscoveredPrinterInfo.fromMap(Map<String, dynamic> map) {
    return DiscoveredPrinterInfo(
      macAddress: map['macAddress'] as String,
      friendlyName: map['friendlyName'] as String?,
    );
  }

  @override
  String toString() => 'DiscoveredPrinterInfo(macAddress: $macAddress, friendlyName: $friendlyName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiscoveredPrinterInfo &&
        other.macAddress == macAddress &&
        other.friendlyName == friendlyName;
  }

  @override
  int get hashCode => macAddress.hashCode ^ friendlyName.hashCode;
}

/// Data model for printer status information
class PrinterStatusInfo {
  final bool isReadyToPrint;
  final bool isPaperOut;
  final bool isHeadOpen;
  final bool isPaused;
  final bool isConnected;
  final String? errorMessage;

  const PrinterStatusInfo({
    required this.isReadyToPrint,
    required this.isPaperOut,
    required this.isHeadOpen,
    required this.isPaused,
    required this.isConnected,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'isReadyToPrint': isReadyToPrint,
      'isPaperOut': isPaperOut,
      'isHeadOpen': isHeadOpen,
      'isPaused': isPaused,
      'isConnected': isConnected,
      'errorMessage': errorMessage,
    };
  }

  factory PrinterStatusInfo.fromMap(Map<String, dynamic> map) {
    return PrinterStatusInfo(
      isReadyToPrint: map['isReadyToPrint'] as bool,
      isPaperOut: map['isPaperOut'] as bool,
      isHeadOpen: map['isHeadOpen'] as bool,
      isPaused: map['isPaused'] as bool,
      isConnected: map['isConnected'] as bool,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  @override
  String toString() {
    return 'PrinterStatusInfo(isReadyToPrint: $isReadyToPrint, isPaperOut: $isPaperOut, '
           'isHeadOpen: $isHeadOpen, isPaused: $isPaused, isConnected: $isConnected, '
           'errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrinterStatusInfo &&
        other.isReadyToPrint == isReadyToPrint &&
        other.isPaperOut == isPaperOut &&
        other.isHeadOpen == isHeadOpen &&
        other.isPaused == isPaused &&
        other.isConnected == isConnected &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return isReadyToPrint.hashCode ^
        isPaperOut.hashCode ^
        isHeadOpen.hashCode ^
        isPaused.hashCode ^
        isConnected.hashCode ^
        errorMessage.hashCode;
  }
}

/// Custom exception for Zebra printer operations
class ZebraPrinterException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const ZebraPrinterException(this.message, {this.code, this.details});

  @override
  String toString() => 'ZebraPrinterException: $message';
}

abstract class ZebraPrintingPluginPlatform extends PlatformInterface {
  /// Constructs a ZebraPrintingPluginPlatform.
  ZebraPrintingPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static ZebraPrintingPluginPlatform _instance = MethodChannelZebraPrintingPlugin();

  /// The default instance of [ZebraPrintingPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelZebraPrintingPlugin].
  static ZebraPrintingPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ZebraPrintingPluginPlatform] when
  /// they register themselves.
  static set instance(ZebraPrintingPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Gets the platform version
  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Discovers available Zebra printers via Bluetooth
  Future<List<DiscoveredPrinterInfo>> discoverPrinters() {
    throw UnimplementedError('discoverPrinters() has not been implemented.');
  }

  /// Connects to a Zebra printer using its MAC address
  Future<PrinterStatusInfo> connect(String macAddress) {
    throw UnimplementedError('connect() has not been implemented.');
  }

  /// Disconnects from the currently connected printer
  Future<bool> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  /// Gets the current status of the connected printer
  Future<PrinterStatusInfo> getPrinterStatus() {
    throw UnimplementedError('getPrinterStatus() has not been implemented.');
  }

  /// Prints ZPL data to the connected printer
  Future<bool> printZpl(String zplData) {
    throw UnimplementedError('printZpl() has not been implemented.');
  }

  /// Sets the printer language to ZPL mode
  Future<bool> setLanguageToZpl() {
    throw UnimplementedError('setLanguageToZpl() has not been implemented.');
  }

  /// Starts receiving real-time status updates from the printer
  Future<void> startStatusUpdates() {
    throw UnimplementedError('startStatusUpdates() has not been implemented.');
  }

  /// Stops receiving status updates from the printer
  Future<void> stopStatusUpdates() {
    throw UnimplementedError('stopStatusUpdates() has not been implemented.');
  }

  /// Stream of printer status updates
  Stream<PrinterStatusInfo?> get statusUpdates {
    throw UnimplementedError('statusUpdates stream has not been implemented.');
  }
}
