// WHY: Export service for CSV/XLSX file generation to data/exports/ directory
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExportService {
  static const String _exportDir = 'data/exports';

  /// Create exports directory if it doesn't exist
  Future<Directory> _ensureExportDirectory() async {
    // Get documents directory for desktop platforms
    Directory documentsDir;
    try {
      documentsDir = await getApplicationDocumentsDirectory();
    } catch (e) {
      // Fallback to application support directory
      documentsDir = await getApplicationSupportDirectory();
    }
    
    final exportDir = Directory(path.join(documentsDir.path, 'Xubudget', _exportDir));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// Export expenses to CSV format
  Future<String> exportToCSV(List<Expense> expenses) async {
    final exportDir = await _ensureExportDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'expenses_$timestamp.csv';
    final filePath = path.join(exportDir.path, fileName);
    
    final file = File(filePath);
    final sink = file.openWrite();
    
    // Write CSV header
    sink.writeln('ID,Description,Amount,Category,Date,Source,Created At');
    
    // Write data rows
    for (final expense in expenses) {
      final row = [
        expense.id?.toString() ?? '',
        _escapeCsvField(expense.description),
        expense.amount.toString(),
        _escapeCsvField(expense.category),
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.source.name,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(expense.createdAt),
      ].join(',');
      sink.writeln(row);
    }
    
    await sink.close();
    return filePath;
  }

  /// Export expenses to XLSX format (simplified as CSV for now since excel package not available)
  Future<String> exportToXLSX(List<Expense> expenses) async {
    final exportDir = await _ensureExportDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'expenses_$timestamp.xlsx';
    final filePath = path.join(exportDir.path, fileName);
    
    // For now, create as CSV with .xlsx extension until excel package is added
    // This is a simplified implementation
    final file = File(filePath);
    final sink = file.openWrite();
    
    // Write tab-separated values (simplified XLSX)
    sink.writeln('ID\tDescription\tAmount\tCategory\tDate\tSource\tCreated At');
    
    for (final expense in expenses) {
      final row = [
        expense.id?.toString() ?? '',
        expense.description,
        expense.amount.toString(),
        expense.category,
        DateFormat('yyyy-MM-dd').format(expense.date),
        expense.source.name,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(expense.createdAt),
      ].join('\t');
      sink.writeln(row);
    }
    
    await sink.close();
    return filePath;
  }

  /// Get the exports directory path for documentation purposes
  Future<String> getExportsDirectoryPath() async {
    final exportDir = await _ensureExportDirectory();
    return exportDir.path;
  }

  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}