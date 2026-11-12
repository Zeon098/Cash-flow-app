import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/finance_controller.dart';
import '../../data/providers/sheets_api_provider.dart';
import '../../data/repositories/finance_repository.dart';
import '../../routes/app_routes.dart';

class SetupController extends GetxController {
  final app = Get.find<AppController>();
  final repo = Get.find<FinanceRepository>();
  final fin = Get.find<FinanceController>();

  late final TextEditingController urlCtrl = TextEditingController(text: app.apiUrl.value);
  late final TextEditingController keyCtrl = TextEditingController(text: app.apiKey.value);
  final busy = false.obs;
  final obscure = true.obs;
  final error = RxnString();

  Future<void> connect() async {
    final url = urlCtrl.text.trim();
    final key = keyCtrl.text.trim();
    if (!url.startsWith('https://script.google.com/') || !url.contains('/exec')) {
      error.value = 'Paste the Web App URL from your Apps Script deployment. It starts with https://script.google.com/ and ends with /exec';
      return;
    }
    busy.value = true;
    error.value = null;
    app.applyConnection(url, key);
    try {
      await repo.ping();
      await app.saveConnection(url, key);
      fin.reset();
      Get.offAllNamed(Routes.home);
    } on ApiException catch (e) {
      error.value = e.message;
      app.applySaved();
    } finally {
      if (!isClosed) busy.value = false;
    }
  }

  @override
  void onClose() {
    urlCtrl.dispose();
    keyCtrl.dispose();
    super.onClose();
  }
}
