// WHY: Web implementation using window.localStorage (very simple, not encrypted)
// Allows app to run on Chrome when emulator is broken.
import 'dart:convert';
import 'dart:html' as html;
import '../models/expense.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _key = 'xubudget_expenses';
  static const String _seedFlagKey = 'xubudget_seeded_v1';

  // Seed simples para primeira execução no Web
  void _maybeSeed() {
    final seeded = html.window.localStorage[_seedFlagKey];
    final raw = html.window.localStorage[_key];
    if (seeded == 'true') return;
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List && decoded.isNotEmpty) {
          return; // já possui dados
        }
      } catch (_) {
        // se falhar decode, vamos semear mesmo assim
      }
    }
    final now = DateTime.now();
    final samples = [
      Expense(
        id: 1,
        description: 'Mercado Bom Preço',
        amount: 120.50,
        category: 'alimentacao',
        date: now.subtract(const Duration(days: 1)),
        source: ExpenseSource.manual,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Expense(
        id: 2,
        description: 'Uber Aeroporto',
        amount: 38.90,
        category: 'transporte',
        date: now.subtract(const Duration(days: 2)),
        source: ExpenseSource.manual,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Expense(
        id: 3,
        description: 'Conta de Luz',
        amount: 210.00,
        category: 'moradia',
        date: now.subtract(const Duration(days: 7)),
        source: ExpenseSource.manual,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];
    _save(samples);
    html.window.localStorage[_seedFlagKey] = 'true';
  }

  Future<int> insertExpense(Expense expense) async {
    _maybeSeed();
    final list = await getAllExpenses();
    final newId = (list.isEmpty
        ? 1
        : (list.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b) + 1));
    final newExpense = Expense(
      id: newId,
      description: expense.description,
      amount: expense.amount,
      category: expense.category,
      date: expense.date,
      source: expense.source,
      receiptImageHash: expense.receiptImageHash,
      createdAt: expense.createdAt,
    );
    list.insert(0, newExpense);
    _save(list);
    return newId;
  }

  Future<List<Expense>> getAllExpenses() async {
    _maybeSeed();
    final raw = html.window.localStorage[_key];
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Expense.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<int> updateExpense(Expense expense) async {
    _maybeSeed();
    final list = await getAllExpenses();
    final idx = list.indexWhere((e) => e.id == expense.id);
    if (idx >= 0) {
      list[idx] = expense;
      _save(list);
      return 1;
    }
    return 0;
  }

  Future<int> deleteExpense(int id) async {
    _maybeSeed();
    final list = await getAllExpenses();
    final before = list.length;
    list.removeWhere((e) => e.id == id);
    _save(list);
    return before - list.length;
  }

  Future<void> close() async {}

  void _save(List<Expense> expenses) {
    final data = jsonEncode(expenses.map((e) => e.toMap()).toList());
    html.window.localStorage[_key] = data;
  }
}
