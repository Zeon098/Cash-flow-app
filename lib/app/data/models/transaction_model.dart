import '../../core/utils/formatters.dart';
import 'transaction_type.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.date,
    required this.type,
    required this.amount,
    this.direction = '',
    this.accountId = '',
    this.toAccountId = '',
    this.categoryId = '',
    this.category = '',
    this.title = '',
    this.note = '',
    this.person = '',
    this.loanId = '',
    this.repaymentId = '',
    this.createdAt = '',
  });

  final String id;
  final DateTime date;
  final TxType type;
  final double amount;
  final String direction; // 'in' | 'out' | ''
  final String accountId;
  final String toAccountId;
  final String categoryId;
  final String category;
  final String title;
  final String note;
  final String person;
  final String loanId;
  final String repaymentId;
  final String createdAt;

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
        id: Json.str(j['id']),
        date: Json.date(j['date']) ?? DateTime.now(),
        type: TxType.fromKey(Json.str(j['type'])),
        amount: Json.dbl(j['amount']),
        direction: Json.str(j['direction']),
        accountId: Json.str(j['accountId']),
        toAccountId: Json.str(j['toAccountId']),
        categoryId: Json.str(j['categoryId']),
        category: Json.str(j['category']),
        title: Json.str(j['title']),
        note: Json.str(j['note']),
        person: Json.str(j['person']),
        loanId: Json.str(j['loanId']),
        repaymentId: Json.str(j['repaymentId']),
        createdAt: Json.str(j['createdAt']),
      );

  /// Effect on the total available balance. Transfers are always 0.
  double get signedAmount {
    if (type == TxType.transfer) return 0;
    final sign = type.fixedSign ?? (direction == 'out' ? -1 : 1);
    return amount * sign;
  }

  /// Effect on one specific account (transfers move money between accounts).
  double effectOn(String account) {
    if (type == TxType.transfer) {
      if (accountId == account) return -amount;
      if (toAccountId == account) return amount;
      return 0;
    }
    return accountId == account ? signedAmount : 0;
  }
}
