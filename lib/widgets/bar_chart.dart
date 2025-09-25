import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';

class DailyBarChart extends StatelessWidget {
  final List<Transaction> transactions;

  const DailyBarChart({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxY(),
          barGroups: _generateBarGroups(),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                    showTitles: true, getTitlesWidget: _bottomTitles)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    // Group transactions by day and find the max daily total
    Map<int, double> dailyTotals = {};
    for (var t in transactions) {
      dailyTotals.update(t.date.day, (value) => value + t.amount,
          ifAbsent: () => t.amount);
    }
    if (dailyTotals.isEmpty) return 100.0; // Default max Y
    return dailyTotals.values.reduce((a, b) => a > b ? a : b) *
        1.2; // Add 20% padding
  }

  List<BarChartGroupData> _generateBarGroups() {
    Map<int, Map<String, double>> dailyData = {};
    for (var t in transactions) {
      dailyData.putIfAbsent(t.date.day, () => {'income': 0, 'expense': 0});
      if (t.type == 'income') {
        dailyData[t.date.day]!['income'] =
            dailyData[t.date.day]!['income']! + t.amount;
      } else {
        dailyData[t.date.day]!['expense'] =
            dailyData[t.date.day]!['expense']! + t.amount;
      }
    }

    return dailyData.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
              toY: entry.value['income']!, color: Colors.green, width: 7),
          BarChartRodData(
              toY: entry.value['expense']!, color: Colors.red, width: 7),
        ],
      );
    }).toList();
  }

  Widget _bottomTitles(double value, TitleMeta meta) {
    final day = value.toInt();
    // Show titles for every 5 days to avoid clutter
    if (day % 5 == 0) {
      return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(day.toString()),
      );
    }
    return Container();
  }
}
