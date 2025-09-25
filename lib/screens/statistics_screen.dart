import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/statistics_provider.dart';
import '../models/statistics_summary.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StatisticsProvider(),
      child: Consumer<StatisticsProvider>(
        builder: (context, provider, child) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('统计'),
              trailing: GestureDetector(
                onTap: () => provider.selectMonth(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('yyyy-MM').format(provider.selectedDate),
                      style: const TextStyle(color: CupertinoColors.activeBlue),
                    ),
                    const SizedBox(width: 4),
                    const Icon(CupertinoIcons.calendar,
                        size: 18, color: CupertinoColors.activeBlue),
                  ],
                ),
              ),
            ),
            child: SafeArea(
              child: provider.isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _buildStatisticsBody(context, provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsBody(
      BuildContext context, StatisticsProvider provider) {
    if (provider.summary == null) {
      return const Center(child: Text('本月暂无数据'));
    }

    final currencyFormat = NumberFormat.currency(symbol: '¥');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildSummaryCard(context, provider.summary!, currencyFormat),
        const SizedBox(height: 24),
        _buildCategoryChart(
            context, 'Expense Breakdown', provider.expenseStats, Colors.red),
        const SizedBox(height: 24),
        _buildCategoryChart(
            context, 'Income Breakdown', provider.incomeStats, Colors.green),
      ],
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, StatisticsSummary summary, NumberFormat format) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Monthly Summary',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                    'Income', format.format(summary.totalIncome), Colors.green),
                _buildSummaryItem(
                    'Expense', format.format(summary.totalExpense), Colors.red),
                _buildSummaryItem('Balance', format.format(summary.balance),
                    Theme.of(context).colorScheme.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildCategoryChart(BuildContext context, String title,
      List<CategoryStat> stats, Color barColor) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            if (stats.isEmpty)
              const Center(child: Text('No data'))
            else
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: stats.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stat = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: stat.total,
                            color: barColor,
                            width: 16,
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 40)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Text(
                            stats[value.toInt()].categoryKey,
                            style: const TextStyle(fontSize: 10),
                          ),
                          reservedSize: 30,
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
