/// Essential budget categories based on best financial practices
/// 50/30/20 rule: 50% needs, 30% wants, 20% savings

class EssentialCategory {
  final String key;
  final String name;
  final String icon;
  final String color;
  final double percentage;
  final String priority;
  final String description;

  const EssentialCategory({
    required this.key,
    required this.name,
    required this.icon,
    required this.color,
    required this.percentage,
    required this.priority,
    required this.description,
  });
}

class EssentialCategories {
  static const List<EssentialCategory> categories = [
    EssentialCategory(
      key: 'housing',
      name: 'Housing & Rent',
      icon: '🏠',
      color: '#8b5cf6',
      percentage: 25.0,
      priority: 'essential',
      description: 'Rent, mortgage, property taxes, insurance',
    ),
    EssentialCategory(
      key: 'food',
      name: 'Food & Groceries',
      icon: '🍽️',
      color: '#10b981',
      percentage: 15.0,
      priority: 'essential',
      description: 'Groceries, dining out, food delivery',
    ),
    EssentialCategory(
      key: 'utilities',
      name: 'Utilities & Bills',
      icon: '⚡',
      color: '#84cc16',
      percentage: 10.0,
      priority: 'essential',
      description: 'Electricity, water, gas, internet, phone',
    ),
    EssentialCategory(
      key: 'transport',
      name: 'Transportation',
      icon: '🚗',
      color: '#3b82f6',
      percentage: 10.0,
      priority: 'essential',
      description: 'Car payment, gas, public transport, maintenance',
    ),
    EssentialCategory(
      key: 'health',
      name: 'Health & Medical',
      icon: '💊',
      color: '#ef4444',
      percentage: 8.0,
      priority: 'essential',
      description: 'Health insurance, doctor visits, medications',
    ),
    EssentialCategory(
      key: 'savings',
      name: 'Savings & Investment',
      icon: '💰',
      color: '#fbbf24',
      percentage: 20.0,
      priority: 'essential',
      description: 'Emergency fund, retirement, investments',
    ),
    EssentialCategory(
      key: 'shopping',
      name: 'Shopping & Personal',
      icon: '🛍️',
      color: '#ec4899',
      percentage: 5.0,
      priority: 'important',
      description: 'Clothing, personal care, household items',
    ),
    EssentialCategory(
      key: 'entertainment',
      name: 'Entertainment & Fun',
      icon: '🎬',
      color: '#f97316',
      percentage: 4.0,
      priority: 'optional',
      description: 'Movies, games, hobbies, subscriptions',
    ),
    EssentialCategory(
      key: 'education',
      name: 'Education & Learning',
      icon: '📚',
      color: '#06b6d4',
      percentage: 2.0,
      priority: 'important',
      description: 'Courses, books, professional development',
    ),
    EssentialCategory(
      key: 'other',
      name: 'Other Expenses',
      icon: '📦',
      color: '#6b7280',
      percentage: 1.0,
      priority: 'optional',
      description: 'Miscellaneous, unexpected expenses',
    ),
  ];

  static EssentialCategory? getCategory(String key) {
    try {
      return categories.firstWhere((cat) => cat.key == key);
    } catch (e) {
      return null;
    }
  }

  static List<EssentialCategory> getEssentialCategories() {
    return categories.where((cat) => cat.priority == 'essential').toList();
  }

  static List<EssentialCategory> getImportantCategories() {
    return categories.where((cat) => cat.priority == 'important').toList();
  }

  static List<EssentialCategory> getOptionalCategories() {
    return categories.where((cat) => cat.priority == 'optional').toList();
  }

  static double getTotalEssentialPercentage() {
    return getEssentialCategories().fold(0.0, (sum, cat) => sum + cat.percentage);
  }

  static double getTotalImportantPercentage() {
    return getImportantCategories().fold(0.0, (sum, cat) => sum + cat.percentage);
  }

  static double getTotalOptionalPercentage() {
    return getOptionalCategories().fold(0.0, (sum, cat) => sum + cat.percentage);
  }
}

class BudgetRules {
  static const Map<String, Map<String, dynamic>> rules = {
    'essential': {
      'maxPercentage': 70.0,
      'description': 'Essential expenses (needs)',
      'color': '#ef4444',
    },
    'important': {
      'maxPercentage': 20.0,
      'description': 'Important expenses (wants)',
      'color': '#f59e0b',
    },
    'optional': {
      'maxPercentage': 10.0,
      'description': 'Optional expenses (wants)',
      'color': '#10b981',
    },
  };

  static List<String> getFinancialTips() {
    return [
      "Follow the 50/30/20 rule: 50% needs, 30% wants, 20% savings",
      "Build an emergency fund with 3-6 months of expenses",
      "Pay yourself first - save before spending",
      "Track every expense to understand your spending patterns",
      "Review and adjust your budget monthly",
      "Use the envelope method for variable expenses",
      "Automate your savings and bill payments",
      "Avoid lifestyle inflation when income increases",
      "Invest in your financial education",
      "Set specific, measurable financial goals"
    ];
  }
}
