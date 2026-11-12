import 'package:get/get.dart';

import '../core/constants/app_constants.dart';
import '../core/services/finance_calculator.dart';
import '../core/utils/formatters.dart';
import '../core/utils/helpers.dart';
import '../data/models/account_model.dart';
import '../data/models/app_data.dart';
import '../data/models/category_model.dart';
import '../data/models/loan_model.dart';
import '../data/models/transaction_model.dart';
import '../data/models/transaction_type.dart';
import '../data/providers/sheets_api_provider.dart';
import '../data/repositories/finance_repository.dart';

/// Single source of truth for all financial data held in memory.
/// Every mutation goes to Google Sheets first; the returned snapshot replaces
/// the local state.
class FinanceController extends GetxController {
  FinanceController(this._repo);
  final FinanceRepository _repo;

  final data = const AppData().obs;
  final isLoading = false.obs;
  final isSaving = false.obs;
  final hasLoaded = false.obs;
  final loadError = RxnString();

  // ───────────────────────── state accessors ─────────────────────────
  List<TransactionModel> get transactions => data.value.transactions;
  List<LoanModel> get loans => data.value.loans;
  List<LoanRepayment> get repayments => data.value.repayments;
  List<CategoryModel> get categories => data.value.categories;
  List<AccountModel> get accounts => data.value.accounts;
  String get currency =>
      data.value.settings['currency'] ?? AppConstants.defaultCurrency;
  String? get defaultAccountId => data.value.settings['defaultAccountId'];

  AccountModel? accountById(String id) =>
      findFirst(accounts, (a) => a.id == id);
  CategoryModel? categoryById(String id) =>
      id.isEmpty ? null : findFirst(categories, (c) => c.id == id);
  LoanModel? loanById(String id) => findFirst(loans, (l) => l.id == id);
  String accountName(String id) => accountById(id)?.name ?? '—';
  List<CategoryModel> categoriesOf(String type) =>
      categories.where((c) => c.type == type).toList();
  List<LoanRepayment> repaymentsOf(String loanId) {
    final list = repayments.where((r) => r.loanId == loanId).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<String> get knownPeople {
    final set = <String>{
      ...loans.map((l) => l.person),
      ...transactions.map((t) => t.person),
    };
    set.removeWhere((p) => p.trim().isEmpty);
    return set.toList()..sort();
  }

  // ───────────────────────── derived figures ─────────────────────────
  double get availableBalance => FinanceCalculator.balance(transactions);
  double get receivables => FinanceCalculator.receivables(loans, repayments);
  double get liabilities => FinanceCalculator.liabilities(loans, repayments);
  double get netPosition =>
      FinanceCalculator.netPosition(availableBalance, receivables, liabilities);
  double accountBalance(String id) =>
      FinanceCalculator.accountBalance(transactions, id);
  double outstanding(LoanModel l) =>
      FinanceCalculator.outstanding(l, repayments);
  double repaid(LoanModel l) => FinanceCalculator.repaid(l, repayments);

  List<CategoryTotal> breakdown(Iterable<TransactionModel> txs, TxType type) {
    final totals = FinanceCalculator.totalsByCategory(txs, type);
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var i = 0;
    return entries.map((e) {
      final cat =
          categoryById(e.key) ?? findFirst(categories, (c) => c.name == e.key);
      final color = cat != null
          ? hexColor(cat.color)
          : AppPalette.fallback[i % AppPalette.fallback.length];
      i++;
      return CategoryTotal(
        cat?.name ?? e.key,
        e.value,
        color,
        AppIcons.of(cat?.icon),
      );
    }).toList();
  }

  // ───────────────────────── loading ─────────────────────────
  void reset() {
    data.value = const AppData();
    hasLoaded.value = false;
    loadError.value = null;
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    loadError.value = null;
    try {
      _apply(await _repo.fetchAll());
      hasLoaded.value = true;
    } on ApiException catch (e) {
      loadError.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  void _apply(AppData d) {
    data.value = d;
    Fmt.symbol = Currencies.symbolOf(currency);
  }

  Future<bool> _write(Future<AppData> Function() op) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    try {
      _apply(await op());
      return true;
    } on ApiException catch (e) {
      Toast.error(e.message);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  // ───────────────────────── mutations ─────────────────────────
  Future<bool> addTransaction(Map<String, dynamic> payload, String requestId) =>
      _write(() => _repo.addTransaction(payload, requestId));
  Future<bool> updateTransaction(Map<String, dynamic> payload) =>
      _write(() => _repo.updateTransaction(payload));
  Future<bool> deleteTransaction(String id) =>
      _write(() => _repo.deleteTransaction(id));
  Future<bool> deleteLoan(String id) => _write(() => _repo.deleteLoan(id));
  Future<bool> deleteRepayment(String id) =>
      _write(() => _repo.deleteRepayment(id));
  Future<bool> saveCategory(Map<String, dynamic> payload) =>
      _write(() => _repo.saveCategory(payload));
  Future<bool> deleteCategory(String id) =>
      _write(() => _repo.deleteCategory(id));
  Future<bool> saveAccount(Map<String, dynamic> payload, String requestId) =>
      _write(() => _repo.saveAccount(payload, requestId));
  Future<bool> deleteAccount(String id) =>
      _write(() => _repo.deleteAccount(id));
  Future<bool> saveSettings(Map<String, String> values) =>
      _write(() => _repo.saveSettings(values));
}
