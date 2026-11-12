import 'package:get/get.dart';

import '../../controllers/finance_controller.dart';
import '../../data/models/loan_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/picker_sheets.dart';
import '../../core/utils/helpers.dart';

class LoansController extends GetxController {
  final fin = Get.find<FinanceController>();

  /// 0 = loans given (receivables), 1 = loans taken (liabilities)
  final tab = 0.obs;
  final showSettled = false.obs;

  bool isOverdue(LoanModel l) {
    if (l.dueDate == null || fin.outstanding(l) <= 0) return false;
    final now = DateTime.now();
    return l.dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  List<LoanModel> get visible {
    final given = tab.value == 0;
    final list = fin.loans.where((l) {
      if (l.isGiven != given) return false;
      final open = fin.outstanding(l) > 0;
      return showSettled.value ? !open : open;
    }).toList();
    list.sort((a, b) {
      final oa = isOverdue(a) ? 0 : 1;
      final ob = isOverdue(b) ? 0 : 1;
      if (oa != ob) return oa.compareTo(ob);
      if (a.dueDate != null && b.dueDate != null) return a.dueDate!.compareTo(b.dueDate!);
      if (a.dueDate != null) return -1;
      if (b.dueDate != null) return 1;
      return b.date.compareTo(a.date);
    });
    return list;
  }

  void open(LoanModel l) => Get.toNamed(Routes.loanDetail, arguments: l.id);

  Future<void> deleteLoan(String id) async {
    final ok = await confirmDialog(
      title: 'Delete loan?',
      message: 'The loan, all of its repayments and the linked transactions will be permanently removed from your Google Sheet.',
    );
    if (!ok) return;
    if (await fin.deleteLoan(id)) {
      Get.back();
      Toast.success('Loan deleted');
    }
  }
}
