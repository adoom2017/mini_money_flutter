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
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpense: (json['totalExpense'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
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
      categoryKey: json['categoryKey'],
      total: (json['total'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
    );
  }
}
