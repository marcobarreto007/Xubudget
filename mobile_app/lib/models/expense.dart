import 'package:flutter/foundation.dart';

enum ExpenseSource { manual, ocr, voice, imported }

 @immutable
class Expense {
  final int? id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final ExpenseSource source;
  final String? receiptImageHash; // For future deduplication
  final DateTime createdAt;

  const Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.source,
    this.receiptImageHash,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'source': source.name,
      'receiptImageHash': receiptImageHash,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      source: ExpenseSource.values.byName(map['source']),
      receiptImageHash: map['receiptImageHash'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}