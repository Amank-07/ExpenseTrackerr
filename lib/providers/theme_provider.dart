import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider();

  static const String _isDarkKey = 'theme_is_dark';

  bool _isDark = false;
  bool _isLoading = true;

  bool get isDark => _isDark;
  bool get isLoading => _isLoading;

  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_isDarkKey) ?? false;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkKey, _isDark);
  }
}

