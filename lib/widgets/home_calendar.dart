import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:mini_money_flutter/utils/app_logger.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/transaction.dart';

class HomeCalendar extends StatefulWidget {
  final List<Transaction> transactions;
  final Function(DateTime) onDaySelected;

  const HomeCalendar({
    super.key,
    required this.transactions,
    required this.onDaySelected,
  });

  @override
  State<HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends State<HomeCalendar> {
  late final ValueNotifier<List<Transaction>> _selectedEvents;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
  }

  @override
  void didUpdateWidget(HomeCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当transactions更新时，重新计算选中日期的事件
    if (oldWidget.transactions != widget.transactions) {
      AppLogger.info(
          'HomeCalendar didUpdateWidget: transactions changed from ${oldWidget.transactions.length} to ${widget.transactions.length}');
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Transaction> _getEventsForDay(DateTime day) {
    final events = widget.transactions.where((t) {
      // 使用年月日进行比较，忽略时间部分
      return t.date.year == day.year &&
          t.date.month == day.month &&
          t.date.day == day.day;
    }).toList();

    return events;
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
      widget.onDaySelected(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info(
        'HomeCalendar build: ${widget.transactions.length} transactions available');
    for (var t in widget.transactions) {
      AppLogger.info(
          'Transaction: ${t.date.toIso8601String()}, amount: ${t.amount}');
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TableCalendar<Transaction>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        eventLoader: _getEventsForDay,
        rowHeight: 48, // 增加行高以容纳收入支出文字
        daysOfWeekHeight: 32, // 固定星期标题高度
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronVisible: false,
          rightChevronVisible: false,
          headerPadding: EdgeInsets.symmetric(vertical: 8),
          titleTextStyle: TextStyle(fontSize: 0), // 隐藏标题，因为我们在外部显示
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: true,
          weekendTextStyle: TextStyle(color: CupertinoColors.label),
          holidayTextStyle: TextStyle(color: CupertinoColors.label),
          defaultTextStyle: TextStyle(color: CupertinoColors.label),
          todayDecoration: BoxDecoration(
            color: CupertinoColors.systemOrange,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: CupertinoColors.systemBlue,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3, // 增加最大标记数量
          markerDecoration: BoxDecoration(
            color: Colors.transparent,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle:
              TextStyle(color: CupertinoColors.placeholderText, fontSize: 12),
          weekendStyle:
              TextStyle(color: CupertinoColors.placeholderText, fontSize: 12),
        ),
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isNotEmpty) {
              return _buildEventsMarker(day, events);
            }
            return null;
          },
          dowBuilder: (context, day) {
            final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
            return Center(
              child: Text(
                weekdays[day.weekday % 7],
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventsMarker(DateTime day, List events) {
    final dayTransactions = widget.transactions
        .where((t) =>
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day)
        .toList();

    if (dayTransactions.isEmpty) {
      return Container();
    }

    double income = dayTransactions
        .where((t) => t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);

    double expense = dayTransactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum - t.amount);

    return Positioned(
      bottom: 4,
      left: 4,
      right: 4,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (income > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '+${income.toInt()}',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (expense > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                '-${expense.toInt()}',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
