import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../widgets/custom_calendar.dart';
import '../models/transaction.dart';
import '../api/api_service.dart';
import 'package:intl/intl.dart';
import '../utils/app_logger.dart';
import '../utils/category_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _selectedDayTransactions = [];
  final ApiService _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  HomeProvider? _homeProvider;
  bool _isInitialized = false;
  bool _isLoadingTransactions = false;

  @override
  void initState() {
    super.initState();
    // 不在这里创建 HomeProvider，而是在 didChangeDependencies 中获取
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保 Provider 只初始化一次
    if (!_isInitialized) {
      _homeProvider = Provider.of<HomeProvider>(context, listen: false);
      _isInitialized = true;
    }
  }

  Future<void> _initializeData() async {
    if (_homeProvider != null) {
      try {
        await _homeProvider!.fetchData();
        if (mounted) {
          // 使用 Provider 中当前选择月份的今天（如果存在）
          final currentMonth = _homeProvider!.selectedMonth;
          final today = DateTime.now();

          // 如果当前选择的月份就是本月，则设置为今天，否则设置为该月第一天
          if (currentMonth.year == today.year &&
              currentMonth.month == today.month) {
            _selectedDate = today;
          } else {
            _selectedDate = DateTime(currentMonth.year, currentMonth.month, 1);
          }

          // 自动获取选中日期的交易数据
          await _fetchTransactionsForDay(_selectedDate);
        }
      } catch (error) {
        AppLogger.error('HomeScreen fetchData failed: $error');
      }
    }
  }

  /// 智能选择新月份中的日期
  /// 优先选择当前选中的日期，如果新月份没有该日期，则选择该月最后一天
  DateTime _getSmartSelectedDate(DateTime targetMonth) {
    final currentDay = _selectedDate.day;

    // 获取目标月份的最后一天
    final lastDayOfMonth =
        DateTime(targetMonth.year, targetMonth.month + 1, 0).day;

    // 如果当前选中的日期在目标月份中存在，则使用该日期
    // 否则使用目标月份的最后一天
    final selectedDay =
        currentDay <= lastDayOfMonth ? currentDay : lastDayOfMonth;

    return DateTime(targetMonth.year, targetMonth.month, selectedDay);
  }

  Widget _buildMonthSelector(HomeProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF8F9FA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 44,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.chevron_left,
                  color: Color(0xFF667EEA),
                  size: 18,
                ),
              ),
              onPressed: () {
                final previousMonth = DateTime(
                  provider.selectedMonth.year,
                  provider.selectedMonth.month - 1,
                );
                provider.fetchData(previousMonth);

                // 智能选择新月份中的日期
                final newSelectedDate = _getSmartSelectedDate(previousMonth);

                setState(() {
                  _selectedDayTransactions = [];
                  _selectedDate = newSelectedDate;
                });

                // 自动获取选中日期的交易记录
                _fetchTransactionsForDay(_selectedDate);
              },
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () async {
              await showCupertinoModalPopup<DateTime>(
                context: context,
                builder: (context) {
                  DateTime tempPickedDate = provider.selectedMonth;
                  return Container(
                    height: 300,
                    color: CupertinoColors.systemBackground,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 44,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CupertinoButton(
                                child: const Text('取消'),
                                onPressed: () => Navigator.pop(context),
                              ),
                              CupertinoButton(
                                child: const Text('确定'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  provider.fetchData(tempPickedDate);

                                  // 智能选择新月份中的日期
                                  final newSelectedDate =
                                      _getSmartSelectedDate(tempPickedDate);

                                  setState(() {
                                    _selectedDayTransactions = [];
                                    _selectedDate = newSelectedDate;
                                  });

                                  // 自动获取选中日期的交易记录
                                  _fetchTransactionsForDay(_selectedDate);
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {
                                PointerDeviceKind.touch,
                                PointerDeviceKind.mouse,
                              },
                            ),
                            child: CupertinoDatePicker(
                              mode: CupertinoDatePickerMode.monthYear,
                              initialDateTime: provider.selectedMonth,
                              maximumDate: DateTime.now(),
                              minimumDate: DateTime(2020),
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
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('yyyy年MM月').format(provider.selectedMonth),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 44,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.chevron_right,
                  color: Color(0xFF667EEA),
                  size: 18,
                ),
              ),
              onPressed: () {
                final nextMonth = DateTime(
                  provider.selectedMonth.year,
                  provider.selectedMonth.month + 1,
                );
                if (nextMonth.isBefore(DateTime.now()) ||
                    nextMonth.month == DateTime.now().month) {
                  provider.fetchData(nextMonth);

                  // 智能选择新月份中的日期
                  final newSelectedDate = _getSmartSelectedDate(nextMonth);

                  setState(() {
                    _selectedDayTransactions = [];
                    _selectedDate = newSelectedDate;
                  });

                  // 自动获取选中日期的交易记录
                  _fetchTransactionsForDay(_selectedDate);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDaySection() {
    if (_isLoadingTransactions) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFAFBFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoActivityIndicator(
                  color: Color(0xFF667EEA),
                  radius: 16,
                ),
                SizedBox(height: 16),
                Text(
                  '加载中...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF667EEA),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_selectedDayTransactions.isEmpty) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16), // 与日历容器对齐
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFAFBFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                spreadRadius: 0,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667EEA).withOpacity(0.2),
                          const Color(0xFF764BA2).withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.calendar_today,
                      color: Color(0xFF667EEA),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '选择日期查看交易',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A5568),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击日历上的日期来查看当天的交易记录',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 创建简单的日期字符串，避免本地化问题
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final dateStr =
        '${DateFormat('MM/dd').format(_selectedDate)} ${weekdays[_selectedDate.weekday % 7]}';
    final totalExpense = _selectedDayTransactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);

    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16), // 与日历容器对齐
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFAFBFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              spreadRadius: 0,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 日期和支出总览 - 固定头部
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF8F9FA), Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          CupertinoIcons.calendar_today,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B6B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '支出 ¥${totalExpense.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 交易列表 - 可滚动部分
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: _selectedDayTransactions.length,
                separatorBuilder: (context, index) => Container(
                  height: 0.5,
                  color: CupertinoColors.separator,
                  margin: const EdgeInsets.only(left: 68),
                ),
                itemBuilder: (context, index) {
                  return _buildTransactionItem(_selectedDayTransactions[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    // 根据交易类型选择颜色
    final Color iconColor = transaction.type == 'expense'
        ? const Color(0xFFFF6B6B)
        : const Color(0xFF4ECDC4);
    final Color bgColor = iconColor.withOpacity(0.12);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'transaction_${transaction.id}_icon',
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    bgColor,
                    bgColor.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                CategoryUtils.getCategoryIcon(transaction.categoryKey),
                color: iconColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isEmpty
                      ? CategoryUtils.getCategoryName(transaction.categoryKey)
                      : transaction.description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.time,
                      size: 12,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('HH:mm').format(transaction.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        CategoryUtils.getCategoryName(transaction.categoryKey),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: transaction.type == 'expense'
                  ? const Color(0xFFFF6B6B).withOpacity(0.1)
                  : const Color(0xFF4ECDC4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${transaction.type == 'expense' ? '-' : '+'}¥${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: transaction.type == 'expense'
                    ? const Color(0xFFFF6B6B)
                    : const Color(0xFF4ECDC4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchTransactionsForDay(DateTime day) async {
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      // 获取 Provider 中当前选择的月份，确保使用正确的年月
      final currentSelectedMonth =
          _homeProvider?.selectedMonth ?? DateTime.now();

      // 使用 Provider 中的年月，结合点击的日期天数
      final correctedDate = DateTime(
        currentSelectedMonth.year,
        currentSelectedMonth.month,
        day.day,
      );

      final dateStr = DateFormat('yyyy-MM-dd').format(correctedDate);
      AppLogger.info(
          'Fetching transactions for corrected date: $dateStr (from day: ${day.day}, selected month: ${DateFormat('yyyy-MM').format(currentSelectedMonth)})');

      final response = await _apiService.getTransactions(d: dateStr);
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          _selectedDate = correctedDate;
          _selectedDayTransactions =
              data.map((item) => Transaction.fromJson(item)).toList();
        });
      }
    } catch (error) {
      AppLogger.error('Failed to fetch transactions for day: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return CupertinoPageScaffold(
          backgroundColor: Colors.transparent,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: Colors.white.withOpacity(0.95),
            border: null,
            middle: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: const SizedBox(
                width: double.infinity,
                height: 60,
                child: Center(
                  child: Text(
                    '💰 交易概览',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFF8F9FA),
                  Color(0xFFE9ECEF),
                  Color(0xFFF8F9FA),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: provider.isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : Stack(
                    children: [
                      // 装饰性背景元素
                      Positioned(
                        top: -100,
                        right: -100,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF667EEA).withOpacity(0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -80,
                        left: -80,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFF764BA2).withOpacity(0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          children: [
                            // 月份选择器
                            _buildMonthSelector(provider),
                            // 日历视图 - 动态高度
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFFAFBFC)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    spreadRadius: 0,
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF667EEA)
                                        .withOpacity(0.1),
                                    spreadRadius: 0,
                                    blurRadius: 30,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: CustomCalendar(
                                  focusedMonth: provider.selectedMonth,
                                  selectedDay: _selectedDate,
                                  transactions: provider.transactions,
                                  onDaySelected: _fetchTransactionsForDay,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // 选中日期的交易详情 - 可滚动列表
                            _buildSelectedDaySection(),
                          ],
                        ),
                      ),
                      // 浮动按钮
                      Positioned(
                        bottom: 70,
                        right: 20,
                        child: FloatingActionButton(
                          onPressed: () => context.go('/add-transaction'),
                          backgroundColor: const Color(0xFF1976D2), // 更亮的蓝色
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shape: const CircleBorder(), // 明确设置为圆形
                          child: const Icon(Icons.add, size: 28),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
