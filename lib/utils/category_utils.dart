import 'package:flutter/material.dart';
import '../models/transaction_category.dart';

class CategoryUtils {
  /// 内置的分类名称映射（用于不需要从服务器加载分类的场景）
  static const Map<String, String> _builtInCategoryNames = {
    // 支出分类
    'food': '餐饮',
    'transport': '交通',
    'shopping': '购物',
    'entertainment': '娱乐',
    'healthcare': '医疗',
    'education': '教育',
    'housing': '住房',
    'communication': '通讯',
    'travel': '旅行',
    'clothing': '服饰',
    'daily': '日常',
    'beauty': '美容',
    'sports': '运动',
    'pets': '宠物',
    'gifts': '礼物',
    'charity': '公益',
    'other_expense': '其他支出',

    // 收入分类
    'salary': '工资',
    'bonus': '奖金',
    'investment': '投资',
    'parttime': '兼职',
    'business': '生意',
    'gift_income': '礼金',
    'other_income': '其他收入',
  };

  /// 获取统一的 emoji 文本样式
  /// 使用 fontFamilyFallback 确保跨平台 emoji 显示一致
  static TextStyle getEmojiTextStyle({
    required double fontSize,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      color: color,
      height: height ?? 1.0,
      fontFamilyFallback: const [
        'Apple Color Emoji', // iOS/macOS
        'Segoe UI Emoji', // Windows
        'Noto Color Emoji', // Android/Linux
        'Segoe UI Symbol', // Windows fallback
        'Android Emoji', // Android fallback
      ],
    );
  }

  /// 获取分类对应的图标 (emoji字符串)
  static String getCategoryIcon(TransactionCategory category) {
    return category.icon;
  }

  /// 获取分类对应的名称
  static String getCategoryName(TransactionCategory category) {
    return category.name;
  }

  /// 根据分类 key 从分类列表中查找分类对象
  static TransactionCategory? findCategoryByKey(
      List<TransactionCategory> categories, String categoryKey) {
    try {
      return categories.firstWhere((cat) => cat.key == categoryKey);
    } catch (e) {
      return null;
    }
  }

  /// 根据分类 key 从分类列表中获取图标（兼容旧代码）
  static String getCategoryIconByKey(
      List<TransactionCategory> categories, String categoryKey) {
    final category = findCategoryByKey(categories, categoryKey);
    return category?.icon ?? '❓'; // 默认问号图标
  }

  /// 根据分类 key 从分类列表中获取名称（兼容旧代码）
  static String getCategoryNameByKey(
      List<TransactionCategory> categories, String categoryKey) {
    final category = findCategoryByKey(categories, categoryKey);
    return category?.name ?? categoryKey; // 默认返回key本身
  }

  /// 根据分类 key 获取内置的中文名称（用于不需要分类列表的场景）
  static String getBuiltInCategoryName(String categoryKey) {
    return _builtInCategoryNames[categoryKey] ?? categoryKey;
  }
}
