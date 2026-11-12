import 'package:get/get.dart';

import '../bindings/bindings.dart';
import '../modules/home/home_view.dart';
import '../modules/loans/loan_detail_view.dart';
import '../modules/settings/accounts_view.dart';
import '../modules/settings/categories_view.dart';
import '../modules/setup/setup_view.dart';
import '../modules/transaction/add_transaction_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage<dynamic>>[
    GetPage(name: Routes.setup, page: () => const SetupView(), binding: SetupBinding()),
    GetPage(name: Routes.home, page: () => const HomeView(), binding: HomeBinding()),
    GetPage(
      name: Routes.addTransaction,
      page: () => const AddTransactionView(),
      binding: AddTransactionBinding(),
      transition: Transition.downToUp,
    ),
    GetPage(name: Routes.loanDetail, page: () => const LoanDetailView()),
    GetPage(name: Routes.accounts, page: () => const AccountsView()),
    GetPage(name: Routes.categories, page: () => const CategoriesView()),
  ];
}
