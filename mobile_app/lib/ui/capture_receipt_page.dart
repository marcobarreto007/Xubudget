// WHY: This screen will handle capturing receipts using the camera or gallery
// and processing them with OCR. For the scaffold, it's a simple placeholder.

import 'package:flutter/material.dart';

class CaptureReceiptPage extends StatelessWidget {
  const CaptureReceiptPage({super.key});

  static const String routeName = '/capture';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturar Recibo (OCR)'),
      ),
      body: const Center(
        child: Text('Placeholder para a captura de recibo.'),
      ),
    );
  }
}
