import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/theme/app_theme.dart';
import 'common_widgets.dart';

Future<T?> showAppSheet<T>(Widget child) {
  final theme = Theme.of(Get.context!);
  return Get.bottomSheet<T>(
    SafeArea(top: false, child: child),
    backgroundColor: theme.colorScheme.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
  );
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 42,
          height: 4,
          margin: const EdgeInsets.only(top: 10, bottom: 14),
          decoration: BoxDecoration(color: AppColors.slate.withValues(alpha: .35), borderRadius: BorderRadius.circular(4)),
        ),
      );
}

class PickerItem<T> {
  const PickerItem({required this.value, required this.label, this.subtitle, this.icon, this.color});
  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
}

Future<T?> pickFromList<T>({required String title, required List<PickerItem<T>> items, T? selected}) {
  return showAppSheet<T>(_PickerSheet<T>(title: title, items: items, selected: selected));
}

class _PickerSheet<T> extends StatelessWidget {
  const _PickerSheet({required this.title, required this.items, this.selected});
  final String title;
  final List<PickerItem<T>> items;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .72),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final isSel = item.value == selected;
                return ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  leading: item.icon == null ? null : IconBadge(icon: item.icon!, color: item.color ?? AppColors.emerald, size: 40),
                  title: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: item.subtitle == null ? null : Text(item.subtitle!),
                  trailing: isSel ? const Icon(Icons.check_circle_rounded, color: AppColors.emerald) : null,
                  onTap: () => Get.back(result: item.value),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable form field that opens a picker.
class SelectorField extends StatelessWidget {
  const SelectorField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.placeholder = 'Select',
    this.onClear,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final IconData? icon;
  final String placeholder;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final has = value != null && value!.isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: dark ? const Color(0x0DFFFFFF) : const Color(0xFFF1F3F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (icon != null) ...[Icon(icon, size: 22, color: AppColors.slate), const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.slate, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    has ? value! : placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: has ? null : AppColors.slate),
                  ),
                ],
              ),
            ),
            if (onClear != null && has)
              GestureDetector(onTap: onClear, child: const Icon(Icons.close_rounded, size: 20, color: AppColors.slate))
            else
              const Icon(Icons.expand_more_rounded, color: AppColors.slate),
          ],
        ),
      ),
    );
  }
}

Future<bool> confirmDialog({
  required String title,
  required String message,
  String confirmText = 'Delete',
  bool danger = true,
}) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Get.back(result: false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: danger ? AppColors.coral : AppColors.emerald, minimumSize: const Size(96, 44)),
          onPressed: () => Get.back(result: true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
  return result ?? false;
}
