import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider with ChangeNotifier {
  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  String _sortOrder = 'title';

  ThemeMode get themeMode => _themeMode;
  String get sortOrder => _sortOrder;

  PreferencesProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = _prefs.getString('themeMode') == 'dark' ? ThemeMode.dark : ThemeMode.light;
    _sortOrder = _prefs.getString('sortOrder') ?? 'title';
    notifyListeners();
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _prefs.setString('themeMode', mode == ThemeMode.dark ? 'dark' : 'light');
    notifyListeners();
  }

  Future<void> updateSortOrder(String order) async {
    _sortOrder = order;
    await _prefs.setString('sortOrder', order);
    notifyListeners();
  }
}