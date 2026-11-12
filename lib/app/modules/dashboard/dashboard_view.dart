import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/helpers.dart';
import '../../routes/app_routes.dart';
import '../../widgets/charts.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/transaction_tile.dart';
import '../../data/models/transaction_type.dart';
import '../home/home_controller.dart';
import '../transaction/add_transaction_controller.dart';
import 'dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CashFlow', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.8)),
                    Text(Fmt.month(DateTime.now()), style: const TextStyle(color: AppColors.slate, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Obx(() => fin.isLoading.value
                  ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.emerald)))
                  : IconButton(onPressed: fin.load, icon: const Icon(Icons.refresh_rounded))),
            ],
          ),
          const SizedBox(height: 16),
          FadeSlide(child: Obx(() => _HeroCard(balance: fin.availableBalance, net: fin.netPosition, accounts: fin.accounts.length))),
          const SizedBox(height: 14),
          FadeSlide(
            index: 1,
            child: Obx(() => Row(children: [
                  Expanded(child: _StatCard(icon: Icons.south_west_rounded, label: 'Income · this month', value: c.monthIncome, color: AppColors.emerald, forceColor: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(icon: Icons.north_east_rounded, label: 'Expenses · this month', value: c.monthExpense, color: AppColors.coral, forceColor: true)),
                ])),
          ),
          const SizedBox(height: 12),
          FadeSlide(
            index: 2,
            child: Obx(() => Row(children: [
                  Expanded(child: _StatCard(icon: Icons.call_made_rounded, label: 'Receivables', value: fin.receivables, color: AppColors.sky, forceColor: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(icon: Icons.call_received_rounded, label: 'Liabilities', value: fin.liabilities, color: AppColors.amber, forceColor: true)),
                ])),
          ),
          const SizedBox(height: 12),
          FadeSlide(index: 3, child: Obx(() => _SavingsCard(savings: c.monthSavings, rate: c.savingsRate))),
          const SizedBox(height: 18),
          FadeSlide(
            index: 4,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Expanded(child: Text('Income vs expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
                    ChartLegend(),
                  ]),
                  const SizedBox(height: 18),
                  Obx(() => IncomeExpenseChart(buckets: c.last6Months, height: 200)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlide(
            index: 5,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spending this month', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  Obx(() {
                    final items = c.expenseBreakdown;
                    if (items.isEmpty) {
                      return const EmptyState(icon: Icons.donut_large_rounded, title: 'No spending yet', subtitle: 'Expenses you add will be broken down here.', compact: true);
                    }
                    final total = items.fold<double>(0, (s, i) => s + i.total);
                    return Row(
                      children: [
                        CategoryDonut(items: items, centerLabel: 'Spent', size: 150),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              for (final i in items.take(5))
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(children: [
                                    Container(width: 10, height: 10, decoration: BoxDecoration(color: i.color, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(i.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                                    Text('${(i.total / total * 100).round()}%', style: const TextStyle(color: AppColors.slate, fontWeight: FontWeight.w700, fontSize: 12.5)),
                                  ]),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader('Accounts'),
          SizedBox(
            height: 104,
            child: Obx(() => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: fin.accounts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final a = fin.accounts[i];
                    final bal = fin.accountBalance(a.id);
                    return SizedBox(
                      width: 168,
                      child: AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(children: [
                              IconBadge(icon: AppIcons.of(a.icon), color: hexColor(a.color), size: 32),
                              const SizedBox(width: 8),
                              Expanded(child: Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700))),
                            ]),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(Fmt.money(bal), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.signed(bal))),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )),
          ),
          const SizedBox(height: 12),
          SectionHeader('Recent transactions', action: 'See all', onAction: () => Get.find<HomeController>().setIndex(1)),
          Obx(() {
            final list = c.recent;
            if (list.isEmpty) {
              return AppCard(
                child: Column(children: [
                  const EmptyState(icon: Icons.receipt_long_rounded, title: 'No transactions yet', subtitle: 'Tap “Add transaction” to record your first entry.', compact: true),
                  FilledButton.icon(
                    onPressed: () => Get.toNamed(Routes.addTransaction, arguments: const AddTxArgs(type: TxType.income)),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add income'),
                  ),
                ]),
              );
            }
            return AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(children: [
                for (var i = 0; i < list.length; i++) ...[
                  TransactionTile(
                    tx: list[i],
                    showDate: true,
                    onTap: () => list[i].type.isLoanLinked
                        ? Get.toNamed(Routes.loanDetail, arguments: list[i].loanId)
                        : Get.toNamed(Routes.addTransaction, arguments: AddTxArgs(editing: list[i])),
                  ),
                  if (i != list.length - 1) const Divider(),
                ],
              ]),
            );
          }),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.balance, required this.net, required this.accounts});
  final double balance;
  final double net;
  final int accounts;

  @override
  Widget build(BuildContext context) {
    final positive = balance >= 0;
    final base = positive ? AppColors.emerald : AppColors.coral;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: positive ? [AppColors.emeraldDeep, AppColors.emerald] : [AppColors.coralDeep, AppColors.coral],
        ),
        boxShadow: [BoxShadow(color: base.withValues(alpha: .32), blurRadius: 28, offset: const Offset(0, 14))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned(right: -36, top: -36, child: _circle(150, .10)),
            Positioned(right: 50, bottom: -62, child: _circle(130, .08)),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available balance', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 8),
                  CountUpMoney(balance, style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w800, letterSpacing: -1.2)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Net financial position', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(Fmt.money(net), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                          ]),
                        ),
                        Container(width: 1, height: 30, color: Colors.white24),
                        const SizedBox(width: 14),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('Accounts', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text('$accounts', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double size, double alpha) =>
      Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: alpha)));
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.label, required this.value, required this.color, this.forceColor = false});
  final IconData icon;
  final String label;
  final double value;
  final Color color;
  final bool forceColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColors.slate, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Fmt.money(value), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: forceColor ? null : AppColors.signed(value))),
          ),
        ],
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.savings, required this.rate});
  final double savings;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.signed(savings);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            IconBadge(icon: Icons.savings_rounded, color: color, size: 36),
            const SizedBox(width: 12),
            const Expanded(child: Text('Monthly savings', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.slate))),
            Text(Fmt.money(savings, sign: true), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: color)),
          ]),
          const SizedBox(height: 14),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: rate),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => LinearProgressIndicator(value: v, minHeight: 8, color: color, backgroundColor: color.withValues(alpha: .15), borderRadius: BorderRadius.circular(8)),
          ),
          const SizedBox(height: 8),
          Text('${(rate * 100).round()}% of this month’s income saved', style: const TextStyle(fontSize: 12, color: AppColors.slate, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
