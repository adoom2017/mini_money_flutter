import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import '../api/api_service.dart';
import '../models/statistics_summary.dart';
import '../models/monthly_data.dart';
import '../utils/app_logger.dart';

class StatisticsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  DateTime _selectedDate = DateTime.now();
  DateTime get selectedDate => _selectedDate;

  // 统计模式：monthly 或 yearly
  String _statisticsMode = 'monthly';
  String get statisticsMode => _statisticsMode;

  StatisticsSummary? _summary;
  StatisticsSummary? get summary => _summary;

  List<CategoryStat> _expenseStats = [];
  List<CategoryStat> get expenseStats => _expenseStats;

  List<CategoryStat> _incomeStats = [];
  List<CategoryStat> get incomeStats => _incomeStats;

  // 年度月份统计数据（用于年度视图）
  List<MonthlyData> _monthlyData = [];
  List<MonthlyData> get monthlyData => _monthlyData;

  StatisticsProvider() {
    // 确保月度统计模式下选择当前月份
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, 1); // 当前月份的第一天
    fetchDataForCurrentMode();
  }

  void switchStatisticsMode(String mode) {
    if (_statisticsMode != mode) {
      _statisticsMode = mode;

      // 根据模式设置合适的默认日期
      if (mode == 'monthly') {
        // 月度模式：选择当前月份的第一天
        final now = DateTime.now();
        _selectedDate = DateTime(now.year, now.month, 1);
      } else if (mode == 'yearly') {
        // 年度模式：选择当前年份的1月1日
        final now = DateTime.now();
        _selectedDate = DateTime(now.year, 1, 1);
      }

      fetchDataForCurrentMode();
    }
  }

  Future<void> fetchDataForCurrentMode() async {
    if (_statisticsMode == 'yearly') {
      await fetchDataForYear(_selectedDate);
    } else {
      await fetchDataForMonth(_selectedDate);
    }
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
      AppLogger.error('Error fetching statistics: $e');
      _summary = null;
      _expenseStats = [];
      _incomeStats = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDataForYear(DateTime date) async {
    _selectedDate = DateTime(date.year);
    _isLoading = true;
    notifyListeners();

    try {
      // 获取整年的统计数据，使用period参数
      final response = await _apiService.getStatistics(
        y: _selectedDate.year,
        period: 'year', // 明确指定按年统计
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _summary = StatisticsSummary.fromJson(data['summary']);

        // 处理分类统计（年度汇总）
        _expenseStats = (data['expenseBreakdown'] as List)
            .map((item) => CategoryStat.fromJson(item))
            .toList();
        _incomeStats = (data['incomeBreakdown'] as List)
            .map((item) => CategoryStat.fromJson(item))
            .toList();

        // 处理月度数据 - 年度统计需要获取每个月的数据用于趋势图
        if (data['monthlyData'] != null) {
          _monthlyData = (data['monthlyData'] as List)
              .map((item) => MonthlyData.fromJson(item))
              .toList();
        } else {
          // 如果API不返回monthlyData，需要逐月获取数据
          await _fetchMonthlyDataForYear(_selectedDate.year);
        }
      } else {
        _summary = null;
        _expenseStats = [];
        _incomeStats = [];
        // 为年度模式提供默认的月度数据，避免图表错误
        _monthlyData = List.generate(12, (index) {
          return MonthlyData(
            month: index + 1,
            monthName: '${index + 1}月',
            totalIncome: 0,
            totalExpense: 0,
            balance: 0,
          );
        });
      }
    } catch (e) {
      AppLogger.error('Error fetching yearly statistics: $e');
      _summary = null;
      _expenseStats = [];
      _incomeStats = [];
      // 提供默认的月度数据避免图表错误
      _monthlyData = List.generate(12, (index) {
        return MonthlyData(
          month: index + 1,
          monthName: '${index + 1}月',
          totalIncome: 0,
          totalExpense: 0,
          balance: 0,
        );
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 获取指定年份每个月的统计数据用于年度趋势图
  Future<void> _fetchMonthlyDataForYear(int year) async {
    List<MonthlyData> monthlyDataList = [];

    try {
      // 并发获取12个月的数据
      List<Future<http.Response>> monthlyRequests = [];
      for (int month = 1; month <= 12; month++) {
        monthlyRequests.add(_apiService.getStatistics(y: year, m: month));
      }

      final responses = await Future.wait(monthlyRequests);

      for (int i = 0; i < responses.length; i++) {
        final month = i + 1;
        final response = responses[i];

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final summary = StatisticsSummary.fromJson(data['summary']);

          monthlyDataList.add(MonthlyData(
            month: month,
            monthName: '$month月',
            totalIncome: summary.totalIncome,
            totalExpense: summary.totalExpense,
            balance: summary.balance,
          ));
        } else {
          // 如果某个月没有数据，添加空数据
          monthlyDataList.add(MonthlyData(
            month: month,
            monthName: '$month月',
            totalIncome: 0,
            totalExpense: 0,
            balance: 0,
          ));
        }
      }

      _monthlyData = monthlyDataList;
    } catch (e) {
      AppLogger.error('Error fetching monthly data for year $year: $e');
      // 如果获取失败，创建默认数据
      _monthlyData = List.generate(12, (index) {
        return MonthlyData(
          month: index + 1,
          monthName: '${index + 1}月',
          totalIncome: 0,
          totalExpense: 0,
          balance: 0,
        );
      });
    }
  }

  void selectMonth(BuildContext context) async {
    DateTime tempPickedDate = _selectedDate;

    await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 350,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // 顶部操作栏
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.separator.withOpacity(0.4),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text(
                        '取消',
                        style: TextStyle(
                          color: CupertinoColors.systemRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      _statisticsMode == 'yearly' ? '选择年份' : '选择月份',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    CupertinoButton(
                      child: const Text(
                        '确定',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        if (tempPickedDate != _selectedDate) {
                          _selectedDate = tempPickedDate;
                          fetchDataForCurrentMode();
                        }
                      },
                    ),
                  ],
                ),
              ),
              // 日期选择器
              Expanded(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: _statisticsMode == 'yearly'
                      ? _buildYearPicker(tempPickedDate, (year) {
                          tempPickedDate = DateTime(year, 1, 1);
                        })
                      : CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.monthYear,
                          initialDateTime: _selectedDate,
                          minimumDate: DateTime(2020),
                          maximumDate: DateTime.now(),
                          onDateTimeChanged: (DateTime newDate) {
                            tempPickedDate = newDate;
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 构建年份选择器
  Widget _buildYearPicker(DateTime currentDate, Function(int) onYearChanged) {
    final currentYear = DateTime.now().year;
    final selectedYear = currentDate.year;
    final years = List.generate(
      currentYear - 2020 + 1,
      (index) => 2020 + index,
    );

    return CupertinoPicker(
      backgroundColor: CupertinoColors.systemBackground,
      itemExtent: 40,
      scrollController: FixedExtentScrollController(
        initialItem: years.indexOf(selectedYear),
      ),
      onSelectedItemChanged: (int index) {
        onYearChanged(years[index]);
      },
      children: years.map((year) {
        return Center(
          child: Text(
            '${year}年',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}
