import 'account_model.dart';
import 'category_model.dart';
import 'loan_model.dart';
import 'transaction_model.dart';

/// Snapshot of everything stored in the Google Sheet.
class AppData {
  const AppData({
    this.transactions = const [],
    this.loans = const [],
    this.repayments = const [],
    this.categories = const [],
    this.accounts = const [],
    this.settings = const {},
  });

  final List<TransactionModel> transactions;
  final List<LoanModel> loans;
  final List<LoanRepayment> repayments;
  final List<CategoryModel> categories;
  final List<AccountModel> accounts;
  final Map<String, String> settings;

  factory AppData.fromJson(Map<String, dynamic> j) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) build) {
      final raw = j[key];
      if (raw is! List) return <T>[];
      return raw.whereType<Map>().map((e) => build(Map<String, dynamic>.from(e))).toList();
    }

    final tx = parse<TransactionModel>('transactions', TransactionModel.fromJson)
      ..sort((a, b) {
        final c = b.date.compareTo(a.date);
        return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
      });

    final settings = <String, String>{};
    final rawSettings = j['settings'];
    if (rawSettings is Map) {
      rawSettings.forEach((k, v) => settings[k.toString()] = v?.toString() ?? '');
    }

    return AppData(
      transactions: tx,
      loans: parse<LoanModel>('loans', LoanModel.fromJson),
      repayments: parse<LoanRepayment>('repayments', LoanRepayment.fromJson),
      categories: parse<CategoryModel>('categories', CategoryModel.fromJson),
      accounts: parse<AccountModel>('accounts', AccountModel.fromJson),
      settings: settings,
    );
  }
}
