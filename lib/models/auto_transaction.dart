class AutoTransaction {
  final int? id;
  final int? userId;
  final String type; // 'income' or 'expense'
  final double amount;
  final String categoryKey;
  final String? description;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final int? dayOfMonth; // 1-31
  final int? dayOfWeek; // 0-6 (0=Sunday)
  final DateTime? nextExecutionDate;
  final DateTime? lastExecutionDate;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AutoTransaction({
    this.id,
    this.userId,
    required this.type,
    required this.amount,
    required this.categoryKey,
    this.description,
    required this.frequency,
    this.dayOfMonth,
    this.dayOfWeek,
    this.nextExecutionDate,
    this.lastExecutionDate,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory AutoTransaction.fromJson(Map<String, dynamic> json) {
    return AutoTransaction(
      id: json['id'],
      userId: json['userId'],
      type: json['type'],
      amount: (json['amount'] ?? 0).toDouble(),
      categoryKey: json['categoryKey'] ?? '',
      description: json['description'],
      frequency: json['frequency'] ?? 'monthly',
      dayOfMonth: json['dayOfMonth'],
      dayOfWeek: json['dayOfWeek'],
      nextExecutionDate: json['nextExecutionDate'] != null
          ? DateTime.parse(json['nextExecutionDate'])
          : null,
      lastExecutionDate: json['lastExecutionDate'] != null
          ? DateTime.parse(json['lastExecutionDate'])
          : null,
      isActive: json['isActive'] ?? true,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'type': type,
      'amount': amount,
      'categoryKey': categoryKey,
      if (description != null) 'description': description,
      'frequency': frequency,
      if (dayOfMonth != null) 'dayOfMonth': dayOfMonth,
      if (dayOfWeek != null) 'dayOfWeek': dayOfWeek,
      if (nextExecutionDate != null)
        'nextExecutionDate': nextExecutionDate!.toIso8601String(),
      if (lastExecutionDate != null)
        'lastExecutionDate': lastExecutionDate!.toIso8601String(),
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // 获取频率的中文名称
  String get frequencyName {
    switch (frequency) {
      case 'daily':
        return '每天';
      case 'weekly':
        return '每周';
      case 'monthly':
        return '每月';
      case 'yearly':
        return '每年';
      default:
        return frequency;
    }
  }

  // 获取星期的中文名称
  String get dayOfWeekName {
    if (dayOfWeek == null) return '';
    const weekDays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekDays[dayOfWeek!];
  }

  // 获取执行时间描述
  String get executionDescription {
    switch (frequency) {
      case 'daily':
        return '每天';
      case 'weekly':
        return '每周$dayOfWeekName';
      case 'monthly':
        return '每月$dayOfMonth日';
      case 'yearly':
        return '每年${nextExecutionDate?.month}月$dayOfMonth日';
      default:
        return '';
    }
  }
}
