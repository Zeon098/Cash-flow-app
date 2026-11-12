import '../models/app_data.dart';
import '../providers/sheets_api_provider.dart';

/// Every write returns the complete, fresh snapshot from Google Sheets so the
/// app never drifts from the source of truth.
class FinanceRepository {
  FinanceRepository(this._api);
  final SheetsApiProvider _api;

  Future<void> ping() => _api.get('ping');

  Future<AppData> fetchAll() async => AppData.fromJson(await _api.get('getAll'));

  Future<AppData> _write(String action, Map<String, dynamic> payload, {String? requestId}) async =>
      AppData.fromJson(await _api.post(action, payload, requestId: requestId));

  Future<AppData> addTransaction(Map<String, dynamic> p, String requestId) =>
      _write('addTransaction', p, requestId: requestId);
  Future<AppData> updateTransaction(Map<String, dynamic> p) => _write('updateTransaction', p);
  Future<AppData> deleteTransaction(String id) => _write('deleteTransaction', {'id': id});
  Future<AppData> deleteLoan(String id) => _write('deleteLoan', {'id': id});
  Future<AppData> deleteRepayment(String id) => _write('deleteRepayment', {'id': id});

  Future<AppData> saveCategory(Map<String, dynamic> p) => _write('saveCategory', p);
  Future<AppData> deleteCategory(String id) => _write('deleteCategory', {'id': id});

  Future<AppData> saveAccount(Map<String, dynamic> p, String requestId) =>
      _write('saveAccount', p, requestId: requestId);
  Future<AppData> deleteAccount(String id) => _write('deleteAccount', {'id': id});

  Future<AppData> saveSettings(Map<String, String> values) => _write('saveSettings', {'values': values});
}
