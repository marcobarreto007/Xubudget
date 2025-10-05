import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String displayName;
  final IconData icon;
  final Color color;

  const ExpenseCategory({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.color,
  });
}

// Lista central de todas as categorias disponíveis
final List<ExpenseCategory> appCategories = [
  const ExpenseCategory(
      id: 'alimentacao',
      displayName: 'Alimentação',
      icon: Icons.restaurant,
      color: Colors.orange),
  const ExpenseCategory(
      id: 'transporte',
      displayName: 'Transporte',
      icon: Icons.directions_car,
      color: Colors.blue),
  const ExpenseCategory(
      id: 'saude',
      displayName: 'Saúde',
      icon: Icons.medical_services,
      color: Colors.red),
  const ExpenseCategory(
      id: 'moradia',
      displayName: 'Moradia',
      icon: Icons.home,
      color: Colors.green),
  const ExpenseCategory(
      id: 'lazer',
      displayName: 'Lazer',
      icon: Icons.movie,
      color: Colors.purple),
  const ExpenseCategory(
      id: 'educacao',
      displayName: 'Educação',
      icon: Icons.school,
      color: Colors.teal),
  const ExpenseCategory(
      id: 'outros',
      displayName: 'Outros',
      icon: Icons.category,
      color: Colors.grey),
];

// Helper para encontrar uma categoria pelo ID, com fallback para 'outros'
ExpenseCategory findCategoryById(String id) {
  return appCategories.firstWhere((c) => c.id == id,
      orElse: () => appCategories.last);
}
