import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../cashflow/cashflow_view.dart';
import '../dashboard/dashboard_view.dart';
import '../loans/loans_view.dart';
import '../reports/reports_view.dart';
import '../settings/settings_view.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final fin = controller.fin;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (!fin.hasLoaded.value) {
            final err = fin.loadError.value;
            if (err == null) return const Center(child: CircularProgressIndicator(color: AppColors.emerald));
            return _ErrorState(message: err, onRetry: fin.load);
          }
          return IndexedStack(
            index: controller.index.value,
            children: const [DashboardView(), CashFlowView(), LoansView(), ReportsView(), SettingsView()],
          );
        }),
      ),
      floatingActionButton: Obx(() => fin.hasLoaded.value
          ? FloatingActionButton.extended(
              onPressed: controller.openAdd,
              icon: const Icon(Icons.add_rounded, size: 26),
              label: Text(controller.index.value == 2 ? 'New loan' : 'Add transaction'),
            )
          : const SizedBox.shrink()),
      bottomNavigationBar: Obx(() => NavigationBar(
            selectedIndex: controller.index.value,
            onDestinationSelected: controller.setIndex,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard_rounded), label: 'Dashboard'),
              NavigationDestination(icon: Icon(Icons.swap_vert_rounded), selectedIcon: Icon(Icons.swap_vert_rounded), label: 'Cash Flow'),
              NavigationDestination(icon: Icon(Icons.handshake_outlined), selectedIcon: Icon(Icons.handshake_rounded), label: 'Loans'),
              NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights_rounded), label: 'Reports'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings_rounded), label: 'Settings'),
            ],
          )),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.slate),
            const SizedBox(height: 16),
            const Text("Couldn't load your data", style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.slate, height: 1.4)),
            const SizedBox(height: 22),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Get.toNamed(Routes.setup), child: const Text('Change connection')),
          ],
        ),
      ),
    );
  }
}
