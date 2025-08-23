import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A class that manages the application's theme state.
///
/// It uses SharedPreferences to persist the user's theme choice.
class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_preference';
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme(); // Load the saved theme preference on startup
  }

  /// Toggles the theme between light and dark mode.
  void toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    _saveTheme();
    notifyListeners(); // Notify all listening widgets to rebuild
  }

  /// Loads the theme preference from local storage.
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false; // Default to light mode
    notifyListeners();
  }

  /// Saves the current theme preference to local storage.
  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_themeKey, _isDarkMode);
  }
}