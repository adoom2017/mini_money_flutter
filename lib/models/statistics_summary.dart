class StatisticsSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  StatisticsSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  factory StatisticsSummary.fromJson(Map<String, dynamic> json) {
    return StatisticsSummary(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
    );
  }
}

class CategoryStat {
  final String categoryKey;
  final double total;
  final double percentage;

  CategoryStat({
    required this.categoryKey,
    required this.total,
    required this.percentage,
  });

  factory CategoryStat.fromJson(Map<String, dynamic> json) {
    return CategoryStat(
      categoryKey: json['categoryKey'] ?? '',
      total: (json['amount'] ?? json['total'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}
