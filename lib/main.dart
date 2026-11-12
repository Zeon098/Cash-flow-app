import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/bindings/bindings.dart';
import 'app/controllers/app_controller.dart';
import 'app/core/constants/app_constants.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // SharedPreferences only stores app configuration (API URL, API key, theme).
  // ALL financial data lives in Google Sheets.
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs, permanent: true);
  final configured = (prefs.getString(AppConstants.prefApiUrl) ?? '').isNotEmpty;
  runApp(CashFlowApp(
    initialRoute: configured ? Routes.home : Routes.setup,
    themeMode: AppController.themeFromName(prefs.getString(AppConstants.prefTheme)),
  ));
}

class CashFlowApp extends StatelessWidget {
  const CashFlowApp({super.key, required this.initialRoute, required this.themeMode});

  final String initialRoute;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      initialBinding: InitialBinding(),
      initialRoute: initialRoute,
      getPages: AppPages.pages,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 280),
    );
  }
}
