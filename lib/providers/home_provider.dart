import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/transaction.dart';
import '../models/statistics_summary.dart';
import '../utils/app_logger.dart';

class HomeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StatisticsSummary? _summary;
  StatisticsSummary? get summary => _summary;

  List<CategoryStat> _expenseStats = [];
  List<CategoryStat> get expenseStats => _expenseStats;

  List<CategoryStat> _incomeStats = [];
  List<CategoryStat> get incomeStats => _incomeStats;

  List<Transaction> _transactions = [];
  List<Transaction> get transactions => _transactions;

  DateTime _selectedMonth = DateTime.now();
  DateTime get selectedMonth => _selectedMonth;

  // 用于防止竞争条件的请求计数器
  int _requestCounter = 0;

  Future<void> fetchData([DateTime? month]) async {
    // 增加请求计数器，用于标识当前请求
    final currentRequest = ++_requestCounter;

    final targetMonth = month ?? _selectedMonth;

    // 如果是相同的月份，避免重复请求
    if (month != null &&
        _selectedMonth.year == targetMonth.year &&
        _selectedMonth.month == targetMonth.month &&
        !_isLoading) {
      return;
    }

    _isLoading = true;
    _selectedMonth = targetMonth;
    notifyListeners();

    try {
      await Future.wait([
        _fetchStatistics(currentRequest),
        _fetchTransactionsForMonth(currentRequest),
      ]);

      // 只有当这是最新的请求时才更新状态
      if (currentRequest == _requestCounter) {
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error fetching home data: $e');
      // 只有当这是最新的请求时才更新状态
      if (currentRequest == _requestCounter) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _fetchStatistics(int requestId) async {
    final response = await _apiService.getStatistics(
      y: _selectedMonth.year,
      m: _selectedMonth.month,
    );

    // 检查请求是否仍然有效
    if (requestId != _requestCounter) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _summary = StatisticsSummary.fromJson(data['summary']);
      _expenseStats = (data['expenseBreakdown'] as List)
          .map((item) => CategoryStat.fromJson(item))
          .toList();
      _incomeStats = (data['incomeBreakdown'] as List)
          .map((item) => CategoryStat.fromJson(item))
          .toList();
    }
  }

  Future<void> _fetchTransactionsForMonth(int requestId) async {
    final monthStr =
        "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}";

    AppLogger.info(
        'HomeProvider._fetchTransactionsForMonth called with monthStr: $monthStr');

    final response = await _apiService.getTransactions(m: monthStr);

    // 检查请求是否仍然有效
    if (requestId != _requestCounter) return;

    AppLogger.info('API response status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      _transactions = data.map((item) => Transaction.fromJson(item)).toList();
    } else {
      AppLogger.error(
          'Failed to fetch transactions, status: ${response.statusCode}');
    }
  }
}
