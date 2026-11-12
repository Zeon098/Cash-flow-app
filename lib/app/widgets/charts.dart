import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/services/finance_calculator.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';

double _niceCeil(double v) {
  final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  final n = v / mag;
  final nice = n <= 1 ? 1 : (n <= 2 ? 2 : (n <= 5 ? 5 : 10));
  return nice * mag;
}

/// Grouped income vs expense bars. Scrolls horizontally when there are many
/// buckets (set [minSlot] to the minimum width per bucket).
class IncomeExpenseChart extends StatelessWidget {
  const IncomeExpenseChart({super.key, required this.buckets, this.height = 220, this.minSlot = 0});

  final List<Bucket> buckets;
  final double height;
  final double minSlot;

  @override
  Widget build(BuildContext context) {
    final grid = Theme.of(context).colorScheme.outlineVariant;
    final maxV = buckets.fold<double>(0, (m, b) => math.max(m, math.max(b.income, b.expense)));
    final maxY = maxV <= 0 ? 100.0 : _niceCeil(maxV);

    return LayoutBuilder(builder: (context, c) {
      final width = math.max(c.maxWidth, buckets.length * minSlot);
      final slot = width / math.max(buckets.length, 1);
      final rod = (slot * .26).clamp(4.0, 14.0).toDouble();

      final chart = SizedBox(
        width: width,
        height: height,
        child: BarChart(
          BarChartData(
            maxY: maxY,
            alignment: BarChartAlignment.spaceAround,
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (_) => FlLine(color: grid, strokeWidth: 1, dashArray: [4, 4]),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  interval: maxY / 4,
                  getTitlesWidget: (v, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(Fmt.compact(v), style: const TextStyle(fontSize: 10.5, color: AppColors.slate)),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(buckets[i].label, style: const TextStyle(fontSize: 10.5, color: AppColors.slate)),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => const Color(0xFF111827),
                getTooltipItem: (group, gi, r, ri) => BarTooltipItem(
                  '${buckets[gi].label} · ${ri == 0 ? 'Income' : 'Expense'}\n${Fmt.money(r.toY)}',
                  const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < buckets.length; i++)
                BarChartGroupData(
                  x: i,
                  barsSpace: 3,
                  barRods: [
                    BarChartRodData(
                      toY: buckets[i].income,
                      width: rod,
                      color: AppColors.emerald,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(rod / 2.2)),
                    ),
                    BarChartRodData(
                      toY: buckets[i].expense,
                      width: rod,
                      color: AppColors.coral,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(rod / 2.2)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      );

      if (width > c.maxWidth) {
        return SingleChildScrollView(scrollDirection: Axis.horizontal, child: chart);
      }
      return chart;
    });
  }
}

class ChartLegend extends StatelessWidget {
  const ChartLegend({super.key});
  @override
  Widget build(BuildContext context) {
    Widget dot(Color c, String t) => Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(t, style: const TextStyle(fontSize: 12, color: AppColors.slate, fontWeight: FontWeight.w600)),
        ]);
    return Row(children: [dot(AppColors.emerald, 'Income'), const SizedBox(width: 14), dot(AppColors.coral, 'Expenses')]);
  }
}

class CategoryDonut extends StatelessWidget {
  const CategoryDonut({super.key, required this.items, required this.centerLabel, this.size = 160});
  final List<CategoryTotal> items;
  final String centerLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (s, i) => s + i.total);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: size * .32,
              startDegreeOffset: -90,
              sections: [
                for (final i in items)
                  PieChartSectionData(value: i.total, color: i.color, radius: size * .15, showTitle: false),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(centerLabel, style: const TextStyle(fontSize: 11, color: AppColors.slate, fontWeight: FontWeight.w600)),
              Text(Fmt.compact(total), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }
}
