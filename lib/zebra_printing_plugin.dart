import 'zebra_printing_plugin_platform_interface.dart';

/// Main plugin class for Zebra Printer integration
class ZebraPrintingPlugin {
  
  /// Gets the platform version
  Future<String?> getPlatformVersion() {
    return ZebraPrintingPluginPlatform.instance.getPlatformVersion();
  }

  /// Discovers available Zebra printers via Bluetooth
  /// 
  /// Returns a list of [DiscoveredPrinterInfo] containing MAC addresses
  /// and friendly names of discovered printers.
  /// 
  /// Throws [ZebraPrinterException] if discovery fails.
  Future<List<DiscoveredPrinterInfo>> discoverPrinters() {
    return ZebraPrintingPluginPlatform.instance.discoverPrinters();
  }

  /// Connects to a Zebra printer using its MAC address
  /// 
  /// [macAddress] - The Bluetooth MAC address of the printer
  /// 
  /// Returns [PrinterStatusInfo] with the initial connection status.
  /// 
  /// Throws [ZebraPrinterException] if connection fails.
  Future<PrinterStatusInfo> connect(String macAddress) {
    return ZebraPrintingPluginPlatform.instance.connect(macAddress);
  }

  /// Disconnects from the currently connected printer
  /// 
  /// Returns `true` if disconnection was successful, `false` otherwise.
  Future<bool> disconnect() {
    return ZebraPrintingPluginPlatform.instance.disconnect();
  }

  /// Gets the current status of the connected printer
  /// 
  /// Returns [PrinterStatusInfo] with current printer state.
  /// 
  /// Throws [ZebraPrinterException] if unable to get status.
  Future<PrinterStatusInfo> getPrinterStatus() {
    return ZebraPrintingPluginPlatform.instance.getPrinterStatus();
  }

  /// Prints ZPL (Zebra Programming Language) data to the connected printer
  /// 
  /// [zplData] - The ZPL commands to send to the printer
  /// 
  /// Returns `true` if printing was successful.
  /// 
  /// Throws [ZebraPrinterException] if printing fails.
  /// 
  /// Example ZPL for a simple label:
  /// ```
  /// ^XA
  /// ^FO50,50^A0N,50,50^FDHello World^FS
  /// ^XZ
  /// ```
  Future<bool> printZpl(String zplData) {
    return ZebraPrintingPluginPlatform.instance.printZpl(zplData);
  }

  /// Sets the printer language to ZPL mode
  /// 
  /// This ensures the printer is configured to interpret ZPL commands.
  /// Should be called after connecting to ensure compatibility.
  /// 
  /// Returns `true` if language setting was successful.
  Future<bool> setLanguageToZpl() {
    return ZebraPrintingPluginPlatform.instance.setLanguageToZpl();
  }

  /// Starts receiving real-time status updates from the printer
  /// 
  /// Use [statusUpdates] stream to listen for updates.
  /// 
  /// Throws [ZebraPrinterException] if unable to start monitoring.
  Future<void> startStatusUpdates() {
    return ZebraPrintingPluginPlatform.instance.startStatusUpdates();
  }

  /// Stops receiving status updates from the printer
  /// 
  /// Throws [ZebraPrinterException] if unable to stop monitoring.
  Future<void> stopStatusUpdates() {
    return ZebraPrintingPluginPlatform.instance.stopStatusUpdates();
  }

  /// Stream of printer status updates
  /// 
  /// Listen to this stream to receive real-time printer status changes.
  /// Call [startStatusUpdates] first to begin monitoring.
  /// 
  /// Example usage:
  /// ```dart
  /// await plugin.startStatusUpdates();
  /// plugin.statusUpdates.listen((status) {
  ///   if (status?.isReadyToPrint == true) {
  ///     print('Printer is ready!');
  ///   }
  /// });
  /// ```
  Stream<PrinterStatusInfo?> get statusUpdates {
    return ZebraPrintingPluginPlatform.instance.statusUpdates;
  }
}

/// ZPL Helper class for common ZPL commands and templates
class ZplHelper {
  
  /// Creates a simple text label with the given content
  /// 
  /// [text] - The text to print
  /// [x] - X position (default: 50)
  /// [y] - Y position (default: 50)
  /// [fontSize] - Font size (default: 50)
  static String createTextLabel(String text, {int x = 50, int y = 50, int fontSize = 50}) {
    return '^XA^FO$x,$y^A0N,$fontSize,$fontSize^FD$text^FS^XZ';
  }

  /// Creates a QR code label
  /// 
  /// [data] - The data to encode in the QR code
  /// [x] - X position (default: 50)
  /// [y] - Y position (default: 50)
  /// [size] - QR code size factor (default: 5)
  static String createQrCodeLabel(String data, {int x = 50, int y = 50, int size = 5}) {
    return '^XA^FO$x,$y^BQN,2,$size^FDQA,$data^FS^XZ';
  }

  /// Creates a Code 128 barcode label
  /// 
  /// [data] - The data to encode in the barcode
  /// [x] - X position (default: 50)
  /// [y] - Y position (default: 50)
  /// [height] - Barcode height (default: 100)
  static String createCode128Label(String data, {int x = 50, int y = 50, int height = 100}) {
    return '^XA^FO$x,$y^BCN,$height,Y,N,N^FD$data^FS^XZ';
  }

  /// Creates a label with both text and barcode
  /// 
  /// [text] - The text to display
  /// [barcodeData] - The data for the barcode
  /// [textX] - Text X position (default: 50)
  /// [textY] - Text Y position (default: 50)
  /// [barcodeX] - Barcode X position (default: 50)
  /// [barcodeY] - Barcode Y position (default: 150)
  static String createTextAndBarcodeLabel(
    String text,
    String barcodeData, {
    int textX = 50,
    int textY = 50,
    int barcodeX = 50,
    int barcodeY = 150,
  }) {
    return '^XA'
           '^FO$textX,$textY^A0N,40,40^FD$text^FS'
           '^FO$barcodeX,$barcodeY^BCN,100,Y,N,N^FD$barcodeData^FS'
           '^XZ';
  }
}
