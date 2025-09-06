// WHY: This is the main entry point of the application. It sets up the
// MaterialApp, defines the navigation routes, and specifies the initial
// screen. This structure allows for a clean separation of concerns and
// scalable navigation.

import 'package:flutter/material.dart';
import 'package:mobile_app/ui/budget_dashboard_page.dart';
import 'package:mobile_app/ui/capture_receipt_page.dart';
import 'package:mobile_app/ui/manual_entry_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xubudget',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Defining the routes for navigation
      initialRoute: BudgetDashboardPage.routeName,
      routes: {
        BudgetDashboardPage.routeName: (context) => const BudgetDashboardPageWithNav(),
        CaptureReceiptPage.routeName: (context) => const CaptureReceiptPage(),
        ManualEntryPage.routeName: (context) => const ManualEntryPage(),
      },
    );
  }
}

// WHY: A wrapper for the dashboard to include navigation buttons, keeping the
// core dashboard view separate from its navigation controls.
class BudgetDashboardPageWithNav extends StatelessWidget {
  const BudgetDashboardPageWithNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The actual dashboard UI is composed here.
      // We reuse the BudgetDashboardPage and add navigation controls.
      body: const BudgetDashboardPage(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, CaptureReceiptPage.routeName),
            label: const Text("OCR"),
            icon: const Icon(Icons.camera_alt),
            heroTag: 'ocr_fab', // Prevents hero animation conflicts
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, ManualEntryPage.routeName),
            label: const Text("Manual"),
            icon: const Icon(Icons.edit),
            heroTag: 'manual_fab', // Prevents hero animation conflicts
          ),
        ],
      ),
    );
  }
}
