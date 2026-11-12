import '../../core/utils/formatters.dart';

class LoanModel {
  const LoanModel({
    required this.id,
    required this.type,
    required this.person,
    required this.amount,
    required this.date,
    this.dueDate,
    this.note = '',
    this.accountId = '',
    this.status = 'open',
    this.transactionId = '',
  });

  final String id;
  final String type; // 'given' | 'taken'
  final String person;
  final double amount;
  final DateTime date;
  final DateTime? dueDate;
  final String note;
  final String accountId;
  final String status;
  final String transactionId;

  bool get isGiven => type == 'given';

  factory LoanModel.fromJson(Map<String, dynamic> j) => LoanModel(
        id: Json.str(j['id']),
        type: Json.str(j['type']),
        person: Json.str(j['person']),
        amount: Json.dbl(j['amount']),
        date: Json.date(j['date']) ?? DateTime.now(),
        dueDate: Json.date(j['dueDate']),
        note: Json.str(j['note']),
        accountId: Json.str(j['accountId']),
        status: Json.str(j['status']),
        transactionId: Json.str(j['transactionId']),
      );
}

class LoanRepayment {
  const LoanRepayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    this.note = '',
    this.accountId = '',
    this.transactionId = '',
  });

  final String id;
  final String loanId;
  final double amount;
  final DateTime date;
  final String note;
  final String accountId;
  final String transactionId;

  factory LoanRepayment.fromJson(Map<String, dynamic> j) => LoanRepayment(
        id: Json.str(j['id']),
        loanId: Json.str(j['loanId']),
        amount: Json.dbl(j['amount']),
        date: Json.date(j['date']) ?? DateTime.now(),
        note: Json.str(j['note']),
        accountId: Json.str(j['accountId']),
        transactionId: Json.str(j['transactionId']),
      );
}
