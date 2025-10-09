class TransactionCategory {
  final String key;
  final String name;
  final String icon;
  final String color;

  TransactionCategory({
    required this.key,
    required this.name,
    required this.icon,
    this.color = '',
  });

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'name': name,
      'icon': icon,
      if (color.isNotEmpty) 'color': color,
    };
  }
}
