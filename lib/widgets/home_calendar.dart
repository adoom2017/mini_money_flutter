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
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TableCalendar<Transaction>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        eventLoader: _getEventsForDay,
        rowHeight: 50, // 进一步减少行高以避免溢出
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
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          selectedDecoration: BoxDecoration(
            color: CupertinoColors.systemBlue,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          markersMaxCount: 3,
          markerDecoration: BoxDecoration(
            color: Colors.transparent,
          ),
          cellMargin: EdgeInsets.all(2),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle:
              TextStyle(color: CupertinoColors.placeholderText, fontSize: 12),
          weekendStyle:
              TextStyle(color: CupertinoColors.placeholderText, fontSize: 12),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, false, false);
          },
          todayBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, true, false);
          },
          selectedBuilder: (context, day, focusedDay) {
            return _buildDayCell(day, false, true);
          },
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

  Widget _buildDayCell(DateTime day, bool isToday, bool isSelected) {
    // 获取当天的交易数据
    final dayTransactions = widget.transactions
        .where((t) =>
            t.date.year == day.year &&
            t.date.month == day.month &&
            t.date.day == day.day)
        .toList();

    double income = dayTransactions
        .where((t) => t.amount > 0)
        .fold(0.0, (sum, t) => sum + t.amount);

    double expense = dayTransactions
        .where((t) => t.amount < 0)
        .fold(0.0, (sum, t) => sum - t.amount);

    Color backgroundColor = const Color.fromRGBO(247, 247, 247, 1.0);
    Color textColor = CupertinoColors.label;

    if (isSelected) {
      backgroundColor = CupertinoColors.systemBlue;
      textColor = CupertinoColors.white;
    } else if (isToday) {
      backgroundColor = CupertinoColors.systemOrange;
      textColor = CupertinoColors.white;
    }

    return Container(
      width: 44, // 固定宽度
      height: 44, // 固定高度
      margin: const EdgeInsets.all(0.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: dayTransactions.isNotEmpty
            ? Border.all(
                color: CupertinoColors.separator.withOpacity(0.4),
                width: 1,
              )
            : Border.all(
                color: CupertinoColors.separator.withOpacity(0.1),
                width: 0.5,
              ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: dayTransactions.isNotEmpty
                  ? FontWeight.w600
                  : FontWeight.w500,
            ),
          ),
          if (dayTransactions.isNotEmpty) ...[
            const SizedBox(height: 1),
            if (expense > 0)
              Text(
                '-${expense.toInt()}',
                style: TextStyle(
                  color: isSelected || isToday
                      ? CupertinoColors.white.withOpacity(0.9)
                      : CupertinoColors.systemRed,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (income > 0)
              Text(
                '+${income.toInt()}',
                style: TextStyle(
                  color: isSelected || isToday
                      ? CupertinoColors.white.withOpacity(0.9)
                      : CupertinoColors.systemGreen,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventsMarker(DateTime day, List events) {
    // 这个方法现在主要用于TableCalendar的内部逻辑
    // 实际的显示由_buildDayCell处理
    return Container();
  }
}
