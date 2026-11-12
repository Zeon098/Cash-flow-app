import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/loan_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_type.dart';

class Bucket {
  const Bucket(this.label, this.income, this.expense);
  final String label;
  final double income;
  final double expense;
  double get net => income - expense;
}

class CategoryTotal {
  const CategoryTotal(this.name, this.total, this.color, this.icon);
  final String name;
  final double total;
  final Color color;
  final IconData icon;
}

typedef DateSlot = ({String label, DateTime start, DateTime end});

/// Pure financial logic. No UI, no I/O.
///
/// Available Balance = Opening + Income + Deposits + Loans Taken + Repayments Received
///                     - Expenses - Withdrawals - Loans Given - Repayments Paid
/// (plus money received/sent and +/- adjustments or misc entries).
/// Transfers are neutral for the total balance.
class FinanceCalculator {
  FinanceCalculator._();

  static double _r(double v) => (v * 100).roundToDouble() / 100;

  static double balance(Iterable<TransactionModel> txs) => _r(txs.fold(0.0, (s, t) => s + t.signedAmount));

  static double accountBalance(Iterable<TransactionModel> txs, String accountId) =>
      _r(txs.fold(0.0, (s, t) => s + t.effectOn(accountId)));

  static double sumType(Iterable<TransactionModel> txs, TxType type) =>
      _r(txs.where((t) => t.type == type).fold(0.0, (s, t) => s + t.amount));

  static List<TransactionModel> inRange(Iterable<TransactionModel> txs, DateTime start, DateTime endExclusive) =>
      txs.where((t) => !t.date.isBefore(start) && t.date.isBefore(endExclusive)).toList();

  static double repaid(LoanModel loan, Iterable<LoanRepayment> reps) =>
      _r(reps.where((r) => r.loanId == loan.id).fold(0.0, (s, r) => s + r.amount));

  static double outstanding(LoanModel loan, Iterable<LoanRepayment> reps) =>
      math.max(0.0, _r(loan.amount - repaid(loan, reps)));

  /// Net receivables = outstanding loans given.
  static double receivables(Iterable<LoanModel> loans, Iterable<LoanRepayment> reps) =>
      _r(loans.where((l) => l.isGiven).fold(0.0, (s, l) => s + outstanding(l, reps)));

  /// Net liabilities = outstanding loans taken.
  static double liabilities(Iterable<LoanModel> loans, Iterable<LoanRepayment> reps) =>
      _r(loans.where((l) => !l.isGiven).fold(0.0, (s, l) => s + outstanding(l, reps)));

  /// Net financial position = balance + receivables - liabilities.
  static double netPosition(double balance, double receivables, double liabilities) =>
      _r(balance + receivables - liabilities);

  static List<Bucket> buckets(Iterable<TransactionModel> txs, List<DateSlot> slots) {
    return slots.map((s) {
      final inSlot = inRange(txs, s.start, s.end);
      return Bucket(s.label, sumType(inSlot, TxType.income), sumType(inSlot, TxType.expense));
    }).toList();
  }

  /// Totals keyed by categoryId (or the category name when the id is missing).
  static Map<String, double> totalsByCategory(Iterable<TransactionModel> txs, TxType type) {
    final out = <String, double>{};
    for (final t in txs.where((t) => t.type == type)) {
      final key = t.categoryId.isNotEmpty ? t.categoryId : (t.category.isNotEmpty ? t.category : 'Uncategorized');
      out[key] = (out[key] ?? 0) + t.amount;
    }
    return out;
  }
}
