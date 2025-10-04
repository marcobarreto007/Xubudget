import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../services/xu_api.dart';
import '../strings_en.dart';
import 'subcategorized_budget_view.dart';

// Final consolidated version of the dashboard UI

final _fmt = NumberFormat.currency(locale: 'en_CA', symbol: r'$');
String money(num v) => _fmt.format(v);

class XuDashboardPage extends StatefulWidget {
  const XuDashboardPage({super.key});

  @override
  State<XuDashboardPage> createState() => _XuDashboardPageState();
}

class _XuDashboardPageState extends State<XuDashboardPage> with TickerProviderStateMixin {
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
    return SingleChildScrollView(
      child: Column(
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
          _IconBudgetSection(),
          const SizedBox(height: 20),
          const SubcategorizedBudgetPanel(),
        ],
      ),
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

// NOVA SEÇÃO COM ÍCONES
class _IconBudgetSection extends StatefulWidget {
  @override
  _IconBudgetSectionState createState() => _IconBudgetSectionState();
}

class _IconBudgetSectionState extends State<_IconBudgetSection> {
  final List<BudgetIcon> icons = [
    BudgetIcon('🛒', 'Supermercado', 400, 0),
    BudgetIcon('🍕', 'Fast Food', 80, 0),
    BudgetIcon('☕', 'Café', 60, 0),
    BudgetIcon('🍺', 'Bar', 100, 0),
    BudgetIcon('🥗', 'Restaurante', 200, 0),
    BudgetIcon('⛽', 'Combustível', 300, 0),
    BudgetIcon('🚇', 'Metro', 80, 0),
    BudgetIcon('🚗', 'Uber', 120, 0),
    BudgetIcon('🚙', 'Mecânico', 150, 0),
    BudgetIcon('🅿️', 'Parking', 60, 0),
    BudgetIcon('🏠', 'Aluguel', 1200, 0),
    BudgetIcon('⚡', 'Luz', 120, 0),
    BudgetIcon('💧', 'Água', 80, 0),
    BudgetIcon('📱', 'Internet', 100, 0),
    BudgetIcon('🧽', 'Casa', 60, 0),
    BudgetIcon('🏥', 'Médico', 200, 0),
    BudgetIcon('💊', 'Remédio', 100, 0),
    BudgetIcon('🦷', 'Dentista', 150, 0),
    BudgetIcon('👓', 'Ótica', 80, 0),
    BudgetIcon('💪', 'Academia', 80, 0),
    BudgetIcon('🎬', 'Cinema', 80, 0),
    BudgetIcon('📺', 'Netflix', 50, 0),
    BudgetIcon('🎮', 'Games', 40, 0),
    BudgetIcon('🏖️', 'Viagem', 300, 0),
    BudgetIcon('📚', 'Livros', 60, 0),
    BudgetIcon('👕', 'Roupas', 150, 0),
    BudgetIcon('👟', 'Sapatos', 80, 0),
    BudgetIcon('💻', 'Tech', 200, 0),
    BudgetIcon('🎁', 'Presentes', 100, 0),
    BudgetIcon('🛍️', 'Compras', 80, 0),
    BudgetIcon('✂️', 'Cabelo', 60, 0),
    BudgetIcon('🧼', 'Lavanderia', 40, 0),
    BudgetIcon('🔧', 'Reparos', 80, 0),
    BudgetIcon('📄', 'Documentos', 50, 0),
    BudgetIcon('💼', 'Trabalho', 100, 0),
    BudgetIcon('💳', 'Cartão', 200, 0),
    BudgetIcon('🏦', 'Empréstimo', 300, 0),
    BudgetIcon('💰', 'Invest', 400, 0),
    BudgetIcon('🎯', 'Reserva', 200, 0),
    BudgetIcon('📊', 'Seguros', 150, 0),
    BudgetIcon('👶', 'Filhos', 300, 0),
    BudgetIcon('🐕', 'Pet', 80, 0),
    BudgetIcon('👴', 'Pais', 200, 0),
    BudgetIcon('🎂', 'Festas', 100, 0),
    BudgetIcon('🚼', 'Creche', 400, 0),
    BudgetIcon('❓', 'Imprevistos', 150, 0),
    BudgetIcon('🎲', 'Jogos', 50, 0),
    BudgetIcon('📰', 'Assinatura', 30, 0),
    BudgetIcon('🚬', 'Vícios', 60, 0),
    BudgetIcon('💸', 'Outros', 100, 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Budget Icons', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              childAspectRatio: 1.0,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final icon = icons[index];
              return GestureDetector(
                onTap: () => _activateIcon(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: icon.isActive ? Colors.blue[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: icon.isOver ? Colors.red : 
                             icon.isActive ? Colors.blue : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(icon.emoji, style: const TextStyle(fontSize: 32)),
                      const SizedBox(height: 4),
                      Text('\$${icon.budget}', 
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      if (icon.spent > 0) ...[
                        const SizedBox(height: 2),
                        Text('Spent: \$${icon.spent.toInt()}', 
                          style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                        LinearProgressIndicator(
                          value: icon.percentage,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(
                            icon.isOver ? Colors.red : Colors.blue),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _activateIcon(int index) {
    setState(() {
      icons[index] = icons[index].copyWith(spent: icons[index].spent + 10);
    });
  }
}

class BudgetIcon {
  final String emoji;
  final String category;
  final double budget;
  final double spent;
  
  BudgetIcon(this.emoji, this.category, this.budget, this.spent);
  
  bool get isActive => spent > 0;
  bool get isOver => spent > budget;
  double get percentage => budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
  
  BudgetIcon copyWith({double? spent}) {
    return BudgetIcon(emoji, category, budget, spent ?? this.spent);
  }
}