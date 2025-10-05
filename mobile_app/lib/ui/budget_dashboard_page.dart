import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import '../models/category_model.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../services/ai_service.dart';
import '../services/export_service.dart';
import 'capture_receipt_page.dart';
import 'manual_entry_page.dart';
import 'widgets/responsive_container.dart';

/// # Budget Dashboard Page
///
/// Tela principal da aplicação que funciona como um painel financeiro.
///
/// ## Estrutura e Funcionalidades:
///
/// - **Aviso de Status da IA**: Exibe um `SnackBar` se o backend de IA (FastAPI)
///   estiver offline. O endereço do servidor é `http://127.0.0.1:5005`.
///
/// - **Resumo de Despesas**:
///   - Um card no topo mostra o valor total das despesas filtradas.
///   - Exibe o número total de transações.
///
/// - **Filtros de Categoria**:
///   - `FilterChip`s permitem que o usuário filtre a lista de despesas por categoria.
///   - As categorias incluem: Todas, Alimentação, Transporte, Saúde, Moradia, Lazer, Educação, Outros.
///
/// - **Lista de Despesas**:
///   - `ListView.builder` exibe as despesas, cada uma em um `Card`.
///   - Cada item da lista mostra:
///     - Ícone e cor representando a categoria.
///     - Descrição da despesa.
///     - Data da despesa (dd/MM/yyyy).
///     - Nome da categoria.
///     - Valor da despesa formatado em BRL (R$).
///
/// - **Ações**:
///   - `FloatingActionButton` para adicionar novas despesas (manual ou via OCR).
///   - `AppBar` com ações para exportar dados para CSV, checar status da IA e atualizar a lista.
class BudgetDashboardPage extends StatefulWidget {
  const BudgetDashboardPage({super.key});

  @override
  State<BudgetDashboardPage> createState() => _BudgetDashboardPageState();
}

class _BudgetDashboardPageState extends State<BudgetDashboardPage> {
  final ExportService _exportService = ExportService();
  String? _categoryFilter; // null = todas
  bool _isAiOnline = true;
  bool _aiStatusChecked = false;
  final TextEditingController _aiTestController =
      TextEditingController(text: 'Uber Aeroporto 38,90 18/09');
  Map<String, dynamic>? _lastAiResult;

