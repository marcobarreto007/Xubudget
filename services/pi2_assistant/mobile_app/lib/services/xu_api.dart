import 'dart:convert';
import 'package:http/http.dart' as http;

class XuApiConfig {
  static const String baseUrl = '/api';
}

class XuApi {
  Future<Map<String, dynamic>> getState({String userId = 'default'}) async {
    final uri = Uri.parse('${XuApiConfig.baseUrl}/state?user_id=$userId');
    final response = await http.get(uri).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Failed to load state: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> sendChat(String message, {String userId = 'default'}) async {
    final uri = Uri.parse('${XuApiConfig.baseUrl}/chat');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'message': message, 'user_id': userId});
    final response = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Failed to send message: ${response.statusCode}');
  }
}

// --- Income Models & API ---
class IncomeItem {
  final double amount;
  final String source;
  final DateTime ts;
  IncomeItem({required this.amount, required this.source, required this.ts});
  factory IncomeItem.fromJson(Map<String, dynamic> j) => IncomeItem(
    amount: (j['amount'] ?? 0).toDouble(),
    source: j['source']?.toString() ?? '',
    ts: DateTime.tryParse(j['ts']?.toString() ?? '') ?? DateTime.now(),
  );
}

extension XuApiIncomes on XuApi {
  Future<List<IncomeItem>> getIncomes({String userId = 'default', int limit = 50}) async {
    final res = await http.get(Uri.parse('${XuApiConfig.baseUrl}/incomes?user_id=$userId&limit=$limit'));
    if (res.statusCode != 200) return [];
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['items'] as List? ?? []).map((e) => IncomeItem.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>?> addIncome({String userId = 'default', required double amount, String? source}) async {
    final res = await http.post(
      Uri.parse('${XuApiConfig.baseUrl}/add_income'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'amount': amount, 'source': source}),
    );
    return res.statusCode == 200 ? jsonDecode(res.body) : null;
  }

  Future<Map<String, dynamic>?> setBudgetMode({String userId = 'default', required String mode}) async {
    final res = await http.post(
      Uri.parse('${XuApiConfig.baseUrl}/set_budget_mode'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'mode': mode}),
    );
    return res.statusCode == 200 ? jsonDecode(res.body) : null;
  }
}

// --- Sub-category Budget Models & API ---
class BudgetStructure {
  final Map<String, CategoryData> structure;
  final BudgetSummary summary;
  
  BudgetStructure({required this.structure, required this.summary});
  
  factory BudgetStructure.fromJson(Map<String, dynamic> json) => BudgetStructure(
    structure: (json['structure'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, CategoryData.fromJson(value)),
    ),
    summary: BudgetSummary.fromJson(json['summary']),
  );
}

class CategoryData {
  final String name;
  final double budget;
  final double spent;
  final double remaining;
  final double percentage;
  final bool isOver;
  final Map<String, SubcategoryData> subcategories;
  final double subcategoriesTotalBudget;
  final double subcategoriesTotalSpent;
  
  CategoryData({
    required this.name,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.isOver,
    required this.subcategories,
    required this.subcategoriesTotalBudget,
    required this.subcategoriesTotalSpent,
  });
  
  factory CategoryData.fromJson(Map<String, dynamic> json) => CategoryData(
    name: json['name'],
    budget: (json['budget'] ?? 0).toDouble(),
    spent: (json['spent'] ?? 0).toDouble(),
    remaining: (json['remaining'] ?? 0).toDouble(),
    percentage: (json['percentage'] ?? 0).toDouble(),
    isOver: json['is_over'] ?? false,
    subcategories: (json['subcategories'] as Map<String, dynamic>).map(
      (key, value) => MapEntry(key, SubcategoryData.fromJson(value)),
    ),
    subcategoriesTotalBudget: (json['subcategories_total_budget'] ?? 0).toDouble(),
    subcategoriesTotalSpent: (json['subcategories_total_spent'] ?? 0).toDouble(),
  );
}

class SubcategoryData {
  final String name;
  final double budget;
  final double spent;
  final double remaining;
  final double percentage;
  final bool isOver;
  final bool isActive;
  
  SubcategoryData({
    required this.name,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentage,
    required this.isOver,
    required this.isActive,
  });
  
