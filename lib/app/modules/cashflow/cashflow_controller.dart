import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/finance_controller.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';
import '../../routes/app_routes.dart';
import '../../widgets/picker_sheets.dart';
import '../transaction/add_transaction_controller.dart';

enum SortMode {
  newest('Newest first'),
  oldest('Oldest first'),
  highest('Highest amount'),
  lowest('Lowest amount');

  const SortMode(this.label);
  final String label;
}

class CashFlowController extends GetxController {
  final fin = Get.find<FinanceController>();

  final searchCtrl = TextEditingController();
  final query = ''.obs;
  final group = Rxn<TxGroup>();
  final categoryId = ''.obs;
  final accountId = ''.obs;
  final range = Rxn<DateTimeRange>();
  final sort = SortMode.newest.obs;

  bool get hasAdvancedFilters => categoryId.value.isNotEmpty || accountId.value.isNotEmpty || range.value != null;
  bool get isGroupedByDay => sort.value == SortMode.newest || sort.value == SortMode.oldest;

  List<TransactionModel> get filtered {
    final q = query.value.trim().toLowerCase();
    final r = range.value;
    final list = fin.transactions.where((t) {
      if (group.value != null && t.type.group != group.value) return false;
      if (categoryId.value.isNotEmpty && t.categoryId != categoryId.value) return false;
      if (accountId.value.isNotEmpty && t.accountId != accountId.value && t.toAccountId != accountId.value) return false;
      if (r != null) {
        final end = DateTime(r.end.year, r.end.month, r.end.day + 1);
        if (t.date.isBefore(r.start) || !t.date.isBefore(end)) return false;
      }
      if (q.isNotEmpty) {
        final hay = '${t.title} ${t.note} ${t.person} ${t.category} ${t.type.label} ${fin.accountName(t.accountId)} ${t.amount}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    switch (sort.value) {
      case SortMode.newest:
        break; // already newest first from the backend snapshot
      case SortMode.oldest:
        list.sort((a, b) {
          final c = a.date.compareTo(b.date);
          return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
        });
      case SortMode.highest:
        list.sort((a, b) => b.amount.compareTo(a.amount));
      case SortMode.lowest:
        list.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return list;
  }

  void clearFilters() {
    categoryId.value = '';
    accountId.value = '';
    range.value = null;
    sort.value = SortMode.newest;
  }

  Future<void> pickCategory() async {
    final v = await pickFromList<String>(
      title: 'Category',
      selected: categoryId.value,
      items: [
        for (final c in fin.categories)
          PickerItem(value: c.id, label: c.name, subtitle: c.type == 'income' ? 'Income' : 'Expense', icon: AppIcons.of(c.icon), color: hexColor(c.color)),
      ],
    );
    if (v != null) categoryId.value = v;
  }

  Future<void> pickAccount() async {
    final v = await pickFromList<String>(
      title: 'Account',
      selected: accountId.value,
      items: [for (final a in fin.accounts) PickerItem(value: a.id, label: a.name, icon: AppIcons.of(a.icon), color: hexColor(a.color))],
    );
    if (v != null) accountId.value = v;
  }

  Future<void> pickRange(BuildContext context) async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 2),
      initialDateRange: range.value,
    );
    if (r != null) range.value = r;
  }

  void open(TransactionModel tx) {
    if (tx.type.isLoanLinked) {
      Get.toNamed(Routes.loanDetail, arguments: tx.loanId);
    } else {
      Get.toNamed(Routes.addTransaction, arguments: AddTxArgs(editing: tx));
    }
  }

  Future<void> remove(TransactionModel tx) async {
    final extra = tx.type.isLoanLinked ? '\n\nThis also updates the linked loan records.' : '';
    final ok = await confirmDialog(title: 'Delete transaction?', message: 'This permanently removes it from your Google Sheet.$extra');
    if (!ok) return;
    if (await fin.deleteTransaction(tx.id)) Toast.success('Transaction deleted');
  }

  @override
  void onClose() {
    searchCtrl.dispose();
    super.onClose();
  }
}
