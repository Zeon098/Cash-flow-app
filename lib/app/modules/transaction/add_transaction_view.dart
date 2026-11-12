import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/helpers.dart';
import '../../data/models/transaction_type.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/picker_sheets.dart';
import '../settings/categories_view.dart';
import 'add_transaction_controller.dart';

class AddTransactionView extends GetView<AddTransactionController> {
  const AddTransactionView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.isEdit ? 'Edit transaction' : 'New transaction'),
        actions: [
          if (c.isEdit) IconButton(onPressed: c.delete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Obx(() => PrimaryButton(
                label: c.isEdit ? 'Save changes' : 'Save transaction',
                icon: Icons.check_rounded,
                loading: c.fin.isSaving.value,
                onPressed: c.save,
              )),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
          children: [
            _amountCard(c),
            const SizedBox(height: 18),
            if (!c.isEdit) ...[
              _groupSelector(c),
              _typeSelector(c),
            ],
            Obx(() {
              final t = c.type.value;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(anim), child: child),
                ),
                child: Column(
                  key: ValueKey(t),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _fields(context, c, t),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── amount hero ─────────────────────────
  Widget _amountCard(AddTransactionController c) {
    return Obx(() {
      final sign = c.effectiveSign;
      final colors = sign > 0
          ? [AppColors.emeraldDeep, AppColors.emerald]
          : sign < 0
              ? [AppColors.coralDeep, AppColors.coral]
              : [const Color(0xFF334155), const Color(0xFF64748B)];
      final t = c.type.value;
      final loan = t.isRepayment ? c.fin.loanById(c.loanId.value) : null;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: colors.last.withValues(alpha: .3), blurRadius: 24, offset: const Offset(0, 12))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(t.icon, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(t.label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)),
            ]),
            TextField(
              controller: c.amountCtrl,
              autofocus: !c.isEdit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              cursorColor: Colors.white,
              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1),
              decoration: InputDecoration(
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                hintText: '0',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 40, fontWeight: FontWeight.w800),
                prefixText: '${Fmt.symbol} ',
                prefixStyle: const TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.w700),
              ),
            ),
            if (loan != null)
              Text('Outstanding: ${Fmt.money(c.fin.outstanding(loan))}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    });
  }

  // ───────────────────────── selectors ─────────────────────────
  Widget _groupSelector(AddTransactionController c) {
    return Obx(() => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final g in TxGroup.values) ...[
              Pill(label: g.label, icon: g.icon, selected: c.type.value.group == g, onTap: () => c.setGroup(g)),
              const SizedBox(width: 8),
            ],
          ]),
        ));
  }

  Widget _typeSelector(AddTransactionController c) {
    return Obx(() {
      final types = TxType.ofGroup(c.type.value.group);
      if (types.length < 2) return const SizedBox(height: 4);
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final t in types) Pill(label: t.label, selected: c.type.value == t, color: t.color, onTap: () => c.setType(t)),
        ]),
      );
    });
  }

  // ───────────────────────── dynamic fields ─────────────────────────
  List<Widget> _fields(BuildContext context, AddTransactionController c, TxType t) {
    final fin = c.fin;
    final w = <Widget>[const SizedBox(height: 18)];
    void gap([double h = 12]) => w.add(SizedBox(height: h));
    void label(String s) => w.add(Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(s, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.slate, fontSize: 13)),
        ));

    // Category (income / expense)
    if (t.needsCategory) {
      label('Category');
      final cats = fin.categoriesOf(t.name);
      w.add(Wrap(spacing: 8, runSpacing: 8, children: [
        for (final cat in cats)
          Pill(
            label: cat.name,
            icon: AppIcons.of(cat.icon),
            color: hexColor(cat.color),
            selected: c.categoryId.value == cat.id,
            onTap: () => c.categoryId.value = cat.id,
          ),
        Pill(label: 'New', icon: Icons.add_rounded, selected: false, onTap: () => showCategoryEditor(type: t.name)),
      ]));
      gap(18);
    }

    // Loan selector for repayments
    if (t.isRepayment) {
      final loan = fin.loanById(c.loanId.value);
      w.add(SelectorField(
        label: t == TxType.repaymentReceived ? 'Repayment received from' : 'Repayment paid to',
        placeholder: 'Select a loan',
        icon: Icons.handshake_rounded,
        value: loan == null ? null : '${loan.person} · ${Fmt.money(fin.outstanding(loan))} left',
        onTap: c.pickLoan,
      ));
      gap();
    }

    // Direction (adjustment / misc)
    if (t.needsDirection) {
      w.add(SizedBox(
        width: double.infinity,
        child: SegmentedButton<String>(
          showSelectedIcon: false,
          style: SegmentedButton.styleFrom(selectedBackgroundColor: AppColors.emerald, selectedForegroundColor: Colors.white),
          segments: const [
            ButtonSegment(value: 'in', label: Text('Increase'), icon: Icon(Icons.add_rounded)),
            ButtonSegment(value: 'out', label: Text('Decrease'), icon: Icon(Icons.remove_rounded)),
          ],
          selected: {c.direction.value},
          onSelectionChanged: (s) => c.direction.value = s.first,
        ),
      ));
      gap();
    }

    // Person
    if (t.isLoanCreate || t == TxType.moneyReceived || t == TxType.moneySent) {
      final text = switch (t) {
        TxType.loanGiven => 'Lent to',
        TxType.loanTaken => 'Borrowed from',
        TxType.moneyReceived => 'Received from (optional)',
        _ => 'Sent to (optional)',
      };
      w.add(TextField(
        controller: c.personCtrl,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: text, prefixIcon: const Icon(Icons.person_rounded)),
      ));
      final people = fin.knownPeople.take(6).toList();
      if (people.isNotEmpty) {
        w.add(const SizedBox(height: 8));
        w.add(Wrap(spacing: 8, runSpacing: 6, children: [
          for (final p in people) Pill(label: p, selected: false, onTap: () => c.personCtrl.text = p),
        ]));
      }
      gap();
    }

    // Accounts
    final acc = fin.accountById(c.accountId.value);
    w.add(SelectorField(
      label: t == TxType.transfer ? 'From account' : (t == TxType.withdrawal ? 'Withdraw from' : (t == TxType.deposit ? 'Deposit into' : 'Account')),
      icon: Icons.account_balance_wallet_rounded,
      value: acc == null ? null : '${acc.name} · ${Fmt.money(fin.accountBalance(acc.id))}',
      onTap: c.pickAccount,
    ));
    gap();
    if (t == TxType.transfer) {
      final to = fin.accountById(c.toAccountId.value);
      w.add(const Center(child: Icon(Icons.south_rounded, color: AppColors.slate)));
      gap(8);
      w.add(SelectorField(
        label: 'To account',
        placeholder: 'Select destination',
        icon: Icons.account_balance_rounded,
        value: to == null ? null : '${to.name} · ${Fmt.money(fin.accountBalance(to.id))}',
        onTap: c.pickToAccount,
      ));
      gap();
    }

    // Dates
    final dateField = SelectorField(label: t.isLoanCreate ? 'Loan date' : 'Date', icon: Icons.event_rounded, value: Fmt.date(c.date.value), onTap: () => c.pickDate(context));
    if (t.isLoanCreate) {
      w.add(dateField);
      gap();
      w.add(SelectorField(
        label: 'Due date (optional)',
        placeholder: 'No due date',
        icon: Icons.event_available_rounded,
        value: c.dueDate.value == null ? null : Fmt.date(c.dueDate.value!),
        onTap: () => c.pickDueDate(context),
        onClear: () => c.dueDate.value = null,
      ));
    } else {
      w.add(dateField);
    }
    gap();

    // Title + note
    if (t.needsCategory || t.needsDirection || t == TxType.openingBalance || t == TxType.deposit || t == TxType.withdrawal) {
      w.add(TextField(controller: c.titleCtrl, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Title (optional)', prefixIcon: Icon(Icons.title_rounded))));
      gap();
    }
    w.add(TextField(controller: c.noteCtrl, maxLines: 2, minLines: 1, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(labelText: 'Note (optional)', prefixIcon: Icon(Icons.notes_rounded))));

    return w;
  }
}
