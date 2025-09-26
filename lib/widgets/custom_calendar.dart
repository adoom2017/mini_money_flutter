import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildWeekdayHeader(),
          const SizedBox(height: 6),
          Expanded(
            child: _buildCalendarGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          DateFormat('yyyy年 MM月').format(focusedMonth),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeader() {
    const weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return Row(
      children: weekdays.map((weekday) {
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              weekday,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.secondaryLabel,
              ),
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

    for (int week = 0; week < 6; week++) {
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

      // 如果当前月份的所有天都已经显示完了，就停止添加新的周
      if (currentDate.month != focusedMonth.month &&
          currentDate.subtract(const Duration(days: 1)).month ==
              focusedMonth.month) {
        break;
      }
    }

    return Column(children: weeks);
  }

  Widget _buildDayCell(DateTime day, DateTime firstDay, DateTime lastDay) {
    final isCurrentMonth = day.month == focusedMonth.month;
    final isToday = _isSameDay(day, DateTime.now());
    final isSelected = selectedDay != null && _isSameDay(day, selectedDay!);

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

    return Container(
      width: 45,
      height: 45,
      margin: const EdgeInsets.all(1),
      child: GestureDetector(
        onTap: isCurrentMonth ? () => onDaySelected(day) : null,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? CupertinoColors.systemBlue.withOpacity(0.1)
                : CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: CupertinoColors.systemBlue, width: 2)
                : isToday
                    ? Border.all(
                        color: CupertinoColors.systemBlue.withOpacity(0.5),
                        width: 1)
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.normal,
                    color: !isCurrentMonth
                        ? CupertinoColors.placeholderText
                        : isSelected
                            ? CupertinoColors.systemBlue
                            : isToday
                                ? CupertinoColors.systemBlue
                                : CupertinoColors.label,
                  ),
                ),
                if (isCurrentMonth && (totalIncome > 0 || totalExpense > 0))
                  Container(
                    constraints: const BoxConstraints(maxHeight: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (totalIncome > 0)
                          Text(
                            '+${totalIncome.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 8,
                              color: CupertinoColors.systemGreen,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (totalExpense > 0)
                          Text(
                            '-${totalExpense.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 8,
                              color: CupertinoColors.systemRed,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
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
