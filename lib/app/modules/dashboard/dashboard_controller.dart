import 'package:get/get.dart';

import '../../controllers/finance_controller.dart';
import '../../core/services/finance_calculator.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';

class DashboardController extends GetxController {
  final fin = Get.find<FinanceController>();

  DateTime get _now => DateTime.now();
  DateTime get monthStart => DateTime(_now.year, _now.month);
  DateTime get monthEnd => DateTime(_now.year, _now.month + 1);

  List<TransactionModel> get monthTx => FinanceCalculator.inRange(fin.transactions, monthStart, monthEnd);
  double get monthIncome => FinanceCalculator.sumType(monthTx, TxType.income);
  double get monthExpense => FinanceCalculator.sumType(monthTx, TxType.expense);

  /// Monthly savings = income - expenses.
  double get monthSavings => monthIncome - monthExpense;
  double get savingsRate => monthIncome <= 0 ? 0 : (monthSavings / monthIncome).clamp(0.0, 1.0).toDouble();

  List<Bucket> get last6Months {
    final n = _now;
    final slots = <DateSlot>[];
    for (var i = 5; i >= 0; i--) {
      final s = DateTime(n.year, n.month - i);
      slots.add((label: Fmt.monthShort(s), start: s, end: DateTime(s.year, s.month + 1)));
    }
    return FinanceCalculator.buckets(fin.transactions, slots);
  }

  List<CategoryTotal> get expenseBreakdown => fin.breakdown(monthTx, TxType.expense);
  List<TransactionModel> get recent => fin.transactions.take(8).toList();
}
