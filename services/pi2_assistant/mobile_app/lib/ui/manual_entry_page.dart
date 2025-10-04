import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../models/category_model.dart';
import '../providers/expense_provider.dart';
import '../services/expense_parser.dart';

class ManualEntryPage extends StatefulWidget {
  final String? initialDescription;

  const ManualEntryPage({super.key, this.initialDescription});

  @override
  State<ManualEntryPage> createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'outros';
  bool _isSuggesting = false;
  String? _lastMethod; // 'ai' ou 'regex'
  double? _lastConfidence;

  @override
  void initState() {
    super.initState();
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _suggestWithAI() async {
    final text = _descriptionController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Digite uma descrição para sugerir com IA.')),
      );
      return;
    }

    setState(() => _isSuggesting = true);
    try {
      final parser = ExpenseParser();
      final result = await parser.parseWithAI(text);

      setState(() {
        if (result.description != null && result.description!.isNotEmpty) {
          _descriptionController.text = result.description!;
        }
        if (result.amount != null) {
          // Formata o valor no padrão brasileiro (ex.: 38,90)
          final nf = NumberFormat('#,##0.00', 'pt_BR');
          _amountController.text = nf.format(result.amount!);
        }
        if (result.date != null) {
          _selectedDate = result.date!;
        }
        if (result.category != null && result.category!.isNotEmpty) {
          _selectedCategory = result.category!;
        }
        _lastMethod = result.method;
        _lastConfidence = result.confidence;
      });

      if (mounted) {
        final viaIA = (_lastMethod == 'ai');
        final conf = (_lastConfidence != null)
            ? ' (confiança ${(100 * _lastConfidence!).toStringAsFixed(0)}%)'
            : '';
        final msg = 'Sugestões aplicadas via ${viaIA ? 'IA' : 'regex'}$conf.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha ao obter sugestões: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSuggesting = false);
    }
  }

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final newExpense = Expense(
        description: _descriptionController.text,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        category: _selectedCategory,
        date: _selectedDate,
        source: widget.initialDescription != null
            ? ExpenseSource.imported
            : ExpenseSource.manual,
        createdAt: DateTime.now(),
      );

      await Provider.of<ExpenseProvider>(context, listen: false)
          .addExpense(newExpense);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Despesa')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            controller: _scrollController,
            children: [
              const Text('Detalhes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  prefixIcon: Icon(Icons.description_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: _isSuggesting ? null : _suggestWithAI,
                  icon: _isSuggesting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome),
                  label: const Text('Sugerir com IA'),
                ),
              ),
              if (_lastMethod != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _lastMethod == 'ai' ? Icons.bolt : Icons.rule,
                      size: 18,
                      color: _lastMethod == 'ai'
                          ? Colors.amber.shade800
                          : Colors.blueGrey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _lastMethod == 'ai' ? 'Sugestão: IA' : 'Sugestão: regex',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (_lastConfidence != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        'conf. ${(100 * _lastConfidence!).toStringAsFixed(0)}%',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 8),
                // Resumo do que foi aplicado para dar visibilidade imediata
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                            SizedBox(width: 6),
                            Text(
                              'Sugestões aplicadas no formulário',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                  'Descrição: ${_descriptionController.text}'),
                              avatar: const Icon(Icons.description, size: 16),
                            ),
                            if (_amountController.text.isNotEmpty)
                              Chip(
                                label: Text(
                                    'Valor: R\$ ${_amountController.text}'),
                                avatar:
                                    const Icon(Icons.attach_money, size: 16),
                              ),
                            Chip(
                              label: Text(
                                  'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                              avatar: const Icon(Icons.event, size: 16),
                            ),
                            Chip(
                              label: Text(
                                  'Categoria: ${appCategories.firstWhere((c) => c.id == _selectedCategory).displayName}'),
                              avatar: const Icon(Icons.category, size: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text('Valores',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um valor';
                  }
                  final sanitizedValue = value.replaceAll(',', '.');
                  if (double.tryParse(sanitizedValue) == null) {
                    return 'Por favor, insira um número válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                    'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category_outlined),
                  border: OutlineInputBorder(),
                ),
                items: appCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category.id,
                    child: Text(category.displayName),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveExpense,
                child: const Text('Salvar Despesa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
