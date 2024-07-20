import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  Future<String?> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('themeMode');
  }

  Future<void> setThemeMode(String themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode);
  }

  Future<String?> getSortOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sortOrder');
  }

  Future<void> setSortOrder(String sortOrder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sortOrder', sortOrder);
  }
}