import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CategoryUtils {
  /// 获取分类对应的图标
  static IconData getCategoryIcon(String categoryKey) {
    switch (categoryKey) {
      // 支出分类图标 🍔⚕️🚌🏠🍿🎓📞💬📈🛒📝
      case 'food':
        return Icons.restaurant; // 餐饮 🍔
      case 'medical':
        return Icons.medical_services; // 医疗 ⚕️
      case 'transport':
        return CupertinoIcons.bus; // 交通 🚌
      case 'housing':
        return CupertinoIcons.house_fill; // 住房 🏠
      case 'snacks':
        return Icons.icecream; // 零食 🍿
      case 'learning':
        return CupertinoIcons.book_fill; // 学习 🎓
      case 'communication':
        return CupertinoIcons.phone_fill; // 通讯 📞
      case 'social':
        return CupertinoIcons.person_2_fill; // 社交 💬
      case 'investment':
        return CupertinoIcons.chart_bar_circle_fill; // 投资 📈
      case 'shopping':
        return CupertinoIcons.shopping_cart; // 购物 🛒

      // 收入分类图标 💼👨‍💻💰🧧🎁
      case 'salary':
        return CupertinoIcons.briefcase_fill; // 工资 💼
      case 'part_time':
        return CupertinoIcons.clock_fill; // 兼职 👨‍💻
      case 'financial':
        return CupertinoIcons.money_dollar_circle_fill; // 理财 💰
      case 'red_packet':
        return CupertinoIcons.gift_fill; // 红包 🧧

      // 通用分类
      case 'other':
        return CupertinoIcons.ellipsis_circle_fill; // 其他 📝 或 🎁

      // 默认图标
      default:
        return CupertinoIcons.circle_fill;
    }
  }

  /// 获取分类对应的中文名称
  static String getCategoryName(String categoryKey) {
    switch (categoryKey) {
      // 支出分类
      case 'food':
        return '餐饮';
      case 'medical':
        return '医疗';
      case 'transport':
        return '交通';
      case 'housing':
        return '住房';
      case 'snacks':
        return '零食';
      case 'learning':
        return '学习';
      case 'communication':
        return '通讯';
      case 'social':
        return '社交';
      case 'investment':
        return '投资';
      case 'shopping':
        return '购物';

      // 收入分类
      case 'salary':
        return '工资';
      case 'part_time':
        return '兼职';
      case 'financial':
        return '理财';
      case 'red_packet':
        return '红包';

      // 通用分类
      case 'other':
        return '其他';

      default:
        return categoryKey;
    }
  }
}
