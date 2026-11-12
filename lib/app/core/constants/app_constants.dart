class AppConstants {
  AppConstants._();
  static const appName = 'CashFlow';
  static const prefApiUrl = 'cashflow.api_url';
  static const prefApiKey = 'cashflow.api_key';
  static const prefTheme = 'cashflow.theme_mode';
  static const defaultCurrency = 'PKR';
  static const requestTimeout = Duration(seconds: 45);
}

class Currencies {
  Currencies._();
  static const Map<String, String> symbols = {
    'PKR': 'Rs',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'AED',
    'SAR': 'SAR',
    'INR': '₹',
    'BDT': '৳',
    'CAD': r'C$',
    'AUD': r'A$',
    'JPY': '¥',
    'CNY': 'CN¥',
    'TRY': '₺',
  };
  static String symbolOf(String code) => symbols[code] ?? code;
}

class AccountTypes {
  AccountTypes._();
  static const Map<String, String> labels = {
    'cash': 'Cash',
    'bank': 'Bank',
    'wallet': 'Wallet',
    'card': 'Card',
    'savings': 'Savings',
  };
  static const Map<String, String> icons = {
    'cash': 'payments',
    'bank': 'account_balance',
    'wallet': 'account_balance_wallet',
    'card': 'credit_card',
    'savings': 'savings',
  };
}
