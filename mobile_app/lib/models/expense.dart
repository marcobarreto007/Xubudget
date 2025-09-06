// WHY: This file defines the core data model for an expense.
// Keeping it in a separate `models` directory helps organize the data
// structure of the application and decouples it from the UI or business logic.

class Expense {
  final int? id;
  final String description;
  final double amount;
  final DateTime date;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
  });
}
