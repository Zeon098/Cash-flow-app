import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum TxGroup {
  income('Income', Icons.south_west_rounded),
  expense('Expense', Icons.north_east_rounded),
  cash('Cash', Icons.account_balance_wallet_rounded),
  loan('Loans', Icons.handshake_rounded),
  other('Other', Icons.swap_horiz_rounded);

  const TxGroup(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Every kind of money movement. `fixedSign`: +1 inflow, -1 outflow,
/// 0 neutral (transfer) and null = user chooses direction (adjustment/misc).
enum TxType {
  income('Income', TxGroup.income, Icons.south_west_rounded, 1),
  expense('Expense', TxGroup.expense, Icons.north_east_rounded, -1),
  deposit('Deposit', TxGroup.cash, Icons.savings_rounded, 1),
  withdrawal('Withdrawal', TxGroup.cash, Icons.atm_rounded, -1),
  openingBalance('Opening balance', TxGroup.cash, Icons.flag_rounded, 1),
  adjustment('Cash adjustment', TxGroup.cash, Icons.tune_rounded, null),
  loanGiven('Loan given', TxGroup.loan, Icons.call_made_rounded, -1),
  loanTaken('Loan taken', TxGroup.loan, Icons.call_received_rounded, 1),
  repaymentReceived('Repayment received', TxGroup.loan, Icons.assignment_returned_rounded, 1),
  repaymentPaid('Repayment paid', TxGroup.loan, Icons.payments_rounded, -1),
  moneyReceived('Money received', TxGroup.other, Icons.arrow_downward_rounded, 1),
  moneySent('Money sent', TxGroup.other, Icons.arrow_upward_rounded, -1),
  transfer('Transfer', TxGroup.other, Icons.swap_horiz_rounded, 0),
  misc('Miscellaneous', TxGroup.other, Icons.more_horiz_rounded, null);

  const TxType(this.label, this.group, this.icon, this.fixedSign);

  final String label;
  final TxGroup group;
  final IconData icon;
  final int? fixedSign;

  static TxType fromKey(String? key) => TxType.values.firstWhere((t) => t.name == key, orElse: () => TxType.misc);
  static List<TxType> ofGroup(TxGroup g) => TxType.values.where((t) => t.group == g).toList();

  Color get color => switch (group) {
        TxGroup.income => AppColors.emerald,
        TxGroup.expense => AppColors.coral,
        TxGroup.cash => AppColors.sky,
        TxGroup.loan => AppColors.amber,
        TxGroup.other => AppColors.violet,
      };

  bool get needsCategory => this == income || this == expense;
  bool get isLoanCreate => this == loanGiven || this == loanTaken;
  bool get isRepayment => this == repaymentReceived || this == repaymentPaid;
  bool get isLoanLinked => isLoanCreate || isRepayment;
  bool get needsDirection => this == adjustment || this == misc;
}
