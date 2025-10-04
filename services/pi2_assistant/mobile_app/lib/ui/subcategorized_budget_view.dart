
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/xu_api.dart';

// 2. Widget principal do sistema subcategorizado
class SubcategorizedBudgetPanel extends StatefulWidget {
  const SubcategorizedBudgetPanel({super.key});
  
  @override
  State<SubcategorizedBudgetPanel> createState() => _SubcategorizedBudgetPanelState();
}

class _SubcategorizedBudgetPanelState extends State<SubcategorizedBudgetPanel> {
  final _api = XuApi();
  bool _loading = true;
  BudgetStructure? _budgetData;
  String _selectedCategory = '';
  bool _showOverspendingOnly = false;
  
  @override
  void initState() {
    super.initState();
    _refresh();
  }
  
  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final response = await _api.getBudgetStructure();
      setState(() {
        _budgetData = response;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    
    if (_budgetData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Erro ao carregar dados de budget'),
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildFilters(),
            const SizedBox(height: 16),
            _buildCategoriesList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.account_tree, color: Color(0xFF7C6BFF), size: 24),
        const SizedBox(width: 8),
        const Text(
          'Budgets Subcategorizados',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar',
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _showAddBudgetDialog,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Novo Budget'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C6BFF),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryCards() {
    final summary = _budgetData!.summary;
    
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Orçado',
            value: '\$${summary.totalBudget.toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet,
            color: const Color(0xFF7C6BFF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Total Gasto',
            value: '\$${summary.totalSpent.toStringAsFixed(2)}',
            icon: Icons.trending_up,
            color: summary.totalSpent > summary.totalBudget ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Restante',
            value: '\$${summary.totalRemaining.toStringAsFixed(2)}',
            icon: Icons.savings,
            color: summary.totalRemaining >= 0 ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Overspending',
            value: '${summary.subcategoriesOverBudget} itens',
            icon: Icons.warning,
            color: summary.subcategoriesOverBudget > 0 ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilters() {
    final categories = _budgetData!.structure.keys.toList()..sort();
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: const Text('Todos'),
          selected: _selectedCategory.isEmpty && !_showOverspendingOnly,
          onSelected: (_) => setState(() {
            _selectedCategory = '';
            _showOverspendingOnly = false;
          }),
        ),
        FilterChip(
          label: const Text('Overspending'),
          selected: _showOverspendingOnly,
          onSelected: (_) => setState(() {
            _showOverspendingOnly = !_showOverspendingOnly;
            _selectedCategory = '';
          }),
        ),
        ...categories.map((category) => FilterChip(
          label: Text(_budgetData!.structure[category]!.name),
          selected: _selectedCategory == category,
          onSelected: (_) => setState(() {
            _selectedCategory = _selectedCategory == category ? '' : category;
            _showOverspendingOnly = false;
          }),
        )),
      ],
    );
  }
  
  Widget _buildCategoriesList() {
    var categories = _budgetData!.structure.entries.toList();
    
    // Aplicar filtros
    if (_selectedCategory.isNotEmpty) {
      categories = categories.where((e) => e.key == _selectedCategory).toList();
    }
    
    if (_showOverspendingOnly) {
      categories = categories.where((e) => 
        e.value.isOver || 
        e.value.subcategories.values.any((sub) => sub.isOver)
      ).toList();
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = categories[index];
        return _CategoryCard(
          categoryKey: entry.key,
          categoryData: entry.value,
          onEdit: () => _showEditCategoryDialog(entry.key, entry.value),
          onTransfer: () => _showTransferDialog(entry.key, entry.value),
        );
      },
    );
  }
  
  void _showAddBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddBudgetDialog(onSaved: _refresh),
    );
  }
  
  void _showEditCategoryDialog(String categoryKey, CategoryData categoryData) {
    showDialog(
      context: context,
      builder: (context) => _EditCategoryDialog(
        categoryKey: categoryKey,
        categoryData: categoryData,
        onSaved: _refresh,
      ),
    );
  }
  
  void _showTransferDialog(String categoryKey, CategoryData categoryData) {
    showDialog(
      context: context,
      builder: (context) => _TransferBudgetDialog(
        allCategories: _budgetData!.structure,
        onTransferred: _refresh,
      ),
    );
  }
}

// 3. Card de categoria com subcategorias
class _CategoryCard extends StatefulWidget {
  final String categoryKey;
  final CategoryData categoryData;
  final VoidCallback onEdit;
  final VoidCallback onTransfer;
  
