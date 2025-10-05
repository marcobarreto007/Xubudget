// WHY: Web export implementation, returns a data URL and opens download
import 'dart:convert';
import 'dart:html' as html;
import 'package:intl/intl.dart';
import '../models/expense.dart';

class ExportService {
  Future<String> exportToCSV(List<Expense> expenses) async {
    final rows = <List<dynamic>>[
      [
        'ID',
        'Description',
        'Amount',
        'Category',
        'Date',
        'Source',
        'Created At'
      ]
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
    final csv = rows
        .map((r) =>
            r.map((c) => '"${c.toString().replaceAll('"', '""')}"').join(','))
        .join('\n');
    final bytes = utf8.encode(csv);
    final b64 = base64Encode(bytes);
    final filename =
        'expenses_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

    final anchor = html.AnchorElement(href: 'data:text/csv;base64,$b64')
      ..setAttribute('download', filename);
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove();

    return filename;
  }

  Future<String> exportToXLSX(List<Expense> expenses) async {
    // For web, reuse CSV but with .xlsx extension so the browser downloads a file
    return exportToCSV(expenses);
  }

  Future<String> getExportsDirectoryPath() async {
    return 'browser-downloads';
  }
}
