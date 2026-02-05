import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _seedColorKey = 'seed_color';

  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = Colors.amberAccent;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  ThemeProvider() {
    _loadTheme();
  }

  void setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  void setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.value);
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();

    final themeIndex = prefs.getInt(_themeKey);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
    }

    final colorValue = prefs.getInt(_seedColorKey);
    if (colorValue != null) {
      _seedColor = Color(colorValue);
    }

    notifyListeners();
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;
}
