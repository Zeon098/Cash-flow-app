import 'package:intl/intl.dart';

class Fmt {
  Fmt._();

  /// Currency symbol, updated by FinanceController whenever settings load.
  static String symbol = 'Rs';

  static final NumberFormat _number = NumberFormat('#,##0.##');
  static final NumberFormat _compact = NumberFormat.compact();

  static String number(double v) => _number.format(v);

  static String money(double v, {bool sign = false}) {
    final body = '$symbol ${_number.format(v.abs())}';
    if (v < -0.004) return '-$body';
    if (sign && v > 0.004) return '+$body';
    return body;
  }

  static String compact(double v) => _compact.format(v);
  static String date(DateTime d) => DateFormat('d MMM yyyy').format(d);
  static String shortDate(DateTime d) => DateFormat('d MMM').format(d);
  static String month(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String monthShort(DateTime d) => DateFormat('MMM').format(d);
  static String iso(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  static String day(DateTime d) {
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final diff = today.difference(DateTime.utc(d.year, d.month, d.day)).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('EEE, d MMM').format(d);
  }

  static double round2(double v) => (v * 100).roundToDouble() / 100;
}

/// Defensive JSON readers (Sheets can return numbers as strings, etc.).
class Json {
  Json._();

  static String str(dynamic v) => v == null ? '' : v.toString();

  static double dbl(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(str(v).replaceAll(',', '')) ?? 0;
  }

  static DateTime? date(dynamic v) {
    final s = str(v).trim();
    if (s.length < 10) return null;
    final p = s.substring(0, 10).split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    final d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }
}
