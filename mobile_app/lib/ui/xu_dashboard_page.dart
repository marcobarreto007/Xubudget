import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/xu_api.dart';
import '../strings_en.dart';

// Final consolidated version of the dashboard UI

final _fmt = NumberFormat.currency(locale: 'en_CA', symbol: r'$');
String money(num v) => _fmt.format(v);

class XuDashboardPage extends StatefulWidget {
  const XuDashboardPage({super.key});

  @override
  State<XuDashboardPage> createState() => _XuDashboardPageState();
}

class _XuDashboardPageState extends State<XuDashboardPage> with SingleTickerProviderStateMixin {
  final _api = XuApi();

  // State
  num _budget = 0;
  num _monthlySpent = 0;
  num _remaining = 0;
  bool _loading = true;
  bool _sending = false;
  bool _showChat = false;

  // Controllers
  final _scrollCtrl = ScrollController();
  final _chatCtrl = TextEditingController();
  late final AnimationController _anim;
  final _chat = <_Msg>[];

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
    _fetchState();
  }

  @override
  void dispose() {
    _anim.dispose();
    _scrollCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchState() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getState();
      setState(() {
        _budget = (data['budget'] ?? 0) as num;
        _monthlySpent = (data['monthly_spent'] ?? 0) as num;
        _remaining = (data['remaining'] ?? (_budget - _monthlySpent)) as num;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Failed to sync: $e');
    }
  }

  Future<void> _sendChat(String msg) async {
    if (msg.trim().isEmpty) return;
    setState(() {
      _chat.add(_Msg.user(msg));
      _sending = true;
    });
    _chatCtrl.clear();
    _jumpToEnd();

    try {
      final res = await _api.sendChat(msg);
      final reply = (res['reply'] ?? 'OK.') as String;
      setState(() => _chat.add(_Msg.bot(reply)));
      await _fetchState();
    } catch (e) {
      setState(() => _chat.add(_Msg.bot('Oops, a technical issue occurred.')));
      _snack('Send error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
      _jumpToEnd();
    }
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  double get _progress => _budget <= 0 ? 0 : (_monthlySpent / _budget).clamp(0, 1).toDouble();

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: Stack(children: [
        _HeaderGradient(onChatTap: () => setState(() => _showChat = !_showChat), showChat: _showChat),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24 + 64, 16, 16),
            child: _buildContent(context),
          ),
        ),
        if (_showChat)
          Align(
            alignment: Alignment.bottomRight,
            child: _ChatPanel(
              controller: _chatCtrl,
              scroll: _scrollCtrl,
              messages: _chat,
              sending: _sending,
              onSend: _sendChat,
              onClose: () => setState(() => _showChat = false),
            ),
          ),
        if (_loading)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: Colors.black.withOpacity(0.02),
                child: Center(child: _LoadingDots(controller: _anim)),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.bolt, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(_loading ? S.syncing : S.synced, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _StatCard(icon: Icons.credit_card, title: S.budget, value: money(_budget))),
          const SizedBox(width: 16),
          Expanded(child: _StatCard(icon: Icons.ssid_chart_rounded, title: S.spent, value: money(_monthlySpent))),
          const SizedBox(width: 16),
          Expanded(child: _StatCard(icon: Icons.savings, title: S.remaining, value: money(_remaining))),
        ]),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                SubcategorizedBudgetPanel(),
                const SizedBox(height: 24),
                _IncomesSection(onStateChange: _fetchState),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ===== Models =====
class _Msg {
  final String text;
  final bool isUser;
  _Msg._(this.text, this.isUser);
  factory _Msg.user(String t) => _Msg._(t, true);
  factory _Msg.bot(String t) => _Msg._(t, false);
}

