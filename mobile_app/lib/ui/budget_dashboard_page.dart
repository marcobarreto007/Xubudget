// WHY: This is the main dashboard screen. It will display a summary of the
// budget and provide navigation to other features. For this scaffold, it
// contains only a dummy total.

import 'package:flutter/material.dart';

class BudgetDashboardPage extends StatelessWidget {
  const BudgetDashboardPage({super.key});

  static const String routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Total de despesas (dummy):'),
            Text(
              'R\$ 1,234.56',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
