class TransactionCategory {
  final String key;
  final String icon;
  final String color;

  TransactionCategory({
    required this.key,
    required this.icon,
    required this.color,
  });

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      key: json['key'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
    );
  }
}
