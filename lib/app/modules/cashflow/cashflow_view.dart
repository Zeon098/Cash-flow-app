import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/picker_sheets.dart';
import '../../widgets/transaction_tile.dart';
import 'cashflow_controller.dart';

class _DayHeader {
  _DayHeader(this.date, this.net);
  final DateTime date;
  final double net;
}

class CashFlowView extends GetView<CashFlowController> {
  const CashFlowView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
          child: Row(
            children: [
              const Expanded(child: Text('Cash Flow', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.8))),
              Obx(() {
                final active = c.hasAdvancedFilters || c.sort.value != SortMode.newest;
                return IconButton(
                  onPressed: () => showAppSheet(_FilterSheet(c: c)),
                  icon: Badge(isLabelVisible: active, smallSize: 9, backgroundColor: AppColors.emerald, child: const Icon(Icons.tune_rounded)),
                );
              }),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: TextField(
            controller: c.searchCtrl,
            onChanged: (v) => c.query.value = v,
            decoration: InputDecoration(
              hintText: 'Search title, note, person, category…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: Obx(() => c.query.value.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        c.searchCtrl.clear();
                        c.query.value = '';
                      },
                    )),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: Obx(() => ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Pill(label: 'All', selected: c.group.value == null, onTap: () => c.group.value = null),
                  for (final g in TxGroup.values) ...[
                    const SizedBox(width: 8),
                    Pill(label: g.label, icon: g.icon, selected: c.group.value == g, onTap: () => c.group.value = g),
                  ],
                ],
              )),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: RefreshIndicator(
            color: AppColors.emerald,
            onRefresh: c.fin.load,
            child: Obx(() {
              final list = c.filtered;
              if (list.isEmpty) {
                return ListView(children: const [
                  SizedBox(height: 60),
                  EmptyState(icon: Icons.search_off_rounded, title: 'Nothing here', subtitle: 'No transactions match your search or filters.'),
                ]);
              }

              final items = <Object>[];
              if (c.isGroupedByDay) {
                final dayNet = <String, double>{};
                for (final t in list) {
                  final k = Fmt.iso(t.date);
                  dayNet[k] = (dayNet[k] ?? 0) + t.signedAmount;
                }
                String? last;
                for (final t in list) {
                  final k = Fmt.iso(t.date);
                  if (k != last) {
                    items.add(_DayHeader(t.date, dayNet[k] ?? 0));
                    last = k;
                  }
                  items.add(t);
                }
              } else {
                items.addAll(list);
              }

              final inflow = list.where((t) => t.signedAmount > 0).fold<double>(0, (s, t) => s + t.signedAmount);
              final outflow = list.where((t) => t.signedAmount < 0).fold<double>(0, (s, t) => s + t.signedAmount.abs());

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                itemCount: items.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) return _SummaryStrip(count: list.length, inflow: inflow, outflow: outflow);
                  final item = items[i - 1];
                  if (item is _DayHeader) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
                      child: Row(children: [
                        Expanded(child: Text(Fmt.day(item.date), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.slate))),
                        Text(Fmt.money(item.net, sign: true), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.signed(item.net))),
                      ]),
                    );
                  }
                  final tx = item as TransactionModel;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Dismissible(
                      key: ValueKey(tx.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        await c.remove(tx);
                        return false; // list rebuilds from the server snapshot
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.delete_rounded, color: Colors.white),
                      ),
                      child: TransactionTile(tx: tx, card: true, showDate: !c.isGroupedByDay, onTap: () => c.open(tx)),
                    ),
                  );
                },
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.count, required this.inflow, required this.outflow});
  final int count;
  final double inflow;
  final double outflow;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value, Color color) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.slate, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color))),
          ]),
        );
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      radius: 18,
      child: Row(children: [
        cell('Entries', '$count', Theme.of(context).colorScheme.onSurface),
        cell('Money in', Fmt.money(inflow), AppColors.emerald),
        cell('Money out', Fmt.money(outflow), AppColors.coral),
      ]),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.c});
  final CashFlowController c;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .8),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
        child: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                Row(children: [
                  const Expanded(child: Text('Filter & sort', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                  TextButton(onPressed: c.clearFilters, child: const Text('Reset')),
                ]),
                const SizedBox(height: 8),
                const Text('Sort by', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.slate)),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final s in SortMode.values) Pill(label: s.label, selected: c.sort.value == s, onTap: () => c.sort.value = s),
                ]),
                const SizedBox(height: 20),
                SelectorField(
                  label: 'Category',
                  placeholder: 'All categories',
                  icon: Icons.category_rounded,
                  value: c.fin.categoryById(c.categoryId.value)?.name,
                  onTap: c.pickCategory,
                  onClear: () => c.categoryId.value = '',
                ),
                const SizedBox(height: 10),
                SelectorField(
                  label: 'Account',
                  placeholder: 'All accounts',
                  icon: Icons.account_balance_wallet_rounded,
                  value: c.accountId.value.isEmpty ? null : c.fin.accountName(c.accountId.value),
                  onTap: c.pickAccount,
                  onClear: () => c.accountId.value = '',
                ),
                const SizedBox(height: 10),
                SelectorField(
                  label: 'Date range',
                  placeholder: 'Any time',
                  icon: Icons.date_range_rounded,
                  value: c.range.value == null ? null : '${Fmt.date(c.range.value!.start)} – ${Fmt.date(c.range.value!.end)}',
                  onTap: () => c.pickRange(context),
                  onClear: () => c.range.value = null,
                ),
                const SizedBox(height: 22),
                PrimaryButton(label: 'Show results', onPressed: Get.back),
              ],
            )),
      ),
    );
  }
}
