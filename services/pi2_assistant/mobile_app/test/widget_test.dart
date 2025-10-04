import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:mobile_app/main.dart';
import 'package:mobile_app/providers/expense_provider.dart';

void main() {
  group('Xubudget App Tests', () {
    testWidgets('App starts with main scaffold and dashboard', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that the app starts with the main scaffold
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Xubudget Dashboard'), findsOneWidget);
    });

    testWidgets('Provider is correctly initialized', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      
      // Find the provider in the widget tree
      final BuildContext context = tester.element(find.byType(MaterialApp));
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      
      expect(provider, isNotNull);
      expect(provider.expenses, isEmpty);
    });
  });
}