import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/statistics_summary.dart';

class CategoryPieChart extends StatelessWidget {
  final List<CategoryStat> categoryStats;

  const CategoryPieChart({super.key, required this.categoryStats});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.5,
      child: PieChart(
        PieChartData(
          sections: _generatePieSections(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections() {
    if (categoryStats.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'No data',
          color: Colors.grey,
          radius: 50,
        )
      ];
    }
    
    // Simple color generation for demonstration
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.yellow];
    
    return List.generate(categoryStats.length, (i) {
      final stat = categoryStats[i];
      return PieChartSectionData(
        color: colors[i % colors.length],
        value: stat.percentage,
        title: '${stat.categoryKey}\n${stat.percentage.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    });
  }
}
