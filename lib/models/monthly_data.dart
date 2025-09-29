class MonthlyData {
  final int month;
  final String monthName;
  final double totalIncome;
  final double totalExpense;
  final double balance;

  MonthlyData({
    required this.month,
    required this.monthName,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  factory MonthlyData.fromJson(Map<String, dynamic> json) {
    return MonthlyData(
      month: json['month'] ?? 0,
      monthName: json['monthName'] ?? '',
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalExpense: (json['totalExpense'] ?? 0).toDouble(),
      balance: (json['balance'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'month': month,
      'monthName': monthName,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': balance,
    };
  }
}