  const _CategoryCard({
    required this.categoryKey,
    required this.categoryData,
    required this.onEdit,
    required this.onTransfer,
  });
  
  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _expanded = false;
  
  @override
  Widget build(BuildContext context) {
    final category = widget.categoryData;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: category.isOver ? Colors.red.withOpacity(0.3) : const Color(0xFFE6E6EF),
          width: category.isOver ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header da categoria
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '\$${category.spent.toStringAsFixed(2)} / \$${category.budget.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: category.isOver ? Colors.red : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${category.percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: category.isOver ? Colors.red : const Color(0xFF7C6BFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (category.percentage / 100).clamp(0.0, 1.0),
                          backgroundColor: const Color(0xFFF1F0FF),
                          valueColor: AlwaysStoppedAnimation(
                            category.isOver ? Colors.red : const Color(0xFF7C6BFF),
                          ),
                          minHeight: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: widget.onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: 'Editar',
                      ),
                      IconButton(
                        onPressed: widget.onTransfer,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        tooltip: 'Transferir Budget',
                      ),
                      Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Subcategorias (expandível)
          if (_expanded && category.subcategories.isNotEmpty)
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE6E6EF))),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Subcategorias',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B6B80),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...category.subcategories.entries
                        .where((entry) => entry.value.isActive || entry.value.spent > 0)
                        .map((entry) => _SubcategoryRow(
                              subcategoryKey: entry.key,
                              subcategoryData: entry.value,
                              categoryKey: widget.categoryKey,
                            )),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// 4. Row de subcategoria
class _SubcategoryRow extends StatelessWidget {
  final String subcategoryKey;
  final SubcategoryData subcategoryData;
  final String categoryKey;
  
  const _SubcategoryRow({
    required this.subcategoryKey,
    required this.subcategoryData,
    required this.categoryKey,
  });
  