  @override
  void initState() {
    super.initState();
    // Garante dados de localização para nomes de meses/datas em pt_BR no Web
    initializeDateFormatting('pt_BR');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().fetchExpenses();
      _checkAI();
    });
  }

  Future<void> _checkAI({bool showSnackbar = false}) async {
    final ok = await AIService.instance.health();
    if (mounted) {
      setState(() {
        _isAiOnline = ok;
        _aiStatusChecked = true;
      });
      if (showSnackbar) _showAiDialog();
    }
  }

  void _showAiDialog() {
    final baseUrl = AIService.instance.baseUrl;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Diagnóstico da IA'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      _isAiOnline ? Icons.check_circle : Icons.error_outline,
                      color: _isAiOnline ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_isAiOnline ? 'IA online' : 'IA offline'),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Base URL: $baseUrl',
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const Divider(height: 16),
                const Text('Teste rápido de categorização',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _aiTestController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Texto da despesa',
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                if (_lastAiResult != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_lastAiResult.toString(),
                        style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
            TextButton(
              onPressed: () async {
                final text = _aiTestController.text.trim();
                if (text.isEmpty) return;
                setState(() => _lastAiResult = null);
                final res = await AIService.instance.categorize(text);
                if (!mounted) return;
                setState(() {
                  _lastAiResult = res == null
                      ? {'error': 'Falha ao categorizar'}
                      : {
                          'category': res.category,
                          'method': res.method,
                          'confidence': res.confidence,
                          'amount': res.amount,
                          'description': res.description,
                          'date': res.date,
                        };
                });
              },
              child: const Text('Testar'),
            ),
            TextButton(
              onPressed: () async {
                await _checkAI(showSnackbar: false);
                if (!mounted) return;
                setState(() {});
              },
              child: const Text('Reverificar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xubudget Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exportar CSV',
            onPressed: _exportExpenses,
          ),
          IconButton(
            icon: const Icon(Icons.bolt),
            tooltip: 'Diagnóstico da IA',
            onPressed: () async {
              await _checkAI(showSnackbar: false);
              if (!mounted) return;
              _showAiDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () => context.read<ExpenseProvider>().fetchExpenses(),
          ),
        ],
      ),
      body: ResponsiveContainer(
        child: Consumer<ExpenseProvider>(
          builder: (context, expenseProvider, _) {
            if (expenseProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final expenses = expenseProvider.expenses;
            final filtered = _applyFilter(expenses);
            final total = filtered.fold<double>(0, (s, e) => s + e.amount);

            final Map<String, List<Expense>> groupedExpenses = {};
            for (var expense in filtered) {
              final groupKey = _getGroupKeyForDate(expense.date);
              if (groupedExpenses[groupKey] == null) {
                groupedExpenses[groupKey] = [];
              }
              groupedExpenses[groupKey]!.add(expense);
            }

            final List<dynamic> listItems = groupedExpenses.entries
                .expand((entry) => [entry.key, ...entry.value])
                .toList();

            return Column(
              children: [
                // AI Status Banner
                if (_aiStatusChecked && !_isAiOnline)
                  Container(
                    color: Colors.orange.shade100,
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange.shade800, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'IA offline: categorização usará o modo simplificado.',
                            style: TextStyle(color: Colors.orange.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                // Total amount card
                Card(
                  margin: const EdgeInsets.only(
                      top: 16, left: 8, right: 8, bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total de Despesas',
                            style: TextStyle(fontSize: 16, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Text(
                          NumberFormat.simpleCurrency(locale: 'pt_BR')
                              .format(total),
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${expenses.length} despesa${expenses.length != 1 ? 's' : ''}',
                          style:
                              const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                // Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      _buildFilterChip(null, 'Todas'),
                      ...appCategories.map((category) => Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: _buildFilterChip(
                                category.id, category.displayName),
                          )),
                    ],
                  ),
                ),

                // Expenses list
                Expanded(
                  child: expenses.isEmpty
                      ? const _EmptyState()
                      : ListView.builder(
                          itemCount: listItems.length,
                          itemBuilder: (context, index) {
                            final item = listItems[index];

                            if (item is String) {
                              // É um cabeçalho de grupo
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 20, 16, 8),
                                child: Text(
                                  item,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              );
                            }

                            final expense = item as Expense;
                            final category = findCategoryById(expense.category);
                            return Dismissible(
                              key: ValueKey(expense.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                context
                                    .read<ExpenseProvider>()
                                    .deleteExpense(expense.id!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Despesa excluída.')),
                                );
                              },
                              background: Container(
                                color: Colors.red,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                alignment: Alignment.centerRight,
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: category.color,
                                    child: Icon(category.icon,
                                        color: Colors.white),
                                  ),
                                  title: Text(expense.description,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                  subtitle: Text(
                                    '${DateFormat('dd/MM/yyyy').format(expense.date)} • ${category.displayName}',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.grey),
                                  ),
                                  trailing: Text(
                                    NumberFormat.simpleCurrency(locale: 'pt_BR')
                                        .format(expense.amount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseOptions,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }

  Future<void> _exportExpenses() async {
    final expenses = context.read<ExpenseProvider>().expenses;
    if (expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma despesa para exportar')));
      return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _exportService.exportToCSV(expenses);

      if (!mounted) return;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exportado com sucesso: $result')),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Erro ao exportar: $e'), backgroundColor: Colors.red),
      );
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
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManualEntryPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Escanear Recibo (OCR)'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CaptureReceiptPage()),
              );
            },
          ),
          // Código de barras removido nesta fase.
        ],
      ),
    );
  }

  // Helpers UI
  Widget _buildFilterChip(String? value, String label) {
    final selected =
        _categoryFilter == value || (_categoryFilter == null && value == null);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _categoryFilter = value),
    );
  }

  List<Expense> _applyFilter(List<Expense> expenses) {
    if (_categoryFilter == null) return expenses;
    return expenses.where((e) => e.category == _categoryFilter).toList();
  }

  String _getGroupKeyForDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) {
      return 'Hoje';
    } else if (expenseDate == yesterday) {
      return 'Ontem';
    } else {
      String monthYear = DateFormat('MMMM y', 'pt_BR').format(date);
      return monthYear[0].toUpperCase() + monthYear.substring(1);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
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
    );
  }
}
