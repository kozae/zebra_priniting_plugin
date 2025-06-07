import 'package:flutter_test/flutter_test.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin_platform_interface.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockZebraPrintingPluginPlatform
    with MockPlatformInterfaceMixin
    implements ZebraPrintingPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<List<DiscoveredPrinterInfo>> discoverPrinters() => Future.value([
    const DiscoveredPrinterInfo(
      macAddress: '00:11:22:33:44:55',
      friendlyName: 'Mock Zebra Printer',
    ),
  ]);

  @override
  Future<PrinterStatusInfo> connect(String macAddress) => Future.value(
    const PrinterStatusInfo(
      isReadyToPrint: true,
      isPaperOut: false,
      isHeadOpen: false,
      isPaused: false,
      isConnected: true,
    ),
  );

  @override
  Future<bool> disconnect() => Future.value(true);

  @override
  Future<PrinterStatusInfo> getPrinterStatus() => Future.value(
    const PrinterStatusInfo(
      isReadyToPrint: true,
      isPaperOut: false,
      isHeadOpen: false,
      isPaused: false,
      isConnected: true,
    ),
  );

  @override
  Future<bool> printZpl(String zplData) => Future.value(true);

  @override
  Future<bool> setLanguageToZpl() => Future.value(true);

  @override
  Future<void> startStatusUpdates() => Future.value();

  @override
  Future<void> stopStatusUpdates() => Future.value();

  @override
  Stream<PrinterStatusInfo?> get statusUpdates => Stream.periodic(
    const Duration(seconds: 1),
    (_) => const PrinterStatusInfo(
      isReadyToPrint: true,
      isPaperOut: false,
      isHeadOpen: false,
      isPaused: false,
      isConnected: true,
    ),
  );
}

void main() {
  final ZebraPrintingPluginPlatform initialPlatform = ZebraPrintingPluginPlatform.instance;

  test('$MethodChannelZebraPrintingPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelZebraPrintingPlugin>());
  });

  test('getPlatformVersion', () async {
    ZebraPrintingPlugin zebraPrintingPlugin = ZebraPrintingPlugin();
    MockZebraPrintingPluginPlatform fakePlatform = MockZebraPrintingPluginPlatform();
    ZebraPrintingPluginPlatform.instance = fakePlatform;

    expect(await zebraPrintingPlugin.getPlatformVersion(), '42');
  });

  test('discoverPrinters', () async {
    ZebraPrintingPlugin zebraPrintingPlugin = ZebraPrintingPlugin();
    MockZebraPrintingPluginPlatform fakePlatform = MockZebraPrintingPluginPlatform();
    ZebraPrintingPluginPlatform.instance = fakePlatform;

    final printers = await zebraPrintingPlugin.discoverPrinters();
    expect(printers.length, 1);
    expect(printers.first.macAddress, '00:11:22:33:44:55');
    expect(printers.first.friendlyName, 'Mock Zebra Printer');
  });

  test('connect to printer', () async {
    ZebraPrintingPlugin zebraPrintingPlugin = ZebraPrintingPlugin();
    MockZebraPrintingPluginPlatform fakePlatform = MockZebraPrintingPluginPlatform();
    ZebraPrintingPluginPlatform.instance = fakePlatform;

    final status = await zebraPrintingPlugin.connect('00:11:22:33:44:55');
    expect(status.isConnected, true);
    expect(status.isReadyToPrint, true);
  });

  test('disconnect from printer', () async {
    ZebraPrintingPlugin zebraPrintingPlugin = ZebraPrintingPlugin();
    MockZebraPrintingPluginPlatform fakePlatform = MockZebraPrintingPluginPlatform();
    ZebraPrintingPluginPlatform.instance = fakePlatform;

    final success = await zebraPrintingPlugin.disconnect();
    expect(success, true);
  });

  test('print ZPL data', () async {
    ZebraPrintingPlugin zebraPrintingPlugin = ZebraPrintingPlugin();
    MockZebraPrintingPluginPlatform fakePlatform = MockZebraPrintingPluginPlatform();
    ZebraPrintingPluginPlatform.instance = fakePlatform;

    final success = await zebraPrintingPlugin.printZpl('^XA^FO50,50^A0N,50,50^FDTest^FS^XZ');
    expect(success, true);
  });

  test('ZPL Helper creates correct text label', () {
    final zpl = ZplHelper.createTextLabel('Hello World');
    expect(zpl, '^XA^FO50,50^A0N,50,50^FDHello World^FS^XZ');
  });

  test('ZPL Helper creates correct QR code label', () {
    final zpl = ZplHelper.createQrCodeLabel('https://example.com');
    expect(zpl, '^XA^FO50,50^BQN,2,5^FDQA,https://example.com^FS^XZ');
  });

  test('ZPL Helper creates correct barcode label', () {
    final zpl = ZplHelper.createCode128Label('123456789');
    expect(zpl, '^XA^FO50,50^BCN,100,Y,N,N^FD123456789^FS^XZ');
  });
}
