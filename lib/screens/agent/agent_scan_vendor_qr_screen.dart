import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cheteni_delivery/screens/agent/agent_confirm_vendor_pickup_screen.dart';

class AgentScanVendorQrScreen extends StatefulWidget {
  const AgentScanVendorQrScreen({super.key});

  @override
  State<AgentScanVendorQrScreen> createState() =>
      _AgentScanVendorQrScreenState();
}

class _AgentScanVendorQrScreenState extends State<AgentScanVendorQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _scanned = false;

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;
      // Expected format: vendor_<id>
      if (raw.startsWith('vendor_')) {
        _scanned = true;
        final vendorIdStr = raw.replaceFirst('vendor_', '');
        final vendorId = int.tryParse(vendorIdStr);
        if (vendorId != null && mounted) {
          Navigator.of(context)
              .push(MaterialPageRoute(
            builder: (_) => AgentConfirmVendorPickupScreen(vendorId: vendorId),
          ))
              .then((_) {
            if (mounted) {
              setState(() => _scanned = false);
            } else {
              _scanned = false;
            }
          });
        }
        return;
      }
    }
  }

  // Confirmation UI lives in AgentConfirmVendorPickupScreen.

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan vendor QR'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Scan the vendor\'s QR code to confirm you picked up the item.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _onDetect,
            ),
          ),
        ],
      ),
    );
  }
}
