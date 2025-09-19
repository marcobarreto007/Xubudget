import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/budget_dashboard_page.dart';
import 'providers/expense_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ExpenseProvider(),
      child: MaterialApp(
        title: 'Xubudget',
        theme: ThemeData.dark(),
        home: const BudgetDashboardPage(),
      ),
    );
  }
}
