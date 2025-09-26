import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/asset.dart';

class AssetDetailScreen extends StatelessWidget {
  final Asset asset;

  const AssetDetailScreen({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(asset.name),
        previousPageTitle: 'Assets',
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 20),
              const Text(
                '资产变化趋势',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildLineChart(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final currentAmount = asset.latestAmount;
    final firstAmount = asset.records.isEmpty ? 0.0 : asset.records.last.amount;
    final change = currentAmount - firstAmount;
    final changePercentage =
        firstAmount != 0 ? (change / firstAmount) * 100 : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          Text(
            asset.category,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.placeholderText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(symbol: '¥').format(currentAmount),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                change >= 0
                    ? CupertinoIcons.arrow_up
                    : CupertinoIcons.arrow_down,
                color: change >= 0
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.systemRed,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${change >= 0 ? '+' : ''}${NumberFormat.currency(symbol: '¥').format(change)}',
                style: TextStyle(
                  fontSize: 14,
                  color: change >= 0
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemRed,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${changePercentage.toStringAsFixed(1)}%)',
                style: TextStyle(
                  fontSize: 12,
                  color: change >= 0
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    if (asset.records.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: CupertinoColors.separator,
            width: 0.5,
          ),
        ),
        child: const Center(
          child: Text(
            '暂无数据',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.placeholderText,
            ),
          ),
        ),
      );
    }

    // 按日期排序记录（从旧到新）
    final sortedRecords = List<AssetRecord>.from(asset.records)
      ..sort((a, b) => a.date.compareTo(b.date));

    // 生成折线图数据点
    final spots = <FlSpot>[];
    for (int i = 0; i < sortedRecords.length; i++) {
      spots.add(FlSpot(i.toDouble(), sortedRecords[i].amount));
    }

    final minY =
        sortedRecords.map((r) => r.amount).reduce((a, b) => a < b ? a : b);
    final maxY =
        sortedRecords.map((r) => r.amount).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1;

    // 计算合适的水平间隔，避免为0的情况
    double horizontalInterval;
    double displayMinY, displayMaxY;

    if (maxY == minY) {
      // 当只有一个数据点或所有数据点相同时，使用固定间隔
      horizontalInterval = maxY > 0 ? maxY / 4 : 100;
      // 为单个数据点创建合理的Y轴范围
      final range = maxY > 0 ? maxY * 0.2 : 100;
      displayMinY = maxY - range;
      displayMaxY = maxY + range;
    } else {
      horizontalInterval = (maxY - minY) / 4;
      displayMinY = minY - padding;
      displayMaxY = maxY + padding;
    }

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.separator,
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: horizontalInterval,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: CupertinoColors.separator,
                  strokeWidth: 0.5,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        NumberFormat.compact().format(value),
                        style: const TextStyle(
                          color: CupertinoColors.placeholderText,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedRecords.length) {
                      final date = sortedRecords[index].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('MM/dd').format(date),
                          style: const TextStyle(
                            color: CupertinoColors.placeholderText,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: const Border(
                left: BorderSide(color: CupertinoColors.separator, width: 0.5),
                bottom:
                    BorderSide(color: CupertinoColors.separator, width: 0.5),
              ),
            ),
            minX: 0,
            maxX: (sortedRecords.length - 1).toDouble(),
            minY: displayMinY,
            maxY: displayMaxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: CupertinoColors.activeBlue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: CupertinoColors.activeBlue,
                      strokeWidth: 2,
                      strokeColor: CupertinoColors.systemBackground,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: CupertinoColors.activeBlue.withOpacity(0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    final index = touchedSpot.x.toInt();
                    if (index >= 0 && index < sortedRecords.length) {
                      final record = sortedRecords[index];
                      return LineTooltipItem(
                        '${DateFormat('yyyy/MM/dd').format(record.date)}\n',
                        const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(
                            text: NumberFormat.currency(symbol: '¥')
                                .format(record.amount),
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
