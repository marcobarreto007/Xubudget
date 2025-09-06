import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../db/database_service.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

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
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'outros'; // Default category

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

  void _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final newExpense = Expense(
        description: _descriptionController.text,
        amount: double.parse(_amountController.text.replaceAll(',', '.')),
        category: _selectedCategory,
        date: _selectedDate,
        source: widget.initialDescription != null ? ExpenseSource.imported : ExpenseSource.manual,
        createdAt: DateTime.now(),
      );

      await Provider.of<ExpenseProvider>(context, listen: false).addExpense(newExpense);

      if (mounted) {
        Navigator.pop(context); // Go back to dashboard
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nova Despesa Manual')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                title: Text('Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
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
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'alimentacao', child: Text('Alimentação')),
                  DropdownMenuItem(value: 'transporte', child: Text('Transporte')),
                  DropdownMenuItem(value: 'saude', child: Text('Saúde')),
                  DropdownMenuItem(value: 'moradia', child: Text('Moradia')),
                  DropdownMenuItem(value: 'lazer', child: Text('Lazer')),
                  DropdownMenuItem(value: 'educacao', child: Text('Educação')),
                  DropdownMenuItem(value: 'outros', child: Text('Outros')),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Salvar Despesa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}