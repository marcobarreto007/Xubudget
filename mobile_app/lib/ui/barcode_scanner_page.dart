// WHY: Barcode scanner page for product scanning functionality
import 'package:flutter/material.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de Código de Barras'),
      ),
      body: const Center(
        child: Text('Scanner de código de barras em desenvolvimento'),
      ),
    );
  }
}