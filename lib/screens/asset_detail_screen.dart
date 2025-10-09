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
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(asset.name),
        previousPageTitle: 'Assets',
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 28),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          CupertinoColors.systemBlue,
                          CupertinoColors.systemTeal,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '资产变化趋势',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            CupertinoColors.systemBlue,
            CupertinoColors.activeBlue,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(4, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            asset.category,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            NumberFormat.currency(symbol: '¥').format(currentAmount),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (change >= 0
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemRed)
                  .withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  change >= 0
                      ? CupertinoIcons.arrow_up
                      : CupertinoIcons.arrow_down,
                  color: change >= 0
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemRed,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '${change >= 0 ? '+' : ''}${NumberFormat.currency(symbol: '¥').format(change)}',
                  style: TextStyle(
                    fontSize: 15,
                    color: change >= 0
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${changePercentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 13,
                    color: change >= 0
                        ? CupertinoColors.systemGreen
                        : CupertinoColors.systemRed,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    if (asset.records.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              CupertinoColors.systemGrey6,
              CupertinoColors.systemBackground,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemBlue.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(4, 8),
              spreadRadius: -2,
            ),
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.chart_bar_alt_fill,
                size: 64,
                color: CupertinoColors.systemGrey,
              ),
              SizedBox(height: 16),
              Text(
                '暂无数据',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.placeholderText,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '记录资产后将显示变化趋势',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ],
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
    final padding = (maxY - minY) * 0.15;

    // 计算合适的水平间隔，减少纵坐标密度（从4个间隔改为2-3个）
    double horizontalInterval;
    double displayMinY, displayMaxY;

    if (maxY == minY) {
      // 当只有一个数据点或所有数据点相同时，使用固定间隔
      horizontalInterval = maxY > 0 ? maxY / 2 : 100;
      // 为单个数据点创建合理的Y轴范围
      final range = maxY > 0 ? maxY * 0.2 : 100;
      displayMinY = maxY - range;
      displayMaxY = maxY + range;
    } else {
      horizontalInterval = (maxY - minY) / 2.5;
      displayMinY = minY - padding;
      displayMaxY = maxY + padding;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            CupertinoColors.systemGrey6,
            CupertinoColors.systemBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemBlue.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(4, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: horizontalInterval,
              getDrawingHorizontalLine: (value) {
                return const FlLine(
                  color: CupertinoColors.separator,
                  strokeWidth: 1,
                  dashArray: [5, 5],
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
                      final date = sortedRecords[index].date.toLocal();
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
                left: BorderSide(
                  color: CupertinoColors.separator,
                  width: 1.5,
                ),
                bottom: BorderSide(
                  color: CupertinoColors.separator,
                  width: 1.5,
                ),
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
                curveSmoothness: 0.35,
                gradient: LinearGradient(
                  colors: [
                    CupertinoColors.systemBlue,
                    CupertinoColors.systemBlue.withOpacity(0.8),
                    CupertinoColors.systemTeal,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: CupertinoColors.white,
                      strokeWidth: 3,
                      strokeColor: CupertinoColors.systemBlue,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      CupertinoColors.systemBlue.withOpacity(0.3),
                      CupertinoColors.systemBlue.withOpacity(0.1),
                      CupertinoColors.systemTeal.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                shadow: const Shadow(
                  color: CupertinoColors.systemBlue,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.all(12),
                tooltipMargin: 8,
                tooltipBgColor: CupertinoColors.systemBlue.withOpacity(0.95),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((LineBarSpot touchedSpot) {
                    final index = touchedSpot.x.toInt();
                    if (index >= 0 && index < sortedRecords.length) {
                      final record = sortedRecords[index];
                      return LineTooltipItem(
                        '${DateFormat('yyyy/MM/dd').format(record.date.toLocal())}\n',
                        const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: NumberFormat.currency(symbol: '¥')
                                .format(record.amount),
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
              getTouchedSpotIndicator:
                  (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    FlLine(
                      color: CupertinoColors.systemBlue.withOpacity(0.5),
                      strokeWidth: 2,
                      dashArray: [5, 5],
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 8,
                          color: CupertinoColors.white,
                          strokeWidth: 4,
                          strokeColor: CupertinoColors.systemBlue,
                        );
                      },
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
