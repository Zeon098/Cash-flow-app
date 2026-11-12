import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/finance_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/transaction_type.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/picker_sheets.dart';
import '../transaction/add_transaction_controller.dart';
import 'loans_controller.dart';

class LoanDetailView extends GetView<FinanceController> {
  const LoanDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final fin = controller;
    final loanId = Get.arguments is String ? Get.arguments as String : '';
    return Obx(() {
      final loan = fin.loanById(loanId);
      if (loan == null) {
        return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.search_off_rounded, title: 'Loan not found'));
      }
      final out = fin.outstanding(loan);
      final repaid = fin.repaid(loan);
      final reps = fin.repaymentsOf(loan.id);
      final color = loan.isGiven ? AppColors.emerald : AppColors.coral;
      final settled = out <= 0;
      final progress = loan.amount <= 0 ? 0.0 : (repaid / loan.amount).clamp(0.0, 1.0).toDouble();

      return Scaffold(
        appBar: AppBar(
          title: Text(loan.person),
          actions: [
            PopupMenuButton<String>(
              onSelected: (_) => Get.find<LoansController>().deleteLoan(loan.id),
              itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('Delete loan'))],
            ),
          ],
        ),
        bottomNavigationBar: settled
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: PrimaryButton(
                    label: loan.isGiven ? 'Record repayment received' : 'Record repayment paid',
                    icon: Icons.add_rounded,
                    onPressed: () => Get.toNamed(
                      Routes.addTransaction,
                      arguments: AddTxArgs(type: loan.isGiven ? TxType.repaymentReceived : TxType.repaymentPaid, loanId: loan.id),
                    ),
                  ),
                ),
              ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            FadeSlide(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: loan.isGiven ? [AppColors.emeraldDeep, AppColors.emerald] : [AppColors.coralDeep, AppColors.coral],
                  ),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loan.isGiven ? 'Loan given · they owe you' : 'Loan taken · you owe them', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  CountUpMoney(out, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1)),
                  Text(settled ? 'Fully settled 🎉' : 'outstanding', style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(value: progress, minHeight: 8, color: Colors.white, backgroundColor: Colors.white24, borderRadius: BorderRadius.circular(8)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: Text('Repaid ${Fmt.money(repaid)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
                    Text('of ${Fmt.money(loan.amount)}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(children: [
                _row('Person', loan.person),
                _row('Date', Fmt.date(loan.date)),
                _row('Due date', loan.dueDate == null ? '—' : Fmt.date(loan.dueDate!)),
                _row('Account', fin.accountName(loan.accountId)),
                if (loan.note.isNotEmpty) _row('Note', loan.note),
              ]),
            ),
            const SizedBox(height: 10),
            SectionHeader('Repayment history (${reps.length})'),
            if (reps.isEmpty)
              const AppCard(child: EmptyState(icon: Icons.history_rounded, title: 'No repayments yet', subtitle: 'Partial or full repayments will be listed here.', compact: true))
            else
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(children: [
                  for (var i = 0; i < reps.length; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(children: [
                        IconBadge(icon: Icons.check_rounded, color: color, size: 38),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(Fmt.date(reps[i].date), style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text('${fin.accountName(reps[i].accountId)}${reps[i].note.isEmpty ? '' : ' · ${reps[i].note}'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, color: AppColors.slate)),
                          ]),
                        ),
                        Text(Fmt.money(reps[i].amount), style: TextStyle(fontWeight: FontWeight.w800, color: color)),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.slate),
                          onPressed: () async {
                            final ok = await confirmDialog(title: 'Delete repayment?', message: 'The outstanding balance will increase again.');
                            if (ok && await fin.deleteRepayment(reps[i].id)) Toast.success('Repayment deleted');
                          },
                        ),
                      ]),
                    ),
                    if (i != reps.length - 1) const Divider(),
                  ],
                ]),
              ),
          ],
        ),
      );
    });
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 90, child: Text(k, style: const TextStyle(color: AppColors.slate, fontWeight: FontWeight.w600))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );
}
