import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChartSection extends StatelessWidget {
  const ChartSection({
    super.key,
    required this.weeklyExpenseData,
    required this.categoryData,
    required this.monthlyExpenseData,
    required this.categoryRangeLabel,
  });

  final Map<DateTime, double> weeklyExpenseData;
  final Map<String, double> categoryData;
  final Map<DateTime, double> monthlyExpenseData;
  final String categoryRangeLabel;

  @override
  Widget build(BuildContext context) {
    final hasWeeklyData = weeklyExpenseData.values.any((value) => value > 0);
    final hasCategoryData = categoryData.isNotEmpty;
    final hasMonthlyExpenseData =
        monthlyExpenseData.values.any((value) => value > 0);

    final topCategory = _topCategory(categoryData);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 800;
        final weeklyCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 200,
              child: hasWeeklyData
                  ? BarChart(_buildBarData(context))
                  : const Center(child: Text('No weekly expense data yet')),
            ),
          ),
        );
        final categoryCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 220,
              child: hasCategoryData
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top: $topCategory',
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Expanded(child: PieChart(_buildPieData())),
                      ],
                    )
                  : Center(
                      child: Text('No $categoryRangeLabel category data yet'),
                    ),
            ),
          ),
        );

        final monthlyCard = Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 220,
              child: hasMonthlyExpenseData
                  ? BarChart(_buildMonthlyBarData(context))
                  : const Center(child: Text('No monthly expense data yet')),
            ),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Charts', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (isWide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: weeklyCard),
                  const SizedBox(width: 12),
                  Expanded(child: categoryCard),
                ],
              )
            else ...[
              weeklyCard,
              const SizedBox(height: 12),
              categoryCard,
            ],
            const SizedBox(height: 12),
            monthlyCard,
          ],
        );
      },
    );
  }

  String _topCategory(Map<String, double> data) {
    if (data.isEmpty) return 'N/A';
    String top = 'N/A';
    double topValue = 0;
    for (final entry in data.entries) {
      if (entry.value > topValue) {
        topValue = entry.value;
        top = entry.key;
      }
    }
    return top;
  }

  BarChartData _buildBarData(BuildContext context) {
    final maxY = _maxWeeklyValue() + 200;

    return BarChartData(
      maxY: maxY == 0 ? 1000 : maxY,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= weeklyExpenseData.keys.length) {
                return const SizedBox.shrink();
              }
              final day = weeklyExpenseData.keys.elementAt(idx);
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(DateFormat('E').format(day)),
              );
            },
          ),
        ),
      ),
      barGroups: weeklyExpenseData.entries.toList().asMap().entries.map((entry) {
        final idx = entry.key;
        final amount = entry.value.value;
        return BarChartGroupData(
          x: idx,
          barRods: [
            BarChartRodData(
              toY: amount,
              width: 18,
              borderRadius: BorderRadius.circular(6),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        );
      }).toList(),
    );
  }

  BarChartData _buildMonthlyBarData(BuildContext context) {
    final monthKeys = monthlyExpenseData.keys.toList();
    final hasBars = monthKeys.isNotEmpty;
    if (!hasBars) {
      return BarChartData(maxY: 100);
    }

    final maxY = _maxMonthlyValue() + 200;

    return BarChartData(
      maxY: maxY == 0 ? 1000 : maxY,
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final idx = value.toInt();
              if (idx < 0 || idx >= monthKeys.length) {
                return const SizedBox.shrink();
              }
              final monthKey = monthKeys[idx];
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(DateFormat('MMM').format(monthKey)),
              );
            },
          ),
        ),
      ),
      barGroups: monthKeys.asMap().entries.map((entry) {
        final idx = entry.key;
        final monthKey = entry.value;
        final amount = monthlyExpenseData[monthKey] ?? 0;
        return BarChartGroupData(
          x: idx,
          barRods: [
            BarChartRodData(
              toY: amount,
              width: 18,
              borderRadius: BorderRadius.circular(6),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        );
      }).toList(),
    );
  }

  PieChartData _buildPieData() {
    final colors = [
      const Color(0xFF60A5FA),
      const Color(0xFF34D399),
      const Color(0xFFFBBF24),
      const Color(0xFFFB7185),
      const Color(0xFFA78BFA),
      const Color(0xFF22D3EE),
    ];
    final items = categoryData.entries.toList();

    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 34,
      sections: items.asMap().entries.map((entry) {
        final index = entry.key;
        final category = entry.value.key;
        final amount = entry.value.value;
        return PieChartSectionData(
          value: amount,
          title: category,
          radius: 70,
          titleStyle: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          color: colors[index % colors.length],
        );
      }).toList(),
    );
  }

  double _maxWeeklyValue() {
    if (weeklyExpenseData.isEmpty) return 0;
    return weeklyExpenseData.values.reduce((a, b) => a > b ? a : b);
  }

  double _maxMonthlyValue() {
    if (monthlyExpenseData.isEmpty) return 0;
    return monthlyExpenseData.values.reduce((a, b) => a > b ? a : b);
  }
}
