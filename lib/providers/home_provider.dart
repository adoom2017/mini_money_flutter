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

  Future<void> fetchData([DateTime? month]) async {
    _isLoading = true;
    notifyListeners();

    _selectedMonth = month ?? _selectedMonth;

    try {
      await Future.wait([
        _fetchStatistics(),
        _fetchTransactionsForMonth(),
      ]);
    } catch (e) {
      AppLogger.error('Error fetching home data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchStatistics() async {
    final response = await _apiService.getStatistics(
      y: _selectedMonth.year,
      m: _selectedMonth.month,
    );

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

  Future<void> _fetchTransactionsForMonth() async {
    final monthStr =
        "${_selectedMonth.year}-${_selectedMonth.month.toString().padLeft(2, '0')}";

    AppLogger.info(
        'HomeProvider._fetchTransactionsForMonth called with monthStr: $monthStr');

    final response = await _apiService.getTransactions(m: monthStr);

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
