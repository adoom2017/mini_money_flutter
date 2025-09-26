import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';
import '../widgets/home_calendar.dart';
import '../models/transaction.dart';
import '../api/api_service.dart';
import 'package:intl/intl.dart';
import '../utils/app_logger.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _selectedDayTransactions = [];
  final ApiService _apiService = ApiService();
  DateTime _selectedDate = DateTime.now();
  late HomeProvider _homeProvider;

  @override
  void initState() {
    super.initState();
    _homeProvider = HomeProvider();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeProvider.fetchData().then((_) {
        _fetchTransactionsForDay(DateTime.now());
      }).catchError((error) {
        AppLogger.error('HomeScreen fetchData failed: $error');
      });
    });
  }

  Widget _buildMonthSelector(HomeProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: CupertinoColors.systemBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 44,
            child: const Icon(
              CupertinoIcons.chevron_left,
              color: CupertinoColors.systemBlue,
              size: 20,
            ),
            onPressed: () {
              final previousMonth = DateTime(
                provider.selectedMonth.year,
                provider.selectedMonth.month - 1,
              );
              provider.fetchData(previousMonth);
            },
          ),
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
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
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
                      ],
                    ),
                  );
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.systemFill,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                DateFormat('yyyy.MM').format(provider.selectedMonth),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.label,
                ),
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 44,
            child: const Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemBlue,
              size: 20,
            ),
            onPressed: () {
              final nextMonth = DateTime(
                provider.selectedMonth.year,
                provider.selectedMonth.month + 1,
              );
              if (nextMonth.isBefore(DateTime.now()) ||
                  nextMonth.month == DateTime.now().month) {
                provider.fetchData(nextMonth);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDaySection() {
    if (_selectedDayTransactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.separator.withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: const Text(
            '点击日历选择日期查看交易',
            style: TextStyle(color: CupertinoColors.placeholderText),
            textAlign: TextAlign.center,
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.separator.withOpacity(0.3),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 日期和支出总览 - 固定头部
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                Text(
                  '支出: ¥${totalExpense.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.placeholderText,
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
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: CupertinoColors.systemOrange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.square_fill_on_circle_fill,
              color: CupertinoColors.systemOrange,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description.isEmpty
                      ? transaction.categoryKey
                      : transaction.description,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('HH:mm').format(transaction.date)} • ${transaction.categoryKey}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.placeholderText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.type == 'expense' ? '-' : '+'}¥${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: transaction.type == 'expense'
                  ? CupertinoColors.label
                  : CupertinoColors.systemGreen,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchTransactionsForDay(DateTime day) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final response = await _apiService.getTransactions(d: dateStr);
    if (response.statusCode == 200 && mounted) {
      final data = jsonDecode(response.body) as List;
      setState(() {
        _selectedDate = day;
        _selectedDayTransactions =
            data.map((item) => Transaction.fromJson(item)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _homeProvider,
      child: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return CupertinoPageScaffold(
            backgroundColor: CupertinoColors.systemGroupedBackground,
            navigationBar: CupertinoNavigationBar(
              backgroundColor: CupertinoColors.systemBackground,
              border: null,
              leading: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.back,
                  color: CupertinoColors.systemBlue,
                ),
                onPressed: () {},
              ),
              middle: const Text(
                '默认账本',
                style: TextStyle(
                  color: CupertinoColors.label,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    '记一笔',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                onPressed: () => context.go('/add-transaction'),
              ),
            ),
            child: provider.isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : Column(
                    children: [
                      // 月份选择器
                      _buildMonthSelector(provider),
                      // 日历视图 - 固定高度
                      Container(
                        height: 360, // 固定日历高度，增加高度以适应更高的行高
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: CupertinoColors.separator.withOpacity(0.3),
                              spreadRadius: 0,
                              blurRadius: 8,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: HomeCalendar(
                          transactions: provider.transactions,
                          onDaySelected: _fetchTransactionsForDay,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 选中日期的交易详情 - 可滚动列表
                      Expanded(
                        child: _buildSelectedDaySection(),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}
