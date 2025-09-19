import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'db/database_service.dart';
import 'services/logging_service.dart';
import 'providers/expense_provider.dart';
import 'ui/main_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize logging service
  LoggingService().init();
  
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
        theme: ThemeData.dark().copyWith(
          primarySwatch: Colors.purple,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
        home: const MainScaffold(),
      ),
    );
  }
}
