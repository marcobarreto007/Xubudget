// WHY: Export service for generating CSV/XLSX files from expense data
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/expense.dart';

class ExportService {
  Future<String> exportToCSV(List<Expense> expenses) async {
    // Create a simple CSV export
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filePath = '${directory.path}/expenses_$timestamp.csv';
    
    final file = File(filePath);
    final csvContent = StringBuffer();
    
    // CSV header
    csvContent.writeln('Date,Description,Amount,Category,Source');
    
    // CSV data
    for (final expense in expenses) {
      csvContent.writeln('${expense.date.toIso8601String()},${expense.description},${expense.amount},${expense.category},${expense.source.name}');
    }
    
    await file.writeAsString(csvContent.toString());
    return filePath;
  }
}