import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'db/database_service.dart';
import 'services/logging_service.dart'; // Import logger
import 'ui/main_scaffold.dart'; // Import the new scaffold

// ... (imports existentes)

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xubudget',
      theme: ThemeData.dark(),
      home: const MainScaffold(), // Use MainScaffold as the home
    );
  }
}