// ===== Global Widgets =====
class _HeaderGradient extends StatelessWidget {
  final VoidCallback onChatTap;
  final bool showChat;
  const _HeaderGradient({required this.onChatTap, required this.showChat});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C6BFF), Color(0xFF8E80FF), Color(0xFFA48BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 8))],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const Icon(Icons.hub_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(S.appTitle, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              Tooltip(
                message: showChat ? 'Close chat' : 'Open chat',
                child: InkWell(
                  onTap: onChatTap,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _StatCard({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x143B3B3B), blurRadius: 14, offset: Offset(0, 8))],
        border: Border.all(color: const Color(0x0F000000)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF2F1FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E4FF)),
          ),
          child: Icon(icon, color: const Color(0xFF7C6BFF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ChatPanel extends StatelessWidget {
  final TextEditingController controller;
  final ScrollController scroll;
  final List<_Msg> messages;
  final bool sending;
  final void Function(String) onSend;
  final VoidCallback onClose;

  const _ChatPanel({
    required this.controller,
    required this.scroll,
    required this.messages,
    required this.sending,
    required this.onSend,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 12, bottom: 12),
      width: 380,
      height: 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7E6F5)),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(children: [
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: const BoxDecoration(
            color: Color(0xFF7C6BFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(children: [
            const Icon(Icons.smart_toy, color: Colors.white),
            const SizedBox(width: 8),
            Text(S.xuChat, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70),
              onPressed: onClose,
              tooltip: 'Close',
            ),
          ]),
        ),
        if (sending) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.all(12),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final m = messages[i];
              final isUser = m.isUser;
              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxWidth: 280),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFFECEBFF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isUser ? const Color(0xFFD9D6FF) : const Color(0xFFE9E9F3)),
                  ),
                  child: Text(m.text),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: S.chatHint,
                  border: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFE7E6F5))),
                  isDense: true,
                ),
                onSubmitted: (v) => onSend(v),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: sending ? null : () => onSend(controller.text),
              icon: const Icon(Icons.send_rounded),
              color: const Color(0xFF7C6BFF),
              tooltip: sending ? S.thinking : 'Send',
            ),
          ]),
        )
      ]),
    );
  }
}

class _LoadingDots extends StatelessWidget {
  final AnimationController controller;
  const _LoadingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              final t = (controller.value + (i * 0.2)) % 1.0;
              final scale = 0.7 + 0.3 * math.sin(t * math.pi * 2);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF7C6BFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// --- Subcategorized Budget Panel ---

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
          child: Text('Error loading budget data'),
        ),
      );
    }
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
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
          'Subcategorized Budgets',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        IconButton(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _showAddBudgetDialog,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('New Budget'),
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
            title: 'Total Budget',
            value: money(summary.totalBudget),
            icon: Icons.account_balance_wallet,
            color: const Color(0xFF7C6BFF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Total Spent',
            value: money(summary.totalSpent),
            icon: Icons.trending_up,
            color: summary.totalSpent > summary.totalBudget ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Remaining',
            value: money(summary.totalBudget - summary.totalSpent),
            icon: Icons.savings,
            color: (summary.totalBudget - summary.totalSpent) >= 0 ? Colors.green : Colors.red,
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
          label: const Text('All'),
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
}

class _CategoryCard extends StatelessWidget {
  final String categoryKey;
  final CategoryData categoryData;
  
  const _CategoryCard({
    required this.categoryKey,
    required this.categoryData,
  });

  @override
  Widget build(BuildContext context) {
    final category = categoryData;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: category.isOver ? Colors.red.withOpacity(0.3) : const Color(0xFFE6E6EF),
          width: category.isOver ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (category.spent / (category.budget > 0 ? category.budget : 1)).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F0FF),
              valueColor: AlwaysStoppedAnimation(category.isOver ? Colors.red : const Color(0xFF7C6BFF)),
            ),
            const SizedBox(height: 4),
            Text('${money(category.spent)} / ${money(category.budget)}'),
          ],
        ),
        children: category.subcategories.entries.map((entry) {
          return _SubcategoryRow(
            subcategoryKey: entry.key,
            subcategoryData: entry.value,
            categoryKey: categoryKey,
          );
        }).toList(),
      ),
    );
  }
}

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(sub.name)),
          Text('${money(sub.spent)} / ${money(sub.budget)}'),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: LinearProgressIndicator(
              value: (sub.spent / (sub.budget > 0 ? sub.budget : 1)).clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFF1F0FF),
              valueColor: AlwaysStoppedAnimation(sub.isOver ? Colors.red : const Color(0xFF7C6BFF)),
            ),
          ),
        ],
      ),
    );
  }
}

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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF6B6B80), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AddBudgetDialog extends StatefulWidget {
  final Function() onSaved;
  const _AddBudgetDialog({required this.onSaved});

  @override
  State<_AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<_AddBudgetDialog> {
  final _api = XuApi();
  final _catCtrl = TextEditingController();
  final _subCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add/Edit Budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: _catCtrl, decoration: const InputDecoration(labelText: 'Category')),
          TextField(controller: _subCtrl, decoration: const InputDecoration(labelText: 'Subcategory')),
          TextField(controller: _budgetCtrl, decoration: const InputDecoration(labelText: 'Budget'), keyboardType: TextInputType.number),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () async {
          final budget = double.tryParse(_budgetCtrl.text);
          if (budget == null) return;
          await _api.setSubcategoryBudget(
            category: _catCtrl.text,
            subcategory: _subCtrl.text,
            budget: budget,
          );
          widget.onSaved();
          Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    );
  }
}

