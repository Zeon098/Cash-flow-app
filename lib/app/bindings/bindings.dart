import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controllers/app_controller.dart';
import '../controllers/finance_controller.dart';
import '../data/providers/sheets_api_provider.dart';
import '../data/repositories/finance_repository.dart';
import '../modules/cashflow/cashflow_controller.dart';
import '../modules/dashboard/dashboard_controller.dart';
import '../modules/home/home_controller.dart';
import '../modules/loans/loans_controller.dart';
import '../modules/reports/reports_controller.dart';
import '../modules/settings/settings_controller.dart';
import '../modules/setup/setup_controller.dart';
import '../modules/transaction/add_transaction_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SheetsApiProvider(), permanent: true);
    Get.put(AppController(Get.find<SharedPreferences>(), Get.find<SheetsApiProvider>()), permanent: true);
    Get.put(FinanceRepository(Get.find<SheetsApiProvider>()), permanent: true);
    Get.put(FinanceController(Get.find<FinanceRepository>()), permanent: true);
  }
}

class SetupBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => SetupController());
}

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => DashboardController());
    Get.lazyPut(() => CashFlowController());
    Get.lazyPut(() => LoansController());
    Get.lazyPut(() => ReportsController());
    Get.lazyPut(() => SettingsController());
  }
}

class AddTransactionBinding extends Bindings {
  @override
  void dependencies() => Get.lazyPut(() => AddTransactionController());
}
