import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/finance_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../core/utils/helpers.dart';
import '../data/models/transaction_model.dart';
import '../data/models/transaction_type.dart';
import 'common_widgets.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.tx, this.onTap, this.card = false, this.showDate = false});

  final TransactionModel tx;
  final VoidCallback? onTap;
  final bool card;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final fin = Get.find<FinanceController>();
    final cat = fin.categoryById(tx.categoryId);
    final byCategory = tx.type.needsCategory;
    final icon = byCategory ? AppIcons.of(cat?.icon) : tx.type.icon;
    final color = byCategory ? hexColor(cat?.color, tx.type.color) : tx.type.color;
    final title = tx.title.isNotEmpty ? tx.title : (tx.category.isNotEmpty ? tx.category : tx.type.label);

    final parts = <String>[
      if (byCategory && tx.title.isNotEmpty && tx.category.isNotEmpty) tx.category,
      if (!byCategory) tx.type.label,
      if (tx.person.isNotEmpty && !tx.type.isRepayment) tx.person,
      tx.type == TxType.transfer
          ? '${fin.accountName(tx.accountId)} → ${fin.accountName(tx.toAccountId)}'
          : fin.accountName(tx.accountId),
      if (showDate) Fmt.shortDate(tx.date),
    ];

    final signed = tx.signedAmount;
    final isTransfer = tx.type == TxType.transfer;
    final amountText = isTransfer ? Fmt.money(tx.amount) : Fmt.money(signed, sign: true);
    final amountColor = isTransfer ? AppColors.slate : AppColors.signed(signed);

    final row = Row(
      children: [
        IconBadge(icon: icon, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(parts.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.slate)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(amountText, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: amountColor)),
      ],
    );

    if (card) {
      return AppCard(radius: 20, padding: const EdgeInsets.all(12), onTap: onTap, child: row);
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10), child: row),
    );
  }
}