  factory SubcategoryData.fromJson(Map<String, dynamic> json) => SubcategoryData(
    name: json['name'],
    budget: (json['budget'] ?? 0).toDouble(),
    spent: (json['spent'] ?? 0).toDouble(),
    remaining: (json['remaining'] ?? 0).toDouble(),
    percentage: (json['percentage'] ?? 0).toDouble(),
    isOver: json['is_over'] ?? false,
    isActive: json['is_active'] ?? false,
  );
}

class BudgetSummary {
  final double totalBudget;
  final double totalSpent;
  final double totalRemaining;
  final int categoriesCount;
  final int categoriesOverBudget;
  final int subcategoriesOverBudget;
  final double overallPercentage;
  
  BudgetSummary({
    required this.totalBudget,
    required this.totalSpent,
    required this.totalRemaining,
    required this.categoriesCount,
    required this.categoriesOverBudget,
    required this.subcategoriesOverBudget,
    required this.overallPercentage,
  });
  
  factory BudgetSummary.fromJson(Map<String, dynamic> json) => BudgetSummary(
    totalBudget: (json['total_budget'] ?? 0).toDouble(),
    totalSpent: (json['total_spent'] ?? 0).toDouble(),
    totalRemaining: (json['total_remaining'] ?? 0).toDouble(),
    categoriesCount: json['categories_count'] ?? 0,
    categoriesOverBudget: json['categories_over_budget'] ?? 0,
    subcategoriesOverBudget: json['subcategories_over_budget'] ?? 0,
    overallPercentage: (json['overall_percentage'] ?? 0).toDouble(),
  );
}

extension XuApiSubcategorized on XuApi {
  Future<BudgetStructure> getBudgetStructure({String userId = 'default'}) async {
    final res = await http.get(Uri.parse('${XuApiConfig.baseUrl}/budget_structure?user_id=$userId'));
    if (res.statusCode != 200) throw Exception('Failed to load budget structure');
    return BudgetStructure.fromJson(jsonDecode(res.body));
  }
  
  Future<bool> setSubcategoryBudget({
    String userId = 'default',
    required String category,
    required String subcategory,
    required double budget,
  }) async {
    final res = await http.post(
      Uri.parse('${XuApiConfig.baseUrl}/set_subcategory_budget_v2'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'category': category,
        'subcategory': subcategory,
        'monthly_budget': budget,
        'is_active': true,
      }),
    );
    return res.statusCode == 200;
  }
  
  Future<bool> transferBudget({
    String userId = 'default',
    required String fromCategory,
    required String fromSubcategory,
    required String toCategory,
    required String toSubcategory,
    required double amount,
  }) async {
    final res = await http.post(
      Uri.parse('${XuApiConfig.baseUrl}/transfer_budget'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'from_category': fromCategory,
        'from_subcategory': fromSubcategory,
        'to_category': toCategory,
        'to_subcategory': toSubcategory,
        'amount': amount,
      }),
    );
    return res.statusCode == 200;
  }
}

// --- Icon Budget Models & API ---
class BudgetIconData {
  final String id;
  final String name;
  final String emoji;
  final double budget;
  final double spent;
  final bool active;

  BudgetIconData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.budget,
    required this.spent,
    required this.active,
  });

  factory BudgetIconData.fromJson(Map<String, dynamic> json) {
    return BudgetIconData(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      budget: (json['budget'] ?? 0).toDouble(),
      spent: (json['spent'] ?? 0).toDouble(),
      active: json['active'] ?? false,
    );
  }
}

extension XuApiIconBudget on XuApi {
  Future<List<BudgetIconData>> getIcons({String userId = 'default'}) async {
    final res = await http.get(Uri.parse('${XuApiConfig.baseUrl}/get_icons?user_id=$userId'));
    if (res.statusCode != 200) throw Exception('Failed to load icons');
    final List<dynamic> data = jsonDecode(utf8.decode(res.bodyBytes));
    return data.map((e) => BudgetIconData.fromJson(e)).toList();
  }

  Future<void> activateIcon({String userId = 'default', required String categoryId, required double amount}) async {
    final res = await http.post(
      Uri.parse('${XuApiConfig.baseUrl}/activate_icon'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'category_id': categoryId, 'amount': amount}),
    );
    if (res.statusCode != 200) throw Exception('Failed to activate icon');
  }
}
