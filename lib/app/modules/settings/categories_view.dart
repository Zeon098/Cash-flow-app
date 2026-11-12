import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/finance_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/category_model.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/picker_sheets.dart';

class CategoriesView extends GetView<FinanceController> {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final fin = controller;
    return DefaultTabController(
      length: 2,
      child: Builder(builder: (context) {
        final tabs = DefaultTabController.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Categories'),
            bottom: const TabBar(
              indicatorColor: AppColors.emerald,
              labelColor: AppColors.emerald,
              unselectedLabelColor: AppColors.slate,
              tabs: [Tab(text: 'Expense'), Tab(text: 'Income')],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showCategoryEditor(type: tabs.index == 0 ? 'expense' : 'income'),
            icon: const Icon(Icons.add_rounded),
            label: const Text('New category'),
          ),
          body: TabBarView(children: [
            _CategoryList(type: 'expense', fin: fin),
            _CategoryList(type: 'income', fin: fin),
          ]),
        );
      }),
    );
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({required this.type, required this.fin});
  final String type;
  final FinanceController fin;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = fin.categoriesOf(type);
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        children: [
          for (final cat in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onTap: () => showCategoryEditor(type: type, existing: cat),
                child: Row(children: [
                  IconBadge(icon: AppIcons.of(cat.icon), color: hexColor(cat.color), size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5))),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.slate),
                    onPressed: () async {
                      final ok = await confirmDialog(title: 'Delete ${cat.name}?', message: 'Existing transactions keep their category label.');
                      if (ok && await fin.deleteCategory(cat.id)) Toast.success('Category deleted');
                    },
                  ),
                ]),
              ),
            ),
        ],
      );
    });
  }
}

/// Create or edit a custom category. Also used from the transaction form.
Future<void> showCategoryEditor({required String type, CategoryModel? existing}) =>
    showAppSheet(_CategoryEditor(type: type, existing: existing));

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.type, this.existing});
  final String type;
  final CategoryModel? existing;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  final fin = Get.find<FinanceController>();
  late final TextEditingController name = TextEditingController(text: widget.existing?.name ?? '');
  late String icon = widget.existing?.icon ?? 'category';
  late String color = widget.existing?.color ?? AppPalette.hex.first;

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      Toast.error('Enter a category name');
      return;
    }
    final ok = await fin.saveCategory({
      if (widget.existing != null) 'id': widget.existing!.id,
      'name': name.text.trim(),
      'type': widget.type,
      'icon': icon,
      'color': color,
    });
    if (ok) {
      Get.back();
      Toast.success('Category saved');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = hexColor(color);
    return Padding(
      padding: EdgeInsets.fromLTRB(22, 0, 22, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SheetHandle(),
          Text('${widget.existing == null ? 'New' : 'Edit'} ${widget.type} category', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Category name')),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final k in AppIcons.keys)
              GestureDetector(
                onTap: () => setState(() => icon = k),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: icon == k ? c : c.withValues(alpha: .1), borderRadius: BorderRadius.circular(14)),
                  child: Icon(AppIcons.of(k), color: icon == k ? Colors.white : c, size: 22),
                ),
              ),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [
            for (final h in AppPalette.hex)
              GestureDetector(
                onTap: () => setState(() => color = h),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: hexColor(h), shape: BoxShape.circle, border: Border.all(color: color == h ? Colors.white : Colors.transparent, width: 3)),
                  child: color == h ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                ),
              ),
          ]),
          const SizedBox(height: 22),
          Obx(() => PrimaryButton(label: 'Save category', loading: fin.isSaving.value, onPressed: save)),
        ]),
      ),
    );
  }
}
