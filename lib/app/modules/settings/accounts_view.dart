import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/finance_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/account_model.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/picker_sheets.dart';

class AccountsView extends GetView<FinanceController> {
  const AccountsView({super.key});

  @override
  Widget build(BuildContext context) {
    final fin = controller;
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAccountEditor(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New account'),
      ),
      body: Obx(() => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              for (final a in fin.accounts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    onTap: () => showAccountEditor(existing: a),
                    child: Row(children: [
                      IconBadge(icon: AppIcons.of(a.icon), color: hexColor(a.color)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(a.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          Text(AccountTypes.labels[a.type] ?? 'Account', style: const TextStyle(color: AppColors.slate, fontSize: 12.5)),
                        ]),
                      ),
                      Builder(builder: (_) {
                        final bal = fin.accountBalance(a.id);
                        return Text(Fmt.money(bal), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.signed(bal)));
                      }),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.slate),
                        onPressed: () async {
                          final ok = await confirmDialog(title: 'Delete ${a.name}?', message: 'Accounts that have transactions cannot be deleted.');
                          if (ok && await fin.deleteAccount(a.id)) Toast.success('Account deleted');
                        },
                      ),
                    ]),
                  ),
                ),
            ],
          )),
    );
  }
}

Future<void> showAccountEditor({AccountModel? existing}) => showAppSheet(_AccountEditor(existing: existing));

class _AccountEditor extends StatefulWidget {
  const _AccountEditor({this.existing});
  final AccountModel? existing;

  @override
  State<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<_AccountEditor> {
  final fin = Get.find<FinanceController>();
  late final TextEditingController name = TextEditingController(text: widget.existing?.name ?? '');
  final opening = TextEditingController();
  late String type = widget.existing?.type ?? 'cash';
  late String color = widget.existing?.color ?? AppPalette.hex.first;
  final String requestId = newRequestId();

  @override
  void dispose() {
    name.dispose();
    opening.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      Toast.error('Enter an account name');
      return;
    }
    final payload = <String, dynamic>{
      if (widget.existing != null) 'id': widget.existing!.id,
      'name': name.text.trim(),
      'type': type,
      'icon': AccountTypes.icons[type] ?? 'account_balance_wallet',
      'color': color,
      if (widget.existing == null) 'openingBalance': double.tryParse(opening.text.trim()) ?? 0,
    };
    if (await fin.saveAccount(payload, requestId)) {
      Get.back();
      Toast.success('Account saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 0, 22, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Text(widget.existing == null ? 'New account' : 'Edit account', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Account name')),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in AccountTypes.labels.entries)
              Pill(label: e.value, icon: AppIcons.of(AccountTypes.icons[e.key]), selected: type == e.key, onTap: () => setState(() => type = e.key)),
          ]),
          if (widget.existing == null) ...[
            const SizedBox(height: 14),
            TextField(
              controller: opening,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'Opening balance', prefixText: '${Fmt.symbol} '),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final h in AppPalette.hex)
              GestureDetector(
                onTap: () => setState(() => color = h),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: hexColor(h), shape: BoxShape.circle, border: Border.all(color: color == h ? Colors.white : Colors.transparent, width: 3), boxShadow: color == h ? [BoxShadow(color: hexColor(h).withValues(alpha: .5), blurRadius: 8)] : null),
                  child: color == h ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                ),
              ),
          ]),
          const SizedBox(height: 22),
          Obx(() => PrimaryButton(label: 'Save account', loading: fin.isSaving.value, onPressed: save)),
        ]),
      ),
    );
  }
}
