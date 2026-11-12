import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common_widgets.dart';
import 'settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final fin = c.fin;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        const Text('Settings', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.8)),
        const SizedBox(height: 16),
        const SectionHeader('Google Sheets'),
        AppCard(
          child: Column(children: [
            Row(children: [
              const IconBadge(icon: Icons.table_chart_rounded, color: AppColors.emerald),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Connected', style: TextStyle(fontWeight: FontWeight.w800)),
                  Obx(() => Text(c.host.isEmpty ? 'Not connected' : c.host, style: const TextStyle(color: AppColors.slate, fontSize: 12.5))),
                ]),
              ),
              Obx(() => c.testing.value
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.emerald))
                  : TextButton(onPressed: c.testConnection, child: const Text('Test'))),
            ]),
            const Divider(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Get.toNamed(Routes.setup), child: const Text('Change'))),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.coral),
                  onPressed: c.disconnect,
                  child: const Text('Disconnect'),
                ),
              ),
            ]),
          ]),
        ),
        const SectionHeader('Preferences'),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(children: [
            Obx(() => _Tile(icon: Icons.currency_exchange_rounded, title: 'Currency', value: '${fin.currency} (${Currencies.symbolOf(fin.currency)})', onTap: c.pickCurrency)),
            const Divider(indent: 16, endIndent: 16),
            Obx(() => _Tile(icon: Icons.star_rounded, title: 'Default account', value: fin.accountName(fin.defaultAccountId ?? ''), onTap: c.pickDefaultAccount)),
            const Divider(indent: 16, endIndent: 16),
            Obx(() => _Tile(icon: Icons.account_balance_wallet_rounded, title: 'Accounts', value: '${fin.accounts.length}', onTap: () => Get.toNamed(Routes.accounts))),
            const Divider(indent: 16, endIndent: 16),
            Obx(() => _Tile(icon: Icons.category_rounded, title: 'Categories', value: '${fin.categories.length}', onTap: () => Get.toNamed(Routes.categories))),
          ]),
        ),
        const SectionHeader('Appearance'),
        AppCard(
          child: Obx(() => SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(selectedBackgroundColor: AppColors.emerald, selectedForegroundColor: Colors.white),
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_rounded)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_rounded)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_rounded)),
                  ],
                  selected: {c.app.themeMode.value},
                  onSelectionChanged: (s) => c.app.setTheme(s.first),
                ),
              )),
        ),
        const SizedBox(height: 22),
        const Center(child: Text('CashFlow 1.0 · Data stored in your Google Sheet', style: TextStyle(color: AppColors.slate, fontSize: 12))),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.title, required this.value, required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: IconBadge(icon: icon, color: AppColors.emerald, size: 38),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        ConstrainedBox(constraints: const BoxConstraints(maxWidth: 130), child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.slate, fontWeight: FontWeight.w600))),
        const Icon(Icons.chevron_right_rounded, color: AppColors.slate),
      ]),
    );
  }
}

