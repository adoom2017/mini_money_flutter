import 'package:flutter/material.dart';
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
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  List<Transaction> _getEventsForDay(DateTime day) {
    return widget.transactions
        .where((t) => isSameDay(t.date, day))
        .toList();
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
    return Column(
      children: [
        TableCalendar<Transaction>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: _onDaySelected,
          eventLoader: _getEventsForDay,
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, day, events) {
              if (events.isNotEmpty) {
                return Positioned(
                  right: 1,
                  bottom: 1,
                  child: _buildEventsMarker(day, events),
                );
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child: ValueListenableBuilder<List<Transaction>>(
            valueListenable: _selectedEvents,
            builder: (context, value, _) {
              return ListView.builder(
                itemCount: value.length,
                itemBuilder: (context, index) {
                  final transaction = value[index];
                  return ListTile(
                    title: Text(transaction.description.isEmpty ? transaction.categoryKey : transaction.description),
                    subtitle: Text(transaction.categoryKey),
                    trailing: Text(
                      '${transaction.type == 'expense' ? '-' : '+'}${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: transaction.type == 'expense' ? Colors.red : Colors.green,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventsMarker(DateTime day, List<Transaction> events) {
    double totalIncome = events.where((t) => t.type == 'income').fold(0, (sum, t) => sum + t.amount);
    double totalExpense = events.where((t) => t.type == 'expense').fold(0, (sum, t) => sum + t.amount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[400],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        '${totalIncome.toStringAsFixed(0)} / ${totalExpense.toStringAsFixed(0)}',
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }
}
