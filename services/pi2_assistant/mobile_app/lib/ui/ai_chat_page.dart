import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import '../services/expense_parser.dart';
import '../services/chat_service.dart';
import '../services/ai_service.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatItem> _messages = [];
  bool _sending = false;
  // Simple in-memory monthly budget (could be stored later)
  double? _monthlyBudget;
  Expense? _pendingExpense; // waiting for user confirmation when over budget

  @override
  void initState() {
    super.initState();
    _loadBudget();
  }

  Future<void> _loadBudget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getDouble('monthly_budget');
      if (val != null) {
        setState(() => _monthlyBudget = val);
        final brl = NumberFormat.simpleCurrency(locale: 'pt_BR').format(val);
        _appendMessage(_ChatItem.assistant('Orçamento carregado: $brl.'));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _appendMessage(_ChatItem item) {
    setState(() => _messages.add(item));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    _messageController.clear();
    _appendMessage(_ChatItem.user(text));

    setState(() => _sending = true);
    try {
      // 1) Try backend chat first
      ChatResponse? chat;
      final backendOnline = await AIService.instance.health();
      if (backendOnline) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        final expenses = context
            .read<ExpenseProvider>()
            .getExpensesByDateRange(monthStart, monthEnd);
        final spent = expenses.fold<double>(0, (s, e) => s + e.amount);

        chat = await ChatService.instance.send(
          message: text,
          userId: 'web-ui',
          conversationContext: {
            'budget': _monthlyBudget ?? 0,
            'monthly_spent': spent,
            'currency': 'CAD',
          },
        );
      }

      if (chat != null) {
        // Show assistant message
        _appendMessage(_ChatItem.assistant(chat.response));

        // Handle intents
        switch (chat.intent) {
          case 'budget_set':
            final newBudget = (chat.data != null && chat.data!['budget'] is num)
                ? (chat.data!['budget'] as num).toDouble()
                : null;
            if (newBudget != null) {
              setState(() => _monthlyBudget = newBudget);
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setDouble('monthly_budget', newBudget);
              } catch (_) {}
            }
            // Action handled; stop here
            return;
          case 'expense_added':
            // If backend recognized an expense, we can optionally add it to local DB
            final amount = (chat.data != null && chat.data!['amount'] is num)
                ? (chat.data!['amount'] as num).toDouble()
                : null;
            final rawCategory = (chat.data != null)
                ? (chat.data!['category'] as String?)
                : null;
            if (amount != null) {
              final localCategory = _mapBackendCategoryToApp(rawCategory);
              final exp = Expense(
                description: text,
                amount: amount,
                category: localCategory,
                date: DateTime.now(),
                source: ExpenseSource.manual,
                createdAt: DateTime.now(),
              );
              await context.read<ExpenseProvider>().addExpense(exp);
            }
            // Action handled; stop here
            return;
          default:
            // If backend intent is 'general', fall back to local logic below
            if (chat.intent != 'general') {
              return;
            }
        }
      }

      final normalized = text.toLowerCase();

      // Supported intents: set budget, status, advise, add expense, list, total
      // Quick confirm for pending over-budget expense
      if (_pendingExpense != null &&
          (normalized == 'confirmar' || normalized.contains('confirmar'))) {
        final exp = _pendingExpense!;
        await context.read<ExpenseProvider>().addExpense(exp);
        final brl =
            NumberFormat.simpleCurrency(locale: 'pt_BR').format(exp.amount);
        final dmy = DateFormat('dd/MM/yyyy').format(exp.date);
        _appendMessage(_ChatItem.assistant(
            'Confirmado! Registrei "${exp.description}" em ${exp.category} no valor de $brl na data $dmy.'));
        setState(() => _pendingExpense = null);
        return;
      }
      if (normalized.startsWith('budget ') ||
          normalized.startsWith('orçamento ') ||
          normalized.contains('definir orçamento') ||
          normalized.contains('defina orçamento')) {
        final amount = _extractAmount(normalized);
        if (amount == null) {
          _appendMessage(
              _ChatItem.assistant('Me diga o valor. Ex.: "Orçamento 4000"'));
        } else {
          setState(() => _monthlyBudget = amount);
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setDouble('monthly_budget', amount);
          } catch (_) {}
          final brl =
              NumberFormat.simpleCurrency(locale: 'pt_BR').format(amount);
          _appendMessage(_ChatItem.assistant(
              'Fechado. Seu orçamento mensal agora é $brl.'));
        }
        return;
      }

      if (normalized.startsWith('status') ||
          normalized.contains('quanto falta') ||
          normalized.contains('restante') ||
          normalized.contains('previsão') ||
          normalized.contains('projeção')) {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        final expenses = context
            .read<ExpenseProvider>()
            .getExpensesByDateRange(monthStart, monthEnd);
        final spent = expenses.fold<double>(0, (s, e) => s + e.amount);
        final budget = _monthlyBudget;
        final brlSpent =
            NumberFormat.simpleCurrency(locale: 'pt_BR').format(spent);
        if (budget == null) {
          _appendMessage(_ChatItem.assistant(
              'Você gastou $brlSpent neste mês. Defina um orçamento: "Orçamento 4000".'));
        } else {
          final remaining =
              (budget - spent).clamp(-double.infinity, double.infinity);
          final brlRemain =
              NumberFormat.simpleCurrency(locale: 'pt_BR').format(remaining);
          final daysInMonth = monthEnd.day;
          final day = now.day;
          final dailyAvg = spent / day;
          final forecast = dailyAvg * daysInMonth;
          final brlForecast =
              NumberFormat.simpleCurrency(locale: 'pt_BR').format(forecast);
          String advice;
          if (remaining < 0) {
            advice =
                'Você já ultrapassou o orçamento. Reduza gastos essenciais e evite compras de lazer.';
          } else if (remaining < budget * 0.1) {
            advice =
                'Atenção: restam menos de 10% do orçamento. Seja conservador nas compras.';
          } else {
            advice = 'Situação sob controle. Continue monitorando.';
          }
          _appendMessage(_ChatItem.assistant(
              'Status do mês:\n- Gasto: $brlSpent\n- Restante: $brlRemain\n- Projeção ao fim do mês: $brlForecast\n$advice'));
        }
        return;
      }

      if (normalized.contains('posso comprar') ||
          normalized.contains('devo comprar') ||
          normalized.contains('vale a pena')) {
        final amount = _extractAmount(normalized);
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        final expenses = context
            .read<ExpenseProvider>()
            .getExpensesByDateRange(monthStart, monthEnd);
        final spent = expenses.fold<double>(0, (s, e) => s + e.amount);
        if (_monthlyBudget == null) {
          _appendMessage(_ChatItem.assistant(
              'Defina um orçamento primeiro. Ex.: "Orçamento 4000".'));
        } else if (amount == null) {
          _appendMessage(_ChatItem.assistant(
              'Quanto custa? Diga: "Posso comprar X por 2500?"'));
        } else {
          final remaining = _monthlyBudget! - spent;
          final brlRemain =
              NumberFormat.simpleCurrency(locale: 'pt_BR').format(remaining);
          final brlAmount =
              NumberFormat.simpleCurrency(locale: 'pt_BR').format(amount);
          if (amount > remaining) {
            _appendMessage(_ChatItem.assistant(
                'Eu não recomendo. Você tem $brlRemain restante este mês e esta compra de $brlAmount te colocaria acima do orçamento.'));
          } else if (amount > remaining * 0.5) {
            _appendMessage(_ChatItem.assistant(
                'Possível, mas alto impacto. A compra ($brlAmount) consome mais de 50% do restante ($brlRemain). Reavalie prioridades.'));
          } else {
            _appendMessage(_ChatItem.assistant(
                'Sim, cabe no orçamento atual. Só não esqueça de manter uma reserva para imprevistos.'));
          }
        }
        return;
      }
      if (normalized.startsWith('adicion') ||
          normalized.contains('nova despesa') ||
          normalized.contains('registrar') ||
          normalized.contains('add')) {
        final parser = ExpenseParser();
        final parsed = await parser.parseWithAI(text);

        if (parsed.amount == null || parsed.description == null) {
          _appendMessage(_ChatItem.assistant(
              'Não consegui entender totalmente. Envie algo como: "Uber Aeroporto 38,90 18/09 transporte"'));
        } else {
          // Build the expense first so we can stage it for confirmation if needed
          final exp = Expense(
            description: parsed.description!,
            amount: parsed.amount!,
            category: parsed.category ?? 'outros',
            date: parsed.date ?? DateTime.now(),
            source: ExpenseSource.manual,
            createdAt: DateTime.now(),
          );
          // Guardrail: warn if adding would exceed or nearly exceed budget
          if (_monthlyBudget != null) {
            final now = DateTime.now();
            final monthStart = DateTime(now.year, now.month, 1);
            final monthEnd = DateTime(now.year, now.month + 1, 0);
            final expenses = context
                .read<ExpenseProvider>()
                .getExpensesByDateRange(monthStart, monthEnd);
            final spent = expenses.fold<double>(0, (s, e) => s + e.amount);
            final remaining = _monthlyBudget! - spent;
            if (exp.amount > remaining) {
              final brlRemain = NumberFormat.simpleCurrency(locale: 'pt_BR')
                  .format(remaining);
              final brlAmount = NumberFormat.simpleCurrency(locale: 'pt_BR')
                  .format(exp.amount);
              setState(() => _pendingExpense = exp);
              _appendMessage(_ChatItem.assistant(
                  'Aviso: esta despesa de $brlAmount ultrapassa o restante do orçamento ($brlRemain). Diga "confirmar" para mesmo assim registrar.'));
              // Wait for confirmation message next
              return;
            } else if (exp.amount > remaining * 0.5) {
              final brlRemain = NumberFormat.simpleCurrency(locale: 'pt_BR')
                  .format(remaining);
              final brlAmount = NumberFormat.simpleCurrency(locale: 'pt_BR')
                  .format(exp.amount);
              _appendMessage(_ChatItem.assistant(
                  'Atenção: esta despesa ($brlAmount) consome mais de 50% do restante do orçamento ($brlRemain).'));
            }
          }
          await context.read<ExpenseProvider>().addExpense(exp);
          final brl =
              NumberFormat.simpleCurrency(locale: 'pt_BR').format(exp.amount);
          final dmy = DateFormat('dd/MM/yyyy').format(exp.date);
          final via = parsed.method == 'ai' ? 'IA' : 'regex';
          _appendMessage(_ChatItem.assistant(
              'Ok! Registrei "${exp.description}" em ${exp.category} no valor de $brl na data $dmy (via $via).'));
        }
        return;
      }

      if (normalized.startsWith('listar') ||
          normalized.contains('mostrar') ||
          normalized.contains('quais')) {
        final expenses = context.read<ExpenseProvider>().expenses;
        if (expenses.isEmpty) {
          _appendMessage(_ChatItem.assistant('Você ainda não tem despesas.'));
        } else {
          final lines = expenses.take(10).map((e) {
            final brl =
                NumberFormat.simpleCurrency(locale: 'pt_BR').format(e.amount);
            final dmy = DateFormat('dd/MM/yyyy').format(e.date);
            return '- ${e.description} • ${e.category} • $brl • $dmy';
          }).join('\n');
          _appendMessage(
              _ChatItem.assistant('Aqui estão as últimas despesas:\n$lines'));
        }
        return;
      }

      if (normalized.contains('total') ||
          normalized.contains('somar') ||
          normalized.contains('quanto gastei')) {
        final expenses = context.read<ExpenseProvider>().expenses;
        final total = expenses.fold<double>(0, (s, e) => s + e.amount);
        final brl = NumberFormat.simpleCurrency(locale: 'pt_BR').format(total);
        _appendMessage(_ChatItem.assistant('Total de despesas: $brl.'));
        return;
      }

      _appendMessage(_ChatItem.assistant(
          'Posso: definir orçamento ("Orçamento 4000"), status do mês ("status"), aconselhar compras ("posso comprar X por 2500?"), registrar ("adicionar ..."), listar ("listar"), e total ("total").'));
    } catch (e) {
      _appendMessage(_ChatItem.assistant('Ocorreu um erro: $e'));
    } finally {
      setState(() => _sending = false);
    }
  }

  String _mapBackendCategoryToApp(String? backend) {
    // Backend uses: food, transportation, housing, healthcare, entertainment, education, others
    switch ((backend ?? '').toLowerCase()) {
      case 'food':
        return 'alimentacao';
      case 'transportation':
        return 'transporte';
      case 'housing':
        return 'moradia';
      case 'healthcare':
        return 'saude';
      case 'entertainment':
        return 'lazer';
      case 'education':
        return 'educacao';
      default:
        return 'outros';
    }
  }

  double? _extractAmount(String text) {
    // Pattern for Brazilian currency format (R$ 12,34 or 12,34 or 12.34)
    final patterns = [
      RegExp(r'r\$\s*(\d{1,3}(?:\.\d{3})*),(\d{2})'),
      RegExp(r'(\d{1,3}(?:\.\d{3})*),(\d{2})\s*r\$'),
      RegExp(r'(\d{1,3}(?:\.\d{3})*),(\d{2})'),
      RegExp(r'(\d+)[\.,](\d{2})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final integerPart = match.group(1)?.replaceAll('.', '') ?? '0';
        final decimalPart = match.group(2) ?? '00';
        return double.tryParse('$integerPart.$decimalPart');
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xubudget Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final item = _messages[index];
                final isUser = item.role == _Role.user;
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText:
                          'Fale com a IA... (ex.: Adicionar Uber 38,90 18/09)',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: const Text('Enviar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Role { user, assistant }

class _ChatItem {
  final _Role role;
  final String text;
  _ChatItem(this.role, this.text);
  factory _ChatItem.user(String t) => _ChatItem(_Role.user, t);
  factory _ChatItem.assistant(String t) => _ChatItem(_Role.assistant, t);
}
