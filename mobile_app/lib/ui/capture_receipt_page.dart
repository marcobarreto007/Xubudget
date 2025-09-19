// WHY: OCR receipt capture page with image picker, text recognition, and expense parsing
// Integrates with OCR service and expense parser to pre-fill expense data

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../services/ocr_service.dart';
import '../services/expense_parser.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';

class CaptureReceiptPage extends StatefulWidget {
  const CaptureReceiptPage({super.key});

  @override
  State<CaptureReceiptPage> createState() => _CaptureReceiptPageState();
}

class _CaptureReceiptPageState extends State<CaptureReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _ocrService = OCRService();
  final _expenseParser = ExpenseParser();
  
  File? _selectedImage;
  bool _isProcessing = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'outros';

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _isProcessing = true;
      });
      
      await _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) return;
    
    try {
      final extractedText = await _ocrService.extractTextFromImage(_selectedImage!);
      if (extractedText != null && extractedText.isNotEmpty) {
        // Use AI categorization if available
        final parsedData = await _expenseParser.parseWithAI(extractedText);
        
        setState(() {
          if (parsedData.description != null) {
            _descriptionController.text = parsedData.description!;
          }
          if (parsedData.amount != null) {
            _amountController.text = parsedData.amount!.toStringAsFixed(2);
          }
          if (parsedData.date != null) {
            _selectedDate = parsedData.date!;
          }
          if (parsedData.category != null) {
            _selectedCategory = parsedData.category!;
          }
          _isProcessing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Texto extraído e categorizado com sucesso!')),
          );
        }
      } else {
        setState(() {
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível extrair texto da imagem.')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar imagem: $e')),
        );
      }
    }
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

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final newExpense = Expense(
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        source: ExpenseSource.ocr,
        createdAt: DateTime.now(),
      );

      await Provider.of<ExpenseProvider>(context, listen: false).addExpense(newExpense);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capturar Recibo')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Image capture section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_selectedImage != null)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Nenhuma imagem selecionada'),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _pickImage,
                        icon: _isProcessing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt),
                        label: Text(_isProcessing ? 'Processando...' : 'Capturar Imagem'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Form fields
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
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um valor';
                  }
                  if (double.tryParse(value) == null) {
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
                initialValue: _selectedCategory,
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