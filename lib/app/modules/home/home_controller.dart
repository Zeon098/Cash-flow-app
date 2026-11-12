import 'package:get/get.dart';

import '../../controllers/finance_controller.dart';
import '../../data/models/transaction_type.dart';
import '../../routes/app_routes.dart';
import '../loans/loans_controller.dart';
import '../transaction/add_transaction_controller.dart';

class HomeController extends GetxController {
  final fin = Get.find<FinanceController>();
  final index = 0.obs;

  @override
  void onReady() {
    super.onReady();
    fin.load();
  }

  void setIndex(int i) => index.value = i;

  void openAdd() {
    AddTxArgs? args;
    if (index.value == 2) {
      final given = Get.find<LoansController>().tab.value == 0;
      args = AddTxArgs(type: given ? TxType.loanGiven : TxType.loanTaken);
    }
    Get.toNamed(Routes.addTransaction, arguments: args);
  }
}
