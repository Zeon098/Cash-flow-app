import 'package:get/get.dart';

import '../../controllers/app_controller.dart';
import '../../controllers/finance_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../routes/app_routes.dart';
import '../../widgets/picker_sheets.dart';

class SettingsController extends GetxController {
  final fin = Get.find<FinanceController>();
  final app = Get.find<AppController>();
  final testing = false.obs;

  String get host => Uri.tryParse(app.apiUrl.value)?.host ?? '';

  Future<void> pickCurrency() async {
    final v = await pickFromList<String>(
      title: 'Currency',
      selected: fin.currency,
      items: [
        for (final e in Currencies.symbols.entries) PickerItem(value: e.key, label: e.key, subtitle: 'Symbol: ${e.value}'),
      ],
    );
    if (v != null && v != fin.currency) {
      if (await fin.saveSettings({'currency': v})) Toast.success('Currency set to $v');
    }
  }

  Future<void> pickDefaultAccount() async {
    final v = await pickFromList<String>(
      title: 'Default account',
      selected: fin.defaultAccountId,
      items: [for (final a in fin.accounts) PickerItem(value: a.id, label: a.name, icon: AppIcons.of(a.icon), color: hexColor(a.color))],
    );
    if (v != null && await fin.saveSettings({'defaultAccountId': v})) Toast.success('Default account updated');
  }

  Future<void> testConnection() async {
    testing.value = true;
    await fin.load();
    testing.value = false;
    final err = fin.loadError.value;
    err == null ? Toast.success('Connected to Google Sheets') : Toast.error(err);
  }

  Future<void> disconnect() async {
    final ok = await confirmDialog(
      title: 'Disconnect?',
      message: 'The saved Web App URL and API key are removed from this device. Your Google Sheet is not touched.',
      confirmText: 'Disconnect',
    );
    if (!ok) return;
    await app.clearConnection();
    fin.reset();
    Get.offAllNamed(Routes.setup);
  }
}
