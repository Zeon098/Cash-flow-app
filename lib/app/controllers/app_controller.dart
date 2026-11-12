import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../data/providers/sheets_api_provider.dart';

/// App-level configuration: API connection and theme (no financial data).
class AppController extends GetxController {
  AppController(this._prefs, this._api);

  final SharedPreferences _prefs;
  final SheetsApiProvider _api;

  final apiUrl = ''.obs;
  final apiKey = ''.obs;
  final themeMode = ThemeMode.system.obs;

  bool get isConfigured => apiUrl.value.isNotEmpty;

  static ThemeMode themeFromName(String? name) =>
      ThemeMode.values.firstWhere((m) => m.name == name, orElse: () => ThemeMode.system);

  @override
  void onInit() {
    super.onInit();
    apiUrl.value = _prefs.getString(AppConstants.prefApiUrl) ?? '';
    apiKey.value = _prefs.getString(AppConstants.prefApiKey) ?? '';
    themeMode.value = themeFromName(_prefs.getString(AppConstants.prefTheme));
    applySaved();
  }

  /// Point the HTTP provider at a URL without persisting it (used to test).
  void applyConnection(String url, String key) => _api.configure(url, key);

  /// Restore the provider to the persisted connection.
  void applySaved() => _api.configure(apiUrl.value, apiKey.value);

  Future<void> saveConnection(String url, String key) async {
    apiUrl.value = url.trim();
    apiKey.value = key.trim();
    await _prefs.setString(AppConstants.prefApiUrl, apiUrl.value);
    await _prefs.setString(AppConstants.prefApiKey, apiKey.value);
    applySaved();
  }

  Future<void> clearConnection() async {
    apiUrl.value = '';
    apiKey.value = '';
    await _prefs.remove(AppConstants.prefApiUrl);
    await _prefs.remove(AppConstants.prefApiKey);
    applySaved();
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    await _prefs.setString(AppConstants.prefTheme, mode.name);
  }
}
