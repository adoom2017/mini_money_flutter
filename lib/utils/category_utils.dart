import 'package:flutter/material.dart';
import '../models/transaction_category.dart';

class CategoryUtils {
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
}
