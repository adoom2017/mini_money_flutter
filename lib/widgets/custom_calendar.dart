import 'package:flutter/cupertino.dart';
import '../models/transaction.dart';

class CustomCalendar extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime? selectedDay;
  final List<Transaction> transactions;
  final Function(DateTime) onDaySelected;

  const CustomCalendar({
    super.key,
    required this.focusedMonth,
    required this.transactions,
    required this.onDaySelected,
    this.selectedDay,
  });

  // 计算日历所需的总高度
  static double calculateHeight(DateTime focusedMonth) {
    const double padding = 24; // 容器内边距 12 * 2
    const double headerSpacing = 12; // 标题下方间距
    const double weekdayHeaderHeight = 28; // 星期标题高度（增加缓冲）
    const double weekdaySpacing = 6; // 星期标题下方间距
    const double cellHeight = 47; // 每个日期单元格高度（增加缓冲）

    // 计算需要多少行 - 使用与_buildCalendarGrid相同的逻辑
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday % 7));

    int weekCount = 0;
    DateTime currentDate = startDate;

    while (true) {
      // 检查这一行是否包含当前月份的任何一天
      DateTime weekStartDate = currentDate;
      bool hasCurrentMonthDay = false;
      for (int day = 0; day < 7; day++) {
        if (weekStartDate.add(Duration(days: day)).month ==
            focusedMonth.month) {
          hasCurrentMonthDay = true;
          break;
        }
      }

      // 如果这一行不包含当前月份的任何一天，且我们至少已经有了一行，则停止
      if (!hasCurrentMonthDay && weekCount > 0) {
        break;
      }

      weekCount++;
      currentDate = currentDate.add(const Duration(days: 7));

      // 安全保护：防止无限循环，最多6行
      if (weekCount >= 6) {
        break;
      }
    }

    final gridHeight = weekCount * cellHeight;
    const double extraBuffer = 8; // 额外的缓冲空间

    return padding +
        headerSpacing +
        weekdayHeaderHeight +
        weekdaySpacing +
        gridHeight +
        extraBuffer;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildWeekdayHeader(),
          const SizedBox(height: 6),
          _buildCalendarGrid(),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: weekdays.asMap().entries.map((entry) {
        final weekday = entry.value;
        final isWeekend = entry.key == 0 || entry.key == 6;
        return Container(
          width: 47, // 与日期单元格相同的宽度
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            weekday,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isWeekend
                  ? CupertinoColors.systemBlue.withOpacity(0.7)
                  : CupertinoColors.label,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final lastDay = DateTime(focusedMonth.year, focusedMonth.month + 1, 0);
    final startDate = firstDay.subtract(Duration(days: firstDay.weekday % 7));

    List<Widget> weeks = [];
    DateTime currentDate = startDate;

    // 动态计算需要的行数，不固定为6行
    while (true) {
      // 检查这一行是否包含当前月份的任何一天
      DateTime weekStartDate = currentDate;
      bool hasCurrentMonthDay = false;
      for (int day = 0; day < 7; day++) {
        if (weekStartDate.add(Duration(days: day)).month ==
            focusedMonth.month) {
          hasCurrentMonthDay = true;
          break;
        }
      }

      // 如果这一行不包含当前月份的任何一天，且我们至少已经有了一行，则停止
      if (!hasCurrentMonthDay && weeks.isNotEmpty) {
        break;
      }

      List<Widget> days = [];
      for (int day = 0; day < 7; day++) {
        days.add(_buildDayCell(currentDate, firstDay, lastDay));
        currentDate = currentDate.add(const Duration(days: 1));
      }
      weeks.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: days,
        ),
      );

      // 安全保护：防止无限循环，最多6行
      if (weeks.length >= 6) {
        break;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: weeks,
    );
  }

  Widget _buildDayCell(DateTime day, DateTime firstDay, DateTime lastDay) {
    final isCurrentMonth = day.month == focusedMonth.month;
    final isToday = _isSameDay(day, DateTime.now());
    final isSelected = selectedDay != null && _isSameDay(day, selectedDay!);
    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    // 获取当天的交易数据
    final dayTransactions = _getTransactionsForDay(day);
    double totalIncome = 0;
    double totalExpense = 0;

    for (var transaction in dayTransactions) {
      if (transaction.type == 'income') {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    final hasTransactions = totalIncome > 0 || totalExpense > 0;

    return Container(
      width: 47,
      height: 47,
      margin: const EdgeInsets.all(1),
      child: GestureDetector(
        onTap: isCurrentMonth ? () => onDaySelected(day) : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      CupertinoColors.systemBlue.withOpacity(0.8),
                      CupertinoColors.systemBlue.withOpacity(0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : isToday
                    ? LinearGradient(
                        colors: [
                          CupertinoColors.systemBlue.withOpacity(0.15),
                          CupertinoColors.systemBlue.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
            color: !isSelected && !isToday
                ? (hasTransactions && isCurrentMonth
                    ? CupertinoColors.systemGrey6.withOpacity(0.3)
                    : null)
                : null,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: CupertinoColors.systemBlue,
                    width: 2,
                  )
                : isToday
                    ? Border.all(
                        color: CupertinoColors.systemBlue.withOpacity(0.6),
                        width: 1.5,
                      )
                    : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: CupertinoColors.systemBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : isToday
                    ? [
                        BoxShadow(
                          color: CupertinoColors.systemBlue.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
          ),
          child: Stack(
            children: [
              // 日期数字
              Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: !isCurrentMonth
                        ? CupertinoColors.placeholderText
                        : isSelected
                            ? CupertinoColors.white
                            : isToday
                                ? CupertinoColors.systemBlue
                                : isWeekend
                                    ? CupertinoColors.systemBlue
                                        .withOpacity(0.7)
                                    : CupertinoColors.label,
                  ),
                ),
              ),
              // 交易指示点
              if (isCurrentMonth && hasTransactions)
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (totalIncome > 0)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? CupertinoColors.white
                                : CupertinoColors.systemGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected
                                        ? CupertinoColors.white
                                        : CupertinoColors.systemGreen)
                                    .withOpacity(0.5),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      if (totalExpense > 0)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? CupertinoColors.white.withOpacity(0.9)
                                : CupertinoColors.systemRed,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isSelected
                                        ? CupertinoColors.white
                                        : CupertinoColors.systemRed)
                                    .withOpacity(0.5),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Transaction> _getTransactionsForDay(DateTime day) {
    return transactions.where((transaction) {
      return transaction.date.year == day.year &&
          transaction.date.month == day.month &&
          transaction.date.day == day.day;
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
