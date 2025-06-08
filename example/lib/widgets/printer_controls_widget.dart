import 'package:flutter/material.dart';

class PrinterControlsWidget extends StatelessWidget {
  final bool isConnected;
  final bool isPrinting;
  final VoidCallback onDisconnect;
  final VoidCallback onPrintTestLabel;
  final VoidCallback onPrintQrCode;
  final VoidCallback onPrintBarcode;

  const PrinterControlsWidget({
    super.key,
    required this.isConnected,
    required this.isPrinting,
    required this.onDisconnect,
    required this.onPrintTestLabel,
    required this.onPrintQrCode,
    required this.onPrintBarcode,
  });

  @override
  Widget build(BuildContext context) {
    if (!isConnected) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Connection Controls
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connection Controls', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: onDisconnect,
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
                if (isPrinting)
                  const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isPrinting ? null : onPrintTestLabel,
                      icon: const Icon(Icons.print),
                      label: const Text('Print Text'),
                    ),
                    ElevatedButton.icon(
                      onPressed: isPrinting ? null : onPrintQrCode,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Print QR Code'),
                    ),
                    ElevatedButton.icon(
                      onPressed: isPrinting ? null : onPrintBarcode,
                      icon: const Icon(Icons.barcode_reader),
                      label: const Text('Print Barcode'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
