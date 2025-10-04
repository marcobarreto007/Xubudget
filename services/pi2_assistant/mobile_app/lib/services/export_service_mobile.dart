// WHY: Mobile/desktop export implementation writing CSV/XLSX-like files to user directory
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import '../models/expense.dart';

class ExportService {
  static const String _exportDir = 'data/exports';

  Future<Directory> _ensureExportDirectory() async {
    Directory documentsDir;
    try {
      documentsDir = await getApplicationDocumentsDirectory();
    } catch (e) {
      documentsDir = await getApplicationSupportDirectory();
    }
    final exportDir = Directory(path.join(documentsDir.path, 'Xubudget', _exportDir));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  Future<String> exportToCSV(List<Expense> expenses) async {
    final exportDir = await _ensureExportDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'expenses_$timestamp.csv';
    final filePath = path.join(exportDir.path, fileName);

    final rows = <List<dynamic>>[
      ['ID', 'Description', 'Amount', 'Category', 'Date', 'Source', 'Created At']
    ];
    for (final e in expenses) {
      rows.add([
        e.id?.toString() ?? '',
        e.description,
        e.amount.toString(),
        e.category,
        DateFormat('yyyy-MM-dd').format(e.date),
        e.source.name,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(e.createdAt),
      ]);
    }
    final csvString = const ListToCsvConverter().convert(rows);
    await File(filePath).writeAsString(csvString);
    return filePath;
  }

  Future<String> exportToXLSX(List<Expense> expenses) async {
    // simplified: generate TSV with .xlsx extension
    final exportDir = await _ensureExportDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'expenses_$timestamp.xlsx';
    final filePath = path.join(exportDir.path, fileName);

    final file = File(filePath);
    final sink = file.openWrite();
    sink.writeln('ID\tDescription\tAmount\tCategory\tDate\tSource\tCreated At');
    for (final e in expenses) {
      sink.writeln([
        e.id?.toString() ?? '',
        e.description,
        e.amount.toString(),
        e.category,
        DateFormat('yyyy-MM-dd').format(e.date),
        e.source.name,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(e.createdAt),
      ].join('\t'));
    }
    await sink.close();
    return filePath;
  }

  Future<String> getExportsDirectoryPath() async {
    final exportDir = await _ensureExportDirectory();
    return exportDir.path;
  }
}
