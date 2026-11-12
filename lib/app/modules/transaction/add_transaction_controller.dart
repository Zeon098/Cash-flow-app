import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/finance_controller.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/loan_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';
import '../../widgets/picker_sheets.dart';

/// Arguments for the transaction form route.
class AddTxArgs {
  const AddTxArgs({this.type, this.loanId, this.editing});
  final TxType? type;
  final String? loanId;
  final TransactionModel? editing;
}

class AddTransactionController extends GetxController {
  final fin = Get.find<FinanceController>();

  TransactionModel? editing;
  bool get isEdit => editing != null;

  final type = TxType.expense.obs;
  final direction = 'in'.obs; // for adjustment / misc
  final date = DateTime.now().obs;
  final dueDate = Rxn<DateTime>();
  final accountId = ''.obs;
  final toAccountId = ''.obs;
  final categoryId = ''.obs;
  final loanId = ''.obs;

  final amountCtrl = TextEditingController();
  final titleCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  final personCtrl = TextEditingController();

  /// Unique per form session → the backend ignores a second submission with the same id.
  final String requestId = newRequestId();

  /// +1 money in, -1 money out, 0 neutral. Drives the colour of the amount card.
  int get effectiveSign =>
      type.value.fixedSign ?? (direction.value == 'out' ? -1 : 1);

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is AddTxArgs) {
      final tx = args.editing;
      if (tx != null) {
        editing = tx;
        type.value = tx.type;
        direction.value = tx.direction == 'out' ? 'out' : 'in';
        date.value = tx.date;
        accountId.value = tx.accountId;
        toAccountId.value = tx.toAccountId;
        categoryId.value = tx.categoryId;
        amountCtrl.text = tx.amount.toStringAsFixed(tx.amount % 1 == 0 ? 0 : 2);
        titleCtrl.text = tx.title;
        noteCtrl.text = tx.note;
        personCtrl.text = tx.person;
      } else {
        if (args.type != null) type.value = args.type!;
        if (args.loanId != null) {
          loanId.value = args.loanId!;
          final loan = fin.loanById(args.loanId!);
          if (loan != null) {
            accountId.value = loan.accountId;
            final out = fin.outstanding(loan);
            if (out > 0)
              amountCtrl.text = out.toStringAsFixed(out % 1 == 0 ? 0 : 2);
          }
        }
      }
    }
    if (accountId.value.isEmpty || fin.accountById(accountId.value) == null) {
      final def = fin.defaultAccountId;
      accountId.value = (def != null && fin.accountById(def) != null)
          ? def
          : (fin.accounts.isNotEmpty ? fin.accounts.first.id : '');
    }
  }

  // ───────────────────────── type selection ─────────────────────────
  void setGroup(TxGroup g) {
    if (type.value.group == g) return;
    setType(TxType.ofGroup(g).first);
  }

  void setType(TxType t) {
    type.value = t;
    categoryId.value = '';
    loanId.value = '';
    dueDate.value = null;
    direction.value = 'in';
  }

  // ───────────────────────── pickers ─────────────────────────
  List<PickerItem<String>> _accountItems({String? exclude}) => [
    for (final a in fin.accounts)
      if (a.id != exclude)
        PickerItem(
          value: a.id,
          label: a.name,
          subtitle: Fmt.money(fin.accountBalance(a.id)),
          icon: AppIcons.of(a.icon),
          color: hexColor(a.color),
        ),
  ];

  Future<void> pickAccount() async {
    final v = await pickFromList<String>(
      title: 'Account',
      items: _accountItems(),
      selected: accountId.value,
    );
    if (v != null) {
      accountId.value = v;
      if (toAccountId.value == v) toAccountId.value = '';
    }
  }

  Future<void> pickToAccount() async {
    final v = await pickFromList<String>(
      title: 'To account',
      items: _accountItems(exclude: accountId.value),
      selected: toAccountId.value,
    );
    if (v != null) toAccountId.value = v;
  }

  Future<void> pickDate(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: date.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) date.value = d;
  }

  Future<void> pickDueDate(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: dueDate.value ?? date.value.add(const Duration(days: 30)),
      firstDate: date.value,
      lastDate: DateTime(2100),
    );
    if (d != null) dueDate.value = d;
  }

  /// Open loans that match the repayment direction.
  List<LoanModel> get repayableLoans {
    final wantGiven = type.value == TxType.repaymentReceived;
    return fin.loans
        .where((l) => l.isGiven == wantGiven && fin.outstanding(l) > 0)
        .toList();
  }

  Future<void> pickLoan() async {
    final loans = repayableLoans;
    if (loans.isEmpty) {
      Toast.info('There are no open loans to repay.');
      return;
    }
    final v = await pickFromList<String>(
      title: 'Select loan',
      selected: loanId.value,
      items: [
        for (final l in loans)
          PickerItem(
            value: l.id,
            label: l.person,
            subtitle:
                '${Fmt.money(fin.outstanding(l))} outstanding · ${Fmt.shortDate(l.date)}',
            icon: Icons.handshake_rounded,
            color: l.isGiven
                ? const Color(0xFF10B981)
                : const Color(0xFFF43F5E),
          ),
      ],
    );
    if (v != null) {
      loanId.value = v;
      final loan = fin.loanById(v);
      if (loan != null && amountCtrl.text.trim().isEmpty) {
        final out = fin.outstanding(loan);
        amountCtrl.text = out.toStringAsFixed(out % 1 == 0 ? 0 : 2);
      }
    }
  }

  // ───────────────────────── save ─────────────────────────
  Future<void> save() async {
    if (fin.isSaving.value) return; // duplicate-tap guard
    final t = type.value;
    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '').trim());

    String? problem;
    if (amount == null || amount <= 0) {
      problem = 'Enter an amount greater than zero.';
    } else if (accountId.value.isEmpty) {
      problem = 'Select an account.';
    } else if (t.needsCategory && categoryId.value.isEmpty) {
      problem = 'Choose a category.';
    } else if (t == TxType.transfer &&
        (toAccountId.value.isEmpty || toAccountId.value == accountId.value)) {
      problem = 'Choose a different destination account.';
    } else if (t.isLoanCreate && personCtrl.text.trim().isEmpty) {
      problem = t == TxType.loanGiven
          ? 'Enter who you lent money to.'
          : 'Enter who you borrowed from.';
    } else if (t.isLoanCreate &&
        dueDate.value != null &&
        dueDate.value!.isBefore(date.value)) {
      problem = 'Due date cannot be before the loan date.';
    } else if (t.isRepayment) {
      final loan = fin.loanById(loanId.value);
      if (loan == null) {
        problem = 'Select the loan this repayment belongs to.';
      } else if (amount > fin.outstanding(loan) + 0.005) {
        problem =
            'Repayment exceeds the outstanding ${Fmt.money(fin.outstanding(loan))}.';
      }
    }
    if (problem != null) {
      Toast.error(problem);
      return;
    }

    final payload = <String, dynamic>{
      if (isEdit) 'id': editing!.id,
      'type': t.name,
      'amount': amount,
      'date': Fmt.iso(date.value),
      'accountId': accountId.value,
      'toAccountId': t == TxType.transfer ? toAccountId.value : '',
      'categoryId': t.needsCategory ? categoryId.value : '',
      'direction': t.needsDirection ? direction.value : '',
      'title': titleCtrl.text.trim(),
      'note': noteCtrl.text.trim(),
      'person': personCtrl.text.trim(),
      'loanId': t.isRepayment ? loanId.value : '',
      'dueDate': t.isLoanCreate && dueDate.value != null
          ? Fmt.iso(dueDate.value!)
          : '',
    };

    final ok = isEdit
        ? await fin.updateTransaction(payload)
        : await fin.addTransaction(payload, requestId);
    if (ok) {
      Get.back();
      Toast.success(
        isEdit ? 'Transaction updated' : 'Transaction saved to Google Sheets',
      );
    }
  }

  Future<void> delete() async {
    if (!isEdit) return;
    final ok = await confirmDialog(
      title: 'Delete transaction?',
      message: 'This permanently removes it from your Google Sheet.',
    );
    if (!ok) return;
    if (await fin.deleteTransaction(editing!.id)) {
      Get.back();
      Toast.success('Transaction deleted');
    }
  }

  @override
  void onClose() {
    amountCtrl.dispose();
    titleCtrl.dispose();
    noteCtrl.dispose();
    personCtrl.dispose();
    super.onClose();
  }
}
