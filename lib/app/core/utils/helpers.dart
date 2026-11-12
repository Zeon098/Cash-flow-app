import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';

T? findFirst<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) return item;
  }
  return null;
}

/// Unique id attached to every write so the backend can ignore duplicates.
String newRequestId() => '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 30)}';

Color hexColor(String? hex, [Color fallback = AppColors.slate]) {
  if (hex == null || hex.isEmpty) return fallback;
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  final v = int.tryParse(h, radix: 16);
  return v == null ? fallback : Color(v);
}

String colorToHex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

class AppIcons {
  AppIcons._();
  static const Map<String, IconData> map = {
    'work': Icons.work_rounded,
    'storefront': Icons.storefront_rounded,
    'laptop': Icons.laptop_mac_rounded,
    'card_giftcard': Icons.card_giftcard_rounded,
    'replay': Icons.replay_rounded,
    'trending_up': Icons.trending_up_rounded,
    'home_work': Icons.home_work_rounded,
    'payments': Icons.payments_rounded,
    'restaurant': Icons.restaurant_rounded,
    'shopping_cart': Icons.shopping_cart_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'house': Icons.house_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'local_gas_station': Icons.local_gas_station_rounded,
    'directions_car': Icons.directions_car_rounded,
    'local_hospital': Icons.local_hospital_rounded,
    'school': Icons.school_rounded,
    'movie': Icons.movie_rounded,
    'subscriptions': Icons.subscriptions_rounded,
    'flight': Icons.flight_rounded,
    'family_restroom': Icons.family_restroom_rounded,
    'category': Icons.category_rounded,
    'account_balance_wallet': Icons.account_balance_wallet_rounded,
    'account_balance': Icons.account_balance_rounded,
    'smartphone': Icons.smartphone_rounded,
    'credit_card': Icons.credit_card_rounded,
    'savings': Icons.savings_rounded,
    'more_horiz': Icons.more_horiz_rounded,
  };

  static IconData of(String? key, [IconData fallback = Icons.category_rounded]) => map[key] ?? fallback;
  static List<String> get keys => map.keys.toList();
}

class AppPalette {
  AppPalette._();
  static const List<String> hex = [
    '#10B981', '#0EA5E9', '#8B5CF6', '#EC4899', '#F59E0B', '#14B8A6', '#6366F1', '#F97316',
    '#84CC16', '#EAB308', '#EF4444', '#F43F5E', '#D946EF', '#06B6D4', '#64748B',
  ];
  static final List<Color> fallback = hex.map((h) => hexColor(h)).toList();
}

class Toast {
  Toast._();

  static void success(String message) => _show('Done', message, AppColors.emeraldDeep, Icons.check_circle_rounded);
  static void error(String message) => _show('Something went wrong', message, AppColors.coralDeep, Icons.error_rounded);
  static void info(String message) => _show('Heads up', message, const Color(0xFF334155), Icons.info_rounded);

  static void _show(String title, String message, Color color, IconData icon) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: color,
      colorText: Colors.white,
      margin: const EdgeInsets.all(14),
      borderRadius: 16,
      icon: Icon(icon, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }
}
