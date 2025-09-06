// WHY: This screen provides a form for users to manually enter expense
// details. For the scaffold, it is just a placeholder.

import 'package:flutter/material.dart';

class ManualEntryPage extends StatelessWidget {
  const ManualEntryPage({super.key});

  static const String routeName = '/manual';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada Manual'),
      ),
      body: const Center(
        child: Text('Placeholder para a entrada manual de despesa.'),
      ),
    );
  }
}
