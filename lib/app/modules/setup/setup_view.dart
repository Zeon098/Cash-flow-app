import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'setup_controller.dart';

class SetupView extends GetView<SetupController> {
  const SetupView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            if (Navigator.of(context).canPop())
              Align(alignment: Alignment.centerLeft, child: IconButton(onPressed: Get.back, icon: const Icon(Icons.arrow_back_rounded))),
            const SizedBox(height: 12),
            FadeSlide(
              child: Container(
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(colors: [AppColors.emeraldDeep, AppColors.emerald], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: .3), blurRadius: 26, offset: const Offset(0, 12))],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 36),
                    SizedBox(height: 16),
                    Text('CashFlow', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
                    SizedBox(height: 6),
                    Text('Your income, expenses and loans, stored privately in your own Google Sheet.',
                        style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            const Text('Connect Google Sheets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Deploy the Apps Script backend, then paste its Web App URL below.', style: TextStyle(color: AppColors.slate)),
            const SizedBox(height: 18),
            TextField(
              controller: c.urlCtrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Web App URL', hintText: 'https://script.google.com/macros/s/.../exec', prefixIcon: Icon(Icons.link_rounded)),
            ),
            const SizedBox(height: 14),
            Obx(() => TextField(
                  controller: c.keyCtrl,
                  obscureText: c.obscure.value,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'API key (optional but recommended)',
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(c.obscure.value ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                      onPressed: () => c.obscure.toggle(),
                    ),
                  ),
                )),
            Obx(() => c.error.value == null
                ? const SizedBox(height: 18)
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AppColors.coral.withValues(alpha: .12), borderRadius: BorderRadius.circular(14)),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.coral, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(c.error.value!, style: const TextStyle(color: AppColors.coral, height: 1.35, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                  )),
            Obx(() => PrimaryButton(label: 'Test & connect', icon: Icons.bolt_rounded, loading: c.busy.value, onPressed: c.connect)),
          ],
        ),
      ),
    );
  }
}
