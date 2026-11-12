import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_type.dart';
import '../../widgets/charts.dart';
import '../../widgets/common_widgets.dart';
import 'reports_controller.dart';

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return RefreshIndicator(
      color: AppColors.emerald,
      onRefresh: c.fin.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          const Text('Reports', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.8)),
          const SizedBox(height: 14),
          Obx(() => SizedBox(
                width: double.infinity,
                child: SegmentedButton<ReportMode>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(selectedBackgroundColor: AppColors.emerald, selectedForegroundColor: Colors.white),
                  segments: const [
                    ButtonSegment(value: ReportMode.daily, label: Text('Daily')),
                    ButtonSegment(value: ReportMode.monthly, label: Text('Monthly')),
                    ButtonSegment(value: ReportMode.yearly, label: Text('Yearly')),
                  ],
                  selected: {c.mode.value},
                  onSelectionChanged: (s) => c.mode.value = s.first,
                ),
              )),
          const SizedBox(height: 8),
          Obx(() => Row(children: [
                IconButton(onPressed: () => c.shift(-1), icon: const Icon(Icons.chevron_left_rounded)),
                Expanded(child: GestureDetector(onTap: c.today, child: Text(c.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)))),
                IconButton(onPressed: () => c.shift(1), icon: const Icon(Icons.chevron_right_rounded)),
              ])),
          const SizedBox(height: 6),
          Obx(() => Row(children: [
                Expanded(child: _Mini(label: 'Income', value: c.income, color: AppColors.emerald)),
                const SizedBox(width: 10),
                Expanded(child: _Mini(label: 'Expenses', value: c.expense, color: AppColors.coral)),
                const SizedBox(width: 10),
                Expanded(child: _Mini(label: 'Savings', value: c.savings, color: AppColors.signed(c.savings), signed: true)),
              ])),
          const SizedBox(height: 14),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Expanded(child: Text('Income vs expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                ChartLegend(),
              ]),
              const SizedBox(height: 18),
              Obx(() => IncomeExpenseChart(
                    key: ValueKey('${c.mode.value}-${c.anchor.value.year}-${c.anchor.value.month}'),
                    buckets: c.buckets,
                    height: 230,
                    minSlot: c.mode.value == ReportMode.daily ? 34 : 0,
                  )),
              Obx(() => c.mode.value == ReportMode.daily
                  ? const Padding(padding: EdgeInsets.only(top: 8), child: Text('Swipe sideways to see every day', style: TextStyle(fontSize: 11.5, color: AppColors.slate)))
                  : const SizedBox.shrink()),
            ]),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Expanded(child: Text('By category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                Obx(() => Pill(label: 'Expenses', selected: c.categoryKind.value == TxType.expense, color: AppColors.coral, onTap: () => c.categoryKind.value = TxType.expense)),
                const SizedBox(width: 6),
                Obx(() => Pill(label: 'Income', selected: c.categoryKind.value == TxType.income, onTap: () => c.categoryKind.value = TxType.income)),
              ]),
              const SizedBox(height: 18),
              Obx(() {
                final items = c.breakdown;
                if (items.isEmpty) {
                  return const EmptyState(icon: Icons.pie_chart_outline_rounded, title: 'No data for this period', compact: true);
                }
                final total = items.fold<double>(0, (s, i) => s + i.total);
                return Column(children: [
                  Center(child: CategoryDonut(items: items, centerLabel: c.categoryKind.value == TxType.expense ? 'Spent' : 'Earned', size: 190)),
                  const SizedBox(height: 18),
                  for (final i in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Column(children: [
                        Row(children: [
                          IconBadge(icon: i.icon, color: i.color, size: 34),
                          const SizedBox(width: 12),
                          Expanded(child: Text(i.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                          Text(Fmt.money(i.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                          SizedBox(width: 46, child: Text('${(i.total / total * 100).toStringAsFixed(0)}%', textAlign: TextAlign.right, style: const TextStyle(color: AppColors.slate, fontWeight: FontWeight.w700, fontSize: 12.5))),
                        ]),
                        const SizedBox(height: 7),
                        LinearProgressIndicator(value: i.total / total, minHeight: 5, color: i.color, backgroundColor: i.color.withValues(alpha: .13), borderRadius: BorderRadius.circular(6)),
                      ]),
                    ),
                ]);
              }),
            ]),
          ),
          const SizedBox(height: 14),
          Obx(() => AppCard(
                child: Row(children: [
                  IconBadge(icon: Icons.percent_rounded, color: AppColors.signed(c.savings), size: 40),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Savings rate', style: TextStyle(fontWeight: FontWeight.w700))),
                  Text('${(c.savingsRate * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.signed(c.savings))),
                ]),
              )),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.color, this.signed = false});
  final String label;
  final double value;
  final Color color;
  final bool signed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      radius: 18,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.slate, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(Fmt.money(value, sign: signed), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color))),
      ]),
    );
  }
}
