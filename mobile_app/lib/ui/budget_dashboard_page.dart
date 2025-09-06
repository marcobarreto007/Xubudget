import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'manual_entry_page.dart';
import 'capture_receipt_page.dart';
import 'barcode_scanner_page.dart'; // Import the new page
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../services/export_service.dart';

class BudgetDashboardPage extends StatefulWidget {
  const BudgetDashboardPage({super.key});

  @override
  State<BudgetDashboardPage> createState() => _BudgetDashboardPageState();
}

class _BudgetDashboardPageState extends State<BudgetDashboardPage> {
  final ExportService _exportService = ExportService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xubudget Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportExpenses,
            tooltip: 'Exportar CSV',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<ExpenseProvider>(context, listen: false).fetchExpenses();
            },
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, expenseProvider, child) {
          if (expenseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = expenseProvider.expenses;
          final totalAmount = expenses.fold<double>(0, (sum, expense) => sum + expense.amount);

          return Column(
            children: [
              // Total amount card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Total de Despesas',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat.simpleCurrency(locale: 'pt_BR').format(totalAmount),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${expenses.length} despesa${expenses.length != 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Expenses list
              Expanded(
                child: expenses.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'Nenhuma despesa ainda.\nAdicione uma!',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getCategoryColor(expense.category),
                                child: Icon(
                                  _getCategoryIcon(expense.category),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                expense.description,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DateFormat('dd/MM/yyyy').format(expense.date)),
                                  Text(
                                    _getCategoryDisplayName(expense.category),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                NumberFormat.simpleCurrency(locale: 'pt_BR').format(expense.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseOptions,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _exportExpenses() async {
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
    final expenses = expenseProvider.expenses;
    
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma despesa para exportar')),
      );
      return;
    }
    
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final filePath = await _exportService.exportToCSV(expenses);
      
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
        
        // Show success message with file path
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exportado com sucesso!\nArquivo: ${filePath.split('/').last}'),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddExpenseOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Entrada Manual'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualEntryPage()));
              // No need to call _refreshExpenses() here, provider handles it
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Escanear Recibo (OCR)'),
            onTap: () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const CaptureReceiptPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Escanear Código de Barras'),
            onTap: () async {
              Navigator.pop(context); // Close the modal
              // Await the result from the scanner
              final String? barcode = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
              );

              if (barcode != null && mounted) {
                // Open manual entry page with the pre-filled description
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManualEntryPage(initialDescription: barcode),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'alimentacao':
        return Colors.orange;
      case 'transporte':
        return Colors.blue;
      case 'saude':
        return Colors.red;
      case 'moradia':
        return Colors.green;
      case 'lazer':
        return Colors.purple;
      case 'educacao':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'alimentacao':
        return Icons.restaurant;
      case 'transporte':
        return Icons.directions_car;
      case 'saude':
        return Icons.medical_services;
      case 'moradia':
        return Icons.home;
      case 'lazer':
        return Icons.movie;
      case 'educacao':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'alimentacao':
        return 'Alimentação';
      case 'transporte':
        return 'Transporte';
      case 'saude':
        return 'Saúde';
      case 'moradia':
        return 'Moradia';
      case 'lazer':
        return 'Lazer';
      case 'educacao':
        return 'Educação';
      default:
        return 'Outros';
    }
  }
}