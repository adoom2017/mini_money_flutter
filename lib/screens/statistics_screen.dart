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
                      '📊 统计分析',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              // trailing removed: date picker moved into page body
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
              child: Stack(
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
                    child: provider.isLoading
                        ? const Center(child: CupertinoActivityIndicator())
                        : _buildStatisticsBody(context, provider),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context, StatisticsProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: GestureDetector(
        onTap: () => provider.selectMonth(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                provider.statisticsMode == 'yearly'
                    ? DateFormat('yyyy年').format(provider.selectedDate)
                    : DateFormat('yyyy.MM').format(provider.selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.calendar,
                  size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsBody(
      BuildContext context, StatisticsProvider provider) {
    if (provider.summary == null) {
      final isYearly = provider.statisticsMode == 'yearly';
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(40),
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
                  CupertinoIcons.chart_bar_alt_fill,
                  color: Color(0xFF667EEA),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isYearly ? '本年暂无数据' : '本月暂无数据',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A5568),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '开始记录您的收支情况\n来查看详细的统计分析',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final currencyFormat = NumberFormat.currency(symbol: '¥');

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // 添加统计模式切换控件
        _buildModeToggle(context, provider),
        const SizedBox(height: 12),
        // 日期选择器：放在标签页（模式切换）下面
        _buildDateSelector(context, provider),
        const SizedBox(height: 16),
        _buildSummaryCard(context, provider, provider.summary!, currencyFormat),
        const SizedBox(height: 24),
        if (provider.statisticsMode == 'yearly')
          _buildYearlyChart(context, provider)
        else ...[
          _buildCategoryChart(
              context, 'Expense Breakdown', provider.expenseStats, Colors.red),
          const SizedBox(height: 24),
          _buildCategoryChart(
              context, 'Income Breakdown', provider.incomeStats, Colors.green),
        ],
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, StatisticsProvider provider,
      StatisticsSummary summary, NumberFormat format) {
    return Container(
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
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.chart_pie_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  provider.statisticsMode == 'yearly' ? '年度财务概览' : '月度财务概览',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                    '收入',
                    format.format(summary.totalIncome),
                    const Color(0xFF4ECDC4),
                    CupertinoIcons.arrow_down_circle_fill),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey[300],
                ),
                _buildSummaryItem(
                    '支出',
                    format.format(summary.totalExpense),
                    const Color(0xFFFF6B6B),
                    CupertinoIcons.arrow_up_circle_fill),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey[300],
                ),
                _buildSummaryItem(
                    '结余',
                    format.format(summary.balance),
                    const Color(0xFF667EEA),
                    CupertinoIcons.chart_bar_circle_fill),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
      String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChart(BuildContext context, String title,
      List<CategoryStat> stats, Color barColor) {
    // 根据图表类型选择不同的图标和颜色
    final isExpense = barColor == Colors.red;
    final chartColor =
        isExpense ? const Color(0xFFFF6B6B) : const Color(0xFF4ECDC4);
    final chartIcon = isExpense
        ? CupertinoIcons.arrow_up_circle_fill
        : CupertinoIcons.arrow_down_circle_fill;
    final chartTitle = isExpense ? '支出分析' : '收入分析';

    return Container(
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
          BoxShadow(
            color: chartColor.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: chartColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    chartIcon,
                    color: chartColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  chartTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (stats.isEmpty)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.chart_bar,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '本月暂无${isExpense ? '支出' : '收入'}数据',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 240,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
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
                            gradient: LinearGradient(
                              colors: [
                                chartColor.withOpacity(0.8),
                                chartColor,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 20,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '¥${(value / 1000).toStringAsFixed(0)}k',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= stats.length) {
                              return const Text('');
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                stats[value.toInt()].categoryKey,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                          reservedSize: 35,
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: stats.isNotEmpty
                          ? stats
                                  .map((s) => s.total)
                                  .reduce((a, b) => a > b ? a : b) /
                              4
                          : 1000,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    borderData: FlBorderData(
                      show: false,
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeToggle(BuildContext context, StatisticsProvider provider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFFAFBFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CupertinoSlidingSegmentedControl<String>(
        groupValue: provider.statisticsMode,
        onValueChanged: (String? value) {
          if (value != null) {
            provider.switchStatisticsMode(value);
          }
        },
        children: const {
          'monthly': Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.calendar, size: 16),
                SizedBox(width: 6),
                Text('月度统计'),
              ],
            ),
          ),
          'yearly': Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.calendar_today, size: 16),
                SizedBox(width: 6),
                Text('年度统计'),
              ],
            ),
          ),
        },
      ),
    );
  }

  Widget _buildYearlyChart(BuildContext context, StatisticsProvider provider) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF667EEA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.chart_bar_fill,
                    color: Color(0xFF667EEA),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '年度月份趋势',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (provider.monthlyData.isEmpty)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.chart_bar,
                        color: Colors.grey[400],
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '本年暂无数据',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 240,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: () {
                        if (provider.monthlyData.isEmpty) return 1000.0;

                        final maxValue = provider.monthlyData
                            .map((m) => m.totalExpense > m.totalIncome
                                ? m.totalExpense
                                : m.totalIncome)
                            .reduce((a, b) => a > b ? a : b);

                        final interval = maxValue / 4;
                        return interval > 0 ? interval : 1000.0;
                      }(),
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '¥${(value / 1000).toStringAsFixed(0)}k',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final month = value.toInt();
                            if (month < 1 || month > 12) return const Text('');
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '$month月',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                          reservedSize: 35,
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 1,
                    maxX: 12,
                    minY: 0,
                    lineBarsData: [
                      // 收入线
                      LineChartBarData(
                        spots: provider.monthlyData
                            .map((data) =>
                                FlSpot(data.month.toDouble(), data.totalIncome))
                            .toList(),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF4ECDC4).withOpacity(0.3),
                              const Color(0xFF4ECDC4).withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      // 支出线
                      LineChartBarData(
                        spots: provider.monthlyData
                            .map((data) => FlSpot(
                                data.month.toDouble(), data.totalExpense))
                            .toList(),
                        isCurved: true,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFEE5A52)],
                        ),
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFFF6B6B).withOpacity(0.3),
                              const Color(0xFFFF6B6B).withOpacity(0.1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