  @override
  Widget build(BuildContext context) {
    final sub = subcategoryData;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: sub.isOver ? Colors.red.withOpacity(0.05) : const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: sub.isOver ? Colors.red.withOpacity(0.2) : const Color(0xFFE6E6EF),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      sub.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (sub.isOver) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.warning,
                        color: Colors.red,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '\$${sub.spent.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: sub.isOver ? Colors.red : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (sub.budget > 0) ...[
                      Text(
                        ' / \$${sub.budget.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF6B6B80),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${sub.percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: sub.isOver ? Colors.red : const Color(0xFF7C6BFF),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ] else ...[
                      const Text(
                        ' (sem limite)',
                        style: TextStyle(
                          color: Color(0xFF6B6B80),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
                if (sub.budget > 0) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: (sub.percentage / 100).clamp(0.0, 1.0),
                    backgroundColor: const Color(0xFFF1F0FF),
                    valueColor: AlwaysStoppedAnimation(
                      sub.isOver ? Colors.red : const Color(0xFF7C6BFF),
                    ),
                    minHeight: 4,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 5. Card de resumo
class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B6B80),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// 6. Dialog para adicionar novo budget
class _AddBudgetDialog extends StatefulWidget {
  final VoidCallback onSaved;
  
  const _AddBudgetDialog({required this.onSaved});
  
  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _categoryController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _budgetController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Budget'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _categoryController,
              decoration: const InputDecoration(
                labelText: 'Categoria',
                hintText: 'ex: Alimentação, Transporte',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite a categoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _subcategoryController,
              decoration: const InputDecoration(
                labelText: 'Subcategoria',
                hintText: 'ex: Supermercado, Restaurantes',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite a subcategoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: 'Budget Mensal',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite o valor do budget';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Digite um valor válido';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveBudget,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
  
  void _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      try {
        final api = XuApi();
        await api.setSubcategoryBudget(
          category: _categoryController.text.trim(),
          subcategory: _subcategoryController.text.trim(),
          budget: double.parse(_budgetController.text),
        );
        
        if (mounted) {
          Navigator.of(context).pop();
          widget.onSaved();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget criado com sucesso!')), 
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao criar budget: $e')),
          );
        }
      }
    }
  }
}

// 7. Dialog para transferir budget
class _TransferBudgetDialog extends StatefulWidget {
  final Map<String, CategoryData> allCategories;
  final VoidCallback onTransferred;
  
  const _TransferBudgetDialog({
    required this.allCategories,
    required this.onTransferred,
  });
  
  @override
  State<_TransferBudgetDialog> createState() => _TransferBudgetDialogState();
}

class _TransferBudgetDialogState extends State<_TransferBudgetDialog> {
  String? _fromCategory;
  String? _fromSubcategory;
  String? _toCategory;
  String? _toSubcategory;
  final _amountController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Transferir Budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Origem
          const Text('DE:', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(
            value: _fromCategory,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: widget.allCategories.keys.map((cat) => 
              DropdownMenuItem(value: cat, child: Text(widget.allCategories[cat]!.name))
            ).toList(),
            onChanged: (value) => setState(() {
              _fromCategory = value;
              _fromSubcategory = null;
            }),
          ),
          if (_fromCategory != null)
            DropdownButtonFormField<String>(
              value: _fromSubcategory,
              decoration: const InputDecoration(labelText: 'Subcategoria'),
              items: widget.allCategories[_fromCategory]!.subcategories.entries
                  .where((entry) => entry.value.budget > 0)
                  .map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text('${entry.value.name} (\$${entry.value.budget.toStringAsFixed(2)})'),
                  )).toList(),
              onChanged: (value) => setState(() => _fromSubcategory = value),
            ),
          
          const SizedBox(height: 16),
          const Divider(),
          
          // Destino
          const Text('PARA:', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField<String>(
            value: _toCategory,
            decoration: const InputDecoration(labelText: 'Categoria'),
            items: widget.allCategories.keys.map((cat) => 
              DropdownMenuItem(value: cat, child: Text(widget.allCategories[cat]!.name))
            ).toList(),
            onChanged: (value) => setState(() {
              _toCategory = value;
              _toSubcategory = null;
            }),
          ),
          if (_toCategory != null)
            DropdownButtonFormField<String>(
              value: _toSubcategory,
              decoration: const InputDecoration(labelText: 'Subcategoria'),
              items: widget.allCategories[_toCategory]!.subcategories.keys
                  .map((subKey) => DropdownMenuItem(
                    value: subKey,
                    child: Text(widget.allCategories[_toCategory]!.subcategories[subKey]!.name),
                  )).toList(),
              onChanged: (value) => setState(() => _toSubcategory = value),
            ),
          
          const SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Valor a Transferir',
              prefixText: '\$',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _canTransfer() ? _performTransfer : null,
          child: const Text('Transferir'),
        ),
      ],
    );
  }
  
  bool _canTransfer() {
    return _fromCategory != null &&
           _fromSubcategory != null &&
           _toCategory != null &&
           _toSubcategory != null &&
           _amountController.text.isNotEmpty &&
           double.tryParse(_amountController.text) != null;
  }
  
  void _performTransfer() async {
    try {
      final api = XuApi();
      await api.transferBudget(
        fromCategory: _fromCategory!,
        fromSubcategory: _fromSubcategory!,
        toCategory: _toCategory!,
        toSubcategory: _toSubcategory!,
        amount: double.parse(_amountController.text),
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onTransferred();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget transferido com sucesso!')), 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro na transferência: $e')),
        );
      }
    }
  }
}

// 8. Dialog para editar categoria
class _EditCategoryDialog extends StatefulWidget {
  final String categoryKey;
  final CategoryData categoryData;
  final VoidCallback onSaved;
  
  const _EditCategoryDialog({
    required this.categoryKey,
    required this.categoryData,
    required this.onSaved,
  });
  
  @override
  State<_EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<_EditCategoryDialog> {
  late final Map<String, TextEditingController> _controllers;
  
  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final entry in widget.categoryData.subcategories.entries) {
      _controllers[entry.key] = TextEditingController(
        text: entry.value.budget > 0 ? entry.value.budget.toStringAsFixed(2) : '',
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar ${widget.categoryData.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.categoryData.subcategories.entries.map((entry) {
            final subKey = entry.key;
            final subData = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                controller: _controllers[subKey],
                decoration: InputDecoration(
                  labelText: subData.name,
                  prefixText: '\$',
                  suffixText: 'Gasto: \$${subData.spent.toStringAsFixed(2)}',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saveChanges,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
  
  void _saveChanges() async {
    try {
      final api = XuApi();
      
      for (final entry in _controllers.entries) {
        final subKey = entry.key;
        final controller = entry.value;
        final budget = double.tryParse(controller.text) ?? 0;
        
        await api.setSubcategoryBudget(
          category: widget.categoryKey,
          subcategory: subKey,
          budget: budget,
        );
      }
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budgets atualizados com sucesso!')), 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar: $e')),
        );
      }
    }
  }
  
  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
