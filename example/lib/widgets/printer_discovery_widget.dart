import 'package:flutter/material.dart';
import 'package:zebra_printing_plugin/zebra_printing_plugin_platform_interface.dart';
import 'qr_scanner_widget.dart';

class PrinterDiscoveryWidget extends StatelessWidget {
  final bool isDiscovering;
  final bool isConnected;
  final bool isConnecting;
  final List<DiscoveredPrinterInfo> discoveredPrinters;
  final VoidCallback onDiscoverPrinters;
  final Function(String) onConnectToPrinter;

  const PrinterDiscoveryWidget({
    super.key,
    required this.isDiscovering,
    required this.isConnected,
    required this.isConnecting,
    required this.discoveredPrinters,
    required this.onDiscoverPrinters,
    required this.onConnectToPrinter,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Printer Discovery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isDiscovering ? null : onDiscoverPrinters,
                    icon: isDiscovering 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.search),
                    label: Text(isDiscovering ? 'Discovering...' : 'Discover Printers'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showQrScanner(context),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (discoveredPrinters.isNotEmpty) ...[
              const Text('Found Printers:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(discoveredPrinters.map((printer) => Card(
                elevation: 2,
                child: ListTile(
                  leading: const Icon(Icons.print),
                  title: Text(printer.friendlyName ?? 'Unknown Printer'),
                  subtitle: Text(printer.macAddress),
                  trailing: ElevatedButton(
                    onPressed: (isConnected || isConnecting) ? null : () => onConnectToPrinter(printer.macAddress),
                    child: isConnecting 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Connect'),
                  ),
                ),
              ))),
            ] else if (!isDiscovering) ...[
              const Text('No printers found. Try discovering again or scan a QR code.', style: TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  void _showQrScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QrScannerWidget(
          onMacAddressScanned: (macAddress) {
            onConnectToPrinter(macAddress);
          },
        ),
      ),
    );
  }
}
