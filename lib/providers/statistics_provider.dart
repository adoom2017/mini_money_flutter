import 'dart:convert';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/statistics_summary.dart';

class StatisticsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  StatisticsSummary? _summary;
  StatisticsSummary? get summary => _summary;

  List<CategoryStat> _expenseStats = [];
  List<CategoryStat> get expenseStats => _expenseStats;

  List<CategoryStat> _incomeStats = [];
  List<CategoryStat> get incomeStats => _incomeStats;

  StatisticsProvider() {
    fetchDataForMonth(_selectedDate);
  }

  Future<void> fetchDataForMonth(DateTime date) async {
    _selectedDate = date;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getStatistics(
        y: _selectedDate.year,
        m: _selectedDate.month,
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
      } else {
        _summary = null;
        _expenseStats = [];
        _incomeStats = [];
      }
    } catch (e) {
      print('Error fetching statistics: $e');
      _summary = null;
      _expenseStats = [];
      _incomeStats = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null && picked != _selectedDate) {
      fetchDataForMonth(picked);
    }
  }
}
