class Transaction {
  final String id;
  final double amount;
  final String type; // 'income' or 'expense'
  final String categoryKey;
  final String description;
  final DateTime date;

  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.categoryKey,
    required this.description,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] ?? '',
      categoryKey: json['categoryKey'] ?? '',
      description: json['description'] ?? '',
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
    );
  }
}
