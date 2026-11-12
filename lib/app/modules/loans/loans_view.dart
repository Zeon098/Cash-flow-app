import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/loan_model.dart';
import '../../widgets/common_widgets.dart';
import 'loans_controller.dart';

class LoansView extends GetView<LoansController> {
  const LoansView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final fin = c.fin;
    return RefreshIndicator(
      color: AppColors.emerald,
      onRefresh: fin.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          const Text('Loans', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.8)),
          const SizedBox(height: 14),
          Obx(() => Row(children: [
                Expanded(
                  child: _SummaryTab(
                    label: 'You are owed',
                    caption: 'Loans given',
                    value: fin.receivables,
                    color: AppColors.emerald,
                    icon: Icons.call_made_rounded,
                    selected: c.tab.value == 0,
                    onTap: () => c.tab.value = 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryTab(
                    label: 'You owe',
                    caption: 'Loans taken',
                    value: fin.liabilities,
                    color: AppColors.coral,
                    icon: Icons.call_received_rounded,
                    selected: c.tab.value == 1,
                    onTap: () => c.tab.value = 1,
                  ),
                ),
              ])),
          const SizedBox(height: 16),
          Obx(() => Row(children: [
                Pill(label: 'Active', selected: !c.showSettled.value, onTap: () => c.showSettled.value = false),
                const SizedBox(width: 8),
                Pill(label: 'Settled history', selected: c.showSettled.value, onTap: () => c.showSettled.value = true),
              ])),
          const SizedBox(height: 14),
          Obx(() {
            final list = c.visible;
            if (list.isEmpty) {
              return EmptyState(
                icon: Icons.handshake_rounded,
                title: c.showSettled.value ? 'No settled loans' : (c.tab.value == 0 ? 'No money lent out' : 'No money borrowed'),
                subtitle: c.showSettled.value ? 'Fully repaid loans will appear here.' : 'Tap “New loan” to record one.',
              );
            }
            return Column(children: [
              for (var i = 0; i < list.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FadeSlide(index: i.clamp(0, 6), child: _LoanCard(loan: list[i], c: c)),
                ),
            ]);
          }),
        ],
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.label, required this.caption, required this.value, required this.color, required this.icon, required this.selected, required this.onTap});
  final String label;
  final String caption;
  final double value;
  final Color color;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: selected ? color : Colors.transparent, width: 1.6),
      ),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconBadge(icon: icon, color: color, size: 32),
            const SizedBox(width: 8),
            Expanded(child: Text(caption, style: const TextStyle(fontSize: 12, color: AppColors.slate, fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.slate)),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(Fmt.money(value), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color))),
        ]),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  const _LoanCard({required this.loan, required this.c});
  final LoanModel loan;
  final LoansController c;

  @override
  Widget build(BuildContext context) {
    final out = c.fin.outstanding(loan);
    final repaid = c.fin.repaid(loan);
    final progress = loan.amount <= 0 ? 0.0 : (repaid / loan.amount).clamp(0.0, 1.0).toDouble();
    final color = loan.isGiven ? AppColors.emerald : AppColors.coral;
    final overdue = c.isOverdue(loan);
    final settled = out <= 0;
    final initial = loan.person.isEmpty ? '?' : loan.person.characters.first.toUpperCase();

    return AppCard(
      onTap: () => c.open(loan),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 22, backgroundColor: color.withValues(alpha: .14), child: Text(initial, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(loan.person, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(
                '${loan.isGiven ? 'Lent' : 'Borrowed'} ${Fmt.shortDate(loan.date)}${loan.dueDate != null ? ' · Due ${Fmt.shortDate(loan.dueDate!)}' : ''}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.slate),
              ),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(Fmt.money(settled ? loan.amount : out), style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: settled ? AppColors.slate : color)),
            const SizedBox(height: 2),
            Text(settled ? 'settled' : 'outstanding', style: const TextStyle(fontSize: 11.5, color: AppColors.slate)),
          ]),
        ]),
        const SizedBox(height: 14),
        LinearProgressIndicator(value: progress, minHeight: 7, color: color, backgroundColor: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(8)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: Text('${Fmt.money(repaid)} repaid of ${Fmt.money(loan.amount)}', style: const TextStyle(fontSize: 12, color: AppColors.slate, fontWeight: FontWeight.w600))),
          if (overdue) _badge('Overdue', AppColors.coral) else if (settled) _badge('Settled', AppColors.emerald),
        ]),
      ]),
    );
  }

  Widget _badge(String t, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: .14), borderRadius: BorderRadius.circular(20)),
        child: Text(t, style: TextStyle(color: color, fontSize: 11.5, fontWeight: FontWeight.w800)),
      );
}
