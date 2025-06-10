import 'dart:async';
import 'package:zebra_printing_plugin/zebra_printing_plugin.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin_platform_interface.dart';

class ZebraPrinterService {
  final ZebraPrintingPlugin _plugin = ZebraPrintingPlugin();
  StreamSubscription<PrinterStatusInfo?>? _statusSubscription;

  // Status stream
  Stream<PrinterStatusInfo?>? get statusUpdates => _plugin.statusUpdates;

  // Discovery
  Future<List<DiscoveredPrinterInfo>> discoverPrinters() async {
    return await _plugin.discoverPrinters();
  }

  // Connection
  Future<PrinterStatusInfo> connect(String macAddress) async {
    return await _plugin.connect(macAddress);
  }

  Future<bool> disconnect() async {
    await stopStatusUpdates();
    return await _plugin.disconnect();
  }

  // Status
  Future<PrinterStatusInfo> getPrinterStatus() async {
    return await _plugin.getPrinterStatus();
  }

  Future<void> startStatusUpdates() async {
    await _plugin.startStatusUpdates();
  }

  Future<void> stopStatusUpdates() async {
    await _plugin.stopStatusUpdates();
    _statusSubscription?.cancel();
    _statusSubscription = null;
  }

  void listenToStatusUpdates(Function(PrinterStatusInfo?) onStatusUpdate, Function(dynamic) onError) {
    _statusSubscription = statusUpdates?.listen(
      onStatusUpdate,
      onError: onError,
    );
  }

  // Printing
  Future<bool> printZpl(String zpl) async {
    return await _plugin.printZpl(zpl);
  }

  Future<bool> printTestLabel() async {
    final zpl = ZplHelper.createTextLabel('Hello from Flutter!');
    return await printZpl(zpl);
  }

  Future<bool> printQrCode(String data) async {
    final zpl = ZplHelper.createQrCodeLabel(data);
    return await printZpl(zpl);
  }

  Future<bool> printBarcode(String data) async {
    final zpl = ZplHelper.createCode128Label(data);
    return await printZpl(zpl);
  }

  // Platform version
  Future<String> getPlatformVersion() async {
    return await _plugin.getPlatformVersion() ?? 'Unknown platform version';
  }

  void dispose() {
    _statusSubscription?.cancel();
  }
}
