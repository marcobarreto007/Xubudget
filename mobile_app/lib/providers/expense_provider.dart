// WHY: State management for expenses using Provider pattern
import 'package:flutter/foundation.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  List<Expense> _expenses = [];
  
  List<Expense> get expenses => _expenses;
  
  void addExpense(Expense expense) {
    _expenses.add(expense);
    notifyListeners();
  }
  
  void removeExpense(Expense expense) {
    _expenses.remove(expense);
    notifyListeners();
  }
  
  void fetchExpenses() {
    // For now, just notify listeners - database integration will come later
    notifyListeners();
  }
  
  double get totalExpenses {
    return _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }
}