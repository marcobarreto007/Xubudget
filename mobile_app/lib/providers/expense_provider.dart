// WHY: Provider for managing expense state throughout the app
import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../db/database_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  double get totalExpenses => _expenses.fold(0.0, (sum, expense) => sum + expense.amount);

  Future<void> fetchExpenses() async {
    _setLoading(true);
    try {
      _expenses = await _databaseService.getAllExpenses();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      final id = await _databaseService.insertExpense(expense);
      final newExpense = Expense(
        id: id,
        description: expense.description,
        amount: expense.amount,
        category: expense.category,
        date: expense.date,
        source: expense.source,
        receiptImageHash: expense.receiptImageHash,
        createdAt: expense.createdAt,
      );
      _expenses.insert(0, newExpense); // Add to beginning for newest first
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding expense: $e');
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _databaseService.updateExpense(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = expense;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _databaseService.deleteExpense(id);
      _expenses.removeWhere((expense) => expense.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Map<String, double> getCategoryTotals() {
    final categoryTotals = <String, double>{};
    for (final expense in _expenses) {
      categoryTotals[expense.category] = 
          (categoryTotals[expense.category] ?? 0.0) + expense.amount;
    }
    return categoryTotals;
  }

  List<Expense> getExpensesByCategory(String category) {
    return _expenses.where((expense) => expense.category == category).toList();
  }

  List<Expense> getExpensesByDateRange(DateTime startDate, DateTime endDate) {
    return _expenses.where((expense) => 
        expense.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        expense.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();
  }
}