// --- Incomes Panel ---

class _IncomesSection extends StatefulWidget {
  final VoidCallback onStateChange;
  const _IncomesSection({required this.onStateChange});

  @override
  State<_IncomesSection> createState() => _IncomesSectionState();
}

class _IncomesSectionState extends State<_IncomesSection> {
  final _api = XuApi();
  bool _loading = true;
  List<IncomeItem> _incomes = [];
  String _budgetMode = 'manual';
  double _monthlyIncomeTotal = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      final incomes = await _api.getIncomes();
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final monthlyTotal = incomes
          .where((i) => i.ts.isAfter(startOfMonth))
          .fold(0.0, (sum, item) => sum + item.amount);
      
      setState(() {
        _incomes = incomes;
        _monthlyIncomeTotal = monthlyTotal;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _addIncome() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddIncomeDialog(),
    );
    
    if (result != null) {
      await _api.addIncome(amount: result['amount'], source: result['source']);
      _refresh();
      widget.onStateChange();
    }
  }

  Future<void> _toggleBudgetMode() async {
    final newMode = _budgetMode == 'manual' ? 'income_sum' : 'manual';
    await _api.setBudgetMode(mode: newMode);
    setState(() => _budgetMode = newMode);
    widget.onStateChange();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, color: Colors.green),
                const SizedBox(width: 8),
                Text(S.incomes, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addIncome,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(S.addIncome),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(S.thisMonthIncome),
              trailing: Text(money(_monthlyIncomeTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            SwitchListTile(
              title: const Text(S.autoBudget),
              value: _budgetMode == 'income_sum',
              onChanged: (_) => _toggleBudgetMode(),
            ),
            const Divider(),
            if (_loading) const Center(child: CircularProgressIndicator()) else
            ..._incomes.map((income) => ListTile(
              title: Text(income.source.isNotEmpty ? income.source : 'Income'),
              subtitle: Text(DateFormat.yMd().format(income.ts)),
              trailing: Text(money(income.amount), style: const TextStyle(color: Colors.green)),
            ))
          ],
        ),
      ),
    );
  }
}

class _AddIncomeDialog extends StatefulWidget {
  @override
  State<_AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<_AddIncomeDialog> {
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  @override
  void dispose() {
    _amountController.dispose();
    _sourceController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(S.addIncome),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: S.amount, prefixText: '\$'),
              keyboardType: TextInputType.number,
              validator: (v) => (v == null || v.isEmpty || double.tryParse(v) == null) ? S.pleaseEnterValidAmount : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sourceController,
              decoration: const InputDecoration(labelText: S.sourceOptional, hintText: S.sourceHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          if (_formKey.currentState!.validate()) {
            Navigator.of(context).pop({
              'amount': double.parse(_amountController.text),
              'source': _sourceController.text.trim(),
            });
          }
        }, child: const Text(S.addIncome)),
      ],
    );
  }
}
