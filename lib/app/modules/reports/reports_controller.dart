import 'package:get/get.dart';

import '../../controllers/finance_controller.dart';
import '../../core/services/finance_calculator.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';

enum ReportMode { daily, monthly, yearly }

class ReportsController extends GetxController {
  final fin = Get.find<FinanceController>();

  final mode = ReportMode.daily.obs;
  final anchor = DateTime.now().obs;
  final categoryKind = TxType.expense.obs; // expense | income

  DateTime get start {
    final a = anchor.value;
    return switch (mode.value) {
      ReportMode.daily => DateTime(a.year, a.month),
      ReportMode.monthly => DateTime(a.year),
      ReportMode.yearly => DateTime(a.year - 4),
    };
  }

  DateTime get end {
    final a = anchor.value;
    return switch (mode.value) {
      ReportMode.daily => DateTime(a.year, a.month + 1),
      ReportMode.monthly || ReportMode.yearly => DateTime(a.year + 1),
    };
  }

  String get title {
    final a = anchor.value;
    return switch (mode.value) {
      ReportMode.daily => Fmt.month(a),
      ReportMode.monthly => '${a.year}',
      ReportMode.yearly => '${a.year - 4} – ${a.year}',
    };
  }

  String get bucketNoun => switch (mode.value) {
        ReportMode.daily => 'day',
        ReportMode.monthly => 'month',
        ReportMode.yearly => 'year',
      };

  void shift(int dir) {
    final a = anchor.value;
    anchor.value = switch (mode.value) {
      ReportMode.daily => DateTime(a.year, a.month + dir),
      ReportMode.monthly || ReportMode.yearly => DateTime(a.year + dir, a.month),
    };
  }

  void today() => anchor.value = DateTime.now();

  List<Bucket> get buckets {
    final a = anchor.value;
    final slots = <DateSlot>[];
    switch (mode.value) {
      case ReportMode.daily:
        final days = DateTime(a.year, a.month + 1, 0).day;
        for (var d = 1; d <= days; d++) {
          slots.add((label: '$d', start: DateTime(a.year, a.month, d), end: DateTime(a.year, a.month, d + 1)));
        }
      case ReportMode.monthly:
        for (var m = 1; m <= 12; m++) {
          final s = DateTime(a.year, m);
          slots.add((label: Fmt.monthShort(s), start: s, end: DateTime(a.year, m + 1)));
        }
      case ReportMode.yearly:
        for (var y = a.year - 4; y <= a.year; y++) {
          slots.add((label: '$y', start: DateTime(y), end: DateTime(y + 1)));
        }
    }
    return FinanceCalculator.buckets(fin.transactions, slots);
  }

  List<TransactionModel> get periodTx => FinanceCalculator.inRange(fin.transactions, start, end);
  double get income => FinanceCalculator.sumType(periodTx, TxType.income);
  double get expense => FinanceCalculator.sumType(periodTx, TxType.expense);
  double get savings => income - expense;
  double get savingsRate => income <= 0 ? 0 : savings / income;
  List<CategoryTotal> get breakdown => fin.breakdown(periodTx, categoryKind.value);
}